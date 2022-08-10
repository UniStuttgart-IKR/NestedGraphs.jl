# Introduction

*A package to handle nested graphs.*

`NestedGraphs.jl` is a young project that aims at easy and type-stable graph analysis for nested graphs.
This package is in an early development stage and might break often.
For a walkthrough of the features, see the [Usage and Examples](@ref) page.

# Concept

The main concept is to hold all nested graphs in a `Vector` and synchronize them with a flat graph.
This means that for each `AbstractGraph` double the space is allocated.
The stored flat graph can be used to call all available functions from the [`Graphs.jl`](https://github.com/JuliaGraphs/Graphs.jl) ecosystem.


# Roadmap
- more support for interfaces of [`Graphs.jl`](https://github.com/JuliaGraphs/Graphs.jl) and [`MetaGraphs`](https://github.com/JuliaGraphs/MetaGraphs.jl) *(WIP)*
- [`Makie`](https://makie.juliaplots.org/stable/) recipes based on [`GraphMakie.jl`](https://github.com/JuliaPlots/GraphMakie.jl) *(WIP)*
- reading/writing `NestedGraph`s with [`GraphIO.jl`](https://github.com/JuliaGraphs/GraphIO.jl) *(WIP)*
- support for [`MetaGraphsNext.jl`](https://github.com/JuliaGraphs/MetaGraphsNext.jl)
- syntactic sugar

# Contribution
Contributors are welcome.
For any ideas or bug reports, feel free to open an issue.
    
# Acknowledgment 
`NestedGraphs.jl` has been created for the analysis of multi-domain networks.\
Part of this work has been performed in the framework of the CELTIC-NEXT EUREKA project AI-NET-ANTILLAS (Project ID C2019/3-3), and it is partly funded by the German BMBF (Project ID 16KIS1312).