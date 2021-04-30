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

# Currently it's just a tiny wrapper over DataFrames, but at some point it should 
# become completely different entity. But user API shouldn't change, that is why we
# introduce this wrapper
struct DB{T1, T2}
    index::Vector{IPv4Net}
    locindex::Vector{Int}
    blocks::Vector{T1}
    locs::Vector{T2}
end

Base.broadcastable(db::DB) = Ref(db)

struct BlockRow{T}
    v4net::T
    geoname_id::Int
    location::Union{Location, Missing}
    registered_country_geoname_id::Union{Int, Missing}
    is_anonymous_proxy::Int
    is_satellite_provider::Int
    postal_code::Union{String, Missing}
    accuracy_radius::Union{Int, Missing}
end

function BlockRow(csvrow)
    net = IPNets.IPv4Net(csvrow.network)
    geoname_id = ismissing(csvrow.geoname_id) ? -1 : csvrow.geoname_id
    location = Location(csvrow.longitude, csvrow.latitude)
    registered_country_geoname_id = csvrow.registered_country_geoname_id
    accuracy_radius = get(csvrow, :accuracy_radius, missing)
    postal_code = csvrow.postal_code

    BlockRow(
        net,
        geoname_id,
        location,
        registered_country_geoname_id,
        csvrow.is_anonymous_proxy,
        csvrow.is_satellite_provider,
        postal_code,
        accuracy_radius
    )
end

# Path to directory with data, can define GEOIP_DATADIR to override
# the default (useful for testing with a smaller test set)
function getdatadir(datadir)
    isempty(datadir) || return datadir
    haskey(ENV, "GEOIP_DATADIR") ?  ENV["GEOIP_DATADIR"] : datadir
end

function getzipfile(zipfile)
    isempty(zipfile) || return zipfile
    haskey(ENV, "GEOIP_ZIPFILE") ? ENV["GEOIP_ZIPFILE"] : zipfile
end

function loadgz(datadir, blockcsvgz, citycsvgz)
    blockfile = joinpath(datadir, blockcsvgz)
    locfile = joinpath(datadir, citycsvgz)

    isfile(blockfile) || throw(ArgumentError("Unable to find blocks file in $(blockfile)"))
    isfile(locfile) || throw(ArgumentError("Unable to find locations file in $(locfile)"))
    
    local blocks
    local locs
    try
        blocks = GZip.open(blockfile, "r") do stream
            CSV.File(read(stream))
        end
        locs = GZip.open(locfile, "r") do stream
            CSV.File(read(stream))
        end
    catch
        @error "Geolocation data cannot be read. Data directory may be corrupt..."
        rethrow()
    end

    return blocks, locs
end

function loadzip(datadir, zipfile)
    zipfile = joinpath(datadir, zipfile)
    isfile(zipfile) || throw(ArgumentError("Unable to find data file in $(zipfile)"))
    
    r = ZipFile.Reader(zipfile)
    local blocks
    local locs
    try
        for f in r.files
            if occursin("City-Locations-en.csv", f.name)
                v = Vector{UInt8}(undef, f.uncompressedsize)
                locs = read!(f, v) |> CSV.File
            elseif occursin("City-Blocks-IPv4.csv", f.name)
                v = Vector{UInt8}(undef, f.uncompressedsize)
                blocks = read!(f, v) |> CSV.File
            end
        end
    catch
        @error "Geolocation data cannot be read. Data directory may be corrupt..."
        rethrow()
    finally
        close(r)
    end

    return blocks, locs
end

"""
    load(; datadir, zipfile, blockcsvgz, citycsvgz)

Load GeoIP database from compressed CSV file or files. If `zipfile` argument is provided then `load` tries to load data from that file, otherwise it will try to load data from `blockcsvgz` and `citycsvgz`. By default `blockcsvgz` equals to `"GeoLite2-City-Blocks-IPv4.csv.gz"` and `citycsvgz` equals to `"GeoLite2-City-Locations-en.csv.gz"`. `datadir` defines where data files are located and can be either set as an argument or read from the `ENV` variable `GEOIP_DATADIR`. In the same way if `ENV` variable `GEOIP_ZIPFILE` is set, then it is used for determining `zipfile` argument.
"""
function load(; zipfile = "",
                datadir = "",
                blockcsvgz = "GeoLite2-City-Blocks-IPv4.csv.gz",
                citycsvgz  = "GeoLite2-City-Locations-en.csv.gz")
    datadir = getdatadir(datadir)
    zipfile = getzipfile(zipfile)
    blocks, locs = if isempty(zipfile)
        loadgz(datadir, blockcsvgz, citycsvgz)
    else
        loadzip(datadir, zipfile)
    end

    blockdb = BlockRow.(blocks)
    sort!(blockdb, by = x -> x.v4net)
    index = map(x -> x.v4net, blockdb)
    locsdb = collect(locs)
    sort!(locsdb, by = x -> x.geoname_id)
    locindex = map(x -> x.geoname_id, locsdb)

    return DB(index, locindex, blockdb, locsdb)
end
