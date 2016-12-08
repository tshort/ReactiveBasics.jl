using LightReactive
using FactCheck

queue_size() = Base.n_avail(Reactive._messages)
number() = round(Int, rand()*1000)

## Basics

facts("Basic checks") do

    a = Signal(number())
    b = map(x -> x*x, a)

    context("map") do

        # Lift type
        #@fact typeof(b) --> Reactive.Lift{Int}

        # type conversion
        push!(a, 1.0)
        @fact value(b) --> 1
        @fact value(b) --> 1

        push!(a, number())
        @fact value(b) --> value(a)^2

        push!(a, -number())
        @fact value(b) --> value(a)^2

        ## Multiple inputs to map
        c = map(+, a, b)
        @fact value(c) --> value(a) + value(b)

        push!(a, number())
        @fact value(c) --> value(a) + value(b)

        push!(b, number())
        @fact value(c) --> value(a) + value(b)
    end


    context("merge") do

        ## Merge
        d = Signal(number())
        e = merge(d, b, a)
        @fact value(e) --> (value(d), value(b), value(a))

        push!(a, number())
        @fact value(e) --> (value(d), value(b), value(a))
    end

    context("foldp") do

        ## foldp over time
        push!(a, 0)
        f = foldp(+, 0, a)
        nums = round(Int, rand(100)*1000)
        nums = [6,3,1]
        map(x -> push!(a, x), nums)
        @fact sum(nums) --> value(f)
    end

    context("filter") do
        # filter
        g = Signal(0)
        pred = x -> x % 2 != 0
        h = filter(pred, 1, g)
        j = filter(x -> x % 2 == 0, 1, g)

        @fact value(h) --> 1
        @fact value(j) --> 0

        push!(g, 2)
        @fact value(h) --> 1

        push!(g, 3)
        @fact value(h) --> 3
    end

    context("push! inside push!") do
        a = Signal(0)
        b = Signal(1)
        subscribe!(x -> push!(a, x), b)
        @fact value(a) --> 0

        push!(a, 2)
        @fact value(a) --> 2
        @fact value(b) --> 1

        push!(b, 3)
        @fact value(b) --> 3
        @fact value(a) --> 3

    end

end