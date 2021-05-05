module TestLocalization

using GeoIP
using Sockets: IPv4, @ip_str
using Test

TEST_DATADIR = joinpath(dirname(@__FILE__), "data")

ENV["GEOIP_DATADIR"] = TEST_DATADIR
ENV["GEOIP_ZIPFILE"] = "GeoLite2-City-CSV.zip"

@testset "Locales setup" begin
    db = load(locales = [:en, :ru])
    geoip1 = db[ip"1.0.8.1"]
    @test geoip1["locale_code"] == "en"
    @test geoip1["continent_name"] == "Asia"

    db2 = setlocale(db, :ru)
    geoip1 = db2[ip"1.0.8.1"]
    @test geoip1["locale_code"] == "ru"
    @test geoip1["continent_name"] == "Азия"
end

@testset "Missed locales" begin
    db = load(locales = [:en, :ru], deflocale = :ru)
    geoip1 = db[ip"1.0.1.1"]
    @test !haskey(geoip1, "locale_code")

    db2 = setlocale(db, :en)
    geoip1 = db2[ip"1.0.1.1"]
    @test geoip1["locale_code"] == "en"
end

end # module
