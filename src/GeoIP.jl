module GeoIP

using DataFrames
using GZip
using ZipFile
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
