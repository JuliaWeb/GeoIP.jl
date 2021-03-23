module TestBase

using GeoIP
using Sockets: IPv4, @ip_str
using Test

# WARNING!!
# Currently tests are trying to download data from maxmind, which is impossible due to 
# the change of maxmind policy
# Placeholders are left, so they can be used later for actual tests
# after resolving https://github.com/JuliaWeb/GeoIP.jl/issues/12

TEST_DATADIR = joinpath(dirname(@__FILE__), "data")
load(TEST_DATADIR)

@testset "Known result" begin
    ip1 = IPv4("1.0.8.1")
    geoip1 = geolocate(ip1)
    @test geoip1["country_iso_code"] == "CN"
    @test geoip1["time_zone"] == "Asia/Shanghai"
    @test ceil(Int, geoip1["location"].x) == 114
end

@testset "Null results" begin
    @test isempty(geolocate(ip"0.0.0.0"))
    @test isempty(geolocate(ip"127.0.0.1"))
end

@testset "Array of ip's" begin
    result = geolocate.([ip"1.0.16.1", ip"1.0.8.1"])
    @test length(Set(result)) == 2
    @test !isempty(result[1])
    @test !isempty(result[2])  
end

end # module
