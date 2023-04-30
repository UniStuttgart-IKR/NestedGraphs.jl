@testset "attributegraphs" begin
    nag = NestedGraph([OAttributeGraph(;vertex_type=String, edge_type=String, graph_type=Dict{Symbol, String}),
                       OAttributeGraph(;vertex_type=String, edge_type=String, graph_type=Dict{Symbol, String})])

    @test all([addvertex!(nag; subgraphs=1) for _ in 1:3])
    @test all([addvertex!(nag; subgraphs=2) for _ in 1:5])

    addedge!(nag, 1, 2)
    addedge!(nag, 2, 1)
    addedge!(nag, 1, 3)
    addedge!(nag, 5, 1)
    addedge!(nag, 1, 4)
    addedge!(nag, 3, 4)
    addedge!(nag, 3, 5)
    addedge!(nag, 7, 8)
    @test ne(nag) == 7
    @test nv(nag) == 8

    addgraphattr!(nag, :ena, "ena")
    addgraphattr!(nag, :dio, "dio")
    @test_throws MethodError addgraphattr!(nag, "tria", "tria")
    @test graph_attr(nag) == Dict{Symbol,String}(:ena => "ena", :dio => "dio")

    @test all(ismissing.(vertex_attr(nag)))
    addvertexattr!(nag, 3, "tria-stays")
    addvertexattr!(nag, 4, "tessera-is-deleted")
    addvertexattr!(nag, 5, "pente-becomes-tessera")
    addvertexattr!(nag, 6, "eksi-becomes-pente")
    @test ismissing.(vertex_attr(nag)) == [true, true, false, false, false, false, true ,true]
    @test collect(skipmissing(vertex_attr(nag))) == ["tria-stays","tessera-is-deleted","pente-becomes-tessera","eksi-becomes-pente"]

    addedgeattr!(nag, 1, 2, "1.2-deleted")
    addedgeattr!(nag, 1, 3, "1.3-stays")
    addedgeattr!(nag, 1, 4, "1.4-deleted")
    addedgeattr!(nag, 3, 4, "3.4-deleted")
    addedgeattr!(nag, 3, 5, "3.5-tobecome-3.4")
    addedgeattr!(nag, 2, 5, "nolinkshouldnotappear")
    addedgeattr!(nag, 7, 8, "remaintogrv2")

    @test edge_attr(nag) == Dict{Tuple{Int,Int,Int}, String}((1,2,1)=>"1.2-deleted", (1,3,1) =>"1.3-stays", (1,4,1)=>"1.4-deleted", (3,4,1)=>"3.4-deleted", (3,5,1)=>"3.5-tobecome-3.4", (7,8,1)=>"remaintogrv2")

    remedge!(nag, 1, 2)
    @test edge_attr(nag) == Dict{Tuple{Int,Int,Int}, String}((1,3,1) =>"1.3-stays", (1,4,1)=>"1.4-deleted", (3,4,1)=>"3.4-deleted", (3,5,1)=>"3.5-tobecome-3.4", (7,8,1)=>"remaintogrv2")

    remvertex!(nag, 4)
    @test ismissing.(vertex_attr(nag)) == [true, true, false, false, false, true, true]
    @test collect(skipmissing(vertex_attr(nag))) == ["tria-stays","pente-becomes-tessera","eksi-becomes-pente"]
    @test nv(nag) == length(vertex_attr(nag)) == 7
    @test edge_attr(nag) == Dict{Tuple{Int,Int,Int}, String}((1,3,1) =>"1.3-stays", (3,4,1)=>"3.5-tobecome-3.4", (6,7,1)=>"remaintogrv2")

    for ((s,d,m),edgatval) in edge_attr(nag)
        if NestedGraphs.issamesubgraph(nag, s, d)
            @test edgatval == edge_attr( nag.grv[nag.vmap[s][1]])[nag.vmap[s][2],nag.vmap[d][2], m]
        end
    end
    for (v, verdat) in enumerate(vertex_attr(nag))
        let nesteddata = vertex_attr( nag.grv[nag.vmap[v][1]] )[nag.vmap[v][2]]
            @test ismissing(verdat) && ismissing(nesteddata) || nesteddata == verdat
        end
    end
end
