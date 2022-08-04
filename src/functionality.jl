add_flat_vertex!(cg) = Graphs.add_vertex!(cg.flatgr)
add_flat_vertex!(cg::NestedGraph, dpr::Dict{Symbol}) = Graphs.add_vertex!(cg.flatgr, dpr)
add_flat_vertices!(cg, vs::Int) = Graphs.add_vertices!(cg.flatgr, vs)
add_flat_edge!(cg::NestedGraph, src::Int, dst::Int) = Graphs.add_edge!(cg.flatgr, src, dst)
add_flat_edge!(cg::NestedGraph, src::Int, dst::Int, dpr::Dict{Symbol}) = Graphs.add_edge!(cg.flatgr, src, dst, dpr)

addshallowcopy_flat_edge!(cg::NestedGraph, src1::Int, dst1::Int, g2::NestedGraph, src2::Int, dst2::Int) = addshallowcopy_edge!(cg.flatgr, src1, dst1, g2.flatgr, src2, dst2)
addshallowcopy_flat_vertex!(cg::NestedGraph, g2::NestedGraph, n::T) where {T<:Integer} = addshallowcopy_vertex!(cg.flatgr, g2.flatgr, n)

addshallowcopy_vertices!(g1::AbstractGraph, g2::NestedGraph) = addshallowcopy_vertices!(g1, g2.flatgr)
function addshallowcopy_vertices!(g1::AbstractGraph, g2::AbstractGraph)
    for v in vertices(g2)
        addshallowcopy_vertex!(g1, g2, v)
    end
end

addshallowcopy_edges!(g1::AbstractGraph, g2::NestedGraph, offset::Integer) = addshallowcopy_edges!(g1, g2.flatgr, offset)
function addshallowcopy_edges!(g1::AbstractGraph, g2::AbstractGraph, offset::Integer)
    for e in edges(g2)
        addshallowcopy_edge!(g1, offset+e.src, offset+e.dst, g2, e.src, e.dst)
    end
end

removeemptygraphs_recursive!(gr::AbstractGraph) = true
function removeemptygraphs_recursive!(cg::NestedGraph)
    grvs2delete = Vector{Int}()
    for (ig,gr) in enumerate(cg.grv)
        if nv(gr) == ne(gr) == 0
            push!(grvs2delete, ig)
        else
            removeemptygraphs_recursive!(gr)
        end
    end
    for ig in grvs2delete
        deleteat!(cg.grv, ig)
        # modify neds
        for (ie,ce) in enumerate(cg.neds)
            newsource = ce.src
            newdest = ce.dst
            if ce.src[1][1] > ig
                newsource = (ce.src[1]-1, ce.src[2])
            end
            if ce.dst[1][1] > ig
                newdest = (ce.dst[1]-1, ce.dst[2])
            end
            cg.neds[ie] = NestedEdge(newsource, newdest)
        end
        # modify vmap
        for (iv,vm) in enumerate(cg.vmap)
            if vm[1] > ig
                cg.vmap[iv] = (vm[1] - 1, vm[2])
            end
        end
    end
end