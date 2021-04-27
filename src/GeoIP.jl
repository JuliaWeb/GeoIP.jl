module GeoIP

using DataFrames
using GZip
using CSV
using IPNets
import Sockets: IPv4

export
    # types
    Location,
    # methods
    geolocate,
    load

include("data.jl")
include("geoip-module.jl")

end # module
