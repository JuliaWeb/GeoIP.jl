using GeoIP
using Documenter

DocMeta.setdocmeta!(GeoIP, :DocTestSetup, :(using GeoIP); recursive=true)

makedocs(;
    modules=[GeoIP],
    authors = ["Andrey Oskin", "Seth Bromberger", "contributors: https://github.com/JuliaWeb/GeoIP.jl/graphs/contributors"],
    repo="https://github.com/JuliaWeb/GeoIP.jl/blob/{commit}{path}#{line}",
    sitename="GeoIP.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaWeb.github.io/GeoIP.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaWeb/GeoIP.jl",
)
