module ReactiveBasics

using DocStringExtensions

export Signal, value, foldp, subscribe!, flatmap, flatten, bind!, droprepeats, previous, sampleon, preserve, filterwhen

# This API mainly follows that of Reactive.jl.

# The algorithms for were derived from the Swift Interstellar package
# https://github.com/JensRavens/Interstellar/blob/master/Sources/Signal.swift
# Copyright (c) 2015 Jens Ravens (http://jensravens.de)
# Offered with the MIT license


"""
A `Signal` is value that will contain a value in the future.
The value of the Signal can change at any time.

Use `map` to derive new Signals, `subscribe!` to subscribe to updates of a Signal,
and `push!` to update the current value of a Signal.
`value` returns the current value of a Signal.

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
function flatmap(f, input::Signal)
    signal = Signal(f(input.value).value)
    subscribe!(input) do u
        innersig = f(u)
        push!(signal, innersig.value)
        subscribe!(innersig) do v
            push!(signal, v)
        end
    end
    signal
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

Unsubscribe to the changes of this Signal.
"""
function unsubscribe!(f, u::Signal)
    u.callbacks = filter(a -> a != f, u.callbacks)
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

Keep updates to `input` only when `switch` is true.
If switch is false initially, the specified default value is used.
"""
function filterwhen{T}(predicate::Signal{Bool}, default::T, u::Signal{T})
    signal = Signal(predicate.value ? u.value : default)
    subscribe!(result -> predicate.value && push!(signal, result), u)
    subscribe!(v -> v && push!(signal, u.value), predicate)
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

"""
$(SIGNATURES)

Flatten a Signal of Signals into a Signal which holds the
value of the current Signal.
"""
function flatten(input::Signal)
    sigref = Ref(input.value)
    signal = Signal(input.value.value)
    updater = u -> push!(signal, u)
    subscribe!(updater, input.value)
    subscribe!(input) do u
        push!(signal, u.value)
        unsubscribe!(updater, sigref[])
        subscribe!(updater, u)
        sigref[] = u
    end
    push!(input, input.value)
    signal
end


"""
$(SIGNATURES)

For every update to `a` also update `b` with the same value and vice-versa.
Initially update `a` with the value in `b`.
"""
function bind!(a::Signal, b::Signal)
    push!(a, b.value)
    subscribe!(u -> u != value(b) && push!(b, u), a)
    subscribe!(u -> u != value(a) && push!(a, u), b)
end

"""
$(SIGNATURES)

Drop updates to `input` whenever the new value is the same
as the previous value of the Signal.
"""
function droprepeats(input::Signal)
    result = Signal(value(input))
    subscribe!(u -> u != value(result) && push!(result, u), input)
    result
end

"""
$(SIGNATURES)

Create a Signal which holds the previous value of `input`.
You can optionally specify a different initial value.
"""
function previous(input::Signal, default=value(input))
    past = Ref(default)
    map(input) do u
        res = past[]
        past[] = u
        res
    end
end

"""
$(SIGNATURES)

Sample the value of `b` whenever `a` updates.
"""
function sampleon(a::Signal, b::Signal)
    result = Signal(value(b))
    subscribe!(u -> push!(result, value(b)), a)
    result
end

"""
$(SIGNATURES)

For compatibility with Reactive.
It just returns the original Signal because this isn't needed with direct `push!` updates.
"""
function preserve(x::Signal)
    x
end


end # module
