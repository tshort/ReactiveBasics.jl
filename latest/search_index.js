var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#ReactiveBasics-1",
    "page": "Home",
    "title": "ReactiveBasics",
    "category": "section",
    "text": "This package implements basic functionality for a type of Functional Reactive Programming (FRP).  This is a style of DataFlow programming where updates propagate to other objects automatically. It follows the same basic API as Reactive.jl. Much of the documentation for Reactive applies to ReactiveBasics."
},

{
    "location": "index.html#Example-1",
    "page": "Home",
    "title": "Example",
    "category": "section",
    "text": "The Signal type holds values that can depend on other Signals.  map(f, xs...) returns a new Signal that depends on one or more Signals xs....  The function f defines the value that the Signal should take as a function of the values of each of the input Signals.  When a Signal is updated using push!, changes propagate to dependent Signals.  Here is an example taken from Reactive.jl:using ReactiveBasics\nx = Signal(0)\nvalue(x)\npush!(x, 42)\nvalue(x)\nxsquared = map(a -> a*a, x)\nvalue(xsquared)\npush!(x, 3)\nvalue(xsquared)Various utility functions are available to manipulate signals, including:subscribe! – Subscribe to the changes of a Signal. \nmerge – Combine Signals.\nzip – Combine Signals as a Tuple.\nfilter – A Signal filtered based on a function.\nfoldp – Fold/map over past values.\nflatmap – Like map, but it's meant for functions that return Signals.\nasyncmap – Like map, but it updates asynchronously.\nflatten – Flatten a Signal of Signals.\nbind! – Bind two Signals, so that updates to one are synchronized with the other.\ndroprepeats – Drop repeats in the input Signal.\nprevious – A Signal with the previous value of the input Signal.\nsampleon – Sample one Signal when another changes.\npreserve – No-op for compatibility with Reactive."
},

{
    "location": "index.html#Change-propagation-1",
    "page": "Home",
    "title": "Change propagation",
    "category": "section",
    "text": "The main difference between ReactiveBasics and Reactive.jl is that Signals propagate immediately  (synchronous operation) in ReactiveBasics. There is no event queue. The implementation uses closures derived from the approach used in the Swift package  Interstellar. The difference in operation makes ReactiveBasics as much as ten times faster than Reactive.  But, because ReactiveBasics is synchronous, this leads to limitations. One is that there  can be race conditions for asynchronous inputs. Those have to be manually handled. Another  issue is that calculations can be triggered twice if there are mutual dependencies.ReactiveBasics uses push-style  reactive programming. When push! is used to update a signal, dependencies of this Signal  update in depth-first fashion. Here is an example that leads to double calculations:using ReactiveBasics\nx = Signal(2)\nx2 = map(u -> 2u, x)\ny = map(+, x2, x) \nsubscribe!(u -> println(\"value of y: $u\"), y)\npush!(x, 3)This push! will trigger y to update twice. The update to x triggers the update to x2. The update to x2 triggers the update to y. But because y also depends on x, it updates a second time.  Both times, the resulting value for y is right, but this effect will be important if a Signal accumulates or otherwise depends on history or the number of calculations."
},

{
    "location": "index.html#Handling-asynchronous-Signals-1",
    "page": "Home",
    "title": "Handling asynchronous Signals",
    "category": "section",
    "text": "Even though ReactiveBasics uses direct, push-style processing, it is possible to handle asynchronous Signals. For long calculations or for input/output, it's often convenient to return a Signal with the end result rather than just a value.  That allows updates to propagate correctly.  flatmap is a useful utility for managing operations that return Signals.  See the space-station example  by GitHub user nixterrimus.Another way to handle asynchronous Signals is to set up a queue of Signals.  See this example. "
},

{
    "location": "index.html#Other-notes-1",
    "page": "Home",
    "title": "Other notes",
    "category": "section",
    "text": "This is a basic implementation. There is no support for error checking, time, or sampling. My main use case is with Sims, and that doesn't need a lot of features."
},

