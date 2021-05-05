module TestBase

using GeoIP
using Sockets: IPv4, @ip_str
using Test

TEST_DATADIR = joinpath(dirname(@__FILE__), "data")

ENV["GEOIP_DATADIR"] = TEST_DATADIR
@testset "ZipFile loading" begin
    ENV["GEOIP_ZIPFILE"] = "GeoLite2-City-CSV.zip"

    geodata = load()

    @testset "Known result" begin
        ip1 = IPv4("1.0.8.1")
        geoip1 = geolocate(geodata, ip1)
        @test geoip1["country_iso_code"] == "CN"
        @test geoip1["time_zone"] == "Asia/Shanghai"
        @test ceil(Int, geoip1["location"].x) == 114

        # String indexing
        geoip1 = geolocate(geodata, "1.0.8.1")
        @test geoip1["country_iso_code"] == "CN"
        @test geoip1["time_zone"] == "Asia/Shanghai"
        @test ceil(Int, geoip1["location"].x) == 114
    end

    @testset "Null results" begin
        @test isempty(geolocate(geodata, ip"0.0.0.0"))
        @test isempty(geolocate(geodata, ip"127.0.0.1"))
    end

    @testset "Broadcasing" begin
        result = geolocate.(geodata, [ip"1.0.16.1", ip"1.0.8.1"])
        @test length(Set(result)) == 2
        @test !isempty(result[1])
        @test !isempty(result[2])  
    end

    @testset "Dict indexing" begin
        geoip1 = geodata[ip"1.0.8.1"]
        @test geoip1["country_iso_code"] == "CN"
        @test geoip1["time_zone"] == "Asia/Shanghai"
        @test ceil(Int, geoip1["location"].x) == 114
    end
end

end # module
