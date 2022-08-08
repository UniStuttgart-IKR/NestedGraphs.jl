using Graphs, MetaGraphs, NestedGraphs
using Test
using TestSetExtensions

include("testutils.jl")

@testset "NestedGraphs.jl" begin
    @includetests ["simple", "simpleadd", "metagraphs"]
end
