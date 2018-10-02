struct Metadata 
    node_count::UInt32
    record_size::UInt16
    ip_version::UInt16
    database_type::String
    languages::Array{String}
    binary_format_major_version::UInt16
    binary_format_minor_version::UInt16
    build_epoch::UInt64
    description::Dict{String, String}
end

const marker = b"\xab\xcd\xefMaxMind.com"

function metadata(buf)
    for i in (length(buf) - length(marker)):-1:1
        if buf[i] == marker[1] && marker == buf[i:i+length(marker)-1]
            return buf[i + length(marker):end]
        end
    end
    return UInt8[]  
end