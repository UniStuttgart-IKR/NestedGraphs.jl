# Usage and Examples
This page shows the basic usage and features of the package, together with examples.
You can also refer to the `./test/*` directory.

# The [`NestedGraph`](@ref) struct
This package defines the [`NestedGraph`](@ref) struct.
Inside the struct, both the nested structure of the graphs is represented (in `grv`) and the flat graph (in `flatgr`).
For communicating between `grv` and `flatgr` a mapping is defined in the `vmap` field.
Lastly, all the top-level (nested) edges are stored in `neds`.

For easier coding, we also define the struct [`NestedEdge`](@ref) and an alias type [`NestedVertex`](@ref).
`NestedEdge` connects 2 `NestedVertex`s.
A tuple of `Integer` describes `NestedVertex` as: (*subgraph_id*, *vertex_id*), where *vertex_id* is the id of the vertex in the specific subgraph.

A `NestedGraph` is defined by 3 parameters `{T,R,N}`, where:
- `T` is the `Integer` type used in the graph.
- `R` is the type of graphs used. It shouldn't be a `NestedGraph`
- `N` is the type of the top-level nested graphs. It could be a `NestedGraph`

In simple scenarios (2-level nesting), `R` and `N` could be the same.
More examples will be shared later.

Following, we deliberately define an abstract type `NestedGraph`, for more dynamicity.
```jldoctest walkthrough 
julia> using NestedGraphs, Graphs; # initialize environment

julia> DynNG = NestedGraph{Int, SimpleGraph{Int}, AbstractGraph}; # define the abstract type we will be working with

julia> ng = DynNG()
NestedGraph{SimpleGraph{Int64},AbstractGraph}({0,0}, 0 subgraphs)
```

Now we can directly start adding nodes or graphs in `ng`.

```jldoctest walkthrough
julia> add_vertex!(ng, SimpleGraph(3)); # add one graph

julia> add_vertex!(ng, SimpleGraph(6)); # add another graph

julia> ng
NestedGraph{SimpleGraph{Int64},AbstractGraph}({9,0}, 2 subgraphs)
```
Now, `ng` has 2 subgraphs and overall 9 nodes.
We can make the scenario more complicated and also add another nested graph.
```jldoctest walkthrough
julia> add_vertex!(ng, DynNG());

julia> ng.grv
3-element Vector{AbstractGraph}:
 {3, 0} undirected simple Int64 graph
 {6, 0} undirected simple Int64 graph
 NestedGraph{SimpleGraph{Int64},AbstractGraph}({0,0}, 0 subgraphs)
```
We can see the three subgraphs stored inside `ng`.
Now we can start adding end nodes to each subgraph.
```jldoctest walkthrough
julia> add_vertex!(ng; subgraphs=1);

julia> add_vertex!(ng; subgraphs=2);

julia> add_vertex!(ng; subgraphs=3);

julia> ng.grv
3-element Vector{AbstractGraph}:
 {4, 0} undirected simple Int64 graph
 {7, 0} undirected simple Int64 graph
 NestedGraph{SimpleGraph{Int64},AbstractGraph}({1,0}, 1 subgraphs)
```
Now all subgraphs have one more node.
But the third subgraph didn't have any nested subgraphs. So, where did that node go?
Let's see...

```jldoctest walkthrough
julia> ng.grv[3].grv
1-element Vector{AbstractGraph}:
 {1, 0} undirected simple Int64 graph
```
When the `subgraphs` keyword is not given, a default of `subgraphs=1` is assumed.
Also, if there is no subgraph at all, a new one is created.
This is done so that there is always a consistent mapping between the flat graph `flatgr` and the nested graphs `grv`.

We can continue adding nodes/subgraphs.
For example let's add another graph of 2 nodes inside the nested `NestedGraph` with index 3.
```jldoctest walkthrough
julia> add_vertex!(ng, SimpleGraph(2); subgraphs=3);

julia> ng.grv[3].grv
2-element Vector{AbstractGraph}:
 {1, 0} undirected simple Int64 graph
 {2, 0} undirected simple Int64 graph
```

And now, let's assume we would like to add a vertex in the 2nd subgraph of the third subgraph (i.e. on `ng.grv[3].grv[2]`).
Then we would have to do
```jldoctest walkthrough
julia> add_vertex!(ng, subgraphs=[3,2]);

julia> ng.grv[3].grv
2-element Vector{AbstractGraph}:
 {1, 0} undirected simple Int64 graph
 {3, 0} undirected simple Int64 graph
```

Success!

