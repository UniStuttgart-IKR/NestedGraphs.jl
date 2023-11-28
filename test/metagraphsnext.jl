@testset "metagraphsnext.jl" begin
    g1 = getdefaultmetagraphnext()
    g2 = getdefaultmetagraphnext()
    g3 = getdefaultmetagraphnext()
    g4 = getdefaultmetagraphnext()

    foreach(1:3) do i
        add_vertex!(g1, Symbol("v",i), i*20)
        add_vertex!(g2, Symbol("v",i), i*200)
        add_vertex!(g3, Symbol("v",i), i*2000)
        add_vertex!(g4, Symbol("v",i), i*20000)
    end

    counter = 1
    for i in MGN.labels(g1)
        for j in MGN.labels(g1)
            i == j && continue
            add_edge!(g1, i, j, counter*0.2)
            add_edge!(g2, i, j, counter*0.02)
            add_edge!(g3, i, j, counter*0.002)
            add_edge!(g4, i, j, counter*0.0002)
            counter += 1
        end
    end

    eds = [((1,1), (2,1)), ((3,2), (2,1)), ((3,3),(2,3)), ((1,1),(4,1))]
    ng = NestedGraph([g1,g2,g3,g4], eds, both_ways=true)

    @test length(ng.neds) == 2*length(NestedEdge.(eds))
    for ned in eds
        @test NestedEdge(ned) in ng.neds && reverse(NestedEdge(ned)) in ng.neds
    end

    for (i,gr) in enumerate([g1, g2, g3, g4])
        for v in vertices(g1)
            @test MG.props(gr, v) === MG.props(ng.grv[i], v)
        end
        for e in edges(g1)
            @test MG.props(gr, e) === MG.props(ng.grv[i], e)
        end
    end

    #change all properties and test again equality
    [MG.set_prop!(g1, e, :el, i*0.1) for (i,e) in enumerate(edges(g1))]
    [MG.set_prop!(g2, e, :el, i*0.01) for (i,e) in enumerate(edges(g2))]
    [MG.set_prop!(g3, e, :el, i*0.001) for (i,e) in enumerate(edges(g3))]

    [MG.set_prop!(g1, v, :sz, v*10) for v in vertices(g1)]
    [MG.set_prop!(g2, v, :sz, v*100) for v in vertices(g2)]
    [MG.set_prop!(g3, v, :sz, v*1000) for v in vertices(g3)]

    for (i,gr) in enumerate([g1, g2, g3, g4])
        for v in vertices(g1)
            @test MG.props(gr, v) === MG.props(ng.grv[i], v)
        end
        for e in edges(g1)
            @test MG.props(gr, e) === MG.props(ng.grv[i], e)
        end
    end

    # rerun all tests from simple graphs
    ng1 = NestedGraph([g1,g2], [((1,1), (2,1))])
    ng2 = NestedGraph([g3,g4], [((1,2), (2,2)), ((1,3), (2,3))])
    ngm = NestedGraph([ng1, ng2], [((1,1),(2,1)), ((1,5),(2,2))], both_ways=true)

    @test @inferred(NestedGraph([ng1, ng2])) isa Any

    basic_test(g1, g2, g3, g4, ng, ng1, ng2, ngm)
end
