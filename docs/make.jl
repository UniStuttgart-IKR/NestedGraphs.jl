using Documenter, NestedGraphs

using Graphs, MetaGraphs

makedocs(sitename="NestedGraphs.jl",
    pages = [
        "Introduction" => "index.md",
        "Usage and Examples" => "usage.md",
        "API" => "API.md"
    ])