!!! warning
    To add/delete nodes/edges/graphs you always need to use as an argument the outmost `NestedGraph`.
    You can see an example how the following code will be faulty and bring the `NestedGraph` in an inconsistent state:
    ```jldoctest walkthrough
    julia> using Test;

    julia> sgs = [SimpleGraph(3), SimpleGraph(3)];

    julia> ng2 = NestedGraph(sgs)
    NestedGraph{SimpleGraph{Int64},SimpleGraph{Int64}}({6,0}, 2 subgraphs)

    julia> add_vertex!(ng2, subgraphs=1) # that's how you should add/remove nodes/edges/graphs
    true
    
    julia> @test nv(ng2) == nv(ng2.grv[1]) + nv(ng2.grv[2])
    Test Passed

    julia> add_vertex!(sgs[1])  # this is how you shouldn't do it. Don't access directly the subgraphs.
    true

    julia> @test nv(ng2) == nv(ng2.grv[1]) + nv(ng2.grv[2])
    Test Failed at none:1
      Expression: nv(ng2) == nv(ng2.grv[1]) + nv(ng2.grv[2])
       Evaluated: 7 == 8
    ERROR: There was an error during testing
    ```
# Removing nodes
 We can remove nodes with the `rem_vertex!` function.
 Assume we would like to remove the node we previously added, i.e. the 3rd node of the 2nd nested graph of the 3rd top-level nested graph. 
 So, the "path" to this node is `[3,2,3]` where the last element is the node id and all previous are the subgraph id's to follow.
 To remove that index we do:

```jldoctest walkthrough
julia> v323 = roll_vertex(ng, [3,2,3]) # get top-level representation in the flatgraph of the NestedVertex
15

julia> rem_vertex!(ng, v323);

julia> ng.grv[3].grv # see that index is deleted
2-element Vector{AbstractGraph}:
 {1, 0} undirected simple Int64 graph
 {2, 0} undirected simple Int64 graph

```
Similarly we can delete nodes directly by specifying the unrolled path to that node.
For example the above block does equivalent job to this:

```jldoctest walkthrough
julia> add_vertex!(ng; subgraphs = [3,2]) # restore previously removed node
true

julia> rem_vertex!(ng, [3,2,3]) # directly remove node
```
If the specified path doesn't point to a node, but to a graph, this whole graph is deleted instead.

```jldoctest walkthrough
julia> add_vertex!(ng, SimpleGraph(10); subgraphs=[3]); # add a graph that we will delete later

julia> ng.grv[3].grv
3-element Vector{AbstractGraph}:
 {1, 0} undirected simple Int64 graph
 {2, 0} undirected simple Int64 graph
 {10, 0} undirected simple Int64 graph

julia> rem_vertex!(ng, [3,3]) # delete previously added graph

julia> ng.grv[3].grv
2-element Vector{AbstractGraph}:
 {1, 0} undirected simple Int64 graph
 {2, 0} undirected simple Int64 graph

```

# Handling Edges
Similarly we can use the `add_edge!` and `rem_edge!`.
For example to add an edge between the node 3 and node 8 of the `flatgr` you do:
```jldoctest walkthrough
julia> add_edge!(ng, 3, 8);

julia> ng
NestedGraph{SimpleGraph{Int64},AbstractGraph}({14,1}, 3 subgraphs)
```
`{14,1}` specifies that the `NestedGraph` has 14 nodes and 1 edge, which we just added.
You can again follow the previous style of calling `roll_vertex` to identify nodes.

In the previous case the edge doesn't propagate to the the nested subgraphs because it connects top-level subgraphs.
For this reason you can find it in the `neds` field
```jldoctest walkthrough
julia> ng.neds
1-element Vector{NestedEdge{Int64}}:
 Edge (1, 3) => (2, 5)
```
Also see that the nested subgraphs still don't have any edge:
```jldoctest walkthrough
julia> ng.grv
3-element Vector{AbstractGraph}:
 {4, 0} undirected simple Int64 graph
 {7, 0} undirected simple Int64 graph
 NestedGraph{SimpleGraph{Int64},AbstractGraph}({3,0}, 2 subgraphs)
```
On the contrary doing the following will propage the edge all the way to the 2nd subgraph of the 3rd subgraph.
```jldoctest walkthrough
julia> add_edge!(ng, roll_vertex(ng, [3,2,1]), roll_vertex(ng, [3,2,2]));

julia> @test ne(ng.grv[3]) == ne(ng.grv[3].grv[2]) == 1
Test Passed
```

