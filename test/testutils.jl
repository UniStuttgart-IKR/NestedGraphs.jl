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
          if !(e in intersubgraphedges(nmg))
               ne = nestededge(nmg, e)
               @test ne.src[1] == ne.dst[1]
               @test props(nmg, e.src, e.dst) === props(nmg.grv[ne.src[1]], ne.src[2], ne.dst[2])
          end
     end
     for gr in nmg.grv
          gr isa NestedGraph && testprops_recu(gr)
     end
end
