using Revise
using Graphs, MetaGraphs, CompositeGraphs
using GraphMakieUtils
using GLMakie

g1 = complete_graph(3) |> MetaDiGraph
g2 = complete_graph(3) |> MetaDiGraph
g3 = complete_graph(3) |> MetaDiGraph

[set_prop!(g1, e, :el, i*0.1) for (i,e) in enumerate(edges(g1))]
[set_prop!(g2, e, :el, i*0.01) for (i,e) in enumerate(edges(g2))]
[set_prop!(g3, e, :el, i*0.001) for (i,e) in enumerate(edges(g3))]

[set_prop!(g1, v, :sz, v*10) for v in vertices(g1)]
[set_prop!(g2, v, :sz, v*100) for v in vertices(g2)]
[set_prop!(g3, v, :sz, v*1000) for v in vertices(g3)]

cg = CompositeGraph([g1,g2,g3], [((1,1), (2,1)), ((3,2), (2,1)), ((3,3),(2,3))], both_ways=true)
f,_,_ = draw_network(cg.flatgr, nlabels = repr.(vertices(cg.flatgr)))
f

cg1 = CompositeGraph([g1,g1], [((1,1), (2,1))])
cg2 = CompositeGraph([g1,g1], [((1,2), (2,2)), ((1,3), (2,3))])
cgm = CompositeGraph([cg1, cg2], [((1,1),(2,1)), ((1,5),(2,2))], both_ways=true)
