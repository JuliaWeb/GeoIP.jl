module TestBase

using GeoIP
using Sockets: IPv4
using Test

# WARNING!!
# Currently tests are trying to download data from maxmind, which is impossible due to 
# the change of maxmind policy
# Placeholders are left, so they can be used later for actual tests
# after resolving https://github.com/JuliaWeb/GeoIP.jl/issues/12

@testset "Known result" begin
    ip1 = IPv4("1.2.3.4")
    # geoip1 = geolocate(ip1; noupdate=false)
    # @test geoip1[:country_iso_code] == "US"
    # @test geoip1[:metro_code] == 819
    # @test ceil(Int, geoip1[:location].x) == -122
end

@testset "Null results" begin
    # @test isempty(geolocate(ip"0.0.0.0"))
    # @test isempty(geolocate(ip"127.0.0.1"))
end

@testset "Array of ip's" begin
    # result = geolocate([ip"1.2.3.4", ip"8.8.8.8"])
    # @test length(Set(result)) == 2
    # @test !isempty(result[1])
    # @test !isempty(result[2])  
end

end # module
