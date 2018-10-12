using Test

import GeoIP

# Load Database
mmdb = GeoIP.MaxMindDB
db = mmdb.DB(joinpath("..", "deps", "GeoLite2-City.mmdb"))
metadata = mmdb.metadata(db)

# Smoke test
@test typeof(metadata) <: Dict{String, Any}
   
# Test that all keys in specification are in the
# metadata
expected = [
    "node_count",
    "record_size",
    "ip_version",
    "database_type",
    "binary_format_major_version",
    "binary_format_minor_version",
    "build_epoch",
    "description"
]
for key in expected
    @test key in keys(metadata)
end

@test mmdb.nodecount(db) == metadata["node_count"]
@test mmdb.recordsize(db) == metadata["record_size"]
@test mmdb.treesize(db) == (mmdb.recordsize(db) >> 2) * mmdb.nodecount(db)
