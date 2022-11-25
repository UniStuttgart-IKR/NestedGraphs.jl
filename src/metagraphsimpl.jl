# In order to extend NestedGraphs.jl for a graph type,
# the following interfaces must be implemented
# TODO

const NestedMetaGraph{T,R,N} = NestedGraph{<:Integer,<:AbstractMetaGraph,<:AbstractGraph} 

# forward all operations to `flatgr`
# shallow MetaGraphs props of `flatgr` will propage to the `grv`s
MetaGraphs.set_prop!(ng::NestedMetaGraph, s::Symbol, val) = MetaGraphs.set_prop!(ng.flatgr, s, val)
MetaGraphs.set_prop!(ng::NestedMetaGraph, n::Integer, s::Symbol, val) = MetaGraphs.set_prop!(ng.flatgr, n, s, val)
MetaGraphs.set_prop!(ng::NestedMetaGraph, n1::Integer, n2::Integer, s::Symbol, val) = MetaGraphs.set_prop!(ng.flatgr, n1, n2, s, val)
MetaGraphs.set_prop!(ng::NestedMetaGraph, e::Edge, s::Symbol, val) = MetaGraphs.set_prop!(ng.flatgr, e, s, val)
MetaGraphs.get_prop(ng::NestedMetaGraph, s::Symbol) = MetaGraphs.get_prop(ng.flatgr, s)
MetaGraphs.get_prop(ng::NestedMetaGraph, n::Integer, s::Symbol) = MetaGraphs.get_prop(ng.flatgr, n, s)
MetaGraphs.get_prop(ng::NestedMetaGraph, n1::Integer, n2::Integer, s::Symbol) = MetaGraphs.get_prop(ng.flatgr, n1, n2, s)
MetaGraphs.get_prop(ng::NestedMetaGraph, e::Edge, s::Symbol) = MetaGraphs.get_prop(ng.flatgr, e, s)
MetaGraphs.props(ng::NestedMetaGraph) = MetaGraphs.props(ng.flatgr)
MetaGraphs.props(ng::NestedMetaGraph, n::Integer) = MetaGraphs.props(ng.flatgr, n)
MetaGraphs.props(ng::NestedMetaGraph, n1::Integer, n2::Integer) = MetaGraphs.props(ng.flatgr, n1, n2)
MetaGraphs.props(ng::NestedMetaGraph, e::Edge) = MetaGraphs.props(ng.flatgr, e)
MetaGraphs.has_prop(ng::NestedMetaGraph, s::Symbol) = MetaGraphs.has_prop(ng.flatgr, s)
MetaGraphs.has_prop(ng::NestedMetaGraph, n::Integer, s::Symbol) = MetaGraphs.has_prop(ng.flatgr, n, s)
MetaGraphs.has_prop(ng::NestedMetaGraph, n1::Integer, n2::Integer, s::Symbol) = MetaGraphs.has_prop(ng.flatgr, n1, n2, s)
MetaGraphs.set_indexing_prop!(ng::NestedMetaGraph, props::Symbol) = MetaGraphs.set_indexing_prop!(ng.flatgr, props)


function Graphs.add_vertex!(ng::NestedMetaGraph{T,R}; subgraphs=1, targetnode=nothing) where {T,R<:AbstractMetaGraph}
    subgraph = first(subgraphs)
    length(ng.grv) == 0 && (add_vertex!(ng, R()))
    isnothing(targetnode) && (targetnode = nv(ng.grv[subgraph])+1)
    Graphs.has_vertex(ng, subgraph, targetnode) && return false
    _propagate_to_nested(ng, Graphs.add_vertex!, subgraphs)
    shallowcopy_vertex!(ng.flatgr, ng.grv[subgraph], nv(ng.grv[subgraph]))
    push!(ng.vmap, (subgraph, targetnode) )
end
Graphs.add_vertex!(ng::NestedMetaGraph, s::Symbol, v; subgraphs=1, targetnode=nothing) = add_vertex!(ng, Dict(s=>v); subgraphs, targetnode)
function Graphs.add_vertex!(ng::NestedMetaGraph{T,R}, dpr::Dict{Symbol}; subgraphs=1, targetnode=nothing) where {T,R<:AbstractMetaGraph}
    subgraph = first(subgraphs)
    length(ng.grv) == 0 && (add_vertex!(ng, R()))
    isnothing(targetnode) && (targetnode = nv(ng.grv[subgraph])+1)
    Graphs.has_vertex(ng, subgraph, targetnode) && return false
    add_vertex!(ng.flatgr, dpr)
    prs = props(ng.flatgr, nv(ng.flatgr))
    _propagate_to_nested(ng, Graphs.add_vertex!, subgraphs, prs)
    push!(ng.vmap, (subgraph, targetnode) )
end
function Graphs.add_edge!(ng::NestedMetaGraph, src::T, dst::T) where T<:Integer
    srctup = ng.vmap[src]
    dsttup = ng.vmap[dst]
    if srctup[1] != dsttup[1]
        push!(ng.neds, NestedEdge(srctup, dsttup))
        add_edge!(ng.flatgr, src, dst)
    else
        add_edge!(ng.grv[srctup[1]], srctup[2], dsttup[2])
        shallowcopy_edge!(ng.flatgr, src, dst, ng.grv[srctup[1]], srctup[2], dsttup[2])
    end
