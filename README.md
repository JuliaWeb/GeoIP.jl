# GeoIP

*IP Geolocalization using the [Geolite2](https://dev.maxmind.com/geoip/geoip2/geolite2/) Database*

| *Package Evaluator* | *Build Status* | *Coverage* |
|:-------------------:|:--------------:|:----------:|
| [![GeoIP](http://pkg.julialang.org/badges/GeoIP_0.6.svg)](http://pkg.julialang.org/?pkg=GeoIP&ver=0.6) | [![Build Status](https://travis-ci.org/JuliaWeb/GeoIP.jl.svg?branch=master)](https://travis-ci.org/JuliaWeb/GeoIP.jl) | [![Coverage Status](https://coveralls.io/repos/github/JuliaWeb/GeoIP.jl/badge.svg)](https://coveralls.io/github/JuliaWeb/GeoIP.jl) |

### Usage

`GeoIP.geolocate(IPv4)` will load data from the CSV if it's
not already loaded.

```julia
using GeoIP
a = ip"1.2.3.4"
geolocate(a)        # returns dictionary with all relevant information
```

### Acknowledgements
This product includes GeoLite2 data created by MaxMind, available from
[http://www.maxmind.com](http://www.maxmind.com).
