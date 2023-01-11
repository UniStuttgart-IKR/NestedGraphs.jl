@testset "addremgraphsimple.jl" begin
    # test deleting nodes 
    ngt = test_simple_top()
    @test length(ngt.neds) == 2
    rem_vertex!(ngt, 1)
    @test length(ngt.neds) == 1

    # test deleting graphs
    ngt = test_simple_top()
    rem_vertex!(ngt, [1])
    @test length(Set(getindex.(ngt.vmap,1))) == 2
    @test length((ngt.grv)) == 2

    ngt = test_simple_top()
    rem_vertex!(ngt, [3,2])
    @test length(Set(getindex.(ngt.grv[3].vmap,1))) == 2
    @test length((ngt.grv[3].grv)) == 2

    ngt = test_simple_top()
    rem_vertex!(ngt, [3,3])
    @test length(Set(getindex.(ngt.grv[3].vmap,1))) == 2
    @test length((ngt.grv[3].grv)) == 2

    ngt = test_simple_top()
    rem_vertex!(ngt, [3,3,1])
    @test length(Set(getindex.(ngt.grv[3].vmap,1))) == 2
    @test length((ngt.grv[3].grv)) == 3
    @test length(ngt.grv[3].grv[3].grv) == nv(ngt.grv[3].grv[3]) == ne(ngt.grv[3].grv[3]) == 0

    # test deleting nodes 
    ngt = test_simple_top()
    while nv(ngt) > 0
        rem_vertex!(ngt, unroll_vertex(ngt, nv(ngt)))
    end
    @test nv(ngt) == 0
end
