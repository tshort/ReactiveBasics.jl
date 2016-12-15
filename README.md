# ReactiveBasics

[![Build Status](https://travis-ci.org/tshort/ReactiveBasics.jl.svg?branch=master)](https://travis-ci.org/tshort/ReactiveBasics.jl)

[![Coverage Status](https://coveralls.io/repos/tshort/ReactiveBasics.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/tshort/ReactiveBasics.jl?branch=master)

[![codecov.io](http://codecov.io/github/tshort/ReactiveBasics.jl/coverage.svg?branch=master)](http://codecov.io/github/tshort/ReactiveBasics.jl?branch=master)


This package implements basic functionality for a type of Functional Reactive Programming (FRP). 
This is a style of DataFlow programming where updates propagate to other objects automatically.
It follows the same basic API as [Reactive.jl](http://julialang.github.io/Reactive.jl/). 
The main difference is that Signals propagate immediately (synchronous operation). There is no event queue.
The implementation uses closures derived from the approach used in the Swift package [Interstellar](https://github.com/JensRavens/Interstellar).
The difference in operation makes ReactiveBasics as much as ten times faster than Reactive. 
But, because ReactiveBasics is synchronous, this leads to limitations. One is that there 
can be race conditions for asynchronous inputs. Those have to be manually handled. Another 
issue is that calculations can be triggered twice if there are mutual dependencies.

As of now, this is a basic implementation. There is no support for error checking, time, or sampling. My main use
case is with [Sims](https://github.com/tshort/Sims.jl), and that doesn't need a lot of features.
