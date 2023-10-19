module NestedGraphsMetaGraphsNextExt

using NestedGraphs, Graphs, DocStringExtensions 
using MetaGraphsNext 

const DynNG = NestedGraph{Int, SimpleGraph{Int64}, AbstractGraph}; 
ng = DynNG()

function NestedGraphs.NestedGraph(gr::MetaGraphsNext.MetaGraph)
   add_vertex!(ng, gr)
   return ng
end

function NestedGraphs.NestedGraph(gr::Vector{GR}) where {GR<:MetaGraphsNext.MetaGraph}
    for ele in gr
        add_vertex!(ng, ele)
    end
    return ng
end

function NestedGraphs.NestedGraph(gr::Vector{GR}, ne::Vector{Tuple{Tuple{Int64, Int64}, Tuple{Int64, Int64}}}; both_ways::Bool = false) where {GR<:MetaGraphsNext.MetaGraph}
    #ng = DynNG()
    for ele in gr
        add_vertex!(ng, ele)
    end

    for i in ne
        flatindex1 = -1  # Initialize with a default value
        flatindex2 = -1  # Initialize with a default value

        for (j,ele) in enumerate(ng.vmap)
            if ele == i[1] 
                flatindex2 = j
            end
        end

        for (j,ele) in enumerate(ng.vmap)
            if ele == i[2]
                flatindex1 = j
            end
        end

        add_edge!(ng, flatindex2, flatindex1)
        
        if both_ways == true 
            add_edge!(ng, flatindex1, flatindex2) 
        end
    end
    return ng
end

end

# function Graphs.add_vertex!(ng::NestedGraph{SimpleGraph{Int64},NestedGraph{Int64, SimpleGraph{Int64}, AbstractGraph}}; subgraph=1) 
# union_type = NestedGraph{Int64, SimpleGraph{Int64}, AbstractGraph} | NestedGraph{SimpleGraph{Int64}, {Int64, SimpleGraph{Int64}, AbstractGraph}}

# function Graphs.add_vertex!(mg::MetaGraphsNext.MetaGraph, subgraph)
#     return add_vertex(NestedGraph(mg); subgraph)

# function Graphs.add_vertex!(ng::P, subgraph=1) where {P<: NestedGraph{Int64,SimpleGraph{Int64},NestedGraph{Int64, SimpleGraph{Int64}, AbstractGraph}}}
#     return add_vertex!(ng.grv[subgraph], SimpleGraph(1))
#     return ng

# function Graphs.add_vertex!(ng::MetaGraphsNext.MetaGraph; subgraphs=1, targetnode = nothing) 
#     subgraph = first(subgraphs)
#     length(ng.grv) == 0 && (add_vertex!(ng, R()))
#     isnothing(targetnode) && (targetnode = nv(ng.grv[subgraph])+1)
#     Graphs.has_vertex(ng, subgraph, targetnode) && return false
#     NestedGraphs._propagate_to_nested(ng, Graphs.add_vertex!, subgraphs)
#     NestedGraphs.shallowcopy_vertex!(ng.flatgr, ng.grv[subgraph], nv(ng.grv[subgraph]))
#     push!(ng.vmap, (subgraph, targetnode) )
# end


# function Graphs.add_vertex!(ng::NestedGraph{Int, SimpleGraph{Int64}, AbstractGraph})
#    add_vertex!(ng.grv[1], MetaGraphsNext.MetaGraph(Graph();label_type=Symbol,vertex_data_type=String,edge_data_type=Int,graph_data=nothing,weight_function=identity,))
# end


