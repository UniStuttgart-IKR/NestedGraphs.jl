<div align="center"> 
<img src="images/NestedGraphs.jl.svg" alt="NestedGraphs.jl" width="30%"></img>

# NestedGraphs.jl
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://UniStuttgart-IKR.github.io/NestedGraphs.jl/dev)
[![codecov.io](http://codecov.io/github/UniStuttgart-IKR/NestedGraphs.jl/coverage.svg?branch=main)](http://codecov.io/github/UniStuttgart-IKR/NestedGraphs.jl?branch=main)

</div>



*A package to handle nested graphs.*

> `NestedGraphs.jl` requires Julia v1.9+

`NestedGraphs.jl` is a young project that aims at easy and type-stable graph analysis for nested graphs.
This package is in an early development stage and might break often.

### Installing 
```julia
julia> import Pkg
julia> Pkg.add("NestedGraphs")
julia> using NestedGraphs
```

### Developing and testing
Setup the test environment using [Run.jl](https://github.com/tkf/Run.jl).
Start julia inside the NestedGraphs dev-ed directory and then:
```julia
julia> using Run
julia> Run.prepare_test() # instantiates and precompiles `./test/`
julia> Run.test()         # test package
```
