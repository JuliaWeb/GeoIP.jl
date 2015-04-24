using Base.Test
using Compat
using GeoIP

ip1 = IPv4("1.2.3.4")
geoip1 = geolocate(ip1; noupdate=false)
@test geoip1[:country_iso_code] == "US"
@test geoip1[:metro_code] == 819
@test @compat(ceil(Int, geoip1[:location].x)) == -122
