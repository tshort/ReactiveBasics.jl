# ReactiveBasics

This package implements basic functionality for a type of Functional Reactive Programming (FRP). 
This is a style of DataFlow programming where updates propagate to other objects automatically.
It follows the same basic API as [Reactive.jl](http://juliagizmos.github.io/Reactive.jl/). Much of
the [documentation for Reactive](http://juliagizmos.github.io/Reactive.jl/) applies to ReactiveBasics.

## Example

The `Signal` type holds values that can depend on other `Signal`s. 
`map(f, xs...)` returns a new Signal that depends on one or more Signals `xs...`. 
The function `f` defines the value that the Signal should take as a function of the values of each of the input Signals. 
When a `Signal` is updated using `push!`, changes propagate to dependent `Signal`s. 
Here is an example taken from Reactive.jl:

```@repl
using ReactiveBasics
x = Signal(0)
value(x)
push!(x, 42)
value(x)
xsquared = map(a -> a*a, x)
value(xsquared)
push!(x, 3)
value(xsquared)
```

Various utility functions are available to manipulate signals, including:

- [`subscribe!`](@ref) -- Subscribe to the changes of a Signal. 
- [`merge`](@ref) -- Combine Signals.
- [`zip`](@ref) -- Combine Signals as a Tuple.
- [`filter`](@ref) -- A Signal filtered based on a function.
- [`foldp`](@ref) -- Fold/map over past values.
- [`flatmap`](@ref) -- Like `map`, but it's meant for functions that return `Signal`s.
- [`asyncmap`](@ref) -- Like `map`, but it updates asynchronously.


## Change propagation

The main difference between ReactiveBasics and Reactive.jl is that Signals propagate immediately 
(synchronous operation) in ReactiveBasics. There is no event queue.
The implementation uses closures derived from the approach used in the Swift package 
[Interstellar](https://github.com/JensRavens/Interstellar).
The difference in operation makes ReactiveBasics as much as ten times faster than Reactive. 
But, because ReactiveBasics is synchronous, this leads to limitations. One is that there 
can be race conditions for asynchronous inputs. Those have to be manually handled. Another 
issue is that calculations can be triggered twice if there are mutual dependencies.

ReactiveBasics uses [push-style](https://en.wikipedia.org/wiki/Reactive_programming#Change_Propagation_Algorithms) 
reactive programming. When `push!` is used to update a signal, dependencies of this Signal 
update in depth-first fashion. 

Here is an example that leads to double calculations:

```@example
using ReactiveBasics
x = Signal(2)
x2 = map(u -> 2u, x)
y = map(+, x2, x) 
subscribe!(u -> println("value of y: $u"), y)
push!(x, 3)
```

This `push!` will trigger `y` to update twice. The update to `x` triggers the update to `x2`. The update
to `x2` triggers the update to `y`. But because `y` also depends on `x`, it updates a second time. 
Both times, the resulting value for `y` is right, but this effect will be
important if a Signal accumulates or otherwise depends on history or the number of calculations.

## Handling asynchronous Signals

Even though ReactiveBasics uses direct, push-style processing, it is possible to handle asynchronous Signals.
For long calculations or for input/output, it's often convenient to return a Signal with the end result rather than just a value. 
That allows updates to propagate correctly. 
`flatmap` is a useful utility for managing operations that return Signals. 
See the [space-station example](https://github.com/tshort/ReactiveBasics.jl/blob/master/examples/space-station.jl) 
by GitHub user [nixterrimus](https://github.com/nixterrimus).

Another way to handle asynchronous Signals is to set up a queue of Signals. 
See [this example](https://github.com/tshort/ReactiveBasics.jl/blob/master/examples/shashi-race-condition.jl). 

## Other notes

This is a basic implementation. There is no support for error checking, time, or sampling. My main use
case is with [Sims](https://github.com/tshort/Sims.jl), and that doesn't need a lot of features.

