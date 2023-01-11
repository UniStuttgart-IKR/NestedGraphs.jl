"$(TYPEDSIGNATURES) Add vertices and edges from `g2` to `g1`"
function shallowcopy_verdges!(g1::AbstractGraph, g2::AbstractGraph)
    offset = length(vertices(g1))
    shallowcopy_vertices!(g1, g2)
    shallowcopy_edges!(g1, g2, offset)
end

"""
$(TYPEDSIGNATURES) 
Add the vertices from `g2` to `g1`.
In case the vertices carry data, a shallow copy needs to be added.
This way any update on the data propagates automatically across the whole `NestedGraph`.
"""
shallowcopy_vertices!(g1::AbstractGraph, g2::NestedGraph) = shallowcopy_vertices!(g1, g2.flatgr)
function shallowcopy_vertices!(g1::AbstractGraph, g2::AbstractGraph)
    for v in vertices(g2)
        add_vertex!(g1)
    end
end

"""
$(TYPEDSIGNATURES) 
Add the edges from `g2` to `g1`.
In case the edges carry data, a shallow copy needs to be added.
This way any update on the data propagates automatically across the whole `NestedGraph`.
`offset` specifies a mapping between the node numbering in `g2` and `g1`.
Actually the nodes of `g2` are mapped to the nodes in `g1 + offset`.
"""
shallowcopy_edges!(g1::AbstractGraph, g2::NestedGraph, offset::Integer) = shallowcopy_edges!(g1, g2.flatgr, offset)
function shallowcopy_edges!(g1::AbstractGraph, g2::AbstractGraph, offset::Integer)
    for e in edges(g2)
        add_edge!(g1, offset+e.src, offset+e.dst)
    end
end

"$(TYPEDSIGNATURES) Unroll a nested vertex along all the nested graph subgraphs"
function unroll_vertex(ng::NestedGraph, v::T)  where T<:Integer
    unr = Vector{T}()
    nver = ng.vmap[v]
    push!(unr, nver[1])
    if ng.grv[nver[1]] isa NestedGraph
        push!(unr, unroll_vertex(ng.grv[nver[1]], nver[2])...)
    else
        push!(unr, nver[2])
    end
    return unr
end
"""
$(TYPEDSIGNATURES) 
Given a vector of the nested inner subgraphs get the index in the flat graph.
The last element of the vector is handled as the node number in the `v[1:end-1]` inner nested graph
"""
function roll_vertex(ng::NestedGraph, v::AbstractVector{T}) where T<:Integer
    if length(v) == 2
        return vertex(ng, v...)
    else
        ngi = innergraph(ng, v[1:end-2])
        vi = vertex(ngi, v[end-1:end]...)
        deleteat!(v, length(v))
        v[end] = vi
        return roll_vertex(ng, v)
    end
end
"$(TYPEDSIGNATURES) Get inner nested graph from a vector. Recursively calls `grv[v[1]].grv[v[2]]...`"
function innergraph(ng::NestedGraph, v::AbstractVector)
    if length(v) > 1
        innergraph(ng.grv[v[1]], v[2:end])
    elseif length(v) == 1
        return ng.grv[v[1]]
    end
end

"$(TYPEDSIGNATURES) Check if path id `v` can represent a graph."
function isagraph(ng::NestedGraph, v::AbstractVector)
    if length(v) > 1
        if 0 <= v[1] <= length(ng.grv)
            isagraph(ng.grv[v[1]], v[2:end])
        else
            return false
        end
    elseif length(v) == 1
        return 0 <= v[1] <= length(ng.grv)
    end
end
isagraph(ng::AbstractGraph, v::AbstractVector) = false

"$(TYPEDSIGNATURES) For usage after single vertex removal only"
function update_vmapneds_after_delete!(ng::NestedGraph, nver::Tuple{T,T}) where T<:Integer
    for (i,vm) in enumerate(ng.vmap)
        if vm[1] == nver[1] && vm[2] > nver[2] 
            ng.vmap[i] = (vm[1], vm[2]-1)
        end
    end
    filter!(ned -> src(ned) != nver && dst(ned) != nver, ng.neds)
    for (i,ned) in enumerate(ng.neds)
        vms = src(ned)
        vmd = dst(ned)
        if vms[1] == nver[1] && vms[2] > nver[2] 
            vms = (vms[1], vms[2]-1)
        end
        if vmd[1] == nver[1] && vmd[2] > nver[2] 
            vmd = (vmd[1], vmd[2]-1)
        end
        ng.neds[i] = NestedEdge(vms, vmd)
    end
end

function update_vmapneds_after_delete_graph!(ng::NestedGraph, grid::T) where T<:Integer
    for (i,vm) in enumerate(ng.vmap)
        if vm[1] > grid 
            ng.vmap[i] = (vm[1]-1, vm[2])
        end
    end
    for (i,ned) in enumerate(ng.neds)
        vms = src(ned)
        vmd = dst(ned)
        if vms[1] > grid
            vms = (vms[1]-1, vms[2])
        end
        if vmd[1] > grid
            vmd = (vmd[1]-1, vmd[2])
        end
        ng.neds[i] = NestedEdge(vms, vmd)
    end
end

removeemptygraphs_recursive!(gr::AbstractGraph) = true
function removeemptygraphs_recursive!(ng::NestedGraph)
    grvs2delete = Vector{Int}()
    for (ig,gr) in enumerate(ng.grv)
        if nv(gr) == ne(gr) == 0
            push!(grvs2delete, ig)
        else
            removeemptygraphs_recursive!(gr)
        end
    end
    for ig in grvs2delete
        deleteat!(ng.grv, ig)
        # modify neds
        for (ie,ce) in enumerate(ng.neds)
            newsource = ce.src
            newdest = ce.dst
            if ce.src[1][1] > ig
                newsource = (ce.src[1]-1, ce.src[2])
            end
            if ce.dst[1][1] > ig
                newdest = (ce.dst[1]-1, ce.dst[2])
            end
            ng.neds[ie] = NestedEdge(newsource, newdest)
        end
        # modify vmap
        for (iv,vm) in enumerate(ng.vmap)
            if vm[1] > ig
                ng.vmap[iv] = (vm[1] - 1, vm[2])
            end
        end
    end
end
