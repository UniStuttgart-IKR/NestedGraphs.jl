using Graphs, NestedGraphs
using MetaGraphsNext
using Test

include("testutils.jl")

@testset "metagraphsnext.jl" begin
    
    g1 = MetaGraphsNext.MetaGraph(Graph();label_type=Symbol,vertex_data_type=String,edge_data_type=Int,graph_data=nothing,weight_function=identity,);
    g2 = MetaGraphsNext.MetaGraph(Graph();label_type=Symbol,vertex_data_type=String,edge_data_type=Int,graph_data=nothing,weight_function=identity,);
    g3 = MetaGraphsNext.MetaGraph(Graph();label_type=Symbol,vertex_data_type=String,edge_data_type=Int,graph_data=nothing,weight_function=identity,);
    g4 = MetaGraphsNext.MetaGraph(Graph();label_type=Symbol,vertex_data_type=String,edge_data_type=Int,graph_data=nothing,weight_function=identity,);

    mgn = [g1, g2, g3, g4]

    for i in mgn add_vertex!(i, :a, "a") end
    for i in mgn add_vertex!(i, :b, "b") end
    for i in mgn add_vertex!(i, :c, "c") end

    for i in mgn add_edge!(i, :a, :b, 10) end
    for i in mgn add_edge!(i, :b, :c, 100) end
    for i in mgn add_edge!(i, :c, :a, 1000) end

    eds = [((1,1), (2,1)), ((3,2), (2,1)), ((3,3),(2,3)), ((1,1),(4,1))]
    ng = NestedGraph([g1,g2,g3,g4], eds, both_ways=true)

    @test length(ng.neds) == 2*length(NestedEdge.(eds))

    for ned in eds
        @test NestedEdge(ned) in ng.neds && reverse(NestedEdge(ned)) in ng.neds
    end

    for (i,gr) in enumerate([g1, g2, g3, g4])
        for v in vertices(g1)
            @test label_for(gr, v) === label_for(ng.grv[i], v)
        end
        for e in vertices(g1)
            for f in vertices(g1)
                if e!= f
                    @test getindex(gr, label_for(gr, e), label_for(gr, f)) ===  getindex(ng.grv[i], label_for(gr, e), label_for(gr, f))
                end
            end
        end


    end

#change all properties and test again equality

for i in mgn set_data!(i, :a, "d") end
for i in mgn set_data!(i, :b, "e") end
for i in mgn set_data!(i, :c, "f") end

for i in mgn set_data!(i, :a, :b, 1000) end
for i in mgn set_data!(i, :b, :c, 100) end
for i in mgn set_data!(i, :c, :a, 10) end

for (i,gr) in enumerate([g1, g2, g3, g4])
    for v in vertices(g1)
        @test label_for(gr, v) === label_for(ng.grv[i], v)
    end
    for e in vertices(g1)
        for f in vertices(g1)
            if e!= f
                @test getindex(gr, label_for(gr, e), label_for(gr, f)) ===  getindex(ng.grv[i], label_for(gr, e), label_for(gr, f))
            end
        end
    end

end

 # rerun all tests from simple graphs
    ng1 = NestedGraph([g1,g2])
    ng2 = NestedGraph([g3,g4])
    ngm = NestedGraph([ng1, ng2])

    @test @inferred(NestedGraph([ng1, ng2])) isa Any
        
    basic_test(g1, g2, g3, g4, ng, ng1, ng2, ngm)
end

