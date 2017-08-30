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

    context("merge") do

        ## Merge
        d = Signal(number())
        e = merge(d, b, a)

        # precedence to d
        @fact value(e) --> value(d)

        push!(a, number())
        # Note that his works differently than Reactive.jl because of the
        # way updates are pushed.
        @fact value(e) --> value(a)

    end

    context("zip") do

        ## zip
        d = Signal(number())
        b = Signal(number())
        a = Signal(number())
        e = zip(d, b, a)
        @fact value(e) --> (value(d), value(b), value(a))

        d = Signal(1)
        b = Signal(2)
        a = Signal(3)
        e = zip(d, b, a)
        @fact value(e) --> (1,2,3)

        push!(a, 6)
        @fact value(e) --> (1,2,3)
        push!(d, 4)
        @fact value(e) --> (1,2,3)
        push!(b, 5)
        @fact value(e) --> (4,5,6)

        e = zip(d, b, a, Signal(3))
        @fact value(e) --> (value(d), value(b), value(a), 3)
    end

    context("foldp") do

        ## foldp over time
        push!(a, 0)
        f = foldp(+, 0, a)
        nums = round.(Int, rand(100)*1000)
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
        u = Signal(3)
        b = flatmap(a) do x
            x > 10 ? Signal(1 + x) : u
        end
        @fact value(b) --> 3
        push!(a, 5)
        @fact value(b) --> 3
        push!(u, 6)
        @fact value(b) --> 6
        push!(a, 15)
        @fact value(b) --> 16
    end

    context("sampleon") do
        # sampleon
        g = Signal(0)

        push!(g, number())
        i = Signal(true)
        j = sampleon(i, g)
        # default value
        @fact value(j) --> value(g)
        push!(g, value(g)-1)
        @fact value(j) --> value(g)+1
        push!(i, true)
        @fact value(j) --> value(g)
    end

    context("droprepeats") do
        # droprepeats
        count = s -> foldp((x, y) -> x+1, -1, s)

        k = Signal(1)
        l = droprepeats(k)

        @fact value(l) --> value(k)
        push!(k, 1)
        @fact value(l) --> value(k)
        push!(k, 0)
        #println(l.value, " ", value(k))
        @fact value(l) --> value(k)

        m = count(k)
        n = count(l)

        seq = [1, 1, 1, 0, 1, 0, 1, 0, 0]
        map(x -> push!(k, x), seq)

        @fact value(m) --> length(seq)
        @fact value(n) --> 6
    end

    context("previous") do
        x = Signal(0)
        y = previous(x)
        @fact value(y) --> 0

        push!(x, 1)

        @fact value(y) --> 0

        push!(x, 2)

        @fact value(y) --> 1

        push!(x, 3)

        @fact value(y) --> 2
    end

    context("bind!") do
        x = Signal(1)
        y = Signal(2)
        xx = map(u -> 2u, x)
        yy = map(u -> 3u, y)
        bind!(x, y)
        @fact value(y) --> value(x)
        @fact value(y) --> 2
        push!(x, 10)
        @fact value(y) --> value(x)
        @fact value(y) --> 10
        @fact value(yy) --> 30
        push!(y, 20)
        @fact value(y) --> value(x)
        @fact value(y) --> 20
        @fact value(xx) --> 40
    end

    context("preserve") do
        x = Signal(1)
        z = let xx = map(u -> 2u, x),
            x2 = preserve(map(u -> 2u, x))
            map(+, xx, x2)
        end
        push!(x, 10)
        @fact value(z) --> 40
    end
end

facts("Flatten") do

    a = Signal(0)
    b = Signal(1)

    c = Signal(a)

    d = flatten(c)
    cnt = foldp((x, y) -> x+1, -1, d)

    context("Signal{Signal} -> flat Signal") do
        # Flatten implies:
        @fact value(c) --> a
        @fact value(d) --> value(a)
    end

    context("Initial update count") do

        @fact value(cnt) --> 0
    end

    context("Current signal updates") do
        push!(a, 2)

        @fact value(cnt) --> 1
        @fact value(d) --> value(a)
    end

    context("Signal swap") do
        push!(c, b)
        @fact value(cnt) --> 2
        @fact value(d) --> value(b)

        push!(a, 3)
        @fact value(cnt) --> 2
        @fact value(d) --> value(b)

        push!(b, 3)

        @fact value(cnt) --> 3
        @fact value(d) --> value(b)
    end
end
