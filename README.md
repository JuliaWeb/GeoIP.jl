GeoIP.jl
========

# Introduction

This is a Julia package for determining the approximate location of Internet
users based on their IP address. To provide this functionality, this package
includes GeoLite data created by MaxMind, available from
[http://www.maxmind.com](http://www.maxmind.com) and distributed under the
Creative Commons Attribution-ShareAlike 3.0 Unported License. In particular, we
use copies of the following
[MaxMind files](http://dev.maxmind.com/geoip/legacy/geolite/):

* Country Database fetched on February 5th, 2013
* City Database fetched on October 25, 2013

If you find that any of these databases have gone out-of-date, please let us
know.

# API and Usage Examples

This package provides functions that operate on IP addresses represented as
integers or strings. The functions can also be used on vectors of IP addresses.
See the examples below for details.

```
using GeoIP

getcountrycode(301989888) # => "US"
getcountryname(301989888) # => "United States"

getcountrycode([301989888, 301989888]) # => ["US", "US"]
getcountryname([301989888, 301989888]) # => ["United States", "United States"]

getcountrycode("18.0.0.0") # => "US"
getcountryname("18.0.0.0") # => "United States"

getcountrycode("18.0.0.0") # => "US"
getcountryname("18.0.0.0") # => "United States"

getcountrycode(["18.0.0.0"]) # => ["US"]
getcountryname(["18.0.0.0"]) # => ["United States"]

getcountrycode(["18.0.0.0", "25.0.0.0"]) # => ["US", "GB"]
getcountryname(["18.0.0.0", "25.0.0.0"]) # => ["United States", "United Kingdom"]

getregionname(1135531255) # => "KS"
getregionname([1135531255,1135531255]) # => ["KS", "KS"]

getcityname(1135531255) # => "Overland Park"
getcityname([1135531255,1135531255]) # => ["Overland Park", "Overland Park"]

getpostalcode(1135531255) # => "66212"
getpostalcode([1135531255,1135531255]) # => ["66212", "66212"]

getlongitude(1135531255) # => -94.6811
getlongitude([1135531255,1135531255]) # => [-94.6811, -94.6811]

getlatitude(1135531255) # => 38.9593
getlatitude([1135531255,1135531255]) # => [38.9593, 38.9593]

getmetrocode(1135531255) # => 616
getmetrocode([1135531255,1135531255]) # => [616, 616]

getareacode(1135531255) # => 913
getareacode([1135531255,1135531255]) # => [913, 913]
```
