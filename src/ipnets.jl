module IPNets

import Base: eltype, lastindex,
length, size, minimum, maximum, extrema, isless,
in, contains, issubset, getindex,
show, string, start, next, done

import Sockets: IPAddr, IPv4, IPv6, @ip_str

export
    # types
    IPNet, IPv4Net, IPv6Net, netmask

IPv4broadcast = typemax(UInt32)
IPv6broadcast = typemax(UInt128)

width(::Type{IPv4}) = UInt8(32)
width(::Type{IPv6}) = UInt8(128)

##################################################
# IPNet
##################################################
abstract type IPNet end

IPNet(ipmask::AbstractString) = ':' in ipmask ? IPv6Net(ipmask) : IPv4Net(ipmask)

##################################################
# Network representations
##################################################

"""Returns the size of an IP network (# of hosts) as a tuple.
"""
function size(net::IPNet)
    numbits = width(typeof(net.netaddr)) - net.netmask
    return (big(2)^numbits, )
end

"""Returns the size of an IP network (# of hosts) as a tuple.
"""
length(net::IPNet) = size(net)[1]

"""String representation of an IP network"""
function string(net::IPNet)
    t = typeof(net)
    s = string("$t(\"")
    s = string(s, net.netaddr, "/", net.netmask, "\")")
    return s
end

show(io::IO, net::IPNet) = print(io, string(net))

# IP Networks are ordered first by starting network address
# and then by network mask. That is, smaller IP nets (with higher
# netmask values) are "less" than larger ones. This corresponds
# to secondary reordering by ending address.
isless(a::T, b::T) where T <: IPNet = a.netaddr == b.netaddr ?
        isless(b.netmask, a.netmask) :
        isless(a.netaddr, b.netaddr)

function issubset(a::T, b::T) where T <: IPNet
    astart, aend = extrema(a)
    bstart, bend = extrema(b)
    return (bstart <= astart <= aend <= bend)
end

"""Membership test for an IP address within an IP network"""
function in(ipaddr::IPAddr, net::IPNet)
    typeof(net.netaddr) == typeof(ipaddr) ||
        error("IPAddr is not the same type as IPNet")
    netstart = net.netaddr.host
    numbits = width(typeof(ipaddr)) - net.netmask
    netend = net.netaddr.host + big(2)^numbits - 1
    return netstart <= ipaddr.host <= netend
end

"""Membership test for an IP address within an IP network"""
contains(net::IPNet, ipaddr::IPAddr) = in(ipaddr, net)

function getindex(net::IPNet, i::Integer)
    t = typeof(net.netaddr)
    ip = t(net.netaddr.host + i - 1)
    ip in net || throw(BoundsError())
    return ip
end


minimum(net::IPNet) = net[1]
maximum(net::IPNet) = net[end]
extrema(net::IPNet) = (minimum(net), maximum(net))
getindex(net::IPNet, r::AbstractRange) = [net[i] for i in r]
start(net::IPNet) = net[1]
next(net::IPNet, s::T) where T <: IPAddr = s, T(s.host + 1)
done(net::IPNet, s::T) where T <: IPAddr = s > net[end]


##################################################
# IPv4
##################################################
"""Type representing an IPv4 network"""
struct IPv4Net <: IPNet
    netaddr::IPv4
    netmask::UInt8
    function IPv4Net(na::IPv4, nmi::Integer)
        (0 <= nmi <= width(IPv4)) || error("Invalid netmask")

        nm = UInt8(nmi)
        mask = _mask2bits(IPv4, nm)
        startip = UInt32(na.host & mask)
        new(IPv4(startip),nm)
    end
end


# "1.2.3.0/24"
function IPv4Net(ipmask::AbstractString)
    if something(findfirst(isequal('/'), ipmask), 0) > 0
        addrstr, netmaskstr = split(ipmask,"/")
        netmask = parse(UInt8, netmaskstr)
    else
        addrstr = ipmask
        netmask = width(IPv4)
    end
    netaddr = IPv4(addrstr)
    return IPv4Net(netaddr,netmask)
