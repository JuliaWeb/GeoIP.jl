export metadata

const marker = b"\xab\xcd\xefMaxMind.com"


"""
    metadata(db::DB) -> Dict

Returns a dictionary describing the database.
"""
function metadata(db::DB)
    b = db.buffer
    lb = length(b)
    lm = length(marker)

    # Traverse buffer in reverse looking for marker
    for i in (lb - lm):-1:1
        if b[i] == marker[1] && marker == b[i:(i + lm - 1)]
            return decode(db, i + lm)
        end
    end
    throw("Failed to find any metadata")
end