!!! note
    Of course, instead of adding edges from zero, you can directly add graphs that containt edges.
    ```jldoctest walkthrough
    julia> cgs = [complete_graph(3), complete_graph(3)];

    julia> ng3 = NestedGraph(cgs)
    NestedGraph{SimpleGraph{Int64},SimpleGraph{Int64}}({6,6}, 2 subgraphs)
    ```
    You can also initialize the `NestedGraph` with some edges between the nested graphs.
    For example initialize with 2 `NestedEdge`.
    That is a `NestedEdge` between the 2nd node of the 1st graph and the 3rd node of the 2nd graph and another one between the 1st node of the 1st graph and the 1 node of the 2nd graph.
    ```jldoctest walkthrough
    julia> ng4 = NestedGraph(cgs, [((1,2), (2,3)), ((1,1), (2,1))])
    NestedGraph{SimpleGraph{Int64},SimpleGraph{Int64}}({6,8}, 2 subgraphs)
    ```

!!! info
    We are aware that handling nested graphs can be complicated and at this moment the syntax to do so could be more friendly. Future work will focus on syntantic sugar.

!!! info
    Most of the times illustrating a nested graph can be very helpful. There is currently *Work In Progress* for a `NestedGraphMakie` package.

# Understanding the mapping from flat graph to nested graphs
The `NestedGraph` `ng` contains `nv(ng) = 14` vertices. The `vmap` field will show us to which subgraphs they belong.
```jldoctest walkthrough
julia> ng.vmap |> pairs
pairs(::Vector{Tuple{Int64, Int64}})(...):
  1  => (1, 1)
  2  => (1, 2)
  3  => (1, 3)
  4  => (2, 1)
  5  => (2, 2)
  6  => (2, 3)
  7  => (2, 4)
  8  => (2, 5)
  9  => (2, 6)
  10 => (1, 4)
  11 => (2, 7)
  12 => (3, 1)
  13 => (3, 2)
  14 => (3, 3)
```
For example node 14 of the `flatgr` refers to the 3rd node of the 3rd subgraph.
If we again ask `vmap` what exactly this node is we get:
```jldoctest walkthrough
julia> ng.grv[3].vmap |> pairs
pairs(::Vector{Tuple{Int64, Int64}})(...):
  1 => (1, 1)
  2 => (2, 1)
  3 => (2, 2)
```
This means the 3rd node of the 3rd subgraph refers locally to the 2nd node of the 2nd subgraph.
Since this 2nd subgraph is not a `NestedGraph` we are sure that the chain ends here:
```jldoctest walkthrough
julia> ng.grv[3].grv[2] |> typeof
SimpleGraph{Int64}
```
So overall the 14th node of `ng` is referring to the 2nd node of the 2nd subgraph of the 3rd subgraph.
This can be retrieved directly will the `unroll_vertex`:
```jldoctest walkthrough
julia> unroll_vertex(ng, 14)
3-element Vector{Int64}:
 3
 2
 2
```

As we saw previously the `roll_vertex` does exactly the opposite:
```jldoctest walkthrough
julia> roll_vertex(ng, unroll_vertex(ng, 14)) == 14
true
```

# Type stable `NestedGraph`
The same procedure follows with the definition of a non abstract typed `NestedGraph`.
```jldoctest walkthrough
julia> ng5 = NestedGraph([SimpleGraph(3), SimpleGraph(3)])
NestedGraph{SimpleGraph{Int64},SimpleGraph{Int64}}({6,0}, 2 subgraphs)

julia> ng5 |> typeof # NestedGraph instance is type stable now
NestedGraph{Int64, SimpleGraph{Int64}, SimpleGraph{Int64}}
```
Of course, we are more constrained with types now:
```jldoctest walkthrough
julia> @test_throws MethodError add_vertex!(ng2, DynNG())
Test Passed
      Thrown: MethodError
```

# MetaGraphs support
`NestedGraphs.jl` comes with built-in support for [`MetaGraphs`](https://github.com/JuliaGraphs/MetaGraphs.jl).
Dealing with generic data in nested structures augments the problem of synchronization.
This problem has already been solved for adding/deleting graphs/nodes/edges as shown previously.
However these elements didn't contain any data.
Previously with `SimpleGraphs`, you couldn't really tell apart 2 nodes and deleting one or the other would many times be indistinguishable (given that edges don't reveal a pattern).
But now, each node can carry different data making it identifiable.
Moreover we would like to be able to modify the data of a node and automatically propagate the changes to the nested graphs.

