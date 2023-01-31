module NestedGraphs
using Graphs
using MetaGraphs, AttributeGraphs
import AttributeGraphs: AbstractAttibuteGraph, addgraphattr!, remgraphattr!, addvertexattr!, remvertexattr!, addedgeattr!, remedgeattr!, graph_attr, vertex_attr, edge_attr, addvertex!, remvertex!, addedge!, remedge!

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
include("attributegraphs.jl")
include("functionality.jl")
include("multilayer.jl")

end
