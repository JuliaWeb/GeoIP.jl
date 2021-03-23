```@meta
CurrentModule = GeoIP
```

# GeoIP

*IP Geolocalization using the [Geolite2](https://dev.maxmind.com/geoip/geoip2/geolite2/) Database*

## Usage

`GeoIP.geolocate(IPv4)` will load data from the CSV if it's
not already loaded.

## Example

```julia
using GeoIP
a = ip"1.2.3.4"
geolocate(a)        # returns dictionary with all relevant information
```

## Acknowledgements
This product uses, but not include, GeoLite2 data created by MaxMind, available from
[http://www.maxmind.com](http://www.maxmind.com).

```@index
```

```@autodocs
Modules = [GeoIP]
```
