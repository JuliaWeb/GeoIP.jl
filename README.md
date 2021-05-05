# GeoIP

IP Geolocalization using the [Geolite2](https://dev.maxmind.com/geoip/geoip2/geolite2/) Database

|                                                                                                **Documentation**                                                                                                |                                                                                                                                        **Build Status**                                                                                                                                        |
|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------:|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------:|
|   [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaWeb.github.io/GeoIP.jl/stable)[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaWeb.github.io/GeoIP.jl/dev)   |                       [![Build](https://github.com/JuliaWeb/GeoIP.jl/workflows/CI/badge.svg)](https://github.com/JuliaWeb/GeoIP.jl/actions)[![Coverage](https://codecov.io/gh/JuliaWeb/GeoIP.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaWeb/GeoIP.jl)                       |

# Installation

The package is registered in the [General](https://github.com/JuliaRegistries/General) registry and so can be installed at the REPL with

```julia
julia> using Pkg
julia> Pkg.add("GeoIP")
```

# Usage

## Data files

You can use [MaxMind geolite2](https://dev.maxmind.com/geoip/geoip2/geolite2/) csv files downloaded from the site. Due to the [MaxMind policy](https://blog.maxmind.com/2019/12/18/significant-changes-to-accessing-and-using-geolite2-databases/), `GeoLite.jl` does not distribute `GeoLite2` files and does not provide download utilities. For automated download it is recommended to use [MaxMind GeoIP Update](https://dev.maxmind.com/geoip/geoipupdate/) program. For proper functioning of `GeoIP.jl` you need to download `GeoLite2 City` datafile, usually it should have a name like `GeoLite2-City-CSV_20191224.zip`. 

Files processing and loading provided with `load()` call. Directory where data is located should be located either in `ENV["GEOIP_DATADIR"]` or it can be passed as an argument to `load` function. Zip file location can be passed as an argument or it can be stored in `ENV["GEOIP_ZIPFILE"]`. For example

```julia
using GeoIP

geodata = load(zipfile = "GeoLite2-City-CSV_20191224.zip", datadir = "/data")
```

If `ENV["GEOIP_DATADIR"]` is set to `"/data"` and `ENV["GEOIP_ZIPFILE"]` is set to `"GeoLite2-City-CSV_20191224.zip"` then it is equivalent to
```julia
using GeoIP

geodata = load()
```

## Example

You can get the ip data with the `geolocate` function or by using `[]`

```julia
using GeoIP

geodata = load(zipfile = "GeoLite2-City-CSV_20191224.zip")
geolocate(geodata, ip"1.2.3.4")        # returns dictionary with all relevant information

# Equivalent to
geodata[ip"1.2.3.4"]

# Equivalent, but slower version
geodata["1.2.3.4"]
```

`geolocate` form is useful for broadcasting

```julia
geolocate.(geodata, [ip"1.2.3.4", ip"8.8.8.8"])  # returns vector of geo data.
```

## Localization

It is possible to use localized version of geo files. To load localized data, one can use `locales` argument of the `load` function. To switch between different locales is possible with the help of `setlocale` function.

```julia
using GeoIP

geodata = load(zipfile = "GeoLite2-City-CSV_20191224.zip", locales = [:en, :fr])

geodata[ip"201.186.185.1"]
# Dict{String, Any} with 21 entries:
#   "time_zone"                     => "America/Santiago"
#   "subdivision_2_name"            => missing
#   "accuracy_radius"               => 100
#   "geoname_id"                    => 3874960
#   "continent_code"                => "SA"
#   "postal_code"                   => missing
#   "continent_name"                => "South America"
#   "locale_code"                   => "en"
#   "subdivision_2_iso_code"        => missing
#   "location"                      => Location(-72.9436, -41.4709, 0.0, "WGS84")
#   "v4net"                         => IPv4Net("201.186.185.0/24")
#   "subdivision_1_name"            => "Los Lagos Region"
#   "subdivision_1_iso_code"        => "LL"
#   "city_name"                     => "Port Montt"
#   "metro_code"                    => missing
#   "registered_country_geoname_id" => 3895114
#   "is_in_european_union"          => 0
#   "is_satellite_provider"         => 0
#   "is_anonymous_proxy"            => 0
#   "country_name"                  => "Chile"
#   "country_iso_code"              => "CL"

geodata_fr = setlocale(geodata, :fr)
geodata_fr[ip"201.186.185.1"]
# Dict{String, Any} with 21 entries:
#   "time_zone"                     => "America/Santiago"
#   "subdivision_2_name"            => missing
#   "accuracy_radius"               => 100
#   "geoname_id"                    => 3874960
#   "continent_code"                => "SA"
#   "postal_code"                   => missing
#   "continent_name"                => "Amérique du Sud"
#   "locale_code"                   => "fr"
#   "subdivision_2_iso_code"        => missing
#   "location"                      => Location(-72.9436, -41.4709, 0.0, "WGS84")
#   "v4net"                         => IPv4Net("201.186.185.0/24")
#   "subdivision_1_name"            => missing
#   "subdivision_1_iso_code"        => "LL"
#   "city_name"                     => "Puerto Montt"
#   "metro_code"                    => missing
#   "registered_country_geoname_id" => 3895114
#   "is_in_european_union"          => 0
#   "is_satellite_provider"         => 0
#   "is_anonymous_proxy"            => 0
#   "country_name"                  => "Chili"
#   "country_iso_code"              => "CL"
```

During `load` procedure, it is possible to use either `Symbol` notation, i.e. `locales = [:en, :fr]` or one can pass `Vector` of `Pair`, where first argument is the locale name and second argument is a regular expression, which defines the name of the CSV file, which contains necessary localization. For example `locales = [:en => r"Locations-en.csv%", :fr => r"Locations-fr.csv"]`. By default, following locales are supported `:en, :de, :ru, :ja, :es, :fr, :pt_br, :zh_cn`.

Default locale, which is used in `getlocale` response can be set with the help of `deflocale` argument of the `load` function. For example, to get `:fr` locale by default

```julia
geodata = load(zipfile = "GeoLite2-City-CSV_20191224.zip", locales = [:en, :fr], deflocale = :fr)
```

# Acknowledgements
This product uses, but not include, GeoLite2 data created by MaxMind, available from
[http://www.maxmind.com](http://www.maxmind.com).
