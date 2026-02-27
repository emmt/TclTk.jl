# Lists of Tcl objects

## Building lists

There are two functions to create lists of Tcl objects out of their arguments: [`TclTk.list`](@ref)
and [`TclTk.concat`](@ref). For example:

```julia-repl
julia> x = TclTk.list("a {b c}", 1, π, (-1, 2, 4))
TclObj(("a {b c}", 1, 3.141592653589793, (-1, 2, 4,),))

julia> y = TclTk.concat("a {b c}", 1, π, (-1, 2, 4))
TclObj(("a", "b c", "1", "3.141592653589793", -1, 2, 4,))

```

As can be seen in the above examples, [`TclTk.list`](@ref) follows the behavior of the Tcl
`list` command and each of `args..` is an element of the returned list, while
[`TclTk.concat`](@ref) follows the behavior of the Tcl `concat` command and concatenates the
elements of the arguments `args...` each being considered as a list.


## Operations on lists

Tcl list objects implement the abstract vector and iterator APIs:

```julia-repl
julia> length(x)
4

julia> length(y)
7

julia> x[1] # same as first(x)
TclObj("a {b c}")

julia> first(y) # same as y[1]
TclObj("a")

julia> x[end] # same as last(x)
TclObj((-1, 2, 4,))

julia> y[2:end-2]
TclObj(("b c", "1", "3.141592653589793", -1,))

```

Indexing a Tcl list object with a scalar index can also take a type `T` to convert the
retrieved item to that type:

```julia
list[i, T]   # yields i-th item of list converted to type T
list[T, i]   # idem
list[i => T] # idem
```

This has two advantages: type-stability (the type of the result is inferable) and, compared
to `convert(T, list[i])`, speed (this avoids allocating a mutable `TclObj` instance).

To follow Tcl behavior, out of range indices yield `missing` when indexing a list with a
scalar index and are simply ignored when indexing a list with an index range or a vector of
indices:

```julia-repl
julia> x[0]
missing

julia> y[end+1]
missing

julia> y[-1:3] # out of bound indices -1 and 0 are ignored
TclObj(("a", "b c", "1",))

```

A list may be indexed by a vector of Booleans (of same length as the list) to extract a
sub-list:

```julia-repl
julia> x[length.(x) .== 1]
TclObj((1, 3.141592653589793,))

```

Base methods `push!` and `append!` add elements to the end of a list, the former performs as
[`TclTk.list`](@ref) and the latter performs as [`TclTk.concat`](@ref):

```julia-repl
julia> push!(TclTk.list("a"), "b c")
TclObj(("a", "b c",))

julia> append!(TclTk.list("a"), "b c")
TclObj(("a", "b", "c",))

```

Base method `delete!` deletes element(s) from a list:

```julia-repl
julia> z = TclTk.list("a {b c}", 1, π, (-1, 2, 4))
TclObj(("a {b c}", 1, 3.141592653589793, (-1, 2, 4,),))

julia> delete!(z, 3)
TclObj(("a {b c}", 1, (-1, 2, 4,),))

```


## Tcl objects as lists

When its content can be converted into a proper list, any Tcl object can be used as a list,
that is to say indexed, iterated, etc. In fact, any successful operation on a Tcl object
that considers the object as a list convert the internal type of the object into a list
type. This is illustrated by the following examples:

```julia-repl
julia> z = TclObj("a {b c} 3 $(sqrt(π))")
TclObj("a {b c} 3 1.7724538509055159")

julia> z.type
:string

julia> z[2]
TclObj("b c")

julia> z.type
:list

julia> z[end-1]
TclObj("3")

julia> z[end+1]
missing

```

The empty string `""` is equivalent to an empty list:

```julia-repl
julia> q = TclObj("")
TclObj("")

julia> length(q)
0

```