end
function Graphs.add_edge!(ng::NestedMetaGraph, src::T, dst::T, dpr::Dict{Symbol}) where T<:Integer
    srctup = ng.vmap[src]
    dsttup = ng.vmap[dst]
    add_edge!(ng.flatgr, src, dst, dpr)
    prs = props(ng.flatgr, src, dst)
    if srctup[1] != dsttup[1]
        push!(ng.neds, NestedEdge(srctup, dsttup))
    else
        add_edge!(ng.grv[srctup[1]], srctup[2], dsttup[2], prs)
    end
end

#
# `MetaGraphs.jl` copies reference if `g1` doesn't have a Dict and 
# calls `merge!` if `g1` has a Dict. Since we want a shallow copy `g1` should not have a Dict. 
# This is always the case, since we create a new node.
# If `g2` doesn't have any properties (i.e. no Dict), then a dummy Dict will be returned from `props`.
# In order to avoid this and return a legit reference from a `Dict` I initialize one in that case.
# TODO: raise issue in MetaGraphs ?
#
"$(TYPEDSIGNATURES) Copy vertices and shallow references to data from `g2` to `g1`"
function shallowcopy_vertices!(g1::R, g2::R) where {R<:AbstractMetaGraph}
    for n in vertices(g2)
        shallowcopy_vertex!(g1,g2,n)
    end
end
"$(TYPEDSIGNATURES)"
shallowcopy_vertex!(g1, g2::R, n) where {R<:NestedMetaGraph} = shallowcopy_vertex!(g1,g2.flatgr,n)
"$(TYPEDSIGNATURES)"
function shallowcopy_vertex!(g1::R, g2::R, n) where {R<:AbstractMetaGraph}
    if ! MetaGraphs._hasdict(g2, n)
        set_props!(g2, n, Dict{Symbol,Any}())
    end
    Graphs.add_vertex!(g1, props(g2,n))
end
"$(TYPEDSIGNATURES) Copy edges and shallow references to data from `g2` to `g1`"
function shallowcopy_edges!(g1::R, g2::R, offset::T) where {R<:AbstractMetaGraph, T<:Integer}
    for e in edges(g2)
        shallowcopy_edge!(g1, offset+e.src, offset+e.dst, g2, e.src, e.dst)
    end
end
"$(TYPEDSIGNATURES)"
shallowcopy_edge!(g1, src1, dst1, g2::R, src2, dst2) where {R<:NestedMetaGraph} = shallowcopy_edge!(g1,src1,dst1,g2.flatgr,src2,dst2)
"$(TYPEDSIGNATURES)"
function shallowcopy_edge!(g1::R, src1::T, dst1::T, g2::R, src2::T, dst2::T) where {R<:AbstractMetaGraph,T<:Integer}
    if ! MetaGraphs._hasdict(g2, Edge(src2,dst2))
        set_props!(g2, Edge(src2, dst2), Dict{Symbol,Any}())
    end
    Graphs.add_edge!(g1, src1, dst1, props(g2,src2,dst2))
end

# not implemented in MetaGraphs.jl
Graphs.add_vertices!(g1::AbstractMetaGraph, g2::AbstractMetaGraph) = [shallowcopy_vertex!(g1, g2, v) for v in vertices(g2)];
    

#
# Methods to enrich graph with more graphs
#
# """
# Add subgraph graph `gr` into the `NestedGraph` `ng`.
# It connectes `gr` with `ng`

# # Arguments
# - `dprops`: vector of dictionaries for all `nedges`
# - `vmap`: customize vmap 
# - `both_ways`: add `nedges` also for the opposite direction
# - `rev_cedges`: 
# """
# function Graphs.add_vertex!(ng::NestedGraph, gr::T, nedges, dprops=nothing; subgraphs=nothing, vmap=nothing, both_ways=false, rev_cedges=false) where {T<:AbstractGraph}
#     if vmap === nothing
#         vmap = vertices(gr)
#     end
#     function localizenestedge(ng, ce, revedges::Bool)
#         revedges == true ? localsubgraph = 2 : localsubgraph = 1
#         src = ce.src[1] == localsubgraph ? ng.vmap[ce.src[2]] : (length(ng.grv), ce.src[2])
#         dst = ce.dst[1] == localsubgraph ? ng.vmap[ce.dst[2]] : (length(ng.grv), ce.dst[2])
#         NestedEdge(src, dst)
#     end
#     shallowcopy_verdges!(ng.flatgr, gr)
#     if subgraphs===nothing
#         push!(ng.grv, gr)
#         [push!(ng.vmap, (length(ng.grv), v)) for v in vmap]
#     else
#         add_vertex!(ng.grv[subgraphs], gr, nedges; subgraphs, dprops, vmap, both_ways, rev_cedges)
#         [push!(ng.vmap, (subgraphs, v)) for v in vmap]
#     end
#     if length(nedges) > 0
#         offcedges = localizenestedge.([ng], nedges, rev_cedges)
#         add_edge!(ng, offcedges, dprops; both_ways=both_ways)
#     end
#     return length(ng.grv)
# end