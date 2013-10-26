module GeoIP
	using DataFrames

	export getcountrycode, getcountryname, getregionname, getcityname, getpostalcode, 
	getlongitude, getlatitude, getmetrocode, getareacode

##########################################################################################
#
# Helper functions
#
##########################################################################################


	# Transform an 4-octet IP address into a base-256 number
	function numericize(ip::String)
		ns = map(int, split(ip, "."))
		return ns[1] * 256^3 + ns[2] * 256^2 + ns[3] * 256^1 + ns[4]
	end



##########################################################################################
#
# Country Database: getcountrycode and getcountryname
#
##########################################################################################

	# A lookup table for IP addresses from country database
	immutable IPTableCountry{T <: ByteString}
		ends::Vector{Int}
		countrycodes::Vector{T}
		countrynames::Vector{T}
	end

	# Read in raw IP data from a CSV file into an IPTable
	function loaddatacountry(pathname::String)
		ips = readtable(pathname,
			            header = false,
			            nastrings = ["NULL"])
		colnames!(ips,
			      UTF8String ["BeginRange",
			                 "EndRange",
			                 "BeginNum",
			                 "EndNum",
			                 "Code",
			                 "Name"])
		return IPTableCountry(int(ips["EndNum"]),
			           convert(Vector{UTF8String }, ips["Code"]),
			           convert(Vector{UTF8String }, ips["Name"]))
	end

	# Cache IP address country lookup table in memory
	const LOOKUPCOUNTRY = loaddatacountry(Pkg.dir("GeoIP", "data", "geoip.csv"))

	# Find the first row in the data set whose end range is larger than IP address
	function getcountrycode(ip::Integer)
		bounds = searchsorted(LOOKUPCOUNTRY.ends, ip)
		return LOOKUPCOUNTRY.countrycodes[bounds.start]
	end
	getcountrycode(ip::String) = getcountrycode(numericize(ip))

	# Find the first row in the data set whose end range is larger than IP address
	function getcountryname(ip::Integer)
		bounds = searchsorted(LOOKUPCOUNTRY.ends, ip)
		return LOOKUPCOUNTRY.countrynames[bounds.start]
	end
	getcountryname(ip::String) = getcountryname(numericize(ip))

	# Vectorize these functions
	Base.@vectorize_1arg Union(Integer, String) getcountrycode
	Base.@vectorize_1arg Union(Integer, String) getcountryname


##########################################################################################
#
# City Database
#
##########################################################################################

# A lookup table for IP addresses from city database
# Evaluate setting more explicit types after code works
	immutable IPTableCity
		ends::DataArray{Int64}
		country::DataArray{UTF8String }   
 		region::DataArray{UTF8String }
 		city::DataArray{UTF8String }      
   		postalcode::DataArray{UTF8String } 
 		latitude::DataArray{Float64}   
 		longitude::DataArray{Float64} 
 		metrocode::DataArray{Int64}  
 		areacode::DataArray{Int64}  
	end

# Read in raw IP data from a CSV file into an IPTable
	function loaddatacity(blockspath::String, locationspath::String)
		
		#Read in blocks and locations, merge by locId
		blocks = readtable(blockspath, nastrings = ["NULL"])

		locations = readtable(locationspath, nastrings = ["NULL"])

		full = join(blocks, locations, on = "locId", kind = :inner)
		

		return IPTableCity(convert(DataArray{Int64}, full["endIpNum"]),
			           	   convert(DataArray{UTF8String }, full["country"]),
			           	   convert(DataArray{UTF8String }, full["region"]),
			           	   convert(DataArray{UTF8String }, full["city"]),
			           	   convert(DataArray{UTF8String }, full["postalCode"]),
			           	   convert(DataArray{Float64}, full["latitude"]),
			           	   convert(DataArray{Float64}, full["longitude"]),
			           	   convert(DataArray{Int64}, full["metroCode"]),
			           	   convert(DataArray{Int64}, full["areaCode"])
			           		)
	end

	# Cache IP address city lookup table in memory
	const LOOKUPCITY = loaddatacity(Pkg.dir("GeoIP", "data", "GeoLiteCity-Blocks.csv"), 
									Pkg.dir("GeoIP", "data", "GeoLiteCity-Location.csv")
									)

	# Find the first row in the data set whose end range is larger than IP address
	# Get Region value
	function getregionname(ip::Integer)
		bounds = searchsorted(LOOKUPCITY.ends, ip)
		return LOOKUPCITY.region[bounds.start]
	end
	getregionname(ip::String) = getregionname(numericize(ip))

	# Find the first row in the data set whose end range is larger than IP address
	# Get City value
	function getcityname(ip::Integer)
		bounds = searchsorted(LOOKUPCITY.ends, ip)
		return LOOKUPCITY.city[bounds.start]
	end
	getcityname(ip::String) = getcityname(numericize(ip))

	# Find the first row in the data set whose end range is larger than IP address
	# Get PostalCode value
	function getpostalcode(ip::Integer)
		bounds = searchsorted(LOOKUPCITY.ends, ip)
		return LOOKUPCITY.postalcode[bounds.start]
	end
	getpostalcode(ip::String) = getpostalcode(numericize(ip))

	# Find the first row in the data set whose end range is larger than IP address
	# Get Longitude value
	function getlongitude(ip::Integer)
		bounds = searchsorted(LOOKUPCITY.ends, ip)
		return LOOKUPCITY.longitude[bounds.start]
	end
	getlongitude(ip::String) = getlongitude(numericize(ip))

	# Find the first row in the data set whose end range is larger than IP address
	# Get Latitude value
	function getlatitude(ip::Integer)
		bounds = searchsorted(LOOKUPCITY.ends, ip)
		return LOOKUPCITY.latitude[bounds.start]
	end
	getlatitude(ip::String) = getlatitude(numericize(ip))

	# Find the first row in the data set whose end range is larger than IP address
	# Get Metro Code value
	function getmetrocode(ip::Integer)
		bounds = searchsorted(LOOKUPCITY.ends, ip)
		return LOOKUPCITY.metrocode[bounds.start]
	end
	getmetrocode(ip::String) = getmetrocode(numericize(ip))

	# Find the first row in the data set whose end range is larger than IP address
	# Get Area Code value
	function getareacode(ip::Integer)
		bounds = searchsorted(LOOKUPCITY.ends, ip)
		return LOOKUPCITY.areacode[bounds.start]
	end
	getareacode(ip::String) = getareacode(numericize(ip))

	#Vectorize functions
	Base.@vectorize_1arg Union(Integer, String) getregionname
	Base.@vectorize_1arg Union(Integer, String) getcityname
	Base.@vectorize_1arg Union(Integer, String) getpostalcode
	Base.@vectorize_1arg Union(Integer, String) getlongitude
	Base.@vectorize_1arg Union(Integer, String) getlatitude
	Base.@vectorize_1arg Union(Integer, String) getmetrocode
	Base.@vectorize_1arg Union(Integer, String) getareacode


end
