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

Returns geolocation and other information determined by `ip`. If `noupdate` is `true`, then no updates check is performed and current data is used for the location lookup.
"""
function geolocate(geodata::DB, ip::IPv4)
    ipnet = IPv4Net(ip, 32)
    db = geodata.db

    # only iterate over rows that actually make sense - this filter is
    # less expensive than iteration with in().
    found = 0
    for i in axes(db, 1)        # iterate over rows
        if db[i, :v4net] > ipnet
            found = i - 1
            break
        end
    end

    # TODO: sentinel value should be returned
    retdict = Dict{String, Any}()
    if (found > 0) && ip in db[found, :v4net]
        # Placeholder, should be removed
        row = db[found, :]
        return Dict(collect(zip(names(row), row)))
    end
    return retdict
end

geolocate(geodata::DB, ipstr::AbstractString) = geolocate(geodata, IPv4(ipstr))
geolocate(geodata::DB, ipint::Integer) = geolocate(geodata, IPv4(ipint))
getindex(geodata::DB, ip) = geolocate(geodata, ip)
