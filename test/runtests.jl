using Base.Test
using Compat
using GeoIP

GeoIP.enable_testing()

ip1 = IPv4("1.0.0.4")
geoip1 = geolocate(ip1; noupdate=false)
@test geoip1[:country_iso_code] == "AU"
@test geoip1[:registered_country_geoname_id] == 2077456
@test @compat(ceil(Int, geoip1[:location].x)) == 133

GeoIP.disable_testing()
