##
# Functions to support multilayer functionality
##

"""
$(TYPEDSIGNATURES) 

Get all multilayer vertices.
Each multilayer vertex is composed by vertices of the graph that are connected and in different layers.
In other words, return all nodes of `ng` that are connected through the interlinks, i.e., the NestedEdges,
i.e., the edges connecting different layers, i.e., the edges connecting different subgraphs.
Malfunctions if more nodes across layers are connected with several non-vertical ways.
"""
function getmlvertices(ng::NestedGraph; subgraph_view=false)
    flatneds = [Edge(vertex(ng, src(ned)), vertex(ng, dst(ned))) for ned in ng.neds]
    indsub, vm = induced_subgraph(ng.flatgr, flatneds)
    lonelynodes = filter(v -> v ∉ vm, vertices(ng))
    wcc = map(weakly_connected_components(indsub)) do convec
        map(convec) do v
            if subgraph_view
                ng.vmap[vm[v]]
            else
                vm[v]
            end
        end
    end
    if subgraph_view
        nestedlonelynodes = ng.vmap[lonelynodes]
        push!(wcc, [[ln] for ln in nestedlonelynodes]...)
    else
        push!(wcc, [[ln] for ln in lonelynodes]...)
    end
end

"""
$(TYPEDSIGNATURES) 

Get a squashed multilayer graph.
All multilayer vertices are squashed down to a single vertex.
All edges in all layers are merged.
"""
function getmlsquashedgraph(ng::NestedGraph)
    mlvertices = getmlvertices(ng; subgraph_view=false)
    getsquashedgraph(ng, mlvertices)
end


"""
$(TYPEDSIGNATURES) 

`sqvertices` are the nodes to be merged/squashed together to the `flatgr` of `ng`.
Return also a mapping of the `ng` vertices to the new vertices of the graph.
Essentially it recursively calls `Graphs.merge_vertices`.
"""
function getsquashedgraph(ng::NestedGraph{T,R,N}, sqvertices::Vector{Vector{Q}}) where {T,R,N,Q<:Integer}
    squashedgraph = deepcopy(ng.flatgr)
    _rec_merge_vertices!(squashedgraph, sqvertices)
end

function _rec_merge_vertices!(squashedgraph, sqvertices)
    vm = collect(vertices(squashedgraph))
    for i in eachindex(sqvertices)
        sqverticestranslated = map(v->vm[v], sqvertices[i])
        vm2 = merge_vertices!(squashedgraph, sqverticestranslated)
        vm = vm2[vm]
    end
    return squashedgraph, vm
end

# merge_vertices is not implemented ofr MetaGraphs
function getsquashedgraph(ng::NestedGraph{T,R,N}, sqvertices::Vector{Vector{Q}}) where {T,R<:AbstractMetaGraph,N,Q<:Integer}
#    squashedgraph = ng.flatgr |> deepcopy |> adjacency_matrix |> SimpleGraph
    squashedgraph = getsimplegraphcopy(ng)
    _rec_merge_vertices!(SimpleGraph(squashedgraph), sqvertices)
end
function getsquashedgraph(ng::NestedGraph{T,R,N}, sqvertices::Vector{Vector{Q}}) where {T,R<:AbstractAttibuteGraph,N,Q<:Integer}
#    squashedgraph = ng.flatgr |> deepcopy |> adjacency_matrix |> SimpleGraph
    squashedgraph = getsimplegraphcopy(ng)
    _rec_merge_vertices!(SimpleGraph(squashedgraph), sqvertices)
end

@traitfn function getsimplegraphcopy(ng::NestedGraph::IsDirected)
    squashedgraph = ng.flatgr |> deepcopy |> adjacency_matrix |> SimpleDiGraph
end

@traitfn function getsimplegraphcopy(ng::NestedGraph::!(IsDirected))
    squashedgraph = ng.flatgr |> deepcopy |> adjacency_matrix |> SimpleGraph
end
