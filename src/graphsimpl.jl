#forward all Graph functions to .flatgr
Graphs.vertices(ng::NestedGraph) = vertices(ng.flatgr)
Graphs.nv(ng::NestedGraph) = nv(ng.flatgr)
Graphs.edges(ng::NestedGraph) = edges(ng.flatgr)
Graphs.ne(ng::NestedGraph) = ne(ng.flatgr)
Graphs.is_directed(ng::NestedGraph) = Graphs.is_directed(ng.flatgr)
Graphs.inneighbors(ng::NestedGraph, v) = Graphs.inneighbors(ng.flatgr, v)

"$(TYPEDSIGNATURES)"
function _propagate_to_nested(ng, fun, subgraphs::AbstractVector{T}, args...) where T<:Integer
    if length(subgraphs) > 2
        fun(ng.grv[subgraphs[1]], args...;subgraphs=subgraphs[2:end])
    elseif length(subgraphs) == 2
        fun(ng.grv[subgraphs[1]], args...;subgraphs=subgraphs[2])
    else
        fun(ng.grv[subgraphs[1]], args...)
    end
end
_propagate_to_nested(ng, fun, subgraph::T, args...) where T<:Integer = fun(ng.grv[subgraph], args...)

"$(TYPEDSIGNATURES) `subgraph` is the nested graph to insert a node"
function Graphs.add_vertices!(ng::NestedGraph, vs; subgraphs=1)
    subgraph = first(subgraph)
    Graphs.add_vertices!(ng.grv[subgraph], vs)
    _propagate_to_nested(ng, Graphs.add_vertices!, subgraphs, vs)
    rang = zip(Iterators.repeated(subgraph), nv(ng.grv[subgraph]):nv(ng.grv[subgraph])+vs)
    push!(ng.vmap, rang... )
end
"$(TYPEDSIGNATURES) `targetnode` is the index of the entering node"
function Graphs.add_vertex!(ng::NestedGraph{T,R}; subgraphs=1, targetnode=nothing) where {T,R}
    subgraph = first(subgraphs)
    length(ng.grv) == 0 && (add_vertex!(ng, R()))
    isnothing(targetnode) && (targetnode = nv(ng.grv[subgraph])+1)
    Graphs.has_vertex(ng, subgraph, targetnode) && return false
    add_vertex!(ng.flatgr)
    push!(ng.vmap, (subgraph, targetnode) )
    _propagate_to_nested(ng, Graphs.add_vertex!, subgraphs)
end
#to do add `subgraphs` argument
function Graphs.rem_vertex!(ng::NestedGraph, v::T) where T<:Integer
    Graphs.has_vertex(ng, v) || return false
    rem_vertex!(ng.flatgr, v)
    nver = ng.vmap[v]
    rem_vertex!(ng.grv[nver[1]], nver[2])
    deleteat!(ng.vmap, v)
    update_vmapneds_after_delete!(ng, nver)
end

"$(TYPEDSIGNATURES)  Remove node or graph identified by `path2rem`."
function Graphs.rem_vertex!(ng::NestedGraph, path2rem::Vector{T}) where T<:Integer
    if !isagraph(ng, path2rem)
        rem_vertex!(ng, roll_vertex(ng, path2rem))
    else
        gr2del = innergraph(ng, path2rem)
        for v in vertices(gr2del)
            path2remvert = vcat(path2rem, [1]) #always delete the first one. others will be pushed.
            rem_vertex!(ng, roll_vertex(ng, path2remvert))
        end
        parentgr = length(path2rem) > 1 ? innergraph(ng, path2rem[1:end-1]) : ng
        deleteat!(parentgr.grv, path2rem[end])
        update_vmapneds_after_delete_graph!(parentgr, path2rem[end])
        # updatge vmap and neds (the subgraph id part)
    end
end

Graphs.add_edge!(ng::NestedGraph, ce::NestedEdge) = add_edge!(ng, edge(ng, ce))
Graphs.add_edge!(ng::NestedGraph, e::Edge) = Graphs.add_edge!(ng, e.src, e.dst)
function Graphs.add_edge!(ng::NestedGraph, src::T, dst::T) where T<:Integer
    srctup = ng.vmap[src]
    dsttup = ng.vmap[dst]
    if srctup[1] != dsttup[1]
        push!(ng.neds, NestedEdge(srctup, dsttup))
    else
        add_edge!(ng.grv[srctup[1]], srctup[2], dsttup[2])
    end
    add_edge!(ng.flatgr, src, dst)
end
function Graphs.rem_edge!(ng::NestedGraph, src::T, dst::T) where T<:Integer
    Graphs.has_edge(ng, src, dst) || return false
    rem_edge!(ng.flatgr, src, dst)
    srctup = ng.vmap[src]
    dsttup = ng.vmap[dst]
    if srctup[1] != dsttup[1]
        deleteat!(ng.neds, findall(==(NestedEdge(srctup, dsttup)), ng.neds))
    else
        rem_edge!(ng.grv[srctup[1]], srctup[2], dsttup[2])
    end
end

