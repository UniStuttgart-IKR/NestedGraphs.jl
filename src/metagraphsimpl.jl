# In order to extend NestedGraphs.jl for a graph type,
# the following interfaces must be implemented
# TODO

# shallow MetaGraphs props will propage properties on the `grv`s automatically
MetaGraphs.set_prop!(cg::NestedGraph, s::Symbol, val) = MetaGraphs.set_prop!(cg.flatgr, s, val)
MetaGraphs.set_prop!(cg::NestedGraph, n::Int, s::Symbol, val) = MetaGraphs.set_prop!(cg.flatgr, n, s, val)
MetaGraphs.set_prop!(cg::NestedGraph, n1::Int, n2::Int, s::Symbol, val) = MetaGraphs.set_prop!(cg.flatgr, n1, n2, s, val)
MetaGraphs.set_prop!(cg::NestedGraph, e::Edge, s::Symbol, val) = MetaGraphs.set_prop!(cg.flatgr, e, s, val)
MetaGraphs.get_prop(cg::NestedGraph, s::Symbol) = MetaGraphs.get_prop(cg.flatgr, s)
MetaGraphs.get_prop(cg::NestedGraph, n::Int, s::Symbol) = MetaGraphs.get_prop(cg.flatgr, n, s)
MetaGraphs.get_prop(cg::NestedGraph, n1::Int, n2::Int, s::Symbol) = MetaGraphs.get_prop(cg.flatgr, n1, n2, s)
MetaGraphs.get_prop(cg::NestedGraph, e::Edge, s::Symbol) = MetaGraphs.get_prop(cg.flatgr, e, s)
MetaGraphs.props(cg::NestedGraph{R}) where {R<:AbstractMetaGraph} = MetaGraphs.props(cg.flatgr)
MetaGraphs.props(cg::NestedGraph{R}, n::Int) where {R<:AbstractMetaGraph} = MetaGraphs.props(cg.flatgr, n)
MetaGraphs.props(cg::NestedGraph{R}, n1::Int, n2::Int) where {R<:AbstractMetaGraph} = MetaGraphs.props(cg.flatgr, n1, n2)
MetaGraphs.props(cg::NestedGraph{R}, e::Edge) where {R<:AbstractMetaGraph} = MetaGraphs.props(cg.flatgr, e)
MetaGraphs.has_prop(cg::NestedGraph, s::Symbol) = MetaGraphs.has_prop(cg.flatgr, s)
MetaGraphs.has_prop(cg::NestedGraph, n::Int, s::Symbol) = MetaGraphs.has_prop(cg.flatgr, n, s)
MetaGraphs.has_prop(cg::NestedGraph, n1::Int, n2::Int, s::Symbol) = MetaGraphs.has_prop(cg.flatgr, n1, n2, s)
MetaGraphs.set_indexing_prop!(cg::NestedGraph, props::Symbol) = MetaGraphs.set_indexing_prop!(cg.flatgr, props)

# initialization
"Composing MetaGraphs, the copy for the metadata is shallow"
NestedGraph{T,R}() where {T<:AbstractMetaGraph, R<:AbstractGraph} = NestedGraph{T,R}(T(), Vector{Union{T,R}}([T()]), Vector{NestedEdge{Int}}(), Vector{Tuple{Int,Int}}())
NestedGraph{T,R}(::Nothing) where {T<:AbstractMetaGraph, R<:AbstractGraph} = NestedGraph{T,R}(T(), Vector{Union{T,R}}(), Vector{NestedEdge{Int}}(), Vector{Tuple{Int,Int}}())

# implement interface of NestedGraphs
add_edge_plus!(g1::R, e::Edge) where {R<:AbstractMetaGraph} = add_edge!(g1,e, props(g1,e))
add_edge_plus!(g1::R, n1::Int, n2::Int) where {R<:AbstractMetaGraph} = add_edge!(g1,n1,n2, props(g1,n1,n2))

"""
MetaGraphs copy reference if props is empty.
If props is not empty it calls merge on the props already existing.
If a call props() and props do not exist a dummy Dict will be returned.
So in order to have a shallow copy I first initiate an empty Dict and then call 
in order to save the reference on a valid Dict
TODO: raise issue in MetaGraphs
"""
function addshallowcopy_vertex!(g1::R, g2::R, n::T) where {R<:AbstractMetaGraph, T<:Integer}
    if ! MetaGraphs._hasdict(g2, n)
        g2.vprops[n] = Dict{Symbol,Any}()
    end
    Graphs.add_vertex!(g1, props(g2,n))
end
function addshallowcopy_edge!(g1::R, src1::Int, dst1::Int, g2::R, src2::Int, dst2::Int) where {R<:AbstractMetaGraph}
    if ! MetaGraphs._hasdict(g2, Edge(src2,dst2))
        set_props!(g2, Edge(src2, dst2), Dict{Symbol,Any}())
    end
    Graphs.add_edge!(g1, src1, dst1, props(g2,src2,dst2))
end

addshallowcopy_flat_vertex!(cg::NestedGraph, g2::R, n::T) where {R<:AbstractMetaGraph, T<:Integer} = addshallowcopy_vertex!(cg.flatgr, g2, n)
addshallowcopy_flat_edge!(cg::NestedGraph, src1::Int, dst1::Int, g2::R, src2::Int, dst2::Int) where {R<:AbstractMetaGraph}= addshallowcopy_edge!(cg.flatgr, src1, dst1, g2, src2, dst2)


add_edges!(g1::AbstractMetaGraph, g2::AbstractMetaGraph, offset::Int) = [add_edge!(g1, offset+e.src, offset+e.dst, props(g2, e)) for e in edges(g2)];

Graphs.add_vertices!(g1::AbstractMetaGraph, g2::AbstractMetaGraph) = [addshallowcopy_vertex!(g1, g2, v) for v in vertices(g2)];
function Graphs.add_vertex!(cg::NestedGraph{T}; domain::Int=1, targetnode::Union{Int,Nothing}=nothing) where {T<:AbstractMetaGraph}
    isnothing(targetnode) && (targetnode = nv(cg.grv[domain])+1)
    Graphs.has_vertex(cg, domain, targetnode) && return false
    Graphs.add_vertex!(cg.grv[domain])
    addshallowcopy_flat_vertex!(cg, cg.grv[domain], nv(cg.grv[domain]))
    push!(cg.vmap, (domain, targetnode) )
end
Graphs.add_edge!(cg::NestedGraph{T}, ce::NestedEdge) where {T<:AbstractMetaGraph} = Graphs.add_edge!(cg, vertex(cg, ce.src[1], ce.src[2]), vertex(cg, ce.dst[1], ce.dst[2]))
function Graphs.add_edge!(cg::NestedGraph{T}, src::Int, dst::Int) where {T<:AbstractMetaGraph}
    srctup = cg.vmap[src]
    dsttup = cg.vmap[dst]
    if srctup[1] != dsttup[1]
        push!(cg.neds, NestedEdge(srctup, dsttup))
        add_flat_edge!(cg, src, dst)
    else
        add_edge!(cg.grv[srctup[1]], srctup[2], dsttup[2])
        addshallowcopy_flat_edge!(cg, src, dst, cg.grv[srctup[1]], srctup[2], dsttup[2])
    end
end