using Test
import Mmap

import GeoIP

decode(x) = hex2bytes(x) |> GeoIP.MaxMindDB.DB |> GeoIP.MaxMindDB.decode

@testset "Boolean Decoding" begin
    @test decode("0007") == false
    @test decode("0107") == true
end

@testset "Float64 Decoding" begin
    @test decode("680000000000000000") == 0.0
    @test decode("683FE0000000000000") == 0.5
    @test decode("68400921FB54442EEA") == 3.14159265359
    @test decode("68405EC00000000000") == 123.0
    @test decode("6841D000000007F8F4") == 1073741824.12457
    @test decode("68BFE0000000000000") == -0.5
    @test decode("68C00921FB54442EEA") == -3.14159265359
    @test decode("68C1D000000007F8F4") == -1073741824.12457
end

@testset "Float32 Decoding" begin
    @test decode("040800000000") == Float32(0.0)
    @test decode("04083F800000") == Float32(1.0)
    @test decode("04083F8CCCCD") == Float32(1.1)
    @test decode("04084048F5C3") == Float32(3.14)
    @test decode("0408461C3FF6") == Float32(9999.99)
    @test decode("0408BF800000") == Float32(-1.0)
    @test decode("0408BF8CCCCD") == Float32(-1.1)
    @test decode("0408C048F5C3") == Float32(-3.14)
    @test decode("0408C61C3FF6") == Float32(-9999.99)
end

@testset "Int32 Decoding" begin
    @test decode("0001") == 0
    @test decode("0401ffffffff") == -1
    @test decode("0101ff") == 255
    @test decode("0401ffffff01") == -255
    @test decode("020101f4") == 500
    @test decode("0401fffffe0c") == -500
    @test decode("0201ffff") == 65535
    @test decode("0401ffff0001") == -65535
    @test decode("0301ffffff")  == 16777215
    @test decode("0401ff000001") == -16777215
    @test decode("04017fffffff") == 2147483647
    @test decode("040180000001") == -2147483647
end

@testset "UInt16 Decoding" begin
    @test decode("a0") == UInt16(0)
    @test decode("a1ff") ==  UInt16(255)
    @test decode("a201f4") == UInt16(500)
    @test decode("a22a78") == UInt16(10872)
    @test decode("a2ffff") == UInt16(65535)
end

@testset "UInt32 Decoding" begin
    @test decode("c0") == UInt32(0)
    @test decode("c1ff")== UInt32(255)
    @test decode("c201f4") == UInt32(500)
    @test decode("c22a78") == UInt32(10872)
    @test decode("c2ffff") == UInt32(65535)
    @test decode("c3ffffff") == UInt32(16777215)
    @test decode("c4ffffffff") == UInt32(4294967295)
end

@testset "UInt64 Decoding" begin
    @test decode("0002") == UInt64(0)
    @test decode("020201f4") == UInt64(500)
    @test decode("02022a78") == UInt64(10872)
end

@testset "UInt128 Decoding" begin
    @test decode("0003") == UInt128(0)
	@test decode("020301f4") == UInt128(500)
    @test decode("02032a78") == UInt128(10872)
end

@testset "Array Decoding" begin
    @test decode("0004") == []
	@test decode("010443466f6f") == ["Foo"]
    @test decode("020443466f6f43e4baba") == ["Foo", "人"]
end

@testset "Dictionary Decoding" begin
    @test decode("e0") == Dict()
    @test decode("e142656e43466f6f") == Dict("en" => "Foo")
	@test decode("e242656e43466f6f427a6843e4baba") == Dict("en" => "Foo", "zh" => "人")
	@test decode("e1446e616d65e242656e43466f6f427a6843e4baba") == Dict("name" => Dict("en" => "Foo", "zh" => "人"))
    @test decode("e1496c616e677561676573020442656e427a68") == Dict("languages" => ["en", "zh"])
end

@testset "String Decoding" begin
    @test decode("40") == ""
    @test decode("4131") == "1"
	@test decode("43E4BABA") == "人"
	@test decode("5b313233343536373839303132333435363738393031323334353637") == "123456789012345678901234567"
    @test decode("5c31323334353637383930313233343536373839303132333435363738") == "1234567890123456789012345678"
	@test decode("5d003132333435363738393031323334353637383930313233343536373839") == "12345678901234567890123456789"
	@test decode("5d01313233343536373839303132333435363738393031323334353637383930") == "123456789012345678901234567890"

    # Long strings
    for (key, value) in Dict("5e00d7" => 500, "5e06b3" => 2000, "5f001053" => 70000)
		@test decode("$key" * repeat("78", value)) == repeat("x", value)
    end
end

@testset "Pointer Decoding" begin
    db = GeoIP.MaxMindDB.DB("maps-with-pointers.raw")
    data = Dict(
        1 => Dict("long_key" => "long_value1"),
	    23 => Dict("long_key" => "long_value2"),
	    38 => Dict("long_key2" => "long_value1"),
	    51 => Dict("long_key2" => "long_value2"),
	    56 => Dict("long_key" => "long_value1"),
        58 => Dict("long_key2" => "long_value2")
    )

    for (ptr, dict) in data
        db.index = ptr
        decoded = GeoIP.MaxMindDB.decode(db)
        @test decoded == dict
    end
end