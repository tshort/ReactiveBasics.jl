using ReactiveBasics
using Test

number() = round(Int, rand()*1000)


abstract type Action{T} end
struct Update{T} <: Action{T}
    val::T
end
struct Reset{T} <: Action{T}
    val::T
end


## Basics


@testset "Basic checks") begin

    x = Signal(Float32
    @test isa(x, Signal{Type{Float32}}) == true

    a = Signal(number())
    b = map(x -> x*x, a)

    @testset "map" begin

        # Lift type
        #@test typeof(b) == Reactive.Lift{Int}

        # type conversion
        push!(a, 1.0)
        @test value(b) == 1

        push!(a, number())
        @test value(b) == value(a)^2

        push!(a, -number())
        @test value(b) == value(a)^2

        ## Multiple inputs to map
        d = Signal(number())
        c = map(+, a, b, d)
        @test value(c) == value(a) + value(b) + value(d)

        push!(a, number())
        @test value(c) == value(a) + value(b) + value(d)

        push!(d, number())
        @test value(c) == value(a) + value(b) +  value(d)

        as = Signal(0)
        bs = map(Update, as, typ = Action{Int64})
        @test typeof(bs) == Signal{Action{Int64}}
    end

    @testset "zipmap" begin

        as = Signal(1)
        bs = map(a -> a * 0.1, as)
        cs = zipmap((a,b) -> a + b, as, bs)
        counts = foldp((cnt,_) -> cnt + 1, 0, cs)

        @test value(counts) == 1
        @test value(cs) == 1.1

        push!(as, 2)
        @test value(counts) == 2
        @test value(cs) == 2.2
    end

    @testset "merge" begin

        ## Merge
        d = Signal(number())
        e = merge(d, b, a)

        # precedence to d
        @test value(e) == value(d)

        push!(a, number())
        # Note that his works differently than Reactive.jl because of the
        # way updates are pushed.
        @test value(e) == value(a)

        # Merge two different signal types
        as = Signal(Update(1))
        bs = Signal(Reset(2))
        cs = merge(as, bs)
        @test typeof(value(cs)) == Update{Int64}
    end

    @testset "zip" begin

        ## zip
        d = Signal(number())
        b = Signal(number())
        a = Signal(number())
        e = zip(d, b, a)
        @test value(e) == (value(d), value(b), value(a))

        d = Signal(1)
        b = Signal(2)
        a = Signal(3)
        e = zip(d, b, a)
        @test value(e) == (1,2,3)

        push!(a, 6)
        @test value(e) == (1,2,3)
        push!(d, 4)
        @test value(e) == (1,2,3)
        push!(b, 5)
        @test value(e) == (4,5,6)

        e = zip(d, b, a, Signal(3))
        @test value(e) == (value(d), value(b), value(a), 3)

        as = Signal(Action{Int64}, Update(1))
        bs = Signal(Reset(2))
        cs = zip(as, bs)
        @test typeof(cs) == Signal{Tuple{Action{Int64}, Reset{Int64}}}

        push!(as, Reset(3))
        @test typeof(cs) == Signal{Tuple{Action{Int64}, Reset{Int64}}}

        d = Signal(1)
        b = Signal(2)
        a = Signal(3)
        e = zip(d, b, a, max_buffer_size = 1)
        @test value(e) == (1,2,3)
        push!(a, 1)
        @test value(e) == (1,2,3)
        error = false
        try
            push!(a, 1)
        catch
            error = true
        end
        @test error == true
        push!(b, 1)
        push!(d, 2)
        @test value(e) == (2, 1, 1)

        d = Signal(1)
        b = Signal(2)
        a = Signal(3)
        e = zip(d, b, a, max_buffer_size = 2)
        @test value(e) == (1,2,3)
        push!(a, 1)
        push!(a, 2)
        @test value(e) == (1,2,3)
        error = false
        try
            push!(a, 1)
        catch
            error = true
        end
        @test error == true
        push!(b, 1)
        push!(d, 2)
        @test value(e) == (2, 1, 1)
    end

    @testset "foldp" begin
        a = Signal(0)
        ## foldp over time
        push!(a, 0)
        f = foldp(+, 0, a)
        nums = [6,3,1]
        map(x -> push!(a, x), nums)
        @test sum(nums) == value(f)

        x = Signal(ones(4,5))
        y = foldp((b,a) -> b + a, ones(4,5) * 2, x)
        @test value(y) == ones(4,5) * 3
        push!(x, ones(4,5))
        @test value(y) == ones(4,5) * 4
    end

    @testset "filter" begin
        # filter
        g = Signal(0)
        pred = x -> x % 2 != 0
        h = filter(pred, 1, g)
        j = filter(x -> x % 2 == 0, 1, g)

        @test value(h) == 1
        @test value(j) == 0

        push!(g, 2)
        @test value(h) == 1

        push!(g, 3)
        @test value(h) == 3
    end

    @testset "filterwhen" begin
        # filterwhen
        bs = Signal(false)
        as = Signal(1)
        cs = filterwhen(bs, 9, as)
        @test value(cs) == 9

        bs = Signal(true)
        as = Signal(1)
        cs = filterwhen(bs, 9, as)
        @test value(cs) == 1

        push!(as, 2)
        @test value(cs) == 2
        push!(bs, false)
        @test value(cs) == 2
        push!(as, 5)
        @test value(cs) == 2
        push!(bs, true)
        @test value(cs) == 5
    end

    @testset "push! inside push!") begin
        a = Signal(0)
        b = Signal(1)
        subscribe!(x -> push!(a, x), b)
        @test value(a) == 0

        push!(a, 2)
        @test value(a) == 2
        @test value(b) == 1

        push!(b, 3)
        @test value(b) == 3
        @test value(a) == 3

    end

    @testset "jw3126" begin   # https://github.com/JuliaLang/Reactive.jl/issues/101
        x1 = Signal(1)
        x2 = Signal(10)
        y1 = map(identity, x1)
        y2 = map(identity, x2)
        y12 = map(+, x1, x2)
        z = map(+, y1, y2, y12)
        y12 = map(+, x1, x2)
        z = map(+, y1, y2, y12)
        push!(x1, 3)
        @test value(x1)  ==  3
        @test value(x2)  == 10
        @test value(y1)  ==  3
        @test value(y2)  == 10
        @test value(y12) == 13
        @test value(z)   == 26
        zz = map(+, y1, y2, y12, Signal(3))
        push!(x1, 3)
        @test value(zz)  == 29
    end

    @testset "asyncmap" begin
        x = Signal(1)
        y = asyncmap(-, 0, x)

        @sync push!(x, 2)

        @test value(y) == -2

        x = Signal(1)
        y = asyncmap(0, x) do z
            sleep(2)
            -z
        end

        @sync push!(x, 2)

        @test value(y) == -2
    end

    @testset "flatmap" begin

        a = Signal(1)
        u = Signal(3)
        b = flatmap(a) do x
            x > 10 ? Signal(1 + x) : u
        end
        @test value(b) == 3
        push!(a, 5)
        @test value(b) == 3
        push!(u, 6)
        @test value(b) == 6
        push!(a, 15)
        @test value(b) == 16
    end

    @testset "sampleon" begin
        # sampleon
        g = Signal(0)

        push!(g, number())
        i = Signal(true)
        j = sampleon(i, g)
        # default value
        @test value(j) == value(g)
        push!(g, value(g)-1)
        @test value(j) == value(g)+1
        push!(i, true)
        @test value(j) == value(g)
    end

    @testset "droprepeats" begin
        # droprepeats
        count = s -> foldp((x, y) -> x+1, -1, s)

        k = Signal(1)
        l = droprepeats(k)

        @test value(l) == value(k)
        push!(k, 1)
        @test value(l) == value(k)
        push!(k, 0)
        #println(l.value, " ", value(k))
        @test value(l) == value(k)

        m = count(k)
        n = count(l)

        seq = [1, 1, 1, 0, 1, 0, 1, 0, 0]
        map(x -> push!(k, x), seq)

        @test value(m) == length(seq)
        @test value(n) == 6
    end

    @testset "skip" begin
        x = Signal(0)
        y = skip(2, x)
        count = foldp((x, y) -> x+1, -1, y)
        @test value(y) == 0
        @test value(count) == 0

        push!(x, 1)
        @test value(y) == 0
        @test value(count) == 0

        push!(x, 2)
        @test value(y) == 0
        @test value(count) == 0

        push!(x, 3)
        @test value(y) == 3
        @test value(count) == 1

        push!(x, 4)
        @test value(y) == 3
        @test value(count) == 1

        push!(x, 5)
        @test value(y) == 3
        @test value(count) == 1

        push!(x, 6)
        @test value(y) == 6
        @test value(count) == 2
    end

    @testset "previous" begin
        x = Signal(0)
        y = previous(x)
        @test value(y) == 0

        push!(x, 1)

        @test value(y) == 0

        push!(x, 2)

        @test value(y) == 1

        push!(x, 3)

        @test value(y) == 2

        x = Signal(zeros(2,3))
        y = previous(x)
        @test value(y) == zeros(2,3)

        push!(x, ones(2,3))

        @test value(y) == zeros(2,3)

        push!(x, ones(2,3) * 2)

        @test value(y) == ones(2,3)

        push!(x, ones(2,3) * 3)

        @test value(y) == ones(2,3) * 2
    end

    @testset "bind!" begin
        x = Signal(1)
        y = Signal(2)
        xx = map(u -> 2u, x)
        yy = map(u -> 3u, y)
        bind!(x, y)
        @test value(y) == value(x)
        @test value(y) == 2
        push!(x, 10)
        @test value(y) == value(x)
        @test value(y) == 10
        @test value(yy) == 30
        push!(y, 20)
        @test value(y) == value(x)
        @test value(y) == 20
        @test value(xx) == 40

        x = Signal(1)
        y = Signal(2)
        xx = map(u -> 2u, x)
        yy = map(u -> 3u, y)
        bind!(x, y, false)
        @test value(y) == value(x)
        @test value(y) == 2
        push!(x, 10)
        @test value(y) == 2
        @test value(x) == 10
        push!(y, 20)
        @test value(y) == value(x)
        @test value(y) == 20
        @test value(xx) == 40

        x = Signal(1)
        y = Signal(2)
        xx = map(u -> 2u, x)
        yy = map(u -> 3u, y)
        bind!(x, y, initial = false)
        @test value(x) == 1
        @test value(y) == 2
        push!(x, 10)
        @test value(y) == 10
        @test value(yy) == 30
        push!(y, 20)
        @test value(y) == value(x)
        @test value(y) == 20
        @test value(xx) == 40
    end

    @testset "preserve" begin
        x = Signal(1)
        z = let xx = map(u -> 2u, x),
            x2 = preserve(map(u -> 2u, x))
            map(+, xx, x2)
        end
        push!(x, 10)
        @test value(z) == 40
    end
end

@testset "Flatten" begin

    a = Signal(0)
    b = Signal(1)

    c = Signal(a)

    d = flatten(c)
    cnt = foldp((x, y) -> x+1, -1, d)

    @testset "Signal{Signal} -> flat Signal" begin
        # Flatten implies:
        @test value(c) == a
        @test value(d) == value(a)
    end

    @testset "Initial update count" begin

        @test value(cnt) == 0
    end

    @testset "Current signal updates" begin
        push!(a, 2)

        @test value(cnt) == 1
        @test value(d) == value(a)
    end

    @testset "Signal swap" begin
        push!(c, b)
        @test value(cnt) == 2
        @test value(d) == value(b)

        push!(a, 3)
        @test value(cnt) == 2
        @test value(d) == value(b)

        push!(b, 3)

        @test value(cnt) == 3
        @test value(d) == value(b)
    end
end
