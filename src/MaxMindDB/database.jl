import Mmap

export DB


mutable struct DB
    buffer::Vector{UInt8}
    index::Int 
end


function DB(buffer::Vector{UInt8})
    return DB(buffer, 1)
end


function DB(filename::String; mode=:mmap)
    db = if mode == :mmap
        f = open(filename, "r")
        buf = Mmap.mmap(f, Vector{UInt8})
        DB(buf)
    elseif mode == :ram
        open(filename, "r") do f
            buf = read(f)
            DB(buf)
        end
    else
        throw("Mode $mode not recognized")
    end
    
    return db
end
