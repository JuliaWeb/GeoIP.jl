import HTTP

ROOT = "http://geolite.maxmind.com/download/geoip/database"

HTTP.download("$ROOT/GeoLite2-City.tar.gz", "geolite2-city.tar.gz")
HTTP.download("$ROOT/GeoLite2-City.tar.gz.md5", "geolite2-city.tar.gz.md5")
