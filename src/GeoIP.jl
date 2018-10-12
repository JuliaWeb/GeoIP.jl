module GeoIP

    using IPNets
    export
        # types
        Location,
        # methods
        geolocate
    
    include("MaxMindDB/MaxMindDB.jl")

    include("data.jl")
    include("geoip-module.jl")

end
