@testset "simpleadd.jl" begin
    DynNG = NestedGraph{Int, SimpleGraph{Int}, AbstractGraph}
    ngdyn = DynNG()    
    add_vertex!(ngdyn, SimpleGraph(3))
    @test nv(ngdyn.grv[1]) == 3

    add_vertex!(ngdyn, SimpleGraph(6))
    @test nv(ngdyn.grv[1]) == 3 && nv(ngdyn.grv[2]) == 6

    # flatnode 10 enters in vmap (1,4)
    add_vertex!(ngdyn)
    @test nv(ngdyn.grv[1]) == 4 && nv(ngdyn.grv[2]) == 6

    add_vertex!(ngdyn, domains = 2)
    @test nv(ngdyn.grv[1]) == 4 && nv(ngdyn.grv[2]) == 7

    add_vertex!(ngdyn, DynNG())
    add_vertex!(ngdyn, domains = 3)
    @test nv(ngdyn.grv[1]) == 4 && nv(ngdyn.grv[2]) == 7 && nv(ngdyn.grv[3]) == 1

    add_vertex!(ngdyn, SimpleGraph(2), domains = 3)
    @test nv(ngdyn.grv[1]) == 4 && nv(ngdyn.grv[2]) == 7 && nv(ngdyn.grv[3]) == 3

    add_vertex!(ngdyn, DynNG(), domains = 3)
    @test nv(ngdyn.grv[1]) == 4 && nv(ngdyn.grv[2]) == 7 && nv(ngdyn.grv[3]) == 3

    # flatnode 15 enters in domain (3,4) 
    add_vertex!(ngdyn, domains=[3,2])
    v15 = nv(NestedGraphs.innergraph(ngdyn, [3,2]))
    @test nv(ngdyn.grv[1]) == 4 && nv(ngdyn.grv[2]) == 7 && nv(ngdyn.grv[3]) == 4

    add_vertex!(ngdyn, SimpleGraph(2), domains=[3,3])
    @test nv(ngdyn.grv[1]) == 4 && nv(ngdyn.grv[2]) == 7 && nv(ngdyn.grv[3]) == 6

    @test nv(ngdyn.grv[3].grv[1]) == 1 && nv(ngdyn.grv[3].grv[2]) == 3 && nv(ngdyn.grv[3].grv[3]) == 2
    @test nv(ngdyn) == nv(ngdyn.grv[1]) + nv(ngdyn.grv[2]) + nv(ngdyn.grv[3])
    
    @test add_edge!(ngdyn, 10, 15)
    @test NestedEdge(ngdyn.vmap[10], ngdyn.vmap[15]) == NestedEdge((1,4), (3,4)) == first(ngdyn.neds) && length(ngdyn.neds) == 1
 
    @test add_edge!(ngdyn, 16, 17)
    @test ne(ngdyn.grv[3]) == ne(ngdyn.grv[3]) == ne(ngdyn.grv[3].grv[3]) == ne(ngdyn.grv[3].grv[3].grv[1]) == 1 == ne(ngdyn) - 1
    
    # inverse - start deleting
    rem_edge!(ngdyn, 16, 17)
    @test ne(ngdyn.grv[3]) == ne(ngdyn.grv[3]) == ne(ngdyn.grv[3].grv[3]) == ne(ngdyn.grv[3].grv[3].grv[1]) == 0 == ne(ngdyn) - 1
    
    rem_edge!(ngdyn, 10, 15)
    @test length(ngdyn.neds) == ne(ngdyn) == 0
    
    #TODO substitute with delete graph
    [rem_vertex!(ngdyn, roll_vertex(ngdyn, [3,3,1])) for i in 1:2]
    @test nv(ngdyn.grv[1]) == 4 && nv(ngdyn.grv[2]) == 7 && nv(ngdyn.grv[3]) == 4

    rem_vertex!(ngdyn, roll_vertex(ngdyn, [3,2,v15]))
    @test nv(ngdyn.grv[1]) == 4 && nv(ngdyn.grv[2]) == 7 && nv(ngdyn.grv[3]) == 3

    [rem_vertex!(ngdyn, roll_vertex(ngdyn, [3, 2, 1])) for i in 1:2]
    @test nv(ngdyn.grv[1]) == 4 && nv(ngdyn.grv[2]) == 7 && nv(ngdyn.grv[3]) == 1

    rem_vertex!(ngdyn, roll_vertex(ngdyn, [3,1,1]))
    @test nv(ngdyn.grv[1]) == 4 && nv(ngdyn.grv[2]) == 7 && nv(ngdyn.grv[3]) == 0

    rem_vertex!(ngdyn, roll_vertex(ngdyn, [2,7]))
    @test nv(ngdyn.grv[1]) == 4 && nv(ngdyn.grv[2]) == 6

    #... tedious. There needs to be a system.

    @test nv(ngdyn) == nv(ngdyn.grv[1]) + nv(ngdyn.grv[2]) + nv(ngdyn.grv[3])
end