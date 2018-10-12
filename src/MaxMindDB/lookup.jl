using Sockets


function asbits(ip::IPv4)
    return UInt32(ip)
end


function asbits(ip::IPv6)
    return UInt128(ip)
end


function firstnode(db::DB)
    size = recordsize(db)
    width = size >> 2
    return db.buffer[1:width]
end


function firstIPv4node(db::DB)
    node = firstnode(db)
    next = zero(UInt)
    for i in 1:96
        next = left(node)
        node = nextnode(db, next)
    end
    return node
end


function nextnode(db::DB, next)
    size = recordsize(db)
    width = size >> 2
    return db.buffer[((next * width) + 1):((next + 1) * width)]    
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
    r = isodd(size) ? UInt(node[(size >> 1) + 1] & 0x0F) : zero(UInt)
    for byte in node[((size >> 1) + 2):end]
        r = (r << 8) | UInt(byte)
    end
    return r
end


function lookup(db::DB, ip::IPv4)
    bits = asbits(ip)
    nodes = nodecount(db)
    node = firstIPv4node(db)
    next = zero(UInt) 
    for i in 0:31
        next = Bool(((bits >> i) & 1)) ? right(node) : left(node)
        println("Next node: $(Int(next)) / $(Int(nodes))")
        if next < nodes
            node = nextnode(db, next)
        elseif next == nodes
            return nothing
        else
            break
        end
    end
    println("Found something! 'next' == $next")
    ptr = (next - nodes) + treesize(db) + 1
    return decode(db, ptr)
end