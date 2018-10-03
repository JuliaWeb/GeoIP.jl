# Maxmind Database specification.
# See http://maxmind.github.io/MaxMind-DB/ for details
export decode

function field_type(buf) 
    if buf[1] >> 0x05 == 0x00
        # Extended data type, look in next byte for value and
        # return value plus 7 for some reason..
        return buf[2] + 0x07
    end
    return buf[1] >> 0x05
end

function field_length(buf)
    # Mask first 3 bits
    first = buf[1] & 0x1f  # 00011111
    if first < 29
        return UInt(first)
    elseif first == 29
        return UInt(first) + 29
    elseif first == 30
        val = 285
        val += UInt(buf[2] << 8) | UInt(buf[3])
        return val
    elseif first == 31
        val = 65_821
        val += UInt(buf[2] << 16) | UInt(buf[3] << 8) | UInt(buf[4])
        return val
    end
end

function decode(buf)
    d = decoders[field_type(buf)]
    return d(buf)
end

decode_pointer(buf) = throw("Now implemented")
decode_string(buf) = throw("Not implemented")

function decode_double(buf)
    d = reinterpret(Float64, buf[2:9])[1]
    ntoh(d)
end

decode_bytes(buf) = thow("Not implemented")
decode_uint16(buf) = throw("Not implemented")
decode_uint32(buf) = throw("Not implemented")
decode_dict(buf) = throw("Not implemented")
decode_int32(buf) = throw("Not implemented")
decode_uint64(buf) = throw("Not implemented")
decode_uint128(buf) = throw("Not implemented")
decode_array(buf) = throw("Not implemented")
decode_data_cache_container(buf) = throw("Not implemented")     # Date cache container. TODO: What should this type be?
decode_endmarker(buf) = throw("Not implemented")     # End marker, empty payload.
decode_bool(buf) = Bool(field_length(buf))

function decode_float(buf)
    d = reinterpret(Float32, buf[3:6])[1]
    ntoh(d)
end



const decoders = Dict{UInt8, Any}(
    1  => decode_pointer,
    2  => decode_string,
    3  => decode_double,
    4  => decode_bytes,
    5  => decode_uint16,
    6  => decode_uint32,
    7  => decode_dict,
    8  => decode_int32,
    9  => decode_uint64,
    10 => decode_uint128,
    11 => decode_array,
    12 => decode_data_cache_container,     # Date cache container. TODO: What should this type be?
    13 => decode_endmarker,                # End marker, empty payload.
    14 => decode_bool,
    15 => decode_float   # Rarely used apparently
)
