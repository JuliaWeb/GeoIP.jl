using Test
using GeoIP

@testset "Decoding" begin
    include("decode.jl")
end

@testset "Metadata" begin
    include("metadata.jl")
end

#=
# Test known result
ip1 = IPv4("1.2.3.4")
geoip1 = geolocate(ip1; noupdate=false)
@test geoip1[:country_iso_code] == "US"
@test geoip1[:metro_code] == 819
@test ceil(Int, geoip1[:location].x) == -122

# Test null results
@test isempty(geolocate(ip"0.0.0.0"))
@test isempty(geolocate(ip"127.0.0.1"))

# Test array of ip's
result = geolocate([ip"1.2.3.4", ip"8.8.8.8"])
@test length(Set(result)) == 2
@test !isempty(result[1])
@test !isempty(result[2])  
=#

