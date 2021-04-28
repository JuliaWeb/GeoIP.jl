```@meta
CurrentModule = GeoIP
```

# GeoIP

IP Geolocalization using the [Geolite2](https://dev.maxmind.com/geoip/geoip2/geolite2/) Database

## Installation

The package is registered in the [General](https://github.com/JuliaRegistries/General) registry and so can be installed at the REPL with

```julia
julia> using Pkg
julia> Pkg.add("GeoIP")
```

## Usage

### Data files

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

### Example

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

## Acknowledgements
This product uses, but not include, GeoLite2 data created by MaxMind, available from
[http://www.maxmind.com](http://www.maxmind.com).

```@index
```

```@autodocs
Modules = [GeoIP]
```
