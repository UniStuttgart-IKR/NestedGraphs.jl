@testset "multilayer" begin
    layer1 = complete_graph(4)
    layer2 = barabasi_albert(4, 3; seed=123)
    layer3 = SimpleGraph(3)
    add_edge!(layer3, 1,2)
    add_edge!(layer3, 2,3)

    mlg = NestedGraph([layer1, layer2, layer3])

    for v in 1:(nv(layer2)-1)
        add_edge!(mlg, NestedEdge(1,v, 2,v))
    end
    for v in 1:(nv(layer3)-1)
        add_edge!(mlg, NestedEdge(2,v, 3,v))
    end
    add_edge!(mlg, NestedEdge(1,4, 3,3))

    sg,vm = getmlsquashedgraph(mlg)
    @test nv(sg) == 5
    @test ne(sg) == 9

    mlvertices = getmlvertices(mlg)
    @test mlvertices == [[1, 5, 9], [2, 6, 10], [3, 7], [4, 11], [8]]

    mlvertices_sgv = getmlvertices(mlg; subgraph_view=true)
    @show mlvertices_sgv
    @test mlvertices_sgv == [[(1, 1), (2, 1), (3, 1)], [(1, 2), (2, 2), (3, 2)], [(1, 3), (2, 3)], [(1, 4), (3, 3)], [(2, 4)]]

    vmstart = [findfirst(mlverts -> v ∈ mlverts, mlvertices) for v in vertices(mlg)]
    @test vmstart == vm #this works only if I pass sqvertices are taked from `getmlvertices`
end
