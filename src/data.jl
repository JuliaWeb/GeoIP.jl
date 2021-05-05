########################################
# Main structures
########################################
struct Locale{T}
    index::Vector{Int}
    locs::T
end

struct BlockRow{T}
    v4net::T
    geoname_id::Int
    location::Union{LLA{Float64}, Missing}
    registered_country_geoname_id::Union{Int, Missing}
    is_anonymous_proxy::Int
    is_satellite_provider::Int
    postal_code::Union{String, Missing}
    accuracy_radius::Union{Int, Missing}
end

function BlockRow(csvrow)
    net = IPNets.IPv4Net(csvrow.network)
    geoname_id = ismissing(csvrow.geoname_id) ? -1 : csvrow.geoname_id

    lat = csvrow.latitude
    lon = csvrow.longitude
    location = ismissing(lon) || ismissing(lat) ? missing : LLA(lat, lon)
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

struct DB{T1, T2 <: Locale}
    index::Vector{T1}
    blocks::Vector{BlockRow{T1}}
    locs::Vector{T2}
    localeid::Int
    ldict::Dict{Symbol, Int}
end

Base.broadcastable(db::DB) = Ref(db)
"""
    setlocale(db, localename)

Set new locale which should be used in return results. If locale is not found, then current locale is going to be used.
"""
function setlocale(db::DB, localename)
    if localename in keys(db.ldict)
        return DB(db.index, db.blocks, db.locs, db.ldict[localename], db.ldict)
    else
        @warn "Unable to find locale $localename"
        return db
    end
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

getlocale(x::Pair) = x
function getlocale(x::Symbol)
    if x == :en
        return :en => r"Locations-en.csv$"
    elseif x == :de
        return :de => r"Locations-de.csv$"
    elseif x == :ru
        return :ru => r"Locations-ru.csv$"
    elseif x == :ja
        return :ja => r"Locations-ja.csv$"
    elseif x == :es
        return :es => r"Locations-es.csv$"
    elseif x == :fr
        return :fr => r"Locations-fr.csv$"
    elseif x == :pt_br
        return :pt_br => r"Locations-pt-BR.csv$"
    elseif x == :zh_cn
        return :zh_cn => r"Locations-zh_cn.csv$"
    end
end

function loadzip(datadir, zipfile, locales)
    zipfile = joinpath(datadir, zipfile)
    isfile(zipfile) || throw(ArgumentError("Unable to find data file in $(zipfile)"))
    
    r = ZipFile.Reader(zipfile)
    ldict = Dict{Symbol, Int}()
    locid = 1
    local blocks
    locs = []
    try
        for f in r.files
            for (l, s) in locales
                if occursin(s, f.name)
                    v = Vector{UInt8}(undef, f.uncompressedsize)
                    ls = read!(f, v) |> CSV.File
                    push!(locs, ls)
                    ldict[l] = locid
                    locid += 1
                end
            end
            if occursin(r"Blocks-IPv4.csv$", f.name)
                v = Vector{UInt8}(undef, f.uncompressedsize)
                blocks = read!(f, v) |> x -> CSV.File(x; types = Dict(:postal_code => String))
            end
        end
    catch
        @error "Geolocation data cannot be read. Data directory may be corrupt..."
        rethrow()
    finally
        close(r)
    end

    return blocks, locs, ldict
end

"""
    load(; datadir, zipfile, locales, deflocale)

Load GeoIP database from compressed CSV file. The argument `zipfile` should be provided, otherwise `load` function error. `datadir` defines where data files are located and can be either set as an argument or read from the `ENV` variable `GEOIP_DATADIR`. In the same way if `ENV` variable `GEOIP_ZIPFILE` is set, then it is used for determining `zipfile` argument.

Argument `locales` determine locale files which should be loaded. Locales can be given as `Symbol`s or `Pair`s of locale name and filename which contains corresponding locale, e.g. `locales = [:en, :fr]` or `locales = [:en => r"-en.csv"]`. Following locales are supported in `Symbol` version `:en, :de, :ru, :ja, :es, :fr, :pt_br, :zh_cn`. To set default locale use `deflocale` argument, e.g. `deflocale = :en`.
"""
function load(; zipfile = "",
                datadir = "",
                locales = [:en],
                deflocale = :en)
    datadir = getdatadir(datadir)
    zipfile = getzipfile(zipfile)
    locales = getlocale.(locales)
    blocks, locs, ldict = loadzip(datadir, zipfile, locales)

    blockdb = BlockRow.(blocks)
    sort!(blockdb, by = x -> x.v4net)
    index = map(x -> x.v4net, blockdb)
    locsdb = map(locs) do loc
        ldb = collect(loc)
        sort!(ldb, by = x -> x.geoname_id)
        lindex = map(x -> x.geoname_id, ldb)
        Locale(lindex, ldb)
    end

    localeid = if deflocale in keys(ldict)
        ldict[deflocale]
    else
        cd = collect(d)
        idx = findfirst(x -> x[2] == 1, cd)
        locname = cd[idx][1]
        @warn "Default locale $deflocale was not found, using locale $locname"
        1
    end

    return DB(index, blockdb, locsdb, localeid, ldict)
end