end

# "1.2.3.0", "255.255.255.0"
function IPv4Net(netaddr::AbstractString, netmask::AbstractString)
    netaddr = IPv4(netaddr).host
    netmask = _contiguousbitcount(IPv4(netmask).host)
    return IPv4Net(netaddr, netmask)
end

# 123872, 24
IPv4Net(ipaddr::Integer, netmask::Integer) = IPv4Net(IPv4(ipaddr), netmask)

# "(x,y)"
IPv4Net(tuple::Tuple{A,M}) where A where M = IPv4Net(tuple[1],tuple[2])

# "1.2.3.0", 24
IPv4Net(netaddr::AbstractString, netmask::Integer) = IPv4Net(IPv4(netaddr), netmask)

"""Returns the netmask as an IPv4 address"""
netmask(n::IPv4Net) = IPv4(IPv4broadcast-2^(32-n.netmask)+1)

eltype(x::IPv4Net) = IPv4
lastindex(net::IPv4Net) = UInt32(length(net))

##################################################
# IPv6
##################################################

"""Type representing an IPv6 network"""
struct IPv6Net <: IPNet
    # we treat the netmask as a potentially noncontiguous bitmask
    # for speed of calculation and consistency, but RFC2373, section
    # 2 provides for contiguous bitmasks only. We validate this
    # in the internal constructor. This wastes ~15 bytes per addr
    # for the benefit of rapid, consistent computation.
    netaddr::IPv6
    netmask::UInt32

    function IPv6Net(na::IPv6, nmi::Integer)
        (0 <= nmi <= width(IPv6)) || error("Invalid netmask")

        nm = UInt8(nmi)
        mask = _mask2bits(IPv6, nm)
        startip = UInt128(na.host & mask)
        return new(IPv6(startip), nm)
    end
end


# "2001::1/64"
function IPv6Net(ipmask::AbstractString)
    if something(findfirst(isequal('/'), ipmask), 0) > 0
        addrstr, netmaskbits = split(ipmask,"/")
        nmi = parse(Int,netmaskbits)
    else
        addrstr = ipmask
        nmi = width(IPv6)
    end
    netaddr = IPv6(addrstr)
    netmask = nmi
    return IPv6Net(netaddr,netmask)
end


# "2001::1", 64
function IPv6Net(netaddr::AbstractString, netmask::Integer)
    netaddr = IPv6(netaddr)
    return IPv6Net(netaddr, netmask)
end


# 123872, 128
IPv6Net(ipaddr::Integer, netmask::Integer) = IPv6Net(IPv6(ipaddr), netmask)


# (123872, 128)
IPv6Net(t::Tuple{A,M}) where A where M = IPv6Net(t[1],t[2])

eltype(x::IPv6Net) = IPv6
lastindex(net::IPv6Net) = UInt128(length(net))


### Helper functions
function _contiguousbitcount(n::Integer,t=UInt32)
    # takes an integer from 0 to 255 and a type, returns the number
    # of contiguous 1 bits in the number assuming it's of that type,
    # starting from the left.
    # cbc(240,UInt8) == 0x04 ("1111 0000")
    # cbc(252,UInt8) == 0x06 ("1111 1100")
    # cbc(127,UInt8) == error ("0111 1111")

    n = convert(t,n)
    invn = ~n
    bitct = log2(invn + 1)
    isinteger(bitct) || error("noncontiguous bits")

    bitct = floor(Int,bitct)
    return UInt8(sizeof(t)*8 - bitct)
end


function _mask2bits(t::Type, n::Unsigned)
    # takes a number of 1's bits in a
    # netmask and returns an integer representation
    maskbits = Int(width(t)) - Int(n)
    maskbits < 0 && throw(BoundsError())

    return (~(UInt128(2)^maskbits-1))
end

end # module
