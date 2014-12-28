CITYMD5URL = "http://geolite.maxmind.com/download/geoip/database/GeoLite2-City-CSV.zip.md5"
CITYDLURL = "http://geolite.maxmind.com/download/geoip/database/GeoLite2-City-CSV.zip"
GEOLITEDATA = Pkg.dir("GeoIP","data")
GEOLITEMD5 = Pkg.dir("GeoIP","data",".md5")
BLOCKCSV = "GeoLite2-City-Blocks-IPv4.csv"
CITYCSV = "GeoLite2-City-Locations-en.csv"
BLOCKCSVGZ = string(BLOCKCSV,".gz")
CITYCSVGZ = string(CITYCSV,".gz")
dataloaded = false
geodata = DataFrame()

pkgdir = Pkg.dir("GeoIP", "data")
# file access = Pkg.dir("GeoIP", "data", "GeoLiteCity-Blocks.csv.gz"),
# It would be great to replace this with a real GIS package.
abstract Point
abstract Point3D <: Point

immutable Location <: Point3D
    x::Float64
    y::Float64
    z::Float64
    datum::String

    function Location(x,y,z=0, datum="WGS84")
        if is(x,NA) || is (y,NA)
            return NA
        end
        return new(x,y,z,datum)
    end
end

function readmd5()
    md5=""
    try
        f = open(GEOLITEMD5)
        md5 = strip(readline(f))
        close(f)
    end
    return md5
end

function getmd5()
    r = get(CITYMD5URL)
    newmd5 = r.data
    return newmd5
end

updaterequired() = (readmd5() != getmd5())
function dldata(md5::AbstractString)
    r = get(CITYDLURL)
    newzip = ZipFile.Reader(IOBuffer(r.data))
    dlcount = 0
    for fn in newzip.files
        if contains(string(fn),BLOCKCSV)
            # try
                f = gzopen(Pkg.dir("GeoIP","data",BLOCKCSVGZ),"w")
                write(f,readall(fn))
                close(f)
                dlcount += 1
            # end
        elseif contains(string(fn),CITYCSV)
            # try
                f = gzopen(Pkg.dir("GeoIP","data",CITYCSVGZ),"w")
                write(f,readall(fn))
                close(f)
                dlcount += 1
            # end
        end
    end
    if dlcount == 2
        try
            f = open(GEOLITEMD5,"w")
            write(f, md5)
            close(f)
        end
    else
        warn("Problem with download: only $dlcount of 2 files downloaded")
    end
    return dlcount
end

function update()
    currmd5 = readmd5()
    newmd5 = getmd5()
    updaterequired = (currmd5 != newmd5)
    if !(updaterequired)
        info("GeoIP data is current.")
    else
        info("Geodata out of date. Updating...")
        dldata(newmd5)
        global dataloaded = false
    end
end


lookupgeoname(locs,id::Integer) = locs[findfirst(locs[:geoname_id],id),:]

function load()
    blockfile = Pkg.dir("GeoIP","data", BLOCKCSVGZ)
    locfile = Pkg.dir("GeoIP", "data", CITYCSVGZ)
    blocks = readtable(blockfile)
    locs = readtable(locfile)
    deletecols = [:represented_country_geoname_id, :is_anonymous_proxy, :is_satellite_provider]
    delete!(blocks,deletecols)
    blocks[:v4net] = map(x->IPNets.IPv4Net(x), blocks[:network])
    delete!(blocks,:network)
    blocks[:location] = map(Location, blocks[:longitude], blocks[:latitude])
    delete!(blocks,[:longitude, :latitude])

    alldata = join(blocks,locs, on=:geoname_id, kind=:inner)
    global dataloaded = true
    global geodata = sort(alldata, cols=[:v4net])
end

function mapcontains(nets::AbstractArray, addr::IPv4)
    return map(x->contains(x,addr), nets)
end

function geolocate(ip::IPv4; noupdate=false)
    if updaterequired() && !(noupdate)
        update()
    end

    if !(dataloaded)
        info("Geolocation data not in memory. Loading...")
        load()
    end
    ipnet = IPv4Net(ip,32)
    # only iterate over rows that actually make sense - this filter is
    # less expensive than iteration with in().
    found = 0
    for i=1:size(geodata, 1)        # iterate over rows
        if geodata[i, :v4net] > ipnet
            found = i - 1
            break
        end
    end
    retdict = Dict{Symbol, Union(Integer, Location, DataArrays.NAtype, IPv4Net, AbstractString)}()
    if (found > 0) && in(ip,geodata[found,:v4net])
        for (k,v) in eachcol(geodata[found,:])
            retdict[k] = v[1]
        end
    end
    return retdict
end


######################################
# deprecations / convenience functions
######################################
@deprecate getcountrycode(ip)   geolocate(IPv4(ip))[:country_iso_code]
@deprecate getcountryname(ip)   geolocate(IPv4(ip))[:country_name]
@deprecate getregionname(ip)    geolocate(IPv4(ip))[:subdivision_1_name]
@deprecate getcityname(ip)      geolocate(IPv4(ip))[:city_name]
@deprecate getpostalcode(ip)    geolocate(IPv4(ip))[:postal_code]
@deprecate getlongitude(ip)     geolocate(IPv4(ip))[:location].x
@deprecate getlatitude(ip)      geolocate(IPv4(ip))[:location].y
@deprecate getmetrocode(ip)     geolocate(IPv4(ip))[:metro_code]
@deprecate getareacode(ip)      geolocate(IPv4(ip))[:metro_code]
