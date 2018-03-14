module GeoIP

    using IPNets
    using DataFrames
    using ZipFile
    using GZip
    using Requests
    using Compat
    export
        # types
        Location,
        # methods
        geolocate

    include("geoip-module.jl")
end
