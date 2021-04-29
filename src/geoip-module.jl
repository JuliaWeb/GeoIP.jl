########################################
# Location structure
########################################
# It would be great to replace this with a real GIS package.
abstract type Point end
abstract type Point3D <: Point end

struct Location <: Point3D
    x::Float64
    y::Float64
    z::Float64
    datum::String

    function Location(x, y, z = 0, datum = "WGS84")
        if x === missing || y === missing
            return missing
        else
            return new(x, y, z, datum)
        end
    end
end

########################################
# Geolocation functions
########################################
"""
    geolocate(geodata::GeoIP.DB, ip)

Returns geolocation and other information determined in `geodata` by `ip`.
"""
function geolocate(geodata::DB, ip::IPv4)
    ipnet = IPv4Net(ip, 32)
    db = geodata.db

    idx = searchsortedfirst(geodata.index, ipnet) - 1

    # TODO: sentinel value should be returned
    res = if idx > 0 && ip in geodata.index[idx]
        db[idx]
    else
        Dict{String, Any}()
    end

    return res
end

geolocate(geodata::DB, ipstr::AbstractString) = geolocate(geodata, IPv4(ipstr))
geolocate(geodata::DB, ipint::Integer) = geolocate(geodata, IPv4(ipint))
getindex(geodata::DB, ip) = geolocate(geodata, ip)
