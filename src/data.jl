# Currently it's just a tiny wrapper over DataFrames, but at some point it should 
# become completely different entity. But user API shouldn't change, that is why we
# introduce this wrapper
struct DB
    db::DataFrame
end


# Path to directory with data, can define GEOIP_DATADIR to override
# the default (useful for testing with a smaller test set)
function getdatadir(datadir)
    isempty(datadir) || return datadir
    haskey(ENV, "GEOIP_DATADIR") ?
        ENV["GEOIP_DATADIR"] :
        joinpath(dirname(@__FILE__), "..", "data")
end

function load(; datadir = "",
                blockcsvgz = "GeoLite2-City-Blocks-IPv4.csv.gz",
                citycsvgz  = "GeoLite2-City-Locations-en.csv.gz")
    datadir = getdatadir(datadir)
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
