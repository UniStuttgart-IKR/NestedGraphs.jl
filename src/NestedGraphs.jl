module NestedGraphs
using Graphs, MetaGraphs

using DocStringExtensions

import Graphs: AbstractSimpleEdge, AbstractGraphFormat, nv, ne
import Base: Pair, Tuple
import AbstractTrees

export NestedEdge, NestedVertex, NestedGraph, vertex, edge, nestededge, nestedvertex, subgraph, subgraphedge, getnestededges, unroll_vertex, roll_vertex
export NestedMetaGraph
export getfoldedgraph, getmlvertices, getmlsquashedgraph, getsquashedgraph, getallsubgraphpaths, getallsubvertices, gettotalsubgraphs
       
include("nestedgraph.jl")
include("graphsimpl.jl")
include("metagraphsimpl.jl")
include("functionality.jl")
include("multilayer.jl")

end
