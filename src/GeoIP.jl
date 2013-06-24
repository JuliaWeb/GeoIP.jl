module GeoIP
	using DataFrames

	export getcountrycode, getcountryname

	# A lookup table for IP addresses
	immutable IPTable{T <: ByteString}
		ends::Vector{Int}
		countrycodes::Vector{T}
		countrynames::Vector{T}
	end

	# Read in raw IP data from a CSV file into an IPTable
	function loaddata(pathname::String)
		ips = readtable(pathname,
			            header = false,
			            nastrings = ["NULL"])
		colnames!(ips,
			      UTF8String["BeginRange",
			                 "EndRange",
			                 "BeginNum",
			                 "EndNum",
			                 "Code",
			                 "Name"])
		return IPTable(int(ips["EndNum"]),
			           convert(Vector{UTF8String}, ips["Code"]),
			           convert(Vector{UTF8String}, ips["Name"]))
	end

	# Cache IP address lookup table in memory
	const LOOKUP = loaddata(Pkg.dir("GeoIP", "data", "geoip.csv"))

	# Transform an 4-octet IP address into a base-256 number
	function numericize(ip::String)
		ns = map(int, split(ip, "."))
		return ns[1] * 256^3 + ns[2] * 256^2 + ns[3] * 256^1 + ns[4]
	end

	# Find the first row in the data set whose end range is larger than IP address
	function getcountrycode(ip::Integer)
		bounds = searchsorted(LOOKUP.ends, ip)
		return LOOKUP.countrycodes[bounds.start]
	end
	getcountrycode(ip::String) = getcountrycode(numericize(ip))

	# Find the first row in the data set whose end range is larger than IP address
	function getcountryname(ip::Integer)
		bounds = searchsorted(LOOKUP.ends, ip)
		return LOOKUP.countrynames[bounds.start]
	end
	getcountryname(ip::String) = getcountryname(numericize(ip))

	# Vectorize these functions
	Base.@vectorize_1arg Union(Integer, String) getcountrycode
	Base.@vectorize_1arg Union(Integer, String) getcountryname
end
