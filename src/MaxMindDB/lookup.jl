using Sockets


function asbits(ip::IPAddr)
    return UInt128(ip)
end


function firstnode(db::DB)
    size = recordsize(db)
    width = 2 * size
    return db.buffer[1:(width - 1)]
end


function nextnode(db::DB, next)
    size = recordsize(db)
    width = 2 * size
    return db.buffer[(next * width):(((next + 1) * width) - 1)]    
end


function left(node)
    size = length(node)
    r = isodd(size) ? UInt(node[(size >> 1) + 1] >> 4) : zero(UInt)
    for byte in node[1:(size >> 1)]
        r = (r << 8) | UInt(byte)
    end
    return r
end


function right(node)
    size = length(node)
    r = isodd(size) ? UInt(node[(size >> 1) + 1] & 0xF0) : zero(UInt)
    for byte in node[((size >> 1) + 2):end]
        r = (r << 8) | UInt(byte)
    end
    return r
end


function lookup(db::DB, ip::IPAddr)
    bits = asbits(ip)
    nodes = nodecount(db)
    node = firstnode(db)
    for i in 1:128
        global _next = Bool(((bits >> i) & 1)) ? right(node) : left(node)
        if _next < nodes
            node = nextnode(db, next)
        elseif _next == nodes
            return nothing
        else
            break
        end
    end
    ptr = (_next - nodes) + treesize(db)
    return decode(db, ptr)
end