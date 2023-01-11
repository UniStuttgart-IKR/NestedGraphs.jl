##
# This file is meant to start up a live-test the package
##

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