{
    "location": "api.html#",
    "page": "API",
    "title": "API",
    "category": "page",
    "text": ""
},

{
    "location": "api.html#ReactiveBasics.Signal",
    "page": "API",
    "title": "ReactiveBasics.Signal",
    "category": "Type",
    "text": "A Signal is value that will contain a value in the future. The value of the Signal can change at any time.\n\nUse map to derive new Signals, subscribe! to subscribe to updates of a Signal, and push! to update the current value of a Signal.  value returns the current value of a Signal.\n\ntext = Signal(\"\")\n\ntext2 = map(s -> \"Bye $s\", text)\n\nsubscribe!(text) do s\n    println(\"Hello $s\")\nend\n\npush!(text, \"world\")\n\nvalue(text)\nvalue(text2)\n\n\n\n"
},

{
    "location": "api.html#ReactiveBasics.bind!-Tuple{ReactiveBasics.Signal,ReactiveBasics.Signal}",
    "page": "API",
    "title": "ReactiveBasics.bind!",
    "category": "Method",
    "text": "bind!(a, b)\n\n\nFor every update to a also update b with the same value and vice-versa. Initially update a with the value in b.\n\n\n\n"
},

{
    "location": "api.html#ReactiveBasics.droprepeats-Tuple{ReactiveBasics.Signal}",
    "page": "API",
    "title": "ReactiveBasics.droprepeats",
    "category": "Method",
    "text": "droprepeats(input)\n\n\nDrop updates to input whenever the new value is the same as the previous value of the Signal.\n\n\n\n"
},

{
    "location": "api.html#ReactiveBasics.flatmap-Tuple{Any,ReactiveBasics.Signal}",
    "page": "API",
    "title": "ReactiveBasics.flatmap",
    "category": "Method",
    "text": "flatmap(f, input)\n\n\nTransform the Signal into another Signal using a function. It's like map,  but it's meant for functions that return Signals.\n\n\n\n"
},

{
    "location": "api.html#ReactiveBasics.flatten-Tuple{ReactiveBasics.Signal}",
    "page": "API",
    "title": "ReactiveBasics.flatten",
    "category": "Method",
    "text": "flatten(input)\n\n\nFlatten a Signal of Signals into a Signal which holds the value of the current Signal. \n\n\n\n"
},

{
    "location": "api.html#ReactiveBasics.foldp-Tuple{Any,Any,Vararg{ReactiveBasics.Signal,N} where N}",
    "page": "API",
    "title": "ReactiveBasics.foldp",
    "category": "Method",
    "text": "foldp(f, v0, us)\n\n\nFold/map over past values. The first argument to the function f is an accumulated value that the function can operate over, and the  second is the current value coming in. v0 is the initial value of the accumulated value.\n\na = Signal(2)\n# accumulate sums coming in from a, starting at zero\nb = foldp(+, 0, a) # b == 2\npush!(a, 2)        # b == 4\npush!(a, 3)        # b == 7\n\n\n\n"
},

{
    "location": "api.html#ReactiveBasics.preserve-Tuple{ReactiveBasics.Signal}",
    "page": "API",
    "title": "ReactiveBasics.preserve",
    "category": "Method",
    "text": "preserve(x)\n\n\nFor compatibility with Reactive.  It just returns the original Signal because this isn't needed with direct push! updates.\n\n\n\n"
},

{
    "location": "api.html#ReactiveBasics.previous",
    "page": "API",
    "title": "ReactiveBasics.previous",
    "category": "Function",
    "text": "previous(input, default)\nprevious(input)\n\n\nCreate a Signal which holds the previous value of input. You can optionally specify a different initial value.\n\n\n\n"
},

