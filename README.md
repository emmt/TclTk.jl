# Julia interface to Tcl/Tk

[![Doc. (stable)](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaInterop.github.io/TclTk.jl/stable)
[![Doc. (devel)](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaInterop.github.io/TclTk.jl/dev)
[![License](http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat)](LICENSE.md)
[![Build Status](https://github.com/JuliaInterop/TclTk.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaInterop/TclTk.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/juliainterop/TclTk.jl/graph/badge.svg?token=MVOdKu5PQF)](https://codecov.io/gh/juliainterop/TclTk.jl)

This package provides an optimized Julia interface to [Tcl/Tk](http://www.tcl-lang.org/).

# Features

* As many Tcl interpreters as needed can be started. A shared interpreter is automatically
  created when needed and serves as the default interpreter for the thread. Just call
  `TclInterp()` to retrieve the shared interpreter of the thread.

* Reading/writing a Tcl variable is as easy as:

  ```julia
  interp = TclInterp()     # get shared interpreter of this thread
  interp[var]             # read Tcl variable value
  interp[var] = val       # set Tcl variable value
  interp[var] = unset     # unset Tcl variable
  delete!(interp, var)    # idem
  ```

  where `interp` is a Tcl interpreter, `var` is the name of the Tcl variable and `val` is
  its value. Variable name can also be given in 2 parts:

  ```julia
  interp[part1,part2]             # read Tcl array value
  interp[part1,part2] = val       # set Tcl array value
  interp[part1,part2] = unset     # unset Tcl array
  delete!(interp, part1, part2)   # idem
  ```

* In Tcl, anything can be equivalently expressed as a string but, for efficiency, everything
  is stored in Tcl objects. Such objects can be manipulated directly in Julia, as instances
  of `TclObj`, and may be converted to Julia values (strings, integers, floats, or vectors
  of these) as needed. By avoiding systematic string conversion, faster communication with
  Tcl/Tk is achieved.

* Tcl scripts can be specified by strings but Tcl commands can also be expressed using a
  syntax which is closer to Julia. For instance, `key => val` pairs are converted to Tcl
  options. Tcl scripts and commands can also be built as efficient lists of Tcl objects.
  Evaluating a script is done by:

  ```julia
  TclTk.eval(script)         # evaluate Tcl script in initial interpreter
  TclTk.eval(interp, script) # evaluate Tcl script with specific interpreter
  interp.eval(script)        # idem
  ```

* A number of wrappers are provided to simplify building and using widgets.

* Julia arrays can be used to set the pixels of Tk images and conversely. A number of
  methods are provided to apply pseudo-colormaps. Temporaries and copies are avoided if
  possible.

* Julia functions may be used as Tk callbacks.


# Alternatives

There exists [another Julia Tk package](http://github.com/JuliaGraphics/Tk.jl) but with
different design choices and some issues I wanted to avoid (for instance, X conflict with
PyPlot when using Gtk backend, Qt backend is OK). This is why I started this project. I
would be very happy if, eventually, the two projects merge.


# Installation

It is easy to install TclTk from the REPL of Julia's package manager<sup>[[pkg]](#pkg)</sup> as follows:

```julia
pkg> add TclTk
```

To check whether `TclTk` package works correctly:

```julia
pkg> test TclTk
```

To update to the last version:

```julia
pkg> update TclTk
pkg> build TclTk
```

and perhaps test again...

If something goes wrong, it may be because you already have an old version of `TclTk`.
Uninstall `TclTk` as follows:

```julia
pkg> rm TclTk
pkg> gc
pkg> add TclTk
```

before re-installing.

<hr>

- <a name="pkg"><sup>[pkg]</sup></a> To switch from [julia
  REPL](https://docs.julialang.org/en/stable/manual/interacting-with-julia/) to the package
  manager REPL, just hit the `]` key and you should get a `... pkg>` prompt. To revert to
  Julia's REPL, hit the `Backspace` key at the `... pkg>` prompt.
