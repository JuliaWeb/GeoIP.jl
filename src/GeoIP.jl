module GeoIP
    using DataArrays
    using DataFrames

    export
        getcountrycode,
        getcountryname,
        getregionname,
        getcityname,
        getpostalcode,
        getlongitude,
        getlatitude,
        getmetrocode,
        getareacode

    # Transform an 4-octet IP address into a base-256 number
    function numericize(ip::String)
        ns = Int[parseint(subip) for subip in split(ip, ".")]
        return ns[1] * 256^3 + ns[2] * 256^2 + ns[3] * 256^1 + ns[4]
    end

    # A lookup table for IP addresses from country database
    immutable IPTableCountry
        ends::Vector{Int}
        countrycode::Vector{UTF8String}
        countryname::Vector{UTF8String}
    end

    # Read in raw IP data from a CSV file into an IPTable
    function loaddatacountry(pathname::String)
        ips = readtable(
            pathname,
            header = false,
            nastrings = ["NULL"]
        )
        names!(
            ips,
            [
                :BeginRange,
                :EndRange,
                :BeginNum,
                :EndNum,
                :Code,
                :Name
            ]
        )
        return IPTableCountry(
            convert(Vector{Int}, ips[:EndNum]),
            convert(Vector{UTF8String}, ips[:Code]),
            convert(Vector{UTF8String}, ips[:Name])
        )
    end

    # Cache IP address country lookup table in memory
    const LOOKUPCOUNTRY = loaddatacountry(
        Pkg.dir("GeoIP", "data", "geoip.csv.gz")
    )

    # A lookup table for IP addresses from city database
    immutable IPTableCity
        ends::Vector{Int}
        country::Vector{UTF8String}
        regionname::Vector{UTF8String}
        cityname::Vector{UTF8String}
        postalcode::Vector{UTF8String}
        latitude::Vector{Float64}
        longitude::Vector{Float64}
        metrocode::DataArray{Int64}
        areacode::DataArray{Int64}
    end

    # Read in raw IP data from a CSV file into an IPTable
    function loaddatacity(blockspath::String, locationspath::String)
        blocks = readtable(blockspath)
        locations = readtable(locationspath, nastrings = ["NULL"])
        full = join(blocks, locations, on = :locId, kind = :inner)
        
        return IPTableCity(
            convert(Vector{Int64}, full[:endIpNum]),
            convert(Vector{UTF8String}, full[:country]),
            convert(Vector{UTF8String}, full[:region]),
            convert(Vector{UTF8String}, full[:city]),
            convert(Vector{UTF8String}, full[:postalCode]),
            convert(Vector{Float64}, full[:latitude]),
            convert(Vector{Float64}, full[:longitude]),
            convert(DataArray{Int64}, full[:metroCode]),
            convert(DataArray{Int64}, full[:areaCode])
        )
    end

    # Cache IP address city lookup table in memory
    const LOOKUPCITY = loaddatacity(
        Pkg.dir("GeoIP", "data", "GeoLiteCity-Blocks.csv.gz"),
        Pkg.dir("GeoIP", "data", "GeoLiteCity-Location.csv.gz")
    )

    macro buildgetter(source, column)
        source = esc(source)
        fname = esc(symbol(string("get", column)))
        quote
            function $fname(ip::Integer)
                bounds = searchsorted($source.ends, ip)
                return ($source.$column)[bounds.start]
            end
            $fname(ip::String) = $fname(numericize(ip))
            Base.@vectorize_1arg Union(Integer, String) $fname
        end
    end

    @buildgetter(LOOKUPCOUNTRY, countrycode)
    @buildgetter(LOOKUPCOUNTRY, countryname)
    @buildgetter(LOOKUPCITY, regionname)
    @buildgetter(LOOKUPCITY, cityname)
    @buildgetter(LOOKUPCITY, postalcode)
    @buildgetter(LOOKUPCITY, longitude)
    @buildgetter(LOOKUPCITY, latitude)
    @buildgetter(LOOKUPCITY, metrocode)
    @buildgetter(LOOKUPCITY, areacode)
end
