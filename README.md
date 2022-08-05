# CompositeGraphs

## TODO
- what to do with MetaGraphsNext ?
- tests for NestedGraphsMakie
- employ Term.jl to show info
- produce easy benchmarks
- what functions return

## Docu
each nested graph is a domain

To have synchronized structures, only initialize and then call `NestedGraphs` methods
to add/remove vertices/edges

The first domain is always the "global domain"

Althouygh technically is possible to have Nested{Nested{...}}} 
the API e.g. add_edge! supports only 2-order nested for now