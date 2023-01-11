@testset "metaadd.jl" begin
    DynMNG = NestedGraph{Int, MetaGraph{Int,Float64}, AbstractGraph}
    ngdyn = DynMNG(extrasubgraph=false)    

    sg1 = MetaGraph(3)
    [set_prop!(sg1, v, :vel, "1.$(v)") for v in vertices(sg1)]
    add_vertex!(ngdyn, sg1)
    @test nv(ngdyn.grv[1]) == 3

    add_vertex!(ngdyn, MetaGraph(6))
    # ngdyn.grv[2] and ngdyn.flatgr `Dict` are shallow copies
    [set_prop!(ngdyn.grv[2], v, :vel, "2.$(v)") for v in 1:6]
    @test nv(ngdyn.grv[1]) == 3 && nv(ngdyn.grv[2]) == 6

    # flatnode 10 enters in vmap (1,4)
    add_vertex!(ngdyn, :vel, "1.4")
    @test nv(ngdyn.grv[1]) == 4 && nv(ngdyn.grv[2]) == 6

    add_vertex!(ngdyn, :vel, "2.7"; subgraphs = 2)
    @test nv(ngdyn.grv[1]) == 4 && nv(ngdyn.grv[2]) == 7

    add_vertex!(ngdyn, DynMNG(extrasubgraph=false))
    add_vertex!(ngdyn, :vel, "3.1.1"; subgraphs = 3)
    @test nv(ngdyn.grv[1]) == 4 && nv(ngdyn.grv[2]) == 7 && nv(ngdyn.grv[3]) == 1

    sg2 = MetaGraph(2)
    [set_prop!(sg2, v, :vel, "3.1.$(v)") for v in vertices(sg2)]
    add_vertex!(ngdyn, sg2, subgraphs = 3)
    @test nv(ngdyn.grv[1]) == 4 && nv(ngdyn.grv[2]) == 7 && nv(ngdyn.grv[3]) == 3

    add_vertex!(ngdyn, DynMNG(extrasubgraph=false), subgraphs = 3)
    @test nv(ngdyn.grv[1]) == 4 && nv(ngdyn.grv[2]) == 7 && nv(ngdyn.grv[3]) == 3

    # flatnode 15 enters in subgraph (3,4) 
    add_vertex!(ngdyn, :vel, "3.3.1",subgraphs=[3,2])
    @test nv(ngdyn.grv[1]) == 4 && nv(ngdyn.grv[2]) == 7 && nv(ngdyn.grv[3]) == 4

    sg3 = MetaGraph(2)
    [set_prop!(sg3, v, :vel, "3.3.2.$(v)") for v in vertices(sg3)]
    add_vertex!(ngdyn, sg3, subgraphs=[3,3])
    @test nv(ngdyn.grv[1]) == 4 && nv(ngdyn.grv[2]) == 7 && nv(ngdyn.grv[3]) == 6

    @test nv(ngdyn.grv[3].grv[1]) == 1 && nv(ngdyn.grv[3].grv[2]) == 3 && nv(ngdyn.grv[3].grv[3]) == 2
    @test nv(ngdyn) == nv(ngdyn.grv[1]) + nv(ngdyn.grv[2]) + nv(ngdyn.grv[3])
    
    @test add_edge!(ngdyn, 10, 15)
    @test NestedEdge(ngdyn.vmap[10], ngdyn.vmap[15]) == NestedEdge((1,4), (3,4)) == first(ngdyn.neds) && length(ngdyn.neds) == 1
 
    @test add_edge!(ngdyn, 16, 17)
    @test ne(ngdyn.grv[3]) == ne(ngdyn.grv[3]) == ne(ngdyn.grv[3].grv[3]) == ne(ngdyn.grv[3].grv[3].grv[1]) == 1 == ne(ngdyn) - 1
    
    testprops_recu(ngdyn)
    # modify
    for v in vertices(ngdyn)
        prevprop = get_prop(ngdyn, v, :vel)
        set_prop!(ngdyn, v, :vel, prevprop*"_mod")
    end
    testprops_recu(ngdyn)
    
    # inverse (copied code from simpleadd.jl)

    # inverse - start deleting
    rem_edge!(ngdyn, 16, 17)
    @test ne(ngdyn.grv[3]) == ne(ngdyn.grv[3]) == ne(ngdyn.grv[3].grv[3]) == ne(ngdyn.grv[3].grv[3].grv[1]) == 0 == ne(ngdyn) - 1
    
    rem_edge!(ngdyn, 10, 15)
    @test length(ngdyn.neds) == ne(ngdyn) == 0
    
    #TODO substitute with delete graph
    [rem_vertex!(ngdyn, roll_vertex(ngdyn, [3,3,1])) for i in 1:2]
    @test nv(ngdyn.grv[1]) == 4 && nv(ngdyn.grv[2]) == 7 && nv(ngdyn.grv[3]) == 4

    rem_vertex!(ngdyn, roll_vertex(ngdyn, [3,2,3]))
    @test nv(ngdyn.grv[1]) == 4 && nv(ngdyn.grv[2]) == 7 && nv(ngdyn.grv[3]) == 3

    [rem_vertex!(ngdyn, roll_vertex(ngdyn, [3, 2, 1])) for i in 1:2]
    @test nv(ngdyn.grv[1]) == 4 && nv(ngdyn.grv[2]) == 7 && nv(ngdyn.grv[3]) == 1

    rem_vertex!(ngdyn, roll_vertex(ngdyn, [3,1,1]))
    @test nv(ngdyn.grv[1]) == 4 && nv(ngdyn.grv[2]) == 7 && nv(ngdyn.grv[3]) == 0

    rem_vertex!(ngdyn, roll_vertex(ngdyn, [2,7]))
    @test nv(ngdyn.grv[1]) == 4 && nv(ngdyn.grv[2]) == 6
    
    #... tedious. There needs to be a system.

    @test nv(ngdyn) == nv(ngdyn.grv[1]) + nv(ngdyn.grv[2]) + nv(ngdyn.grv[3])

    # extra subgraph
    ngdyn2 = DynMNG(;extrasubgraph=true)    
    @test length(ngdyn2.grv) == 1
end
