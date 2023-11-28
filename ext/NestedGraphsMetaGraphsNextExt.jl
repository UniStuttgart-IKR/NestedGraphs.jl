module NestedGraphsMetaGraphsNextExt

using NestedGraphs, Graphs, DocStringExtensions
using MetaGraphsNext

const NestedMetaGraph{T,R,N} = NestedGraph{<:Integer,<:MetaGraph,<:AbstractGraph} 

# forward all operations to `flatgr`
# shallow MetaGraphs props of `flatgr` will propage to the `grv`s

function NestedGraphs.initialize(::Type{<:MetaGraph{C,G,L,VD,ED,GD}}) where {C,G,L,VD,ED,GD}
    return MetaGraph(G(), L, VD, ED, GD)
end

end
