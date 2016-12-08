module TestBench

using Reactive, LightReactive, BenchmarkTools

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

function testLightReactive()
    a = LightReactive.Signal(0.0)
    b = LightReactive.Signal(1.0)
    c = map(+, a, b)
    d = LightReactive.foldp(+, 0.0, a)
    x = 0.0
    for i in 1:N
        push!(a, V[i])
        x = LightReactive.value(c) + LightReactive.value(d)
    end
    x
end

@show @benchmark testReactive()
@show @benchmark testLightReactive()

end # module