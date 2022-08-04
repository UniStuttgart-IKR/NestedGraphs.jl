#forward all Graph functions to .flatgr
Graphs.vertices(cg::NestedGraph) = vertices(cg.flatgr)
Graphs.nv(cg::NestedGraph) = nv(cg.flatgr)
Graphs.edges(cg::NestedGraph) = edges(cg.flatgr)
Graphs.ne(cg::NestedGraph) = ne(cg.flatgr)
Graphs.is_directed(cg::NestedGraph) = Graphs.is_directed(cg.flatgr)
Graphs.inneighbors(cg::NestedGraph, v) = Graphs.inneighbors(cg.flatgr, v)
function Graphs.add_vertices!(cg::NestedGraph, vs::Int; domain::Int=1)
    Graphs.add_vertices!(cg.grv[domain], vs)
    add_flat_vertices!(cg, vs)
    rang = zip(Iterators.repeated(domain), nv(cg.grv[domain]):nv(cg.grv[domain])+vs)
    push!(cg.vmap, rang... )
end
"`targetnode` is the index of the entering node"
function Graphs.add_vertex!(cg::NestedGraph; domain::Int=1, targetnode::Union{Int,Nothing}=nothing)
    isnothing(targetnode) && (targetnode = nv(cg.grv[domain])+1)
    Graphs.has_vertex(cg, domain, targetnode) && return false
    Graphs.add_vertex!(cg.grv[domain])
    add_flat_vertex!(cg)
    push!(cg.vmap, (domain, targetnode) )
end
function Graphs.add_vertex!(cg::NestedGraph, dpr::Dict{Symbol}; domain::Int=1, targetnode::Union{Int,Nothing}=nothing)
    isnothing(targetnode) && (targetnode = nv(cg.grv[domain])+1)
    Graphs.has_vertex(cg, domain, targetnode) && return false
    Graphs.add_vertex!(cg.grv[domain], dpr)
    add_flat_vertex!(cg, dpr)
    push!(cg.vmap, (domain, targetnode) )
end

function Graphs.add_edge!(cg::NestedGraph, src::Int, dst::Int)
    srctup = cg.vmap[src]
    dsttup = cg.vmap[dst]
    if srctup[1] != dsttup[1]
        push!(cg.neds, NestedEdge(srctup, dsttup))
    else
        add_edge!(cg.grv[srctup[1]], srctup[2], dsttup[2])
    end
    add_flat_edge!(cg, src, dst)
end
Graphs.add_edge!(cg::NestedGraph, e::Edge) = Graphs.add_edge!(cg, e.src, e.dst)
function Graphs.add_edge!(cg::NestedGraph, src::Int, dst::Int, dpr::Dict{Symbol})
    srctup = cg.vmap[src]
    dsttup = cg.vmap[dst]
    if srctup[1] != dsttup[1]
        push!(cg.neds, NestedEdge(srctup, dsttup))
    else
        add_edge!(cg.grv[srctup[1]], srctup[2], dsttup[2], dpr)
    end
    add_flat_edge!(cg, src, dst, dpr)
end

Graphs.induced_subgraph(cg::NestedGraph, ve::AbstractVector{R}) where {R<:Integer} = Graphs.induced_subgraph(cg.flatgr, ve)
Graphs.induced_subgraph(cg::NestedGraph, ve::AbstractVector{R}) where {R<:Edge} = Graphs.induced_subgraph(cg.flatgr, ve)
function Graphs.has_vertex(cg::NestedGraph, v1::Integer, v2::Integer)
    v = vertex(cg, v1, v2)
    isnothing(v) && return false
    Graphs.has_vertex(cg, v)
end
Graphs.has_vertex(cg::NestedGraph, v::Integer) = Graphs.has_vertex(cg.flatgr, v)
Graphs.has_edge(cg::NestedGraph, n1, n2) = has_edge(cg.flatgr, n1, n2)


# Methods to enrich graph with more graphs
#
Graphs.add_vertex!(cg::NestedGraph, grv::T) where {T<:AbstractGraph} = Graphs.add_vertex!(cg, grv, Vector{NestedEdge{Int}}())
function Graphs.add_vertex!(cg::NestedGraph, gr::T, cedges::Vector{NestedEdge{R}}, dprops::Union{Vector{Dict{Symbol,U}}, Nothing}=nothing; vmap::Union{AbstractVector{Int}, Nothing}=nothing, both_ways::Bool=false, rev_cedges::Bool=false) where {T<:AbstractGraph, R<:Int, U}
    if vmap === nothing
        vmap = vertices(gr)
    end
    function localizecompedge(cg, ce, revedges::Bool)
        local localdomain
        revedges == true ? localdomain = 2 : localdomain = 1
        src = ce.src[1] == localdomain ? cg.vmap[ce.src[2]] : (length(cg.grv), ce.src[2])
        dst = ce.dst[1] == localdomain ? cg.vmap[ce.dst[2]] : (length(cg.grv), ce.dst[2])
        NestedEdge(src, dst)
    end
    add_verdges!(cg.flatgr, gr)
    push!(cg.grv, gr)
    [push!(cg.vmap, (length(cg.grv), v)) for v in vmap]
    if length(cedges) > 0
        offcedges = localizecompedge.([cg], cedges, rev_cedges)
        add_edges!(cg, offcedges, dprops; both_ways=both_ways)
    end
end
Graphs.add_edge!(cg::NestedGraph, ce::NestedEdge) = error("notimplemented")

Graphs.add_vertices!(g1::AbstractGraph, g2::AbstractGraph, vlis::Vector{Int}) = add_vertices!(g1, induced_subgraph(g2, vlis)[1]);
Graphs.add_vertices!(g1::AbstractGraph, g2::AbstractGraph) = add_vertices!(g1, length(vertices(g2)));
Graphs.add_vertices!(g1::NestedGraph, g2::AbstractGraph) = add_vertices!(g1.flatgr, g2)
Graphs.add_vertices!(g1::NestedGraph, g2::NestedGraph) = add_vertices!(g1.flatgr, g2)
function Graphs.add_vertices!(g1::AbstractGraph, g2::NestedGraph) 
    for gr in g2.grv
        add_vertices!(g1, gr)
    end
end