using Revise
using Graphs, MetaGraphs, NestedGraphs

using Test

g1 = complete_graph(3) |> MetaDiGraph
g2 = complete_graph(3) |> MetaDiGraph
g3 = complete_graph(3) |> MetaDiGraph

[set_prop!(g1, e, :el, i*0.1) for (i,e) in enumerate(edges(g1))]
[set_prop!(g2, e, :el, i*0.01) for (i,e) in enumerate(edges(g2))]
[set_prop!(g3, e, :el, i*0.001) for (i,e) in enumerate(edges(g3))]

[set_prop!(g1, v, :sz, v*10) for v in vertices(g1)]
[set_prop!(g2, v, :sz, v*100) for v in vertices(g2)]
[set_prop!(g3, v, :sz, v*1000) for v in vertices(g3)]

ng = NestedGraph([g1,g2,g3], [((1,1), (2,1)), ((3,2), (2,1)), ((3,3),(2,3))], both_ways=true)
# f,_,_ = draw_network(ng.flatgr, nlabels = repr.(vertices(ng.flatgr)))
# f

cg1 = NestedGraph([g1,g2], [((1,1), (2,1))])
cg2 = NestedGraph([g1,g3], [((1,2), (2,2)), ((1,3), (2,3))])
cgm = NestedGraph([cg1, cg2], [((1,1),(2,1)), ((1,5),(2,2))], both_ways=true)

add_vertex!(cgm; domain=1)
nv(cg1.grv[1])

# add new elements

# Further tests
# simple initialization

 sg1 = complete_graph(3)
 sg2 = complete_graph(3)
 sg3 = complete_graph(3)
 csg = NestedGraph([sg1,sg2,sg3], [((1,1), (2,1)), ((3,2), (2,1)), ((3,3),(2,3))], both_ways=true)
 csg1 = NestedGraph([sg1,sg2], [((1,1), (2,1))])
 csg2 = NestedGraph([sg1,sg3], [((1,2), (2,2)), ((1,3), (2,3))])
 csgm = NestedGraph([csg1, csg2], [((1,1),(2,1)), ((1,5),(2,2))], both_ways=true)
 
 @assert nv(sg1) == nv(csg.grv[1]) == nv(csg1.grv[1]) == nv(csgm.grv[1].grv[1])
 
 @assert ne(sg1) == ne(csg.grv[1]) == ne(csg1.grv[1]) == ne(csgm.grv[1].grv[1])