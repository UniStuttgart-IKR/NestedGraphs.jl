module NestedGraphs
using Graphs, MetaGraphs

import Graphs: AbstractSimpleEdge, AbstractGraphFormat, nv, ne
import Base: Pair, Tuple
import AbstractTrees

export NestedEdge, NestedGraph, vertex, edge, compositeedge, domain, domainedge, interdomainedges
       
include("nestedgraph.jl")
include("graphsimpl.jl")
include("metagraphsimpl.jl")
include("functionality.jl")

end
