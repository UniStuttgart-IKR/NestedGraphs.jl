using Graphs, MetaGraphs, NestedGraphs, AttributeGraphs
using Test
using TestSetExtensions

include("testutils.jl")

@testset "NestedGraphs.jl" begin
    @includetests ["simple", "simpleadd", "metagraphs", "metaadd", "addremgraphsimple", "multilayer", "attributegraphs"]
end
