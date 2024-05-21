using Graphs, NestedGraphs, AttributeGraphs
import MetaGraphs as MG
import MetaGraphsNext as MGN
using Test, Aqua, JET
using TestSetExtensions

include("testutils.jl")

@testset verbose=true "Code quality (Aqua.jl)" begin
    Aqua.test_all(NestedGraphs)
end

# @testset "Code quality (JET.jl)" begin
#     JET.test_package(NestedGraphs; target_defined_modules=true)
# end


@testset verbose=true "NestedGraphs.jl" begin
    for f in ["simple", "simpleadd", "metagraphs", "metaadd", "addremgraphsimple", "multilayer", "attributegraphs"]
        include(f*".jl")
    end
end

nothing
