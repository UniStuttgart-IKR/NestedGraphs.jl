module NestedGraphsAttributeGraphsExt

using NestedGraphs, Graphs, DocStringExtensions
using AttributeGraphs

import AttributeGraphs: AbstractAttributeGraph, addgraphattr!, remgraphattr!, addvertexattr!, remvertexattr!, addedgeattr!, remedgeattr!, graph_attr, vertex_attr, edge_attr, addvertex!, remvertex!, addedge!, remedge!, hasedgeattr, hasgraphattr, hasvertexattr, getgraphattr, getvertexattr, getedgeattr

getgraphattr(ag::NestedGraph{T,G}, k) where {T<:Integer,G<:AbstractAttributeGraph} = getgraphattr(NestedGraphs.getgraph(ag), k)
getvertexattr(ag::NestedGraph{T,G}, k) where {T<:Integer,G<:AbstractAttributeGraph} = getvertexattr(NestedGraphs.getgraph(ag), k)
getedgeattr(ag::NestedGraph{T,G}, args...) where {T<:Integer,G<:AbstractAttributeGraph} = getedgeattr(NestedGraphs.getgraph(ag), args...)

hasgraphattr(ag::NestedGraph{T,G}, k) where {T<:Integer,G<:AbstractAttributeGraph} = hasgraphattr(NestedGraphs.getgraph(ag), k)
hasvertexattr(ag::NestedGraph{T,G}, k) where {T<:Integer,G<:AbstractAttributeGraph} = hasvertexattr(NestedGraphs.getgraph(ag), k)
hasedgeattr(ag::NestedGraph{T,G}, args...) where {T<:Integer,G<:AbstractAttributeGraph} = hasedgeattr(NestedGraphs.getgraph(ag), args...)


function addvertex!(ng::NestedGraph{T,G}; subgraphs=1, targetnode=nothing) where {T<:Integer, G<:AbstractAttributeGraph}
    subgraph = first(subgraphs)
    length(ng.grv) == 0 && (add_vertex!(ng, G()))
    isnothing(targetnode) && (targetnode = nv(ng.grv[subgraph])+1)
    Graphs.has_vertex(ng, subgraph, targetnode) && return false
    addvertex!(ng.flatgr)
    push!(ng.vmap, (subgraph, targetnode) )
    NestedGraphs._propagate_to_nested(ng, addvertex!, subgraphs)
end

function remvertex!(ng::NestedGraph{T,G}, v::T) where {T<:Integer, G<:AbstractAttributeGraph}
    Graphs.has_vertex(ng, v) || return false
    remvertex!(ng.flatgr, v)
    nver = ng.vmap[v]
    remvertex!(ng.grv[nver[1]], nver[2])
    deleteat!(ng.vmap, v)
    NestedGraphs.update_vmapneds_after_delete!(ng, nver)
end

addedge!(mg::NestedGraph{T,G}, args...) where {T<:Integer, G<:AbstractAttributeGraph} = add_edge!(mg, args...)

function remedge!(ng::NestedGraph{T,G}, src::T, dst::T) where {T<:Integer, G<:AbstractAttributeGraph}
    Graphs.has_edge(ng, src, dst) || return false
    remedge!(ng.flatgr, src, dst)
    srctup = ng.vmap[src]
    dsttup = ng.vmap[dst]
    if srctup[1] != dsttup[1]
        deleteat!(ng.neds, findfirst(==(NestedEdge(srctup, dsttup)), ng.neds))
    else
        remedge!(ng.grv[srctup[1]], srctup[2], dsttup[2])
    end
end

addgraphattr!(ng::NestedGraph{T,G}, k, v) where {T<:Integer, G<:AbstractAttributeGraph} = addgraphattr!(NestedGraphs.getgraph(ng), k, v)
remgraphattr!(ng::NestedGraph{T,G}, k) where {T<:Integer, G<:AbstractAttributeGraph} = remgraphattr!(NestedGraphs.getgraph(ng), k)