To deal with the problem of synchronization Julia offers several tools for reactive programming.
However, at the moment we deal with this problem with shallow copying of the data.
This makes the overall update mechanism much simpler, faster and more reliable.

The interface to `NestedGraphs` stays the same:
```jldoctest walkthrough
julia> using MetaGraphs;

julia> mgs = [MetaGraph(3), MetaGraph(3)];

julia> nmg = NestedGraph(mgs)
NestedGraph{MetaGraph{Int64, Float64},MetaGraph{Int64, Float64}}({6,0}, 2 subgraphs)
```
Now we can add some data to the `Nested(Meta)Graph`:
```jldoctest walkthrough
julia> set_prop!(nmg, 2, :el, "elelemt_data") # add data to the 2nd node of nmg
true
```
Finally notice that the data for the `flatgr` and the node inside `grv` are identical, meaning that they reference to the same part in memory.
```jldoctest walkthrough
julia> props(nmg.flatgr, 2) === props(nmg.grv[nmg.vmap[2][1]], nmg.vmap[2][2])
true
```
As a result, updates to the modified data are done instantly.

The same holds for deeper nested graphs and for edge data.

!!! info
    There are many [resources](https://stackoverflow.com/questions/38601141/what-is-the-difference-between-and-comparison-operators-in-julia) online for the difference between `==` and `===` in Julia. 

!!! info
    `NestedGraphs.jl` boils down to just being a wrapper.
    This means more graph types can be supported.
    In the future we will disintegrate `MetaGraphs` from the `NestedGraphs.jl` to possibly an external package (or we might use [`Require.jl`](https://github.com/JuliaPackaging/Requires.jl)) in order to not always carry this dependency to the end users.
    In the future we would also like to support a type-stable version of `MetaGraphs`, the [`MetaGraphsNext.jl`](https://github.com/JuliaGraphs/MetaGraphsNext.jl).


# A use case with multi layer graphs
`NestedGraphs` provides an interface to handle structures of interacting graph groups.
A common use case might be dealing with multi layer graphs.
You can create a multi layer graph with the syntax already provided:
```jldoctest walkthrough
julia> layer1 = complete_graph(4)
{4, 6} undirected simple Int64 graph

julia> layer2 = barabasi_albert(4, 3; seed=123)
{4, 3} undirected simple Int64 graph

julia> layer3 = SimpleGraph(3)
{3, 0} undirected simple Int64 graph

julia> add_edge!(layer3, 1,2)
true

julia> add_edge!(layer3, 2,3)
true

julia> mlg = NestedGraph([layer1, layer2, layer3])  # now form the interlayer edges
NestedGraph{SimpleGraph{Int64},SimpleGraph{Int64}}({11,11}, 3 subgraphs)

julia> for v in 1:(nv(layer2)-1)
           add_edge!(mlg, NestedEdge(1,v, 2,v))
       end

julia> for v in 1:(nv(layer3)-1)
           add_edge!(mlg, NestedEdge(2,v, 3,v))
       end

julia> add_edge!(mlg, NestedEdge(1,4, 3,3))
true
```
Using [NestedGraphMakie.jl](https://github.com/UniStuttgart-IKR/NestedGraphMakie.jl) you can visualize with `ngraphplot(mlg; multilayer=true, nlabels=repr.(mlg.vmap))`, which outputs:

![Plot using NestedGraphMakie.jl](assets/mlgraph.png)

For more visualizations have a look in the `NestedGraphMakie.jl` repository.

`NestedGraphs.jl` offers some helpful functions which can often be used for multi layer graphs.
You can get the squashed graph by merging all multi layer nodes together using
```jldoctest walkthrough
julia> sg,vm = getmlsquashedgraph(mlg)
(SimpleGraph{Int64}(9, [[2, 3, 4, 5], [1, 3, 4, 5], [1, 2, 4, 5], [1, 2, 3], [1, 2, 3]]), [1, 2, 3, 4, 1, 2, 3, 5, 1, 2, 4])
```
`sg` is a simple graph, which if we plot we will get a graph like if all nodes were in the same layer.
We plot using `GraphMakie.graphplot(sg)`

![Plot using GraphMakie.jl](assets/squashedgraph.png)

We can get all multi layer nodes groupped together with
```jldoctest walkthrough
julia> mlvertices = getmlvertices(mlg; subgraph_view=true)
5-element Vector{Vector{Tuple{Int64, Int64}}}:
 [(1, 1), (2, 1), (3, 1)]
 [(1, 2), (2, 2), (3, 2)]
 [(1, 3), (2, 3)]
 [(1, 4), (3, 3)]
 [(2, 4)]
```
