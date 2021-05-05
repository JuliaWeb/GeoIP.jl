########################################
# Geolocation functions
########################################
"""
    geolocate(geodata::GeoIP.DB, ip)

Returns geolocation and other information determined in `geodata` by `ip`.
"""
function geolocate(geodata::DB, ip::IPv4)
    ipnet = IPv4Net(ip, 32)

    # TODO: Dict should be changed to a more suitable structure
    res = Dict{String, Any}()
    
    idx = searchsortedfirst(geodata.index, ipnet) - 1
    if idx == 0 || !(ip in geodata.index[idx])
        return res
    end
    row = geodata.blocks[idx]

    res["v4net"] = row.v4net
    res["geoname_id"] = row.geoname_id
    res["location"] = row.location
    res["registered_country_geoname_id"] = row.registered_country_geoname_id
    res["is_anonymous_proxy"] = row.is_anonymous_proxy
    res["is_satellite_provider"] = row.is_satellite_provider
    res["postal_code"] = row.postal_code
    res["accuracy_radius"] = row.accuracy_radius

    geoname_id = row.geoname_id
    locale = geodata.locs[geodata.localeid]
    idx2 = searchsortedfirst(locale.index, geoname_id)
    if idx2 > length(locale.locs) || idx2 < 1
        return res
    end
    if locale.index[idx2] != geoname_id
        return res
    end
    
    row2 = locale.locs[idx2]
    for k in keys(row2)
        res[string(k)] = row2[k]
    end

    return res
end

geolocate(geodata::DB, ipstr::AbstractString) = geolocate(geodata, IPv4(ipstr))
geolocate(geodata::DB, ipint::Integer) = geolocate(geodata, IPv4(ipint))
getindex(geodata::DB, ip) = geolocate(geodata, ip)