{
    "location": "api.html#ReactiveBasics.sampleon-Tuple{ReactiveBasics.Signal,ReactiveBasics.Signal}",
    "page": "API",
    "title": "ReactiveBasics.sampleon",
    "category": "Method",
    "text": "sampleon(a, b)\n\n\nSample the value of b whenever a updates.\n\n\n\n"
},

{
    "location": "api.html#ReactiveBasics.subscribe!-Tuple{Any,ReactiveBasics.Signal}",
    "page": "API",
    "title": "ReactiveBasics.subscribe!",
    "category": "Method",
    "text": "subscribe!(f, u)\n\n\nSubscribe to the changes of this Signal. Every time the Signal is updated, the function f runs.\n\n\n\n"
},

{
    "location": "api.html#ReactiveBasics.value-Tuple{ReactiveBasics.Signal}",
    "page": "API",
    "title": "ReactiveBasics.value",
    "category": "Method",
    "text": "value(u)\n\n\nThe current value of the Signal u.\n\n\n\n"
},

{
    "location": "api.html#Base.Iterators.zip-Tuple{ReactiveBasics.Signal,Vararg{ReactiveBasics.Signal,N} where N}",
    "page": "API",
    "title": "Base.Iterators.zip",
    "category": "Method",
    "text": "zip(u, us)\n\n\nZip (combine) Signals into the current Signal. The value of the Signal is a Tuple of the values of the contained Signals.\n\nsignal = zip(Signal(\"Hello\"), Signal(\"World\"))\nvalue(signal)    # (\"Hello\", \"World\")\n\n\n\n"
},

{
    "location": "api.html#Base.asyncmap-Tuple{Any,Any,ReactiveBasics.Signal,Vararg{ReactiveBasics.Signal,N} where N}",
    "page": "API",
    "title": "Base.asyncmap",
    "category": "Method",
    "text": "asyncmap(f, init, input, inputs; ntasks, batch_size)\n\n\nAn asynchronous version of map that returns a Signal that is updated after f operates asynchronously. The initial value of the returned Signal (the init arg) must be supplied.\n\n\n\n"
},

{
    "location": "api.html#Base.filter-Union{Tuple{Any,T,ReactiveBasics.Signal{T}}, Tuple{T}} where T",
    "page": "API",
    "title": "Base.filter",
    "category": "Method",
    "text": "Return a Signal that updates based on the Signal u if f(value(u)) evaluates to true.\n\n\n\n"
},

{
    "location": "api.html#Base.map-Tuple{Any,ReactiveBasics.Signal}",
    "page": "API",
    "title": "Base.map",
    "category": "Method",
    "text": "map(f, u)\n\n\nTransform the Signal into another Signal using a function.\n\n\n\n"
},

{
    "location": "api.html#Base.merge-Tuple{ReactiveBasics.Signal,Vararg{ReactiveBasics.Signal,N} where N}",
    "page": "API",
    "title": "Base.merge",
    "category": "Method",
    "text": "merge(u, us)\n\n\nMerge Signals into the current Signal. The value of the Signal is that from the most recent update.\n\n\n\n"
},

{
    "location": "api.html#Base.push!-Tuple{ReactiveBasics.Signal,Any}",
    "page": "API",
    "title": "Base.push!",
    "category": "Method",
    "text": "push!(u, val)\n\n\nUpdate the value of a Signal and propagate the change.\n\n\n\n"
},

{
    "location": "api.html#ReactiveBasics.unsubscribe!-Tuple{Any,ReactiveBasics.Signal}",
    "page": "API",
    "title": "ReactiveBasics.unsubscribe!",
    "category": "Method",
    "text": "unsubscribe!(f, u)\n\n\nUnsubscribe to the changes of this Signal. \n\n\n\n"
},

{
    "location": "api.html#ReactiveBasics-API-1",
    "page": "API",
    "title": "ReactiveBasics API",
    "category": "section",
    "text": "Pages = [\"api.md\"]Modules = [ReactiveBasics]"
},

]}
