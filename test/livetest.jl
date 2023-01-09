DynNG = NestedGraph{Int, SimpleGraph{Int}, AbstractGraph}
ngdyn = DynNG()
add_vertex!(ngdyn, SimpleGraph(3))
@assert nv(ngdyn.grv[1]) == 3

add_vertex!(ngdyn, SimpleGraph(6))
@assert nv(ngdyn.grv[1]) == 3 && nv(ngdyn.grv[2]) == 6

add_vertex!(ngdyn)
@assert nv(ngdyn.grv[1]) == 4 && nv(ngdyn.grv[2]) == 6

add_vertex!(ngdyn, subgraphs = 2)
@assert nv(ngdyn.grv[1]) == 4 && nv(ngdyn.grv[2]) == 7

ngin = add_vertex!(ngdyn, DynNG())
add_vertex!(ngdyn, subgraphs = ngin)
@assert nv(ngdyn.grv[1]) == 4 && nv(ngdyn.grv[2]) == 7 && nv(ngdyn.grv[3]) == 1

add_vertex!(ngdyn, SimpleGraph(2), subgraphs = ngin)
@assert nv(ngdyn.grv[1]) == 4 && nv(ngdyn.grv[2]) == 7 && nv(ngdyn.grv[3]) == 3

add_vertex!(ngdyn, DynNG(), subgraphs = ngin)
@assert nv(ngdyn.grv[1]) == 4 && nv(ngdyn.grv[2]) == 7 && nv(ngdyn.grv[3]) == 3

add_vertex!(ngdyn, subgraphs=[3,2])
@assert nv(ngdyn.grv[1]) == 4 && nv(ngdyn.grv[2]) == 7 && nv(ngdyn.grv[3]) == 4

add_vertex!(ngdyn, SimpleGraph(2), subgraphs=[3,3])
@assert nv(ngdyn.grv[1]) == 4 && nv(ngdyn.grv[2]) == 7 && nv(ngdyn.grv[3]) == 6

@assert nv(ngdyn.grv[3].grv[1]) == 1 && nv(ngdyn.grv[3].grv[2]) == 3 && nv(ngdyn.grv[3].grv[3]) == 2
@assert nv(ngdyn) == nv(ngdyn.grv[1]) + nv(ngdyn.grv[2]) + nv(ngdyn.grv[3])
