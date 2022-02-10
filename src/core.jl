import Graphs: AbstractSimpleEdge

struct CompositeEdge{T<:Integer} <: AbstractSimpleEdge{T}
    src::Tuple{T, T}
    dst::Tuple{T, T}
end
CompositeEdge(t::Tuple{Tuple{T,T}, Tuple{T,T}}) where {T<:Int} = CompositeEdge(t[1], t[2])
CompositeEdge(p::Pair{Tuple{T,T}}) where {T<:Int} = CompositeEdge(p.first, p.second)

"""
If composing MetaGraphs, the copy for the metadata is shallow
CompositeGraphs of CompositeGraphs are allowed
"""
struct CompositeGraph{T<:AbstractGraph, R<:AbstractGraph} <: AbstractGraph{Int}
    "Flat graph combining all domain graphs given with the edges"
    flatgr::T
    "Original domain graphs"
    grv::Vector{R}
    "Maps the nodes of flat network to the original graph (Domain, Node)"
    vmap::Vector{Tuple{Int,Int}}
end
import Base: Pair, Tuple

#forward all Graph functions to .flatgr
@forward CompositeGraph.flatgr Graphs.vertices
@forward CompositeGraph.flatgr Graphs.edges
Graphs.add_vertices!(cg::CompositeGraph, vs) = Graphs.add_vertices!(cg.flatgr, vs)
Graphs.add_vertex!(cg::CompositeGraph) = Graphs.add_vertex!(cg.flatgr)
Graphs.add_vertex!(cg::CompositeGraph, dpr::Dict{Symbol, Any}) = Graphs.add_vertex!(cg.flatgr, dpr)
Graphs.add_edge!(cg::CompositeGraph, src, dst) = Graphs.add_edge!(cg.flatgr, src, dst)
Graphs.add_edge!(cg::CompositeGraph, e::Edge) = Graphs.add_edge!(cg.flatgr, e)
Graphs.add_edge!(cg::CompositeGraph, src, dst, dpr::Dict{Symbol, Any}) = Graphs.add_edge!(cg.flatgr, src, dst, dpr)
Graphs.add_edge!(cg::CompositeGraph, e::Edge, dpr::Dict{Symbol, Any}) = Graphs.add_edge!(cg.flatgr, e, dpr)
MetaGraphs.set_prop!(cg::CompositeGraph, n::Int, s::Symbol, val) = MetaGraphs.set_prop!(cg.flatgr, n, s, val)
MetaGraphs.set_prop!(cg::CompositeGraph, n1::Int, n2::Int, s::Symbol, val) = MetaGraphs.set_prop!(cg.flatgr, n1, n2, s, val)
MetaGraphs.set_prop!(cg::CompositeGraph, e::Edge, s::Symbol, val) = MetaGraphs.set_prop!(cg.flatgr, e, s, val)
MetaGraphs.get_prop(cg::CompositeGraph, n::Int, s::Symbol) = MetaGraphs.get_prop(cg.flatgr, n, s)
MetaGraphs.get_prop(cg::CompositeGraph, n1::Int, n2::Int, s::Symbol) = MetaGraphs.get_prop(cg.flatgr, n1, n2, s)
MetaGraphs.get_prop(cg::CompositeGraph, e::Edge, s::Symbol) = MetaGraphs.get_prop(cg.flatgr, e, s)
MetaGraphs.props(cg::CompositeGraph, n::Int) = MetaGraphs.props(cg.flatgr, n)
MetaGraphs.props(cg::CompositeGraph, n1::Int, n2::Int) = MetaGraphs.props(cg.flatgr, n1, n2)
MetaGraphs.props(cg::CompositeGraph, e::Edge) = MetaGraphs.props(cg.flatgr, e)

vertex(cg::CompositeGraph, net::Int, nod::Int) = findfirst(==((net,nod)), cg.vmap)
domain(cg::CompositeGraph, nd::Int) = cg.vmap[nd][1]
edge(cg::CompositeGraph, ce::CompositeEdge) = Edge(vertex(cg, ce.src[1], ce.src[2]), vertex(cg, ce.dst[1], ce.dst[2]))
compositeedge(cg::CompositeGraph, e::Edge) = CompositeEdge(cg.vmap[e.src], cg.vmap[e.dst])
domainedge(cg::CompositeGraph, e::Edge) = samedomain(e.src, e.dst) ? Edge(cg.vmap[e.src][2], cg.vmap[e.dst][2]) : nothing
samedomain(cg::CompositeGraph, v1::Int, v2::Int) = domain(cg, v1) == domain(cg,v2)
interdomainedges(cg::CompositeGraph) = [e for e in edges(cg) if cg.vmap[e.src][1] != cg.vmap[e.dst][1]]

"Unwrap CompositeGraph to Graph type"
unwraptype(cgt::Type{CompositeGraph{T,R}}) where {T<:AbstractGraph, R<:AbstractGraph} = return unwraptype(T)
unwraptype(gt::Type{T}) where {T<:AbstractGraph} = return gt

CompositeGraph{T}() where {T<:AbstractGraph} = CompositeGraph(T(), Vector{T}(), Vector{Tuple{Int,Int}}())
CompositeGraph(grv::Vector{T}) where {T<:AbstractGraph} = CompositeGraph(grv, Vector{CompositeEdge{Int}}())

CompositeGraph(grv::Vector{T}, edges::Vector{Tuple{Tuple{Int,Int}, Tuple{Int,Int}}}; args...) where {T<:AbstractGraph} = CompositeGraph(grv, CompositeEdge.(edges); args...)

function CompositeGraph(grv::Vector{T}, edges::Vector{CompositeEdge{R}}; both_ways::Bool=false) where {T<:AbstractGraph, R<:Int}
    flatgr = unwraptype(T)()
    vmap = Vector{Tuple{Int,Int}}()
    # transfer the graphs to flat graph
    for (i,g) in enumerate(grv)
        offset = length(vertices(flatgr))
        add_vertices!(flatgr, g)
        add_edges!(flatgr, g, offset)
        [push!(vmap, (i,v)) for v in vertices(g)]
    end
    # register edges between the graphs
    for e in edges
        src = findfirst(==(e.src), vmap)
        dst = findfirst(==(e.dst), vmap)
        add_edge!(flatgr, src, dst)
        if both_ways
            add_edge!(flatgr, dst, src)
        end
    end
    CompositeGraph(flatgr, grv, vmap)
end

Graphs.add_vertices!(fg::AbstractGraph, fg2::AbstractGraph) = add_vertices!(fg, length(vertices(fg2)))
Graphs.add_vertices!(g1::AbstractMetaGraph, g2::AbstractMetaGraph) = [add_vertex!(g1, props(g2, v)) for v in vertices(g2)]

add_edges!(g1::AbstractGraph, g2::AbstractGraph, offset::Int) = [add_edge!(g1, offset+e.src, offset+e.dst) for e in edges(g2)]
add_edges!(g1::AbstractMetaGraph, g2::AbstractMetaGraph, offset::Int) = [add_edge!(g1, offset+e.src, offset+e.dst, props(g2, e)) for e in edges(g2)]