Graphs.induced_subgraph(ng::NestedGraph, ve::AbstractVector{T}) where {T<:Integer} = Graphs.induced_subgraph(ng.flatgr, ve)
Graphs.induced_subgraph(ng::NestedGraph, ve::AbstractVector{R}) where {R<:Edge} = Graphs.induced_subgraph(ng.flatgr, ve)
function Graphs.has_vertex(ng::NestedGraph, v1::T, v2::T) where T<:Integer
    v = vertex(ng, v1, v2)
    isnothing(v) && return false
    Graphs.has_vertex(ng, v)
end
Graphs.has_vertex(ng::NestedGraph, v::T) where T<:Integer = Graphs.has_vertex(ng.flatgr, v)
Graphs.has_edge(ng::NestedGraph, n1, n2) = has_edge(ng.flatgr, n1, n2)

#
# Methods to enrich graph with more graphs
#
"$(TYPEDSIGNATURES) To create a new top-level subgraph, pass `subgraphs=nothing` (default)"
function Graphs.add_vertex!(ng::NestedGraph, gr::T; subgraphs=nothing) where {T<:AbstractGraph}
    vmap = vertices(gr)
    shallowcopy_verdges!(ng.flatgr, gr)
    if subgraphs===nothing
        push!(ng.grv, gr)
        [push!(ng.vmap, (length(ng.grv), v)) for v in vmap]
    else
        nvbefore = nv(ng.grv[subgraphs[1]])
        _propagate_to_nested(ng, Graphs.add_vertex!, subgraphs, gr)
        [push!(ng.vmap, (subgraphs[1], nvbefore+v)) for v in vmap]
    end
end

#
# Methods to enrich graph with more graphs cumulatively
#
Graphs.add_vertices!(g1::AbstractGraph, g2::AbstractGraph, vlis::Vector{T}) where T<:Integer = add_vertices!(g1, induced_subgraph(g2, vlis)[1]);
Graphs.add_vertices!(g1::AbstractGraph, g2::AbstractGraph) = add_vertices!(g1, length(vertices(g2)));
Graphs.add_vertices!(g1::NestedGraph, g2::AbstractGraph) = add_vertices!(g1.flatgr, g2)
Graphs.add_vertices!(g1::NestedGraph, g2::NestedGraph) = add_vertices!(g1.flatgr, g2)
function Graphs.add_vertices!(g1::AbstractGraph, g2::NestedGraph) 
    for gr in g2.grv
        add_vertices!(g1, gr)
    end
end

# deprecated
add_vertex_old!(ng::NestedGraph, grv::T) where {T<:AbstractGraph} = Graphs.add_vertex!(ng, grv, Vector{NestedEdge{Int}}())
"""
$(TYPEDSIGNATURES) 
Add subgraph graph `gr` into the `NestedGraph` `ng`.
It connectes `gr` with `ng`
"""
function add_vertex_old!(ng::NestedGraph, gr::T, nedges, dprops=nothing; subgraphs=nothing, vmap=nothing, both_ways=false, rev_cedges=false) where {T<:AbstractGraph}
    if vmap === nothing
        vmap = vertices(gr)
    end
    function localizenestedge(ng, ce, revedges::Bool)
        revedges == true ? localsubgraph = 2 : localsubgraph = 1
        src = ce.src[1] == localsubgraph ? ng.vmap[ce.src[2]] : (length(ng.grv), ce.src[2])
        dst = ce.dst[1] == localsubgraph ? ng.vmap[ce.dst[2]] : (length(ng.grv), ce.dst[2])
        NestedEdge(src, dst)
    end
    shallowcopy_verdges!(ng.flatgr, gr)
    if subgraphs===nothing
        push!(ng.grv, gr)
        [push!(ng.vmap, (length(ng.grv), v)) for v in vmap]
    else
        add_vertex!(ng.grv[subgraphs], gr, nedges; subgraphs, dprops, vmap, both_ways, rev_cedges)
        [push!(ng.vmap, (subgraphs, v)) for v in vmap]
    end
    if length(nedges) > 0
        offcedges = localizenestedge.([ng], nedges, rev_cedges)
        add_edges!(ng, offcedges, dprops; both_ways=both_ways)
    end
    return length(ng.grv)
end

# `add_edges!` is not defined in `Graphs.jl`. Make a PR to add it?
# TODO: this is for MetaGraphs. move to metagraphsimpl.jl
function add_edges_old!(flatgr::AbstractGraph, vmap::Vector{Tuple{R,R}}, nedges::Vector{NestedEdge{R}}, dprops::Union{Vector{Dict{Symbol,U}}, Nothing}=nothing; both_ways::Bool=false) where {R<:Integer, U}
    dprops !== nothing && length(dprops) != length(nedges) && error("`nedges` and `dprops` must have equal length")
    for (i,e) in enumerate(nedges)
        src = findfirst(==(e.src), vmap)
        dst = findfirst(==(e.dst), vmap)
        if dprops !== nothing
            add_edge!(flatgr, src, dst, dprops[i])
        else
            add_edge!(flatgr, src, dst)
        end
        if both_ways
            if dprops !== nothing
                add_edge!(flatgr, dst, src, dprops[i])
            else 
                add_edge!(flatgr, dst, src)
            end
        end
    end
end
