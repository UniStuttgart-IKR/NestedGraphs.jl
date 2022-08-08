"Used by GraphIO.jl for several file formats"
struct NestedGraphFormat <: AbstractGraphFormat end

"""
A `NestedEdge` connects graphs inside a `NestedGraph` or simply nodes inside a `NestedGraph`.
The `NestedEdge` connects two `NestedVertex`s.
This means that every `NestedEdge` connects to a specific node and not as a hyperedge to the whole domain graph.
"""
struct NestedEdge{T<:Integer} <: AbstractSimpleEdge{T}
    src::Tuple{T, T}
    dst::Tuple{T, T}
end
NestedEdge(t::Tuple{Tuple{T,T}, Tuple{T,T}}) where {T<:Integer} = NestedEdge(t[1], t[2])
NestedEdge(p::Pair{Tuple{T,T}}) where {T<:Integer} = NestedEdge(p.first, p.second)
NestedEdge(t11::T, t12::T, t21::T, t22::T) where {T<:Integer} = NestedEdge((t11,t12),(t21,t22))
Base.:+(offset::Int, ce::NestedEdge) = NestedEdge(ce.src[1] + offset, ce.src[2], ce.dst[1] + offset, ce.dst[2])

# TODO: convert Tuple{Tuple{T,T}, Tuple{T,T}} where T<Integer to NestedEdge
Base.convert(::Type{NestedEdge}, e::Tuple{Tuple{T,T}, Tuple{T,T}}) where T<:Integer = NestedEdge(e)

"""
A `NestedVertex` is the local view of a vertex inside a `NestedGraph`.
It contains the domain and the vertex indices.
"""
NestedVertex{T} = Tuple{T,T} where T<:Integer

"""
A `NestedGraph` is a graph of vertices, where each vertex can be a complete graph.
Connections are done with `NestedEdge`s and the vertices are `NestedVertex`s.
NestedGraphs of NestedGraphs are allowed.
"""
struct NestedGraph{T <: Integer, R <: AbstractGraph{T}, N <: Union{AbstractGraph, AbstractGraph}} <: AbstractGraph{T}
    #TODO modifying flatgr should modify grv, neds & modifying grv neds should modiufy flatgr
    "Flat graph view combining all domain graphs given with the edges"
    flatgr::R
    "Original domain graphs"
    grv::Vector{N}
    "interdomain edges"
    neds::Vector{NestedEdge{T}}
    "Maps the nodes of flat network to the original graph (Domain, Node)"
    vmap::Vector{Tuple{T,T}}
    # TODO create a synchro Dict{Tuple{Int, Int}, Int} for reverse operation
end

Base.show(io::IO, t::NestedGraph{T,R,N}) where {T,R,N} = print(io, "NestedGraph{$(R),$(N)}({$(nv(t)),$(ne(t))}, $(length(t.grv)) subnets)")
NestedGraph{T,R}() where {T,R} = NestedGraph{T,R,R}()
NestedGraph{T,R,N}() where {T,R,N} = NestedGraph(R(), Vector{N}(), Vector{NestedEdge{T}}(), Vector{Tuple{T,T}}())
NestedGraph(::Type{R}) where {R<:AbstractGraph} = NestedGraph(R(), [R()], Vector{NestedEdge{Int}}(), Vector{Tuple{Int,Int}}())
NestedGraph(grv::Vector{T}) where {T<:AbstractGraph} = NestedGraph(grv, Vector{NestedEdge{Int}}())
NestedGraph(gr::T) where {T<:AbstractGraph} = NestedGraph([gr])
function NestedGraph(grv::Vector{R}, edges::AbstractVector; both_ways::Bool=false) where {R<:AbstractGraph}
    nedgs = convert.(NestedEdge, edges)
    flatgrtype = unwraptype(R)
    if !isconcretetype(flatgrtype)
        flatgrtypes = [unwraptype(typeof(gr)) for gr in grv]
        @assert all(==(flatgrtypes[1]), flatgrtypes)
        flatgrtype = flatgrtypes[1]
    end
    flatgr = flatgrtype()
    vmap = Vector{Tuple{Int,Int}}()
    # transfer the graphs to flat graph
    for (i,g) in enumerate(grv)
        shallowcopy_verdges!(flatgr, g)
        [push!(vmap, (i,v)) for v in vertices(g)]
    end
    ng = NestedGraph(flatgr, grv, Vector{NestedEdge{Int}}(), vmap)
    for nedg in nedgs
        add_edge!(ng, nedg)
        both_ways && add_edge!(ng, reverse(nedg))
    end
    return ng
end

"Unwrap NestedGraph to Graph type"
unwraptype(::Type{NestedGraph{T,R}}) where {T,R} = return unwraptype(R)
unwraptype(::Type{NestedGraph{T,R,N}}) where {T,R,N} = return unwraptype(R)
unwraptype(gt::Type{T}) where {T<:AbstractGraph} = return gt

# implement `AbstractTrees` (possibly more in the future)
AbstractTrees.children(node::NestedGraph) = node.grv

Base.getindex(ng::NestedGraph, indx, props::Symbol) = Base.getindex(ng.flatgr, indx, props)

"Convert a local view `NestedVertex` to a global view"
vertex(ng::NestedGraph, cv::NestedVertex) = vertex(ng, cv...)
vertex(ng::NestedGraph, d::T, v::T) where T<:Integer = findfirst(==((d,v)), ng.vmap)
"Get the domain index of a vertex `v`"
domain(ng::NestedGraph, v::T) where T<:Integer = ng.vmap[v][1]
"Convert a local view `NestedEdge` to a global view"
edge(ng::NestedGraph, ce::NestedEdge) = Edge(vertex(ng, ce.src[1], ce.src[2]), vertex(ng, ce.dst[1], ce.dst[2]))
"Convert a global view of an edge to local view `NestedEdge`"
nestededge(ng::NestedGraph, e::Edge) = NestedEdge(ng.vmap[e.src], ng.vmap[e.dst])
nestedvertex(ng::NestedGraph, v) = ng.vmap[v]
"""
Get the domain of an edge
If the edge connects 2 domains, it returns `nothing`
"""
domainedge(ng::NestedGraph, e::Edge) = issamedomain(ng, e.src, e.dst) ? Edge(ng.vmap[e.src][2], ng.vmap[e.dst][2]) : nothing
"Checks if two nodes are in the same domain"
issamedomain(ng::NestedGraph, v1::Int, v2::Int) = domain(ng, v1) == domain(ng,v2)
issamedomain(ng::NestedGraph, e::Edge) = issamedomain(ng, e.src, e.dst) 
issamedomain(ce::NestedEdge) = ce.src[1] == ce.dst[1]
"Get all edges that have no domain, i.e. that interconnect domains"
interdomainedges(ng::NestedGraph) = [e for e in edges(ng) if ng.vmap[e.src][1] != ng.vmap[e.dst][1]]