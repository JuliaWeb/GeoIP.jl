import HTTP
import MD5


ROOT = "http://geolite.maxmind.com/download/geoip/database"
DBURL = "$ROOT/GeoLite2-City.tar.gz"
MD5URL = "$DBURL.md5"
DBFILE = "geolite2-city.tar.gz"


function download_and_verify()
    HTTP.download(DBURL, DBFILE)
    @assert remotemd5() == localmd5()
end


function remotemd5()
    resp = HTTP.get(MD5URL)
    transcode(String, resp.body)
end


function localmd5()
    try
        bytes2hex(open(MD5.md5, DBFILE))
    catch SytemError
        # Return md5 of an empty file
        bytes2hex(MD5.md5("")) 
    end
end


function unpack()
    untar = if Sys.iswindows()
        # If windows, use the 7z that ships with julia to unpack
        # the tarball
        _7z = joinpath(Sys.BINDIR, "7z.exe")
        (source, output) -> pipeline(`$_7z x $(source) -so`, `$_7z x -aoa -si -ttar -o$(output)`)
    else
        # Assume tar exists in the path otherwise
        (source, output) -> `tar xzf $source --directory=$output`
    end
    mkdir("output")
    run(untar(DBFILE, "output"))
end


function movefile()
    dir = readdir("output")[1]
    mv(joinpath("output", dir, "GeoLite2-City.mmdb"), "GeoLite2-City.mmdb")
    rm("output", force=true, recursive=true)
end


## Main script
if localmd5() != remotemd5()
    download_and_verify()
    unpack()
    movefile()
end