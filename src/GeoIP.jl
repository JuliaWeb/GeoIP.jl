module GeoIP

    using IPNets
    using DataFrames
    using ZipFile
    using GZip

    export
        # types
        Location,
        # methods
        geolocate

    include("data.jl")
    include("geoip-module.jl")

    include("MaxMindDB/MaxMindDB.jl")
end
