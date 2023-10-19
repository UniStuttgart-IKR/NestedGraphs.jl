function basic_test(g1, g2, g3, g4, ng, ng1, ng2, ngm)
     @test nv(ng) == nv(g1) + nv(g2) + nv(g3) + nv(g4)
     @test nv(g1) == nv(ng.grv[1]) == nv(ng1.grv[1]) == nv(ngm.grv[1].grv[1])
     @test ne(g1) == ne(ng.grv[1]) == ne(ng1.grv[1]) == ne(ngm.grv[1].grv[1])
     
     @test nv(g3) == nv(ng.grv[3]) == nv(ng2.grv[1]) == nv(ngm.grv[2].grv[1])
     @test ne(g3) == ne(ng.grv[3]) == ne(ng2.grv[1]) == ne(ngm.grv[2].grv[1])
     numnodes_sg1 = nv(g1)
     numnodes_sg2 = nv(g2)
     numnodes_sg3 = nv(g3)

     # ---------- start modifying the `NestedGraph` ---------
     # ----- add_vertex! -----
     # add to csgm.grv[1].grv[1] aka sg1
     
     add_vertex!(ngm)
     @test nv(g1) == nv(ng.grv[1]) == nv(ng1.grv[1]) == nv(ngm.grv[1].grv[1]) == (numnodes_sg1+1)

     numnodes_sg1 = nv(g1)

     # add to csgm.grv[2].grv[1] aka sg3
     add_vertex!(ngm; subgraphs=2)
     @test nv(g3) == nv(ng.grv[3]) == nv(ng2.grv[1]) == nv(ngm.grv[2].grv[1]) == (numnodes_sg3+1)

     # add to csgm.grv[1].grv[2] aka sg2
     add_vertex!(ngm; subgraphs=[1,2])
     @test nv(g2) == nv(ng.grv[2]) == nv(ng1.grv[2]) == nv(ngm.grv[1].grv[2]) == (numnodes_sg2+1)
     @test nv(ng1) == nv(g1) + nv(g2)

     # csg will not be notified of the updates
     @test nv(ng) != nv(g1) + nv(g2) + nv(g3) + nv(g4)

     # ----- add_edge! -----
     numedges_csg1 = ne(ng1)
     numedges_csgm = ne(ngm)
     add_edge!(ngm, NestedEdge(1,1,1,5))
     @test ne(ngm) == (numedges_csgm + 1)
     @test ne(ng1) == (numedges_csg1 + 1)
     
     # TODO test add_edges! add_vertices!
end

function testprops_recu(nmg)
     for (n, (d, v)) in enumerate(nmg.vmap)
          @test props(nmg, n) === props(nmg.grv[d], v)
     end
     for e in edges(nmg)
          if !(e in getnestededges(nmg))
               ne = nestededge(nmg, e)
               @test ne.src[1] == ne.dst[1]
               @test props(nmg, e.src, e.dst) === props(nmg.grv[ne.src[1]], ne.src[2], ne.dst[2])
          end
     end
     for gr in nmg.grv
          gr isa NestedGraph && testprops_recu(gr)
     end
end

function test_simple_top()
    DynNG = NestedGraph{Int, SimpleGraph{Int}, AbstractGraph}
    ngdyn = DynNG()
    add_vertex!(ngdyn, SimpleGraph(3))
    add_vertex!(ngdyn, SimpleGraph(6))
    add_vertex!(ngdyn)
    add_vertex!(ngdyn, subgraphs = 2)
    add_vertex!(ngdyn, DynNG())
    ngin = length(ngdyn.grv)
    add_vertex!(ngdyn, subgraphs = ngin)
    add_vertex!(ngdyn, SimpleGraph(2), subgraphs = ngin)
    add_vertex!(ngdyn, DynNG(), subgraphs = ngin)
    add_vertex!(ngdyn, subgraphs=[3,2])
    add_vertex!(ngdyn, SimpleGraph(2), subgraphs=[3,3])
    add_edge!(ngdyn, 1,8)
    add_edge!(ngdyn, 2,9)
    return ngdyn
end

function test_meta_top()
    DynMNG = NestedGraph{Int, MetaGraph{Int,Float64}, AbstractGraph}
    ngdyn = DynMNG(extrasubgraph=false)    
    sg1 = MetaGraph(3)
    [set_prop!(sg1, v, :vel, "1.$(v)") for v in vertices(sg1)]
    add_vertex!(ngdyn, sg1)
    add_vertex!(ngdyn, MetaGraph(6))
    # ngdyn.grv[2] and ngdyn.flatgr `Dict` are shallow copies
    [set_prop!(ngdyn.grv[2], v, :vel, "2.$(v)") for v in 1:6]
    # flatnode 10 enters in vmap (1,4)
    add_vertex!(ngdyn, :vel, "1.4")
    add_vertex!(ngdyn, :vel, "2.7"; subgraphs = 2)
    add_vertex!(ngdyn, DynMNG(extrasubgraph=false))
    add_vertex!(ngdyn, :vel, "3.1.1"; subgraphs = 3)
    sg2 = MetaGraph(2)
    [set_prop!(sg2, v, :vel, "3.1.$(v)") for v in vertices(sg2)]
    add_vertex!(ngdyn, sg2, subgraphs = 3)
    add_vertex!(ngdyn, DynMNG(extrasubgraph=false), subgraphs = 3)
    # flatnode 15 enters in subgraph (3,4) 
    add_vertex!(ngdyn, :vel, "3.3.1",subgraphs=[3,2])
    sg3 = MetaGraph(2)
    [set_prop!(sg3, v, :vel, "3.3.2.$(v)") for v in vertices(sg3)]
    add_vertex!(ngdyn, sg3, subgraphs=[3,3])
    return ngdyn
end
