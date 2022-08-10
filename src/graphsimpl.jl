#forward all Graph functions to .flatgr
Graphs.vertices(ng::NestedGraph) = vertices(ng.flatgr)
Graphs.nv(ng::NestedGraph) = nv(ng.flatgr)
Graphs.edges(ng::NestedGraph) = edges(ng.flatgr)
Graphs.ne(ng::NestedGraph) = ne(ng.flatgr)
Graphs.is_directed(ng::NestedGraph) = Graphs.is_directed(ng.flatgr)
Graphs.inneighbors(ng::NestedGraph, v) = Graphs.inneighbors(ng.flatgr, v)

"$(TYPEDSIGNATURES)"
function _propagate_to_nested(ng, fun, domains::AbstractVector{T}, args...) where T<:Integer
    if length(domains) > 2
        fun(ng.grv[domains[1]], args...;domains=domains[2:end])
    elseif length(domains) == 2
        fun(ng.grv[domains[1]], args...;domains=domains[2])
    else
        fun(ng.grv[domains[1]], args...)
    end
end
_propagate_to_nested(ng, fun, domain::T, args...) where T<:Integer = fun(ng.grv[domain], args...)

"$(TYPEDSIGNATURES) `domain` is the nested graph to insert a node"
function Graphs.add_vertices!(ng::NestedGraph, vs; domains=1)
    domain = first(domain)
    Graphs.add_vertices!(ng.grv[domain], vs)
    _propagate_to_nested(ng, Graphs.add_vertices!, domains, vs)
    rang = zip(Iterators.repeated(domain), nv(ng.grv[domain]):nv(ng.grv[domain])+vs)
    push!(ng.vmap, rang... )
end
"$(TYPEDSIGNATURES) `targetnode` is the index of the entering node"
function Graphs.add_vertex!(ng::NestedGraph{T,R}; domains=1, targetnode=nothing) where {T,R}
    domain = first(domains)
    length(ng.grv) == 0 && (add_vertex!(ng, R()))
    isnothing(targetnode) && (targetnode = nv(ng.grv[domain])+1)
    Graphs.has_vertex(ng, domain, targetnode) && return false
    add_vertex!(ng.flatgr)
    push!(ng.vmap, (domain, targetnode) )
    _propagate_to_nested(ng, Graphs.add_vertex!, domains)
end
#to do add `domains` argument
function Graphs.rem_vertex!(ng::NestedGraph, v::T) where T<:Integer
    Graphs.has_vertex(ng, v) || return false
    rem_vertex!(ng.flatgr, v)
    nver = ng.vmap[v]
    rem_vertex!(ng.grv[nver[1]], nver[2])
    deleteat!(ng.vmap, v)
    update_vmap_after_delete!(ng, nver)
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
"$(TYPEDSIGNATURES) To create a new top-level domain, pass `domains=nothing` (default)"
function Graphs.add_vertex!(ng::NestedGraph, gr::T; domains=nothing) where {T<:AbstractGraph}
    vmap = vertices(gr)
    shallowcopy_verdges!(ng.flatgr, gr)
    if domains===nothing
        push!(ng.grv, gr)
        [push!(ng.vmap, (length(ng.grv), v)) for v in vmap]
    else
        nvbefore = nv(ng.grv[domains[1]])
        _propagate_to_nested(ng, Graphs.add_vertex!, domains, gr)
        [push!(ng.vmap, (domains[1], nvbefore+v)) for v in vmap]
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
Add domain graph `gr` into the `NestedGraph` `ng`.
It connectes `gr` with `ng`
"""
function add_vertex_old!(ng::NestedGraph, gr::T, nedges, dprops=nothing; domains=nothing, vmap=nothing, both_ways=false, rev_cedges=false) where {T<:AbstractGraph}
    if vmap === nothing
        vmap = vertices(gr)
    end
    function localizenestedge(ng, ce, revedges::Bool)
        revedges == true ? localdomain = 2 : localdomain = 1
        src = ce.src[1] == localdomain ? ng.vmap[ce.src[2]] : (length(ng.grv), ce.src[2])
        dst = ce.dst[1] == localdomain ? ng.vmap[ce.dst[2]] : (length(ng.grv), ce.dst[2])
        NestedEdge(src, dst)
    end
    shallowcopy_verdges!(ng.flatgr, gr)
    if domains===nothing
        push!(ng.grv, gr)
        [push!(ng.vmap, (length(ng.grv), v)) for v in vmap]
    else
        add_vertex!(ng.grv[domains], gr, nedges; domains, dprops, vmap, both_ways, rev_cedges)
        [push!(ng.vmap, (domains, v)) for v in vmap]
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