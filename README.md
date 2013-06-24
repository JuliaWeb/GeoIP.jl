GeoIP.jl
========

# Introduction

This is a Julia package for determining the approximate location of Internet users based on their IP address. To provide this functionality, this package includes GeoLite data created by MaxMind, available from [http://www.maxmind.com](http://www.maxmind.com) and distributed under the Creative Commons Attribution-ShareAlike 3.0 Unported License. In particular, we use a copy of the [http://dev.maxmind.com/geoip/legacy/geolite/](GeoLite) database that was fetched on February 5th, 2013. If you find that this data has gone out-of-date, please let us know.

# API and Usage Examples

This package provides two functions: `getcountrycode` and `getcountryname`.
`getcountrycode` returns a two-letter code for the country in which an IP address is located, whereas `getcountryname` returns the full name of the country in which an IP address is located. These functions operate on IP addresses represented as integers or strings. The functions can also be used on vectors of IP addresses. See the examples below for details.

	using GeoIP

	getcountrycode(18 * 256^3) # => "US"
	getcountryname(18 * 256^3) #=> "United States"

	getcountrycode([18 * 256^3, 18 * 256^3]) #=> ["US", "US"]
	getcountryname([18 * 256^3, 18 * 256^3]) #=> ["United States", "United States"]

	getcountrycode("18.0.0.0") #=> "US"
	getcountryname("18.0.0.0") #=> "United States"

	getcountrycode("18.0.0.0") #=> "US"
	getcountryname("18.0.0.0") #=> "United States"

	getcountrycode(["18.0.0.0"]) #=> ["US"]
	getcountryname(["18.0.0.0"]) #=> ["United States"]

	getcountrycode(["18.0.0.0", "25.0.0.0"]) #=> ["US", "GB"]
	getcountryname(["18.0.0.0", "25.0.0.0"]) #=> ["United States", "United Kingdom"]
