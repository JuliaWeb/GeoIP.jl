module GeoIP

using IPNets
using DataFrames
using ZipFile
using GZip
using HTTP
using CSV
import Sockets: IPv4

export
    # types
    Location,
    # methods
    geolocate

include("data.jl")
include("geoip-module.jl")

end # module
