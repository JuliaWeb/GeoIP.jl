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
function geolocate(ip::IPv4; noupdate = true)
    if updaterequired()
        if !(noupdate)
            update()
        else
            warn("Geolocation data is out of date. Consider updating.")
        end
    end

    if !(dataloaded)
        info("Geolocation data not in memory. Loading...")
        load()
    end

    ipnet = IPv4Net(ip, 32)

    # only iterate over rows that actually make sense - this filter is
    # less expensive than iteration with in().
    found = 0
    for i in 1:size(geodata, 1)        # iterate over rows
        if geodata[i, :v4net] > ipnet
            found = i - 1
            break
        end
    end

    retdict = Dict{Symbol, Any}()
    if (found > 0) && ip in geodata[found, :v4net]
        for (k,v) in eachcol(geodata[found, :])
            retdict[k] = v[1]
        end
    end
    return retdict
end

function geolocate(iparr::AbstractArray; noupdate = true)
    masterdict = Dict{Symbol, Any}[]
    for el in iparr
        push!(masterdict, geolocate(el; noupdate = noupdate))
    end
    return masterdict
end

geolocate(ipstr::AbstractString; noupdate = true) = geolocate(IPv4(ipstr); noupdate = noupdate)
geolocate(ipint::Integer; noupdate = true) = geolocate(IPv4(ipint); noupdate = noupdate)
