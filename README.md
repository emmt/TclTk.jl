# Julia interface to Tcl/Tk

[![Docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaInterop.github.io/TclTk.jl/)
[![License](http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat)](LICENSE.md)
[![Build Status](https://github.com/JuliaInterop/TclTk.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaInterop/TclTk.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/juliainterop/TclTk.jl/graph/badge.svg?token=MVOdKu5PQF)](https://codecov.io/gh/juliainterop/TclTk.jl)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

This package provides an optimized Julia interface to [Tcl/Tk](http://www.tcl-lang.org/).
The [documentation is available on-line](https://JuliaInterop.github.io/TclTk.jl/) but a few
examples are given below to whet your appetite.

## Tcl scripts and commands

The traditional *"Hello world!"* example:

``` julia-repl
julia> TclTk.eval(Nothing, "puts {Hello world!}")
Hello world!
```

which shows how to evaluate a Tcl script. Here, `Nothing` indicates that we are not
interested in the result of the script. Another type can be specified if the result is of
interest and has a known type:

``` julia-repl
julia> TclTk.eval(Float64, "expr {4*atan(1)}")
3.141592653589793
```

If the leading type argument is omitted, a Tcl object is returned which can be reused or
converted later:

``` julia-repl
julia> x = TclTk.eval("format \"%s/data-%06d.bin\" \"/tmp\" 123")
TclObj("/tmp/data-000123.bin")

julia> String(x) # `string(x)` and `convert(String, x)` work as well
"/tmp/data-000123.bin"
```

Spaces and braces are special characters in Tcl and may have to be properly escaped in
scripts, perhaps with the help of `TclTk.escape_string`. A better solution, if the script is
a single Tcl command, is to call `TclTk.exec` which assumes that each argument (after an
optional leading type) is a single Tcl token:

``` julia-repl
julia> msg = "- - } Hello world! { - -"
"- -} Hello world! { - -"

julia> x = TclTk.exec(Nothing, :puts, msg)
- - } Hello world! { - -

julia> x = TclTk.exec(String, "format", "%s/%s/data-%06d.bin", ENV["HOME"], "tmp", 123)
"/home/eric/tmp/data-000123.bin"
```

## Widgets and images

Below is a simple example to show an image in a Tk top-level window:

``` julia-repl
julia> using TclTk, TestImages

julia> img = testimage("mandrill"); # read some image data

julia> tk_start() # make sure Tk package is loaded and event loop is running
Tcl interpreter (address: 0x0000000017dc33e0, threadid: 1)

julia> top = TkToplevel(:background => "darkseagreen")
TkToplevel(".top1")

julia> TclTk.exec(Nothing, :wm, :title, top, "A Nice Image")

julia> lab = TkLabel(top, :image => TkPhoto(permutedims(img)), :cursor => :target)
TkLabel(".top1.lab1")

julia> TclTk.pack(Nothing, lab, :side => :top, :padx => 20, :pady => 30)
```

The different stages are:

- Load some image data as a Julia array.

- Call `tk_start()` to make sure that Tk package is loaded and the event loop is running.

- Create a top-level window `top` with a given background color.

- Call window manager `wm` command to set the title of the top-level window. When specifying
  tokens or options in commands symbols and strings are equivalent, they can even be mixed.
  Here or above, `:wm`, `:title`, or `:background` could have been specified as `"wm"`,
  `"title"`, or `"background"`, while ` "darkseagreen"` could have been specified as
  `:darkseagreen`. The choice is purely a matter of style.

- Create a widget, here a label `lab`, whose parent is `top` to display the image.

- Call the `pack` geometry manager to specify how to display the `lab` widget in its parent
  (leading `Nothing` argument is because we are not interested in the result of this
  command).

It may be noticed that, following Tk conventions, the width and height of an image are its
respective first and second dimensions. The images provided by the `TestImages` have a
different convention and we call `permutedims(img)` to cope with that. Using the apostrophe,
i.e. `img'`, would also do the job.

A Tk widget instance can be called to perform widget actions such as (re-)configuring some
options. For example, let us show the frame of the image with a *sunken* relief:

``` julia-repl
julia> lab(Nothing, :config,  :borderwidth => 5, :relief => :sunken)

```

The change should be immediate as Tk widgets apply their configuration dynamically.


## Features

* As many Tcl interpreters as needed can be started. A shared interpreter is automatically
  created when needed and serves as the default interpreter for the thread. Just call
  `TclInterp()` to retrieve the shared interpreter of the thread.

* Reading/writing a Tcl variable is as easy as:

  ```julia
  interp = TclInterp()    # get shared interpreter of this thread
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


## Alternatives

There exists [another Julia Tk package](http://github.com/JuliaGraphics/Tk.jl) but with
different design choices and some issues I wanted to avoid (for instance, X conflict with
PyPlot when using Gtk backend, Qt backend is OK). This is why I started this project. I
would be very happy if, eventually, the two projects merge.


## Installation

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
