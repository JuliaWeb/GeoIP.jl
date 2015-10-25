__precompile__(false)  # until we can fix the Zlib issue
module GeoIP

    using IPNets
    using DataFrames
    using ZipFile
    # using GZip
    using Requests
    using Compat
    import Base: Zip2
    export
        # types
        Location,
        # methods
        geolocate

    include("geoip-module.jl")
end
