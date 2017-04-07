# GeoIP

[//]: [![GeoIP](http://pkg.julialang.org/badges/GeoIP_0.3.svg)](http://pkg.julialang.org/?pkg=GeoIP&ver=0.3)
[//]: [![GeoIP](http://pkg.julialang.org/badges/GeoIP_0.4.svg)](http://pkg.julialang.org/?pkg=GeoIP&ver=0.4)

Support for Maxmind's IP Geolocation (v2) CSVs.

`GeoIP.geolocate(IPv4)` will load data from the CSV if it's
not already loaded.

### Example
```
a = ip"1.2.3.4"
geolocate(a)        # returns dictionary with all relevant information
```

### Acknowledgements
This product includes GeoLite2 data created by MaxMind, available from
<a href="http://www.maxmind.com">http://www.maxmind.com</a>.
