# Currently it's just a tiny wrapper over DataFrames, but at some point it should 
# become completely different entity. But user API shouldn't change, that is why we
# introduce this wrapper
struct DB
    db::DataFrame
end

Base.broadcastable(db::DB) = Ref(db)

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
            CSV.File(read(stream)) |> DataFrame
            # CSV.File(stream, types=[String, Int, Int, String, Int, Int, String, Float64, Float64, Int]) |> DataFrame
        end
        locs = GZip.open(locfile, "r") do stream
            # CSV.File(stream, types=[Int, String, String, String, String, String, String, String, String, String, String, Int, String, Int]) |> DataFrame
            CSV.File(read(stream)) |> DataFrame
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
            if f.name == "GeoLite2-City-Locations-en.csv"
                v = Vector{UInt8}(undef, f.uncompressedsize)
                locs = read!(f, v) |> CSV.File |> DataFrame
            elseif f.name == "GeoLite2-City-Blocks-IPv4.csv"
                v = Vector{UInt8}(undef, f.uncompressedsize)
                blocks = read!(f, v) |> CSV.File |> DataFrame
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

    # Clean up unneeded columns and map others to appropriate data structures
    select!(blocks, Not([:represented_country_geoname_id, :is_anonymous_proxy, :is_satellite_provider]))

    blocks[!, :v4net] = map(x -> IPNets.IPv4Net(x), blocks[!, :network])
    select!(blocks, Not(:network))

    blocks[!, :location] = map(Location, blocks[!, :longitude], blocks[!, :latitude])
    select!(blocks, Not([:longitude, :latitude]))
    blocks.geoname_id = map(x -> ismissing(x) ? -1 : Int(x), blocks.geoname_id)

    alldata = leftjoin(blocks, locs, on = :geoname_id)

    return DB(sort!(alldata, :v4net))
end
