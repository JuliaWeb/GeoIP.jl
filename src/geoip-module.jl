import Sockets

function geolocate(ip::Sockets.IPv4; noupdate=true)
    throw("Not implemented")
end

function geolocate(iparr::AbstractArray; noupdate=true)
    masterdict = Dict{Symbol, Any}[]
    for el in iparr
        push!(masterdict, geolocate(el; noupdate=noupdate))
    end
    return masterdict
end
