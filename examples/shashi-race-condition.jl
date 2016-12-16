# Examples of handling a race condition.
# From https://github.com/JuliaGizmos/Reactive.jl/issues/115

module Example

using ReactiveBasics


# Here's the naive case from the issue.
# The update to `w` is faster, so we get a -41 as an intermediate answer before the final update to -60.
# For some applications, this may be fine, but for others, we might want a different order of operation.
# Results:
#  -11
#  -41
#  -60
function test1()
    x = Signal(1)
    y = map(a -> (sleep(2); -a), x)
    w = Signal(10)
    map(println, map(-, y, w))
    # suddenly two events appear in this order:
    @async push!(x, 20) # the @async just represents updates coming from a different task
    @async push!(w, 40)
    sleep(2.5); # wait till previous update goes through
end


# Here's another approach where we don't want the long operation to be bypassed.
# So, we use `flatmap` to create a Signal to make it wait for the value from the long calc.
# Note that ultimately, this only responds to changes in `x`.
# Results:
#  -11
#  -60
function test2()
    x = Signal(1)
    y = map(a -> (sleep(2); -a), x)
    w = Signal(10)
    map(println, flatmap(u -> map(-, Signal(u), w), y))
    # suddenly two events appear in this order:
    @async push!(x, 20) # the @async just represents updates coming from a different task
    @async push!(w, 40)
    sleep(2.5); # wait till previous update goes through
end


# Here's another try that responds to both x and w. It takes the inputs
# and puts them in an input queue to process one at a time.
# Results:
#  -11
#  -30
#  -60
function test3()
    queue = Any[]
    function queued(u::Signal)
        signal = Signal(u.value)
        subscribe!(u) do x
            unshift!(queue, (signal, x))  # add the signal to the queue
        end
        signal
    end
    function nextqueued()
        if !isempty(queue)
            signal, x = pop!(queue) 
            push!(signal, x) 
        end
    end
    xi = Signal(1)
    x = queued(xi)
    wi = Signal(10)
    w = queued(wi)
    y = map(a -> (sleep(2); -a), x)
    z = map(-, y, w)
    map(println, z)
    # suddenly two events appear in this order:
    @async push!(xi, 20) # the @async just represents updates coming from a different task
    @async push!(wi, 40)
    sleep(2.5); # wait till previous update goes through
    nextqueued()
    nextqueued()
end

println("Naive")
test1()
println("Better")
test2()
println("Input queue")
test3()

end # module