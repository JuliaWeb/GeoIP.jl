# GeoIP

Support for Maxmind's IP Geolocation (v2) csvs.

Requires some IPv4 constructors not yet merged into Base.

`GeoIP.geolocate(IPv4)` will load data from the CSV if it's
not already loaded.

*TODO:*
- tests
- prettier output
- API access instead of CSV
- parallelism?

###Acknowledgements
This product includes GeoLite2 data created by MaxMind, available from
<a href="http://www.maxmind.com">http://www.maxmind.com</a>.
