
@testset "simple.jl" begin
    @test @inferred(NestedGraph(SimpleGraph)) isa Any
    @test @inferred(NestedGraph(SimpleGraph)) isa Any
    @test @inferred(NestedGraph{Int, SimpleGraph{Int}, Union{NestedGraph, SimpleGraph{Int}}}()) isa Any
    @test @inferred(NestedGraph{Int, SimpleGraph{Int}, Union{NestedGraph{Int, SimpleGraph{Int}, Union{NestedGraph, SimpleGraph{Int}}}, SimpleGraph{Int}}}()) isa Any
    
    g1 = complete_graph(3)
    g2 = complete_graph(3)
    g3 = complete_graph(3)
    g4 = complete_graph(3)
    eds = [((1,1), (2,1)), ((3,2), (2,1)), ((3,3),(2,3)), ((1,1),(4,1))]
    ng = NestedGraph([g1,g2,g3,g4], eds, both_ways=true)
    ng1 = NestedGraph([g1,g2], [((1,1), (2,1))])
    ng2 = NestedGraph([g3,g4], [((1,2), (2,2)), ((1,3), (2,3))])
    ngm = NestedGraph([ng1, ng2], [((1,1),(2,1)), ((1,5),(2,2))], both_ways=true)
    
    counter = 1
    for i in 1:2, j in 1:2, k in 1:3
        @test unroll_vertex(ngm, counter) == [i,j,k]
        @test roll_vertex(ngm, [i,j,k]) == counter
        counter += 1
    end
    
    basic_test(g1, g2, g3, g4, ng, ng1, ng2, ngm)

    # another graph
    nsg = NestedGraph([SimpleGraph(3), SimpleGraph(3)])
    add_edge!(nsg, 1, 3)
    add_edge!(nsg, 1, 3)
    add_edge!(nsg, 1, 6)
    add_edge!(nsg, 1, 6)
    @test length(nsg.neds) == 1
    @test length(edges(nsg)) == 2
end

@testset "lesslesssimple.jl" begin
    g1 = complete_graph(3)
    g2 = complete_graph(3)
    g3 = complete_graph(3)
    g4 = complete_graph(4)
    eds = [((1,1), (2,1)), ((3,2), (2,1)), ((3,3),(2,3)), ((1,1),(4,1))]
    ng = NestedGraph([g1,g2,g3,g4], eds, both_ways=true)
    ng1 = NestedGraph([g1,g2], [((1,1), (2,1))])
    ng2 = NestedGraph([g3,g4], [((1,2), (2,2)), ((1,3), (2,3))])
    ngm = NestedGraph([ng1, ng2], [((1,1),(2,1)), ((1,5),(2,2))], both_ways=true)


    @test NestedGraphs.getallsubvertices(ngm) == [ [1, 2, 3, 4, 5, 6],
                                                  [1, 2, 3],
                                                  [4, 5, 6],
                                                  [7, 8, 9, 10, 11, 12, 13],
                                                  [7, 8, 9],
                                                  [10, 11, 12, 13]]

    @test NestedGraphs.getallsubgraphpaths(ngm; startingpath=[1]) ==  [[1,1],[1,2]]

    @test NestedGraphs.gettotalsubgraphs(ngm) == 6
end
