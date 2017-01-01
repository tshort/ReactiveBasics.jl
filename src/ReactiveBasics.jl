module ReactiveBasics

export Signal, value, foldp, subscribe!, flatmap

# This API mainly follows that of Reactive.jl. 

# The algorithms for were derived from the Swift Interstellar package
# https://github.com/JensRavens/Interstellar/blob/master/Sources/Signal.swift
# Copyright (c) 2015 Jens Ravens (http://jensravens.de)
# Offered with the MIT license


"""
A `Signal` is value that will contain a value in the future.
The value of the Signal can change at any time.

Use `map` to derive new Signals, `subscribe!` to subscribe to updates of a Signal,
and `push!` to update the current value of a Signal. `value` returns the current
value of a Signal.

```julia
text = Signal("")

text2 = map(s -> "Bye \$s", text)

subscribe!(text) do s
    println("Hello \$s")
end

push!(text, "world")

value(text)
value(text2)
```
"""
type Signal{T}
   value::T
   callbacks::Vector{Function}   # usually Functions, but could be other callable types
end

Signal(val) = Signal(val, Function[])

"""
$(SIGNATURES)

The current value of the Signal `u`.
"""
value(u::Signal) = u.value

"""
$(SIGNATURES)

Transform the Signal into another Signal using a function.
"""
function Base.map(f, u::Signal)
    signal = Signal(f(u.value))
    subscribe!(x -> push!(signal, f(x)), u)
    signal
end
function Base.map(f, u::Signal, v::Signal)
    signal = Signal(f(u.value, v.value))
    subscribe!(x -> push!(signal, f(x, v.value)), u)
    subscribe!(x -> push!(signal, f(u.value, x)), v)
    signal
end
function Base.map(f, u::Signal, v::Signal, w::Signal)
    signal = Signal(f(u.value, v.value, w.value))
    subscribe!(x -> push!(signal, f(x, v.value, w.value)), u)
    subscribe!(x -> push!(signal, f(u.value, x, w.value)), v)
    subscribe!(x -> push!(signal, f(u.value, v.value, x)), w)
    signal
end
function Base.map(f, u::Signal, v::Signal, w::Signal, xs::Signal...)
    us = (u,v,w,xs...)
    signal = Signal(f((u.value for u in us)...))
    for (i,u) in enumerate(us)
        subscribe!(u) do x
            vals = f(((i == j ? x : us[j].value for j in 1:length(us))...)...)
            push!(signal, vals)
        end
    end
    signal
end

"""
$(SIGNATURES)

Transform the Signal into another Signal using a function. It's like `map`, 
but it's meant for functions that return `Signal`s.
"""
function flatmap(f, u::Signal, us::Signal...)
    map((x...) -> f(x...).value, u, us...)
end

"""
$(SIGNATURES)

Update the value of a Signal and propagate the change.
"""
function Base.push!(u::Signal, val)
    u.value = val
    foreach(f -> f(val), u.callbacks)
end

"""
$(SIGNATURES)

Subscribe to the changes of this Signal. Every time the Signal is updated, the function `f` runs.
"""
function subscribe!(f, u::Signal)
    push!(u.callbacks, f)
    u
end


"""
$(SIGNATURES)

Zip (combine) Signals into the current Signal. The value of the Signal is a
Tuple of the values of the contained Signals.
    
    signal = zip(Signal("Hello"), Signal("World"))
    value(signal)    # ("Hello", "World")
"""
function Base.zip(u::Signal, us::Signal...)
    map((args...) -> (args...), u, us...)
end

"""
$(SIGNATURES)

Merge Signals into the current Signal. The value of the Signal is that from
the most recent update.
"""
function Base.merge(u::Signal, us::Signal...)
    signal = Signal(u.value)
    for v in (u, us...)
        subscribe!(x -> push!(signal, x), v)
    end
    signal
end

"""
$(SIGNATURES)

Fold/map over past values. The first argument to the function `f`
is an accumulated value that the function can operate over, and the 
second is the current value coming in. `v0` is the initial value of
the accumulated value.

    a = Signal(2)
    # accumulate sums coming in from a, starting at zero
    b = foldp(+, 0, a) # b == 2
    push!(a, 2)        # b == 4
    push!(a, 3)        # b == 7
"""
function foldp(f, v0, us::Signal...)
    v0r = Ref(v0)
    map((x...) -> v0r[] = f(v0r[], x...), us...)
end

"""
Return a Signal that updates based on the Signal `u` if `f(value(u))` evaluates to `true`.
"""
function Base.filter{T}(f, default::T, u::Signal{T})
    signal = Signal(f(u.value) ? u.value : default)
    subscribe!(result -> f(result) && push!(signal, result), u)
    signal
end

"""
$(SIGNATURES)

An asynchronous version of `map` that returns a Signal that is updated after `f` operates asynchronously.
The initial value of the returned Signal (the `init` arg) must be supplied.
"""
function Base.asyncmap(f, init, input::Signal, inputs::Signal...)
    result = Signal(init)
    map(input, inputs...) do args...
        @async push!(result, f(args...))
    end
    result
end

end # module