# Path to directory with data, can define GEOIP_DATADIR to override
# the default (useful for testing with a smaller test set)
const DATADIR = haskey(ENV, "GEOIP_DATADIR") ?
    ENV["GEOIP_DATADIR"] :
    joinpath(dirname(@__FILE__), "..", "data")

const MD5 = joinpath(DATADIR, ".md5")
const CITYMD5URL = "http://geolite.maxmind.com/download/geoip/database/GeoLite2-City-CSV.zip.md5"
const CITYDLURL = "http://geolite.maxmind.com/download/geoip/database/GeoLite2-City-CSV.zip"

const BLOCKCSV = "GeoLite2-City-Blocks-IPv4.csv"
const CITYCSV = "GeoLite2-City-Locations-en.csv"

const BLOCKCSVGZ = "$BLOCKCSV.gz"
const CITYCSVGZ = "$CITYCSV.gz"

dataloaded = false
geodata = DataFrame()

function readmd5()
    if isfile(MD5)
        return open(MD5) do f
            strip(readline(f))
        end
    else
        @info "Failed to find checksum file, updating data..."
        update()
        readmd5()
    end
end

function getmd5()
    try
        r = HTTP.get(CITYMD5URL)
        return string(r.data)
    catch
        @error "Failed to download checksum file from MaxMind, check network connectivity"
    end
end

updaterequired() = (readmd5() != getmd5())

function dldata(md5::String)
    r = try
        HTTP.get(CITYDLURL)
    catch
        @error "Failed to download file from MaxMind, check network connectivity"
    end

    archive = ZipFile.Reader(IOBuffer(r.data))
    dlcount = 0
    for fn in archive.files
        if contains(string(fn),BLOCKCSV)
            GZip.open(joinpath(DATADIR, BLOCKCSVGZ), "w") do f
                write(f, read(fn))
            end
            dlcount += 1
        elseif contains(string(fn),CITYCSV)
            GZip.open(joinpath(DATADIR, CITYCSVGZ), "w") do f
                write(f, read(fn))
            end
            dlcount += 1
        end
    end

    if dlcount == 2
        open(MD5, "w") do f
            write(f, md5)
        end
    else
        @error "Problem with download: only $dlcount of 2 files downloaded"
    end
end

function update()
    dldata(getmd5())
    global dataloaded = false
end

function load(datadir = DATADIR)
    blockfile = joinpath(datadir, BLOCKCSVGZ)
    locfile = joinpath(datadir, CITYCSVGZ)

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
    end

    # Clean up unneeded columns and map others to appropriate data structures
    select!(blocks, Not([:represented_country_geoname_id, :is_anonymous_proxy, :is_satellite_provider]))

    blocks[!, :v4net] = map(x -> IPNets.IPv4Net(x), blocks[!, :network])
    select!(blocks, Not(:network))

    blocks[!, :location] = map(Location, blocks[!, :longitude], blocks[!, :latitude])
    select!(blocks, Not([:longitude, :latitude]))
    blocks.geoname_id = map(x -> ismissing(x) ? -1 : Int(x), blocks.geoname_id)

    alldata = leftjoin(blocks, locs, on = :geoname_id)

    global dataloaded = true
    global geodata = sort(alldata, :v4net)
end
