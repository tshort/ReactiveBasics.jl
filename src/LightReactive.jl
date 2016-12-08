module LightReactive

export Signal, value, foldp, subscribe!

# Derived from the Swift Interstellar package
# https://github.com/JensRavens/Interstellar/blob/master/Sources/Signal.swift
# Copyright (c) 2015 Jens Ravens (http://jensravens.de)
# Offered with the MIT license


"""
A Signal is value that will contain a value in the future.
The value of a signal can change at any time.

Use `next` to subscribe to updates and `update` to update the current value of the signal.

    text = Signal<String>()

    text.next { string in
        println("Hello \(string)")
    }

    text.update(.Success("World"))
"""

type Signal{T}
   value::T
   callbacks::Vector{Function}     # Is Function too restrictive here?
end

Signal(val) = Signal(val, Function[])

value(u::Signal) = u.value

"""
Transform the signal into another signal using a function.
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
        subscribe!(x -> push!(signal, f((i == j ? x : us[j].value for j in 1:length(us)))), u)
    end
    signal
end

"""
Update the value of a Signal and propagate the change.
"""
function Base.push!(u::Signal, val)
    u.value = val
    map(f -> f(val), u.callbacks)
end

"""
Subscribe to the changes of this signal.
"""
function subscribe!(f, u::Signal)
    push!(u.callbacks, f)
    u
end



"""
Merge another signal into the current signal. This creates a signal that is
a success if both source signals are a success. The value of the signal is a
Tuple of the values of the contained signals.
    
    signal = merge(Signal("Hello"), Signal("World"))
    value(signal)
"""
Base.merge(f, us::Signal...) = map!()
function Base.merge(u::Signal, v::Signal)
    signal = Signal((u.value, v.value))
    subscribe!(x -> push!(signal, (x, v.value)), u)
    subscribe!(x -> push!(signal, (u.value, x)), v)
    signal
end
function Base.merge(u::Signal, v::Signal, w::Signal)
    signal = Signal((u.value, v.value, w.value))
    subscribe!(x -> push!(signal, (x, v.value, w.value)), u)
    subscribe!(x -> push!(signal, (u.value, x, w.value)), v)
    subscribe!(x -> push!(signal, (u.value, v.value, x)), w)
    signal
end
function Base.merge(u::Signal, v::Signal, w::Signal, xs::Signal...)
    us = (u,v,w,xs...)
    signal = Signal((u.value for u in us))
    for (i,u) in enumerate(us)
        subscribe!(x -> push!(signal, (i == j ? x : us[j].value for j in 1:length(us))), u)
    end
    signal
end

"""
Fold/map over past values
"""
function foldp(f, v0, us::Signal...)
    map(x -> v0 = f(v0, x), us...)
end

"""
Filter
"""
function Base.filter{T}(f, default::T, u::Signal{T})
    signal = Signal(f(u.value) ? u.value : default)
    subscribe!(result -> f(result) && push!(signal, result), u)
    signal
end

end # module
