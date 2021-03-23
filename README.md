# GeoIP

IP Geolocalization using the [Geolite2](https://dev.maxmind.com/geoip/geoip2/geolite2/) Database

|                                                                                                **Documentation**                                                                                                |                                                                                                                                        **Build Status**                                                                                                                                        |
|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------:|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------:|
|   [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaWeb.github.io/GeoIP.jl/stable)[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaWeb.github.io/GeoIP.jl/dev)   |                       [![Build](https://github.com/JuliaWeb/GeoIP.jl/workflows/CI/badge.svg)](https://github.com/JuliaWeb/GeoIP.jl/actions)[![Coverage](https://codecov.io/gh/JuliaWeb/GeoIP.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaWeb/GeoIP.jl)                       |

## Usage

`GeoIP.geolocate(::IPv4)` will load data from the CSV if it's
not already loaded.

Manual loading can be forced with `load()` call. Data should be located either in `ENV["GEOIP_DATADIR"]` or in package "data" subdirectory.

## Example

```julia
using GeoIP

a = ip"1.2.3.4"
geolocate(a)        # returns dictionary with all relevant information
```

## Acknowledgements
This product uses, but not include, GeoLite2 data created by MaxMind, available from
[http://www.maxmind.com](http://www.maxmind.com).

Source code of [IPNets.jl](https://github.com/JuliaWeb/IPNets.jl) was integrated as a part of package.
