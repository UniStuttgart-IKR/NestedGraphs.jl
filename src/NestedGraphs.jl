module NestedGraphs
using Graphs, MetaGraphs

import Graphs: AbstractSimpleEdge, AbstractGraphFormat, nv, ne
import Base: Pair, Tuple
import AbstractTrees

export NestedEdge, NestedVertex, NestedGraph, vertex, edge, nestededge, nestedvertex, domain, domainedge, interdomainedges
export NestedMetaGraph
       
include("nestedgraph.jl")
include("graphsimpl.jl")
include("metagraphsimpl.jl")
include("functionality.jl")

end
