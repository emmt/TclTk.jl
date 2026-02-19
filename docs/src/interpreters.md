# Tcl interpreters

## Managing interpreters

Tcl scripts and commands are executed by a Tcl *interpreter* which is an instance of
[`TclInterp`](@ref) in `TclTk`. An application may have multiple Tcl interpreters but a
given interpreter must only be used in the thread where the interpreter was created
otherwise Tcl would *panic* (thus aborting the program). To prevent this, `TclTk` throws an
exception if such an attempt is made. Furthermore, `TclTk` maintains a cached list of
so-called *shared* interpreters, one for each thread, to used as the default interpreter for
a given tread. These shared interpreter are only created when needed. The shared interpreter
of the calling thread can be retrieved by calling the [`TclInterp`](@ref) constructor with
no argument of with the symbol `:shared`:

```julia-repl
julia> interp = TclInterp()
Tcl interpreter (address: 0x000000002274e130, threadid: 1)

julia> interp = TclInterp(:shared)
Tcl interpreter (address: 0x000000002274e130, threadid: 1)

```

To create a *private* Tcl interpreter, call the [`TclInterp`](@ref) constructor with the
symbol `:private`:

```julia-repl
julia> interp = TclInterp(:private)
Tcl interpreter (address: 0x0000000023461410, threadid: 1)

```

The resources associated with a Tcl interpreter are automatically released when the
[`TclInterp`](@ref) object is no longer referenced (that is garbage collected).


## Evaluation of commands

Execution of a Tcl command may be done in three different ways:

```julia
TclTk.exec(T=TclObj, interp=TclInterp(), args...)
interp.exec(T=TclObj, args...)
interp(T=TclObj, args...)
```

which execute the command specified by `args...` with the Tcl interpreter `interp` and yield
a result of type `T` (a Tcl object by default). Any `key => val` pair in `args...` is
converted in the pair of arguments `-key` and `val` in the command list (note the hyphen
before the key name). Otherwise, each of `args...` is a token of the command. The specific
handling of pairs is very useful for specifying options for [widgets](#widgets).

The execution of a Tcl command stores a result (or an error message) in the interpreter and
returns a status. The behavior of [`TclTk.exec`](@ref), or equivalent, depends on the type
`T` of the expected result:

* If `T` is [`TclStatus`](@ref), the status of the evaluation is returned and the command
  result may be retrieved by calling [`TclTk.getresult`](@ref), by `interp.result(...)`, or
  by `interp[...]`.

* If `T` is `Nothing`, an exception is thrown if the status is not [`TCL_OK`](@ref
  TclStatus) and `nothing` is returned otherwise (i.e., the result of the command is
  ignored).

* Otherwise, an exception is thrown if the status is not [`TCL_OK`](@ref TclStatus) and the
  result of the command is returned as a value of type `T` otherwise.

With [`TclTk.exec`](@ref), the shared interpreter of the thread is used by default.


## Evaluation of scripts

Evaluation of Tcl scripts may be done in two different ways:

```julia
TclTk.eval(T=TclObj, interp=TclInterp(), args...)
interp.eval(T=TclObj, args...)
```

which concatenate `args...` (as done by the [`TclTk.concat`](@ref) function) in the form of
script evaluated by the Tcl interpreter `interp` and yield the result of the script as a
value of type `T` (a Tcl object by default). In case of error, the behavior depends on `T`
as for the execution of a Tcl command described above. With [`TclTk.eval`](@ref), the shared
interpreter of the thread is used by default.

## Indexation

A Tcl interpreter may be indexed to access the result of global variables stored by the
interpreter. Apart from an optional type `T`, the index may have 0, 1, or 2 parts which
correspond to the interpreter's result or to a global variable whose name is specified by
one or two parts:

```julia
interp[]              # yield the interpreter result as a string
interp[T]             # yield the interpreter result as a value of type `T`
interp[name]          # yield the value of the global variable `name`
interp[T,name]        # idem but value is converted to type `T`
interp[part1,part2]   # yield the value of the global variable `part1(part2)`
interp[T,part1,part2] # idem but value is converted to type `T`
```

The `setindex!` method can also be used to set the interpreter result or the value of a
global variable:

```julia
interp[] = result            # set the interpreter result
interp[name] = value         # set the value of the global variable `name`
interp[part1,part2] = value  # set the value of the global variable `part1(part2)`
```

Under the hood, retrieving and setting the interpreter result is done by
[`TclTk.getresult`](@ref) and [`TclTk.setresult!`](@ref) while retrieving and setting the
value of a global variable is done by [`TclTk.getvar`](@ref) and [`TclTk.setvar!`](@ref).

## Properties

A Tcl interpreter, say `interp::TclInterp` has a number of properties:

- `interp.list(args...)` is a shortcut for [`TclTk.list(interp, args...)`](@ref TclTk.list)
  to build a list of Tcl objects, one for each of `args...`. In this context, the
  interpreter is only used to report errors if any, the returned list is not linked to the
  interpreter.

- `interp.concat(args...)` is a shortcut for [`TclTk.concat(interp, args...)`](@ref
  TclTk.concat) to concatenate arguments `args...` to form a list of Tcl objects. In this
  context, the interpreter is only used to report errors if any, the returned list is not
  linked to the interpreter.

- `interp.exec(T=TclObj, args...)` is a shortcut for [`TclTk.exec(T, interp, args...)`](@ref
  TclTk.exec) to execute a Tcl command with the interpreter and return a result of type `T`,
  a Tcl object by default. The first of `args...` is the Tcl command while the remaining
  `args...` are the arguments (or tokens) of the command.

- `interp.eval(T=TclObj, args...)` is a shortcut for [`TclTk.eval(T, interp, args...)`](@ref
  TclTk.eval) to evaluate the concatenation of `args...` as a Tcl script with the
  interpreter and return a result of type `T`, a Tcl object by default.

- `interp.result(T=String)` is a shortcut for [`TclTk.getresult(T, interp)`](@ref
  TclTk.getresult) and the same as `interp[T]` to get the result stored by the interpreter
  as a value of type `T`. Depending on the last thing done by the interpreter, its result
  may be: empty, the result of the last command evaluated by the interpreter, or the error
  message of the last error occurring in the interpreter. See [`TclTk.setresult!`](@ref) for
  setting the result of a Tcl interpreter.

- `interp.threadid` yields the identifier of the thread where the interpreter lives.

- `interp.ptr` yields the pointer to the Tcl interpreter, this is the same as
  `pointer(interrp)`. Using this property to call a C function is *unsafe* (the object must
  be preserved from being garbage collected).
