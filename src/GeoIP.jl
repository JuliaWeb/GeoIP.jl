module GeoIP

using ZipFile
using Geodesy
using CSV
using IPNets
import Sockets: IPv4
import Base: getindex

export
    # types
    Location,
    # methods
    geolocate,
    setlocale,
    load

include("data.jl")
include("geoip-module.jl")

end # module
