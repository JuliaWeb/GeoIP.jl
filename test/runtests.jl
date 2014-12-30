using Base.Test
using GeoIP

ip1 = IPv4("1.2.3.4")
geoip1 = geolocate(ip1; noupdate=false)
@test geoip1[:country_iso_code] == "US"
@test geoip1[:metro_code] == 819
@test geoip1[:location].x == -122.3042
