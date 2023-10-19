module NestedGraphs
using Graphs
using SimpleTraits

using DocStringExtensions

import Graphs: AbstractSimpleEdge, AbstractGraphFormat, nv, ne
import Base: Pair, Tuple
import AbstractTrees

export NestedEdge, NestedVertex, NestedGraph, vertex, edge, nestededge, nestedvertex, subgraph, subgraphedge, getnestededges, unroll_vertex, roll_vertex
export getgraph, getsubgraphs
export getfoldedgraph, getmlvertices, getmlsquashedgraph, getsquashedgraph, getallsubgraphpaths, getallsubvertices, gettotalsubgraphs
       
include("nestedgraph.jl")
include("graphsimpl.jl")
include("functionality.jl")
include("multilayer.jl")

function helloWorld()
    println("Hello World")
end

end
