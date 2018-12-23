module ReactiveBasics

using DocStringExtensions, DataStructures

export Signal, value, foldp, subscribe!, unsubscribe!, flatmap, flatten, bind!,
       droprepeats, skip, previous, sampleon, preserve, filterwhen, zipmap

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
The type of the Signal can optionally be set by the first parameter. Otherwise
it will default to the type of the initial value.

```julia
text = Signal("")

text2 = map(s -> "Bye \$s", text)

subscribe!(text) do s
    println("Hello \$s")
end

push!(text, "world")

value(text)
value(text2)

float_number = Signal(Float64, 1) # Optionally set the type of the Signal
```
"""
mutable struct Signal{T}
   value::T
   callbacks::Vector{Function}   # usually Functions, but could be other callable types
end

Signal(val) = Signal(val, Function[])

Signal{T}(::Type{T}, val) = Signal{T}(val, Function[])

Base.eltype{T}(::Type{Signal{T}}) = T

"""
$(SIGNATURES)

The current value of the Signal `u`.
"""
value(u::Signal) = u.value

"""
$(SIGNATURES)

Transform the Signal into another Signal using a function. The initial value of
the output Signal can optionally be set via `init`. Otherwise it defaults to
`f(u.value)`, where f is the passed function and u is the passed Signal. The type
of the output Signal can optionally be set via `typ`. Otherwise it defaults to
the type of the initial value.
"""
function Base.map(f, u::Signal; init = f(u.value), typ = typeof(init))
    signal = Signal(typ, init)
    subscribe!(x -> push!(signal, f(x)), u)
    signal
end
function Base.map(f, u::Signal, v::Signal; init = f(u.value, v.value), typ = typeof(init))
    signal = Signal(typ, init)
    subscribe!(x -> push!(signal, f(x, v.value)), u)
    subscribe!(x -> push!(signal, f(u.value, x)), v)
    signal
end
function Base.map(f, u::Signal, v::Signal, w::Signal; init = f(u.value, v.value, w.value), typ = typeof(init))
    signal = Signal(typ, init)
    subscribe!(x -> push!(signal, f(x, v.value, w.value)), u)
    subscribe!(x -> push!(signal, f(u.value, x, w.value)), v)
    subscribe!(x -> push!(signal, f(u.value, v.value, x)), w)
    signal
end
function Base.map(f, u::Signal, v::Signal, w::Signal, xs::Signal...; init = f((u.value for u in (u,v,w,xs...))...), typ = typeof(init))
    us = (u,v,w,xs...)
    signal = Signal(typ, init)
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
but it's meant for functions that return `Signal`s. The initial value of
the output Signal can optionally be set via `init`. Otherwise it defaults to
`f(input.value).value`, where f is the passed function and input is the passed
Signal of Signals. The type of the output Signal can optionally be set via `typ`.
Otherwise it defaults to the type of the initial value.
"""
function flatmap(f, input::Signal; init = f(input.value).value, typ = typeof(init))
    signal = Signal(typ, init)
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

Zips given signals first and then applies the `map` function onto the
zipped value. This omits the double calculation when using `map`. The
initial value of the output Signal can optionally be set via `init`. Otherwise
it defaults to `f(zip(u, us...).value...)`, where f is the passed function and
(u, us...) are the passed Signals. The type of the output Signal can optionally
be set via `typ`. Otherwise it defaults to the type of the initial value.

    as = Signal(1)
    bs = map(a -> a * 0.1, as)
    cs = zipmap((a,b) -> a + b, as, bs) # This calculation is done once for
                                        # every change in `as`
"""
function zipmap(f, u::Signal, us::Signal...; init = f(zip(u, us...).value...), typ = typeof(init), max_buffer_size = 0)
    zipped_signal = zip(u, us..., max_buffer_size = max_buffer_size)
    signal = Signal(typ, init)
    subscribe!(x -> push!(signal, f(x...)), zipped_signal)
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
function Base.zip(u::Signal, us::Signal...; max_buffer_size = 0)
    signals = (u,us...)
    signal = Signal(Tuple{map(eltype, signals)...}, map(value, signals))
    pasts = map(u -> max_buffer_size != 0 ? CircularDeque{eltype(u)}(max_buffer_size) : Deque{eltype(u)}(), signals)
    for i in 1:length(signals)
        subscribe!(signals[i]) do u
            push!(pasts[i], u)
            if all(map(!isempty, pasts))
                push!(signal, map(shift!, pasts))
            end
        end
    end
    signal
end

"""
$(SIGNATURES)

Merge Signals into the current Signal. The value of the Signal is that from
the most recent update.
"""
function Base.merge(u::Signal, us::Signal...)
    signal = Signal(typejoin(map(eltype, (u, us...))...), u.value)
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
    v0r = Base.RefValue(v0)
    map((x...) -> v0r[] = f(v0r[], x...), us...)
end

"""
Return a Signal that updates based on the Signal `u` if `f(value(u))` evaluates to `true`.
"""
function Base.filter(f, default, u::Signal)
    signal = Signal(T, f(u.value) ? u.value : default)
    subscribe!(result -> f(result) && push!(signal, result), u)
    signal
end

"""
$(SIGNATURES)

Keep updates to `u` only when `predicate` is true.
If `predicate` is false initially, the specified `default` value is used.
"""
function filterwhen(predicate::Signal{Bool}, default, u::Signal)
    signal = Signal(T, predicate.value ? u.value : default)
    subscribe!(result -> predicate.value && push!(signal, result), u)
    subscribe!(v -> v && push!(signal, u.value), predicate)
    signal
end

"""
$(SIGNATURES)

An asynchronous version of `map` that returns a Signal that is updated after `f`
operates asynchronously. The initial value of the returned Signal
(the `init` arg) must be supplied. The type of the output Signal can optionally
be set via `typ`. Otherwise it defaults to the type of the initial value.
"""
function Base.asyncmap(f, init, input::Signal, inputs::Signal...; typ = typeof(init))
    result = Signal(typ, init)
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
    sigref = Base.RefValue(input.value)
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

For every update to `b` also update `a` with the same value and, if `twoway` is true,
ice-versa.
If `initial` is set to true, `a` is updated immediately and, if `twoway` is true, `b`
is updated immediately as well.
"""
function bind!(a::Signal, b::Signal, twoway = true; initial = true)
    if initial
        push!(a, b.value)
        if twoway
            push!(b, a.value)
        end
    end
    if twoway
        subscribe!(u -> u != value(b) && push!(b, u), a)
    end
    subscribe!(u -> u != value(a) && push!(a, u), b)
end

"""
$(SIGNATURES)

Drop updates to `input` whenever the new value is the same
as the previous value of the Signal.
"""
function droprepeats{T}(input::Signal{T})
    result = Signal(T, value(input))
    subscribe!(u -> u != value(result) && push!(result, u), input)
    result
end

"""
$(SIGNATURES)

Continuously skip a predefined number of updates to `input`
"""
function Base.skip{T}(num::Int, input::Signal{T})
    result = Signal(T, value(input))
    counter = 1
    subscribe!(input) do u
        mod(counter, num + 1) == 0 && push!(result, u)
        counter = mod(counter, num + 1) + 1
    end
    result
end

"""
$(SIGNATURES)

Create a Signal which holds the previous value of `input`.
You can optionally specify a different initial value.
"""
function previous(input::Signal, default=value(input))
    past = Base.RefValue(default)
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
function sampleon{T}(a::Signal, b::Signal{T})
    result = Signal(T, value(b))
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
