"Adds vertices and edges from `g2` to `g1`"
function shallowcopy_verdges!(g1::AbstractGraph, g2::AbstractGraph)
    offset = length(vertices(g1))
    shallowcopy_vertices!(g1, g2)
    shallowcopy_edges!(g1, g2, offset)
end

"""
Adds the vertices from `g2` to `g1`.
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
Adds the edges from `g2` to `g1`.
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