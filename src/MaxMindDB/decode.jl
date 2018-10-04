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
    first = Int(buf[1] & 0x1f)  # 00011111
    if first < 29
        return first
    elseif first == 29
        return UInt(buf[2]) + 29
    elseif first == 30
        val = 285
        val += (UInt(buf[2]) << 8) | UInt(buf[3])
        return val
    elseif first == 31
        val = UInt(65_821)
        val += (UInt(buf[2]) << 16) | (UInt(buf[3]) << 8) | UInt(buf[4])
        return val
    end
end

function decode(buf)
    d = decoders[field_type(buf)]
    return d(buf)
end

decode_pointer(buf) = throw("Now implemented")

function decode_string(buf)
    l = field_length(buf)
    if l < 29
        offset = 2
    elseif 29 <= l < 285
        offset = 3
    elseif 265 <= l < 65_821
        offset = 4
    else
        offset = 5
    end
    return transcode(String, buf[offset:(offset+l-1)]), offset + l - 1
end

function decode_double(buf)
    d = reinterpret(Float64, buf[2:9])[1]
    return ntoh(d), 9
end

decode_bytes(buf) = thow("Not implemented")

function decode_uint16(buf)
    r = 0x0000
    l = field_length(buf)
    for byte in buf[2:(2 + l - 1)]
        r = (r << 8) | UInt16(byte)
    end
   return r, l + 1
end

function decode_uint32(buf) 
    r = 0x00000000
    l = field_length(buf)
    for byte in buf[2:(2 + l -1)]
        r = (r << 8) | UInt32(byte)
    end
    return r, l + 1
end

function decode_dict(buf)
    # field length indicates number of pairs for dicts
    pairs = field_length(buf)
    if pairs < 29
        length = 1
    elseif 29 <= pairs < 285
        length = 2
    elseif 265 <= l < 65_821
        length = 3
    else
        length = 4
    end
    dict = Dict{String, Any}()
    
    for pair in 1:pairs
        key, decoded = decode(buf[(length + 1):end])
        length += decoded
        value, decoded = decode(buf[(length + 1):end])
        length += decoded

        dict[key] = value
    end

    return dict, length
end

function decode_int32(buf)
    r = Int32(0)
    l = field_length(buf)
    for byte in buf[3:3+l-1]
        r = (r << 8) | Int32(byte)
    end
    return r, 2 + l
end

function decode_uint64(buf)
    r = zero(UInt64)
    l = field_length(buf)
    for byte in buf[3:(3+l-1)]
        r = (r << 8) | UInt64(byte)
    end
    return r, 2 + l
end

function decode_uint128(buf)
    r = zero(UInt128)
    l = field_length(buf)
    for byte in buf[3:(3 + l - 1)]
        r = (r << 8) | UInt128(byte)
    end
    return r, 2 + l
end

function decode_array(buf)
    # field length indicates number of elements for arrays
    eles = field_length(buf)
    if eles < 29
        length = 2
    elseif 29 <= eles < 285
        length = 2
    elseif 265 <= eles < 65_821
        length = 3
    else
        length = 4
    end
    
    arr = []

    for ele in 1:eles
        value, decoded = decode(buf[(length + 1):end])
        length += decoded
        push!(arr, value)
    end
    return arr, length
end

decode_data_cache_container(buf) = throw("Not implemented")     # Date cache container. TODO: What should this type be?
decode_endmarker(buf) = throw("Not implemented")     # End marker, empty payload.

function decode_bool(buf)
    return Bool(field_length(buf)), 1
end

function decode_float(buf)
    d = reinterpret(Float32, buf[3:6])[1]
    return ntoh(d), 6
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
