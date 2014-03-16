module TestGeoIP
    using Base.Test
    using GeoIP

	ip1i = GeoIP.numericize("18.0.0.0")
	ip2i = GeoIP.numericize("25.0.0.0")
	ip1s = "18.0.0.0"
	ip2s = "25.0.0.0"

	@test ip1i == 18 * 256^3
	@test ip2i == 25 * 256^3

	@test getcountrycode(ip1i) == "US"
	@test getcountryname(ip1i) == "United States"
	@test getcountrycode(ip1s) == "US"
	@test getcountryname(ip1s) == "United States"

	@test getcountrycode([ip1i, ip1i]) == ["US", "US"]
	@test getcountryname([ip1i, ip1i]) == ["United States", "United States"]
	@test getcountrycode([ip1s, ip2s]) == ["US", "GB"]
	@test getcountryname([ip1s, ip2s]) == ["United States", "United Kingdom"]

    @test getregionname(1135531255) == "KS"
    @test getregionname([1135531255,1135531255]) == ["KS", "KS"]

    @test getcityname(1135531255) == "Overland Park"
    @test getcityname([1135531255, 1135531255]) == [
        "Overland Park", "Overland Park"
    ]

    @test getpostalcode(1135531255) == "66212"
    @test getpostalcode([1135531255, 1135531255]) == ["66212", "66212"]

    @test getlongitude(1135531255) == -94.6811
    @test getlongitude([1135531255, 1135531255]) == [-94.6811, -94.6811]

    @test getlatitude(1135531255) == 38.9593
    @test getlatitude([1135531255, 1135531255]) == [38.9593, 38.9593]

    @test getmetrocode(1135531255) == 616
    @test getmetrocode([1135531255,1135531255]) == [616, 616]

    @test getareacode(1135531255) == 913
    @test getareacode([1135531255,1135531255]) == [913, 913]
end