function addvertexattr!(ng::NestedGraph{T,G}, k, v) where {T<:Integer, G<:AbstractAttributeGraph}
    addvertexattr!(NestedGraphs.getgraph(ng), k, v)
    addvertexattr!(ng.grv[ng.vmap[k][1]], ng.vmap[k][2], v)
end
function remvertexattr!(ng::NestedGraph{T,G}, k) where {T<:Integer, G<:AbstractAttributeGraph}
    remvertexattr!(NestedGraphs.getgraph(ng), k)
    remvertexattr!(ng.grv[ng.vmap[k][1]], ng.vmap[k][2])
end

remedgeattr!(ng::NestedGraph{T,G}, e::AbstractEdge, args...) where {T<:Integer, G<:AbstractAttributeGraph} = remedgeattr!(ng, src(e), dst(e), args...)
function remedgeattr!(ng::NestedGraph{T,G}, s::T, d::T, args...) where {T<:Integer, G<:AbstractAttributeGraph}
    remedgeattr!(NestedGraphs.getgraph(ng), s, d, args...)
    if NestedGraphs.issamesubgraph(ng, s, d)
        remedgeattr!(ng.grv[ng.vmap[s][1]], ng.vmap[s][2], ng.vmap[d][2], args...)
    end
end

addedgeattr!(ng::NestedGraph{T,G}, e::AbstractEdge, args...) where {T<:Integer, G<:AbstractAttributeGraph} = addedgeattr!(ng, src(e), dst(e), args...)
function addedgeattr!(ng::NestedGraph{T,G}, s::T, d::T, args...) where {T<:Integer, G<:AbstractAttributeGraph}
    addedgeattr!(NestedGraphs.getgraph(ng), s, d, args...)
    if NestedGraphs.issamesubgraph(ng, s, d)
        addedgeattr!(ng.grv[ng.vmap[s][1]], ng.vmap[s][2], ng.vmap[d][2], args...)
    end
end

vertex_attr(mg::NestedGraph{T,G}) where {T<:Integer, G<:AbstractAttributeGraph} = vertex_attr(NestedGraphs.getgraph(mg))
edge_attr(mg::NestedGraph{T,G}) where {T<:Integer, G<:AbstractAttributeGraph} = edge_attr(NestedGraphs.getgraph(mg))
graph_attr(mg::NestedGraph{T,G}) where {T<:Integer, G<:AbstractAttributeGraph} = graph_attr(NestedGraphs.getgraph(mg))

# I need to implement shallow copy
function NestedGraphs.shallowcopy_vertices!(g1::AttributeGraph{T,G,V}, g2::AttributeGraph{T,G,V}) where {T<:Integer,G<:AbstractGraph{T},V<:AbstractVector}
    for _ in vertices(g2)
        add_vertex!(g1)
    end
    # todo shallow reference ?
    for vatr in vertex_attr(g2)
        push!(vertex_attr(g1), vatr)
    end
end

function NestedGraphs.shallowcopy_edges!(g1::AttributeGraph{T,G,V,E}, g2::AttributeGraph{T,G,V,E}, offset::Int) where {T<:Integer,G<:AbstractGraph{T},V,E<:AbstractDict}
    for e in edges(g2)
        add_edge!(g1, offset+src(e), offset+dst(e))
    end
    # todo shallow reference ?
    for (eatrkey,eatrval) in edge_attr(g2)
        edge_attr(g1)[eatrkey] = eatrval
    end
end


# multilayer.jl
function NestedGraphs.getsquashedgraph(ng::NestedGraph{T,R,N}, sqvertices::Vector{Vector{Q}}) where {T,R<:AbstractAttributeGraph,N,Q<:Integer}
#    squashedgraph = ng.flatgr |> deepcopy |> adjacency_matrix |> SimpleGraph
    squashedgraph = NestedGraphs.getsimplegraphcopy(ng)
    NestedGraphs._rec_merge_vertices!(SimpleGraph(squashedgraph), sqvertices)
end

end
