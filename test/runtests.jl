using ReactiveBasics
using FactCheck

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


    context("zip") do

        ## zip
        d = Signal(number())
        e = zip(d, b, a)
        @fact value(e) --> (value(d), value(b), value(a))

        push!(a, number())
        @fact value(e) --> (value(d), value(b), value(a))
        
        e = zip(d, b, a, Signal(3))
        push!(a, number())
        @fact value(e) --> (value(d), value(b), value(a), 3)
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

    context("jw3126") do   # https://github.com/JuliaLang/Reactive.jl/issues/101
        x1 = Signal(1)
        x2 = Signal(10)
        y1 = map(identity, x1)
        y2 = map(identity, x2)
        y12 = map(+, x1, x2)
        z = map(+, y1, y2, y12)
        y12 = map(+, x1, x2)
        z = map(+, y1, y2, y12)
        push!(x1, 3)
        @fact value(x1)  -->  3
        @fact value(x2)  --> 10
        @fact value(y1)  -->  3
        @fact value(y2)  --> 10
        @fact value(y12) --> 13
        @fact value(z)   --> 26
        zz = map(+, y1, y2, y12, Signal(3))
        push!(x1, 3)
        @fact value(zz)  --> 29
    end

    context("asyncmap") do
        x = Signal(1)
        y = asyncmap(-, 0, x)

        @sync push!(x, 2)

        @fact value(y) --> -2

        x = Signal(1)
        y = asyncmap(0, x) do z
            sleep(2)
            -z
        end

        @sync push!(x, 2)

        @fact value(y) --> -2
    end
    
    context("flatmap") do

        a = Signal(1)
        b = flatmap(a) do x
            Signal(10 + x)
        end
        @fact value(b) --> 11
        push!(a, 5)
        @fact value(b) --> 15
        push!(a, 15)
        @fact value(b) --> 25
    end

end
