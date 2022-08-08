# Introduction
`NestedGraphs.jl` is a package to help with nested graphs. 
It's philosophy is to be type-stable for optimum performance with several available compromises for easier coding.
The main concept is to hold the nested structure of the graphs in a `Vector` and generate a flat graph that will call all performant functions from the `Graphs.jl` ecosystem.

# Aplication
`NestedGraphs.jl` has been created to be used for the analyis of multi-domain networks.
Due to the general functionality exposed, we believe that `NestedGraphs.jl` will also be useful for other disciplines.

# Project status
This project is WIP and likely to have breaking changes.
Future plans include:
- integration with `MetaGraphsNext.jl`
- more `Makie` recipes

# Contribution
Feel free to open an issue for any ideas, possible extensions, different architectures or implementation suggestions.