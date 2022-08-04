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

Base.show(io::IO, t::NestedGraph{T,R}) where {T,R} = print(io, "NestedGraph{$(R)}({$(nv(t)),$(ne(t))}, $(length(t.grv)) subnets)")
NestedGraph{T,R,N}() where {T,R,N} = NestedGraph(R(), Vector{N}([R()]), Vector{NestedEdge{T}}(), Vector{Tuple{T,T}}())
NestedGraph(::Type{R}) where {R<:AbstractGraph} = NestedGraph(R(), [R()], Vector{NestedEdge{Int}}(), Vector{Tuple{Int,Int}}())
NestedGraph(grv::Vector{T}) where {T<:AbstractGraph} = NestedGraph(grv, Vector{NestedEdge{Int}}())
function NestedGraph(grv::Vector{R}, edges; both_ways::Bool=false) where {R<:AbstractGraph}
    nedgs = convert.(NestedEdge, edges)
    flatgr = unwraptype(R)()
    vmap = Vector{Tuple{Int,Int}}()
    # transfer the graphs to flat graph
    for (i,g) in enumerate(grv)
        add_verdges!(flatgr, g)
        [push!(vmap, (i,v)) for v in vertices(g)]
    end
    # register nedgs between the graphs
    add_edges!(flatgr, vmap, nedgs; both_ways = both_ways)
    NestedGraph(flatgr, grv, nedgs, vmap)
end

"Unwrap NestedGraph to Graph type"
unwraptype(::Type{NestedGraph{T,R}}) where {T<:Integer, R<:AbstractGraph} = return unwraptype(R)
unwraptype(gt::Type{T}) where {T<:AbstractGraph} = return gt

# implement `AbstractTrees` (possibly more in the future)
AbstractTrees.children(node::NestedGraph) = node.grv

Base.getindex(cg::NestedGraph, indx, props::Symbol) = Base.getindex(cg.flatgr, indx, props)

"Convert a local view `NestedVertex` to a global view"
vertex(cg::NestedGraph, cv::NestedVertex) = vertex(cg, cv...)
vertex(cg::NestedGraph, d::T, v::T) where T<:Integer = findfirst(==((d,v)), cg.vmap)
"Get the domain index of a vertex `v`"
domain(cg::NestedGraph, v::T) where T<:Integer = cg.vmap[v][1]
"Convert a local view `NestedEdge` to a global view"
edge(cg::NestedGraph, ce::NestedEdge) = Edge(vertex(cg, ce.src[1], ce.src[2]), vertex(cg, ce.dst[1], ce.dst[2]))
"Convert a global view of an edge to local view `NestedEdge`"
nestededge(cg::NestedGraph, e::Edge) = NestedEdge(cg.vmap[e.src], cg.vmap[e.dst])
"""
Get the domain of an edge
If the edge connects 2 domains, it returns `nothing`
"""
domainedge(cg::NestedGraph, e::Edge) = issamedomain(cg, e.src, e.dst) ? Edge(cg.vmap[e.src][2], cg.vmap[e.dst][2]) : nothing
"Checks if two nodes are in the same domain"
issamedomain(cg::NestedGraph, v1::Int, v2::Int) = domain(cg, v1) == domain(cg,v2)
issamedomain(cg::NestedGraph, e::Edge) = issamedomain(cg, e.src, e.dst) 
issamedomain(ce::NestedEdge) = ce.src[1] == ce.dst[1]
"Get all edges that have no domain, i.e. that interconnect domains"
interdomainedges(cg::NestedGraph) = [e for e in edges(cg) if cg.vmap[e.src][1] != cg.vmap[e.dst][1]]

"Adds edges plus the properties if any"
add_edge_plus!(g1::AbstractGraph, e::Edge) = add_edge!(g1,e)
add_edge_plus!(g1::AbstractGraph, n1::Int, n2::Int) = add_edge!(g1,n1,n2)

# `add_edges!` is not defined in `Graphs.jl`. Make a PR to add it?
add_edges!(cg::NestedGraph, cedges::Vector{NestedEdge{R}}, dprops::Union{Vector{Dict{Symbol,U}}, Nothing}=nothing; both_ways::Bool=false) where {R<:Int, U} = add_edges!(cg.flatgr, cg.vmap, cedges, dprops; both_ways=both_ways)
function add_edges!(flatgr::AbstractGraph, vmap::Vector{Tuple{Int,Int}}, cedges::Vector{NestedEdge{R}}, dprops::Union{Vector{Dict{Symbol,U}}, Nothing}=nothing; both_ways::Bool=false) where {R<:Int, U}
    dprops !== nothing && length(dprops) != length(cedges) && error("`cedges` and `dprops` must have equal length")
    for (i,e) in enumerate(cedges)
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
add_edges!(g1::AbstractGraph, g2::AbstractGraph, offset::Int) = [add_edge!(g1, offset+e.src, offset+e.dst) for e in edges(g2)];
function add_edges!(g1::AbstractGraph, g2::NestedGraph, offset::Int) 
    recoffset = 0
    for gr in g2.grv
        add_edges!(g1, gr, offset+recoffset)
        recoffset += length(vertices(gr))
    end
    # add interdomain edges
    for e in interdomainedges(g2)
        add_edge_plus!(g1, e.src+offset, e.dst+offset)
    end
end

"Adds vertices and edges from `g2` to `g1`"
function add_verdges!(g1::AbstractGraph, g2::AbstractGraph)
    offset = length(vertices(g1))
    addshallowcopy_vertices!(g1, g2)
    addshallowcopy_edges!(g1, g2, offset)
end
