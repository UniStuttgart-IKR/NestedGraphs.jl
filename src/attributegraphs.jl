getgraphattr(ag::NestedGraph{T,G}, k) where {T<:Integer,G<:AbstractAttibuteGraph} = getgraphattr(graph(ag), k)
getvertexattr(ag::NestedGraph{T,G}, k) where {T<:Integer,G<:AbstractAttibuteGraph} = getvertexattr(graph(ag), k)
getedgeattr(ag::NestedGraph{T,G}, args...) where {T<:Integer,G<:AbstractAttibuteGraph} = getedgeattr(graph(ag), args...)

hasgraphattr(ag::NestedGraph{T,G}, k) where {T<:Integer,G<:AbstractAttibuteGraph} = hasgraphattr(graph(ag), k)
hasvertexattr(ag::NestedGraph{T,G}, k) where {T<:Integer,G<:AbstractAttibuteGraph} = hasvertexattr(graph(ag), k)
hasedgeattr(ag::NestedGraph{T,G}, args...) where {T<:Integer,G<:AbstractAttibuteGraph} = hasedgeattr(graph(ag), args...)


function addvertex!(ng::NestedGraph{T,G}; subgraphs=1) where {T<:Integer, G<:AbstractAttibuteGraph}
    subgraph = first(subgraphs)
    length(ng.grv) == 0 && (add_vertex!(ng, G()))
    targetnode = nv(ng.grv[subgraph])+1
    Graphs.has_vertex(ng, subgraph, targetnode) && return false
    addvertex!(ng.flatgr)
    push!(ng.vmap, (subgraph, targetnode) )
    _propagate_to_nested(ng, addvertex!, subgraphs)
end

function remvertex!(ng::NestedGraph{T,G}, v::T) where {T<:Integer, G<:AbstractAttibuteGraph}
    Graphs.has_vertex(ng, v) || return false
    remvertex!(ng.flatgr, v)
    nver = ng.vmap[v]
    remvertex!(ng.grv[nver[1]], nver[2])
    deleteat!(ng.vmap, v)
    update_vmapneds_after_delete!(ng, nver)
end

addedge!(mg::NestedGraph{T,G}, args...) where {T<:Integer, G<:AbstractAttibuteGraph} = add_edge!(mg, args...)

function remedge!(ng::NestedGraph{T,G}, src::T, dst::T) where {T<:Integer, G<:AbstractAttibuteGraph}
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

addgraphattr!(ng::NestedGraph{T,G}, k, v) where {T<:Integer, G<:AbstractAttibuteGraph} = addgraphattr!(graph(ng), k, v)
remgraphattr!(ng::NestedGraph{T,G}, k) where {T<:Integer, G<:AbstractAttibuteGraph} = remgraphattr!(graph(ng), k)

function addvertexattr!(ng::NestedGraph{T,G}, k, v) where {T<:Integer, G<:AbstractAttibuteGraph}
    addvertexattr!(graph(ng), k, v)
    addvertexattr!(ng.grv[ng.vmap[k][1]], ng.vmap[k][2], v)
end
function remvertexattr!(ng::NestedGraph{T,G}, k) where {T<:Integer, G<:AbstractAttibuteGraph}
    remvertexattr!(graph(ng), k)
    remvertexattr!(ng.grv[ng.vmap[k][1]], ng.vmap[k][2])
end

remedgeattr!(ng::NestedGraph{T,G}, e::AbstractEdge, args...) where {T<:Integer, G<:AbstractAttibuteGraph} = remedgeattr!(ng, src(e), dst(e), args...)
function remedgeattr!(ng::NestedGraph{T,G}, s::T, d::T, args...) where {T<:Integer, G<:AbstractAttibuteGraph}
    remedgeattr!(graph(ng), s, d, args...)
    if issamesubgraph(ng, s, d)
        remedgeattr!(ng.grv[ng.vmap[s][1]], ng.vmap[s][2], ng.vmap[d][2], args...)
    end
end

addedgeattr!(ng::NestedGraph{T,G}, e::AbstractEdge, args...) where {T<:Integer, G<:AbstractAttibuteGraph} = addedgeattr!(ng, src(e), dst(e), args...)
function addedgeattr!(ng::NestedGraph{T,G}, s::T, d::T, args...) where {T<:Integer, G<:AbstractAttibuteGraph}
    addedgeattr!(graph(ng), s, d, args...)
    if issamesubgraph(ng, s, d)
        addedgeattr!(ng.grv[ng.vmap[s][1]], ng.vmap[s][2], ng.vmap[d][2], args...)
    end
end

vertex_attr(mg::NestedGraph{T,G}) where {T<:Integer, G<:AbstractAttibuteGraph} = vertex_attr(graph(mg))
edge_attr(mg::NestedGraph{T,G}) where {T<:Integer, G<:AbstractAttibuteGraph} = edge_attr(graph(mg))
graph_attr(mg::NestedGraph{T,G}) where {T<:Integer, G<:AbstractAttibuteGraph} = graph_attr(graph(mg))

# I need to implement shallow copy
function shallowcopy_vertices!(g1::AttributeGraph{T,G,V}, g2::AttributeGraph{T,G,V}) where {T<:Integer,G<:AbstractGraph{T},V<:AbstractVector}
    for _ in vertices(g2)
        add_vertex!(g1)
    end
    # todo shallow reference ?
    for vatr in vertex_attr(g2)
        push!(vertex_attr(g1), vatr)
    end
end

function shallowcopy_edges!(g1::AttributeGraph{T,G,V,E}, g2::AttributeGraph{T,G,V,E}, offset::Int) where {T<:Integer,G<:AbstractGraph{T},V,E<:AbstractDict}
    for e in edges(g2)
        add_edge!(g1, offset+src(e), offset+dst(e))
    end
    # todo shallow reference ?
    for (eatrkey,eatrval) in edge_attr(g2)
        edge_attr(g1)[eatrkey] = eatrval
    end
end
