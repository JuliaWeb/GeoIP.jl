export decode


# Returns the type of a field. 
#
# The type is a number from 1 - 15. If the type is in [1, 7] then the first 
# three bits are the type. If not these bits are equal to zero and the type is 
# "extended". In this case the next byte plus 7 is the type.
function field_type(db::DB) 
    b, i = db.buffer, db.index
    n = b[i] >> 0x05
    if n == 0x00
        return b[i + 1] + 0x07
    end
    return n
end

# Returns the length of the data section of the field
#
# Length information of a field is encoded in the last 5 bits of the first byte.
# In the case where the length overflows the those 5 bits, subsequent bytes are
# used to specify the length.
function field_length(db::DB)
    b, i = db.buffer, db.index
    # Mask first 3 bits
    first = Int(b[i] & 0x1f)
    if first < 29
        return first
    elseif first == 29
        return UInt(b[i + 1]) + 29
    elseif first == 30
        val = 285
        val += (UInt(b[i + 1]) << 8) | UInt(b[i + 2])
        return val
    elseif first == 31
        val = UInt(65_821)
        val += (UInt(b[i + 1]) << 16) | (UInt(b[i + 2]) << 8) | UInt(b[i + 3])
        return val
    end
end


"""
    decode(db::DB, [i])

Returns the field value at the databases current or, optionally, a specified
location.
"""
function decode(db::DB)
    dec = decoders[field_type(db)]
    return dec(db)
end


function decode(db::DB, i)
    db.index = i
    return decode(db)
end


function decode_pointer(db::DB)
    b, i = db.buffer, db.index

    # Pointers are different than most fields. First byte has the format
    # "001SSVVV" where S refers to the size of the pointer and V refers to the 
    # value of the pointer. If the value overflows 3 bits, subsequent bytes are
    # used to encode the value.
    size = ((b[i] >> 3) & 0x03)
    bytes = b[(i + 1):(i + 1 + size)]    
    
    # If the size == 3, we ignore the values in the first byte and just
    # take the proceding bytes instead.
    value = size == 3 ? zero(UInt) : UInt(size & 0x07)

    for byte in bytes
        value = (value << 8) | UInt(byte)
    end

    if size == 1
        value += UInt(2048)
    elseif size == 2
        value += UInt(526336)
    end

    # Set index to pointer value and decode the field it references
    db.index = value + 1 
    decoded = decode(db)

    # After resolving the pointer, set the index directly after the
    # pointer field. This is critical for correctly traversing arrays
    # and dictionaries that contain pointers.
    db.index = i + size + 2
    return decoded
end


function decode_string(db::DB)
    b, i = db.buffer, db.index
    l = field_length(db)
    if l < 29
        offset = 1
    elseif 29 <= l < 285
        offset = 2
    elseif 265 <= l < 65_821
        offset = 3
    else
        offset = 4
    end
    
    db.index += offset + l
    return transcode(String, b[(i + offset):(i + offset + l - 1)])
end


function decode_double(db::DB)
    b, i = db.buffer, db.index
    v = reinterpret(Float64, b[(i + 1):(i + 8)])[1]
    db.index += 9
    return ntoh(v)
end


decode_bytes(buf) = thow("Not implemented")


function decode_uint16(db::DB)
    b, i = db.buffer, db.index
    l = field_length(db)
    r = zero(UInt16)
    for byte in b[(i + 1):(i + l)]
        r = (r << 8) | UInt16(byte)
    end
    db.index += l + 1
    return r
end


function decode_uint32(db::DB) 
    b, i = db.buffer, db.index
    l = field_length(db)
    r = zero(UInt32)
    for byte in b[(i + 1):(i + l)]
        r = (r << 8) | UInt32(byte)
    end
    db.index += l + 1
    return r
end


function decode_dict(db::DB)
    # field length indicates number of pairs for dicts
    pairs = field_length(db)
    if pairs < 29
        db.index += 1
    elseif 29 <= pairs < 285
        db.index += 2
    elseif 265 <= l < 65_821
        db.index += 3
    else
        db.index += 4
    end
    dict = Dict{String, Any}()

    for pair in 1:pairs
        key = decode(db)
        value = decode(db)
        dict[key] = value
    end

    return dict
end


function decode_int32(db::DB)
    b, i = db.buffer, db.index
    l = field_length(db)
    r = zero(Int32)
    for byte in b[(i + 2):(i + l + 1)]
        r = (r << 8) | Int32(byte)
    end
    db.index += 2 + l
    return r
end


function decode_uint64(db::DB)
    b, i = db.buffer, db.index
    l = field_length(db)
    r = zero(UInt64)
    for byte in b[(i + 2):(i + l + 1)]
        r = (r << 8) | UInt64(byte)
    end
    db.index += l + 2
    return r
end


function decode_uint128(db::DB)
    b, i = db.buffer, db.index
    l = field_length(db)
    r = zero(UInt128)
    for byte in b[(i + 2):(i + l + 1)]
        r = (r << 8) | UInt128(byte)
    end
    db.index += l + 2
    return r
end


function decode_array(db::DB)
    # field length indicates number of elements for arrays
    fields = field_length(db)
    length = if fields < 29
        2
    elseif 29 <= fields < 285
        2
    elseif 265 <= fields < 65_821
        3
    else
        4
    end
    db.index += length
    
    arr = []

    for field in 1:fields
        value = decode(db)
        push!(arr, value)
    end

    return arr
end


decode_data_cache_container(buf) = throw("Not implemented") 
decode_endmarker(buf) = throw("Not implemented")


function decode_bool(db)
    b = Bool(field_length(db))
    db.index += 2
    return b
end


function decode_float(db)
    b, i = db.buffer, db.index
    d = reinterpret(Float32, b[(i + 2):(i + 5)])[1]
    db.index += 6
    return ntoh(d)
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
