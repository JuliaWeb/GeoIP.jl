using GeoIP

let
	# Numeric coding
	ip = GeoIP.numericize("18.0.0.0")
	@assert ip == 18 * 256^3

	@assert getcountrycode(ip) == "US"
	@assert getcountryname(ip) == "United States"

	@assert getcountrycode([ip, ip]) == ["US", "US"]
	@assert getcountryname([ip, ip]) == ["United States", "United States"]

	# String coding
	@assert getcountrycode("18.0.0.0") == "US"
	@assert getcountryname("18.0.0.0") == "United States"

	@assert getcountrycode("18.0.0.0") == "US"
	@assert getcountryname("18.0.0.0") == "United States"

	@assert getcountrycode(["18.0.0.0"]) == ["US"]
	@assert getcountryname(["18.0.0.0"]) == ["United States"]

	@assert getcountrycode(["18.0.0.0", "25.0.0.0"]) == ["US", "GB"]
	@assert getcountryname(["18.0.0.0", "25.0.0.0"]) == ["United States", "United Kingdom"]
end
