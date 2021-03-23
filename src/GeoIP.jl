module GeoIP

using DataFrames
using ZipFile
using GZip
using HTTP
using CSV
import Sockets: IPv4

include("ipnets.jl")
using .IPNets

export
    # types
    Location,
    # methods
    geolocate,
    load

include("data.jl")
include("geoip-module.jl")

end # module
