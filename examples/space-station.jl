# Derived from the following cool example by @nixterrimus: (MIT licensed)
# https://github.com/JensRavens/Interstellar/blob/master/Interstellar.playground/Pages/6%20Using%20flatMap%20on%20signals%20of%20signals.xcplaygroundpage/Contents.swift


"""
It's your first day at Space Inc, and you've been given the job to write some code
to refuel an orbiting space station.  There's already been some code written, and
at the center of this code are Signals.

Talking to the space station, takes a lot of time.  Commands need to be send via a
radio tower and then results returned to the radio tower.  These kind of operations
are perfect to be Signals- they return values... eventually.
"""
module SpaceStation

using ReactiveBasics


"""
Get fuel levels for the space station
Returns an Int for the fuel level

In this stub implementation we return a value right away
"""
get_fuel_levels_from_space_station() = Signal(255)


"""
Sends the command to open the fuel port
Returns a Bool representing if the fuel port is open (true) or closed (false)

In this stub implementation we return a value right away
"""
open_fuel_port() = Signal(true)


"""
Sends the command to refuel from a fuel pack
WARNING: Make sure the fuel port is open before you do this!
WARNING: The space station can only contain 1000 fuel units
Returns an Int representing the fuel level for the space station

In this stub implementation we return a value right away
"""
refuel_space_station_from_fuel_pack(fuel_pack_size::Int) = Signal(255 + fuel_pack_size)


"""
We've been tasked with taking this library code and writing a refueling function.
This is a perfect case for `flatmap`.

`flatmap` is a tool that takes a function that returns a Signal and returns its inner
Signal's values.

Let's start by getting the fuel level and opening the opening the fuel port.

The result of running this code is:
The space station now has 755 fuel units available

Notice how the inner blocks return a Signal but the next blocks reference the value that
is returned by the inner Signal.

`flatmap` is a wonderful tool when you are dealing with multiple asynchrous operations that
need to be chained.
"""
function example()
    fuel_pack_size = 500
    s = get_fuel_levels_from_space_station()
    s = flatmap(s) do fuel_level
        if fuel_level < 500
            return open_fuel_port()
        else
            return Signal(false)
        end
    end
    s = flatmap(s) do fuel_port_is_open
        if fuel_port_is_open
            return refuel_space_station_from_fuel_pack(fuel_pack_size)
        else
            return Signal(0)
        end
    end
    map(space_station_fuel -> 
        println("The space station now has $space_station_fuel fuel units available"), s)
end

example()

end # module



