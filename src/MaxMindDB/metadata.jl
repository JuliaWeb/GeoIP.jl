export metadata

const marker = b"\xab\xcd\xefMaxMind.com"

# Cache for metadata calls
const cache = Dict{DB, Dict{String, Any}}()

"""
    metadata(db::DB) -> Dict

Returns a dictionary describing the database.
"""
function metadata(db::DB)
    if db in keys(cache)
        return cache[db]
    end

    b = db.buffer
    lb = length(b)
    lm = length(marker)

    # Scan buffer in reverse looking for marker
    for i in (lb - lm):-1:1
        if b[i] == marker[1] && marker == b[i:(i + lm - 1)]
            return decode(db, i + lm)
        end
    end
    throw("Failed to find any metadata")
end


function nodecount(db::DB)
    m = metadata(db)
    return m["node_count"]
end


function recordsize(db::DB)
    m = metadata(db)
    return m["record_size"]    
end


function treesize(db::DB)
    return (recordsize(db) / 4) * nodecount(db)
end
