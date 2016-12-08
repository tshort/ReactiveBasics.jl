module TestBench

using Reactive, ReactiveBasics, BenchmarkTools

const N = 10^3
const V = rand(N)
function testReactive()
    a = Reactive.Signal(0.0)
    b = Reactive.Signal(1.0)
    c = map(+, a, b)
    d = Reactive.foldp(+, 0.0, a)
    x = 0.0
    for i in 1:N
        push!(a, V[i])
        Reactive.run(1)
        x = Reactive.value(c) + Reactive.value(d)
    end
    x
end

function testReactiveBasics()
    a = ReactiveBasics.Signal(0.0)
    b = ReactiveBasics.Signal(1.0)
    c = map(+, a, b)
    d = ReactiveBasics.foldp(+, 0.0, a)
    x = 0.0
    for i in 1:N
        push!(a, V[i])
        x = ReactiveBasics.value(c) + ReactiveBasics.value(d)
    end
    x
end

@show @benchmark testReactive()
@show @benchmark testReactiveBasics()

end # module