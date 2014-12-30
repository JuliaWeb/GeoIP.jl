# GeoIP

Support for Maxmind's IP Geolocation (v2) csvs.

`GeoIP.geolocate(IPv4)` will load data from the CSV if it's
not already loaded.

###Example
```
a = ip"1.2.3.4"
geolocate(a)        # returns dictionary with all relevant information
```

###Acknowledgements
This product includes GeoLite2 data created by MaxMind, available from
<a href="http://www.maxmind.com">http://www.maxmind.com</a>.
