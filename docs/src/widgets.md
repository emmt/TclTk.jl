# Widgets

## Widget creation

A top-level or a menu widget are created by:

```julia
top = TkToplevel(interp=TclInterp(), path, option => value, ...)
menu = TkMenu(interp=TclInterp(), path, option => value, ...)
```

where `interp` is the interpreter where to create the widget (the shared interpreter of the
thread by default), `path` is the widget path like `".top"` or `".menu"` (it must start with
a dot and have no other dots) and `option => value, ...` denotes any number of settings with
`option` an option name (a string or a symbol without a leading hyphen) an `value` its
value. The `path` argument is optional, if omitted an widget path is automatically generated
in the form `".$(pfx)$(num)"` where `pfx` is a short prefix specific to the widget class and
`num` is a unique number.

For example:

```julia
julia> top = TkToplevel(:relief => :sunken, :borderwidth => 5, :background => :cyan)
TkToplevel(".top3")

```

Note that symbols like `:relief` and `:sunken` can also be specified as literal strings (or
as Tcl objects but this is less common).

Other widgets have a parent (a top-level widget, a frame, etc.) which must be provided to
the constructor. For example, a label is created by something like:

```julia
lab = TkLabel(parent, child, option => value, ...)
```

where `child` is the path of the widget relative to its parent, it must have no dots. The relative path is optional and is automatically generated if
omitted.

The path of the widget is the concatenation of its parent path and the widget relative path
with a dot separator. The widget path is given by the property `w.path` for a widget `w`.
The widget path is unique for a given interpreter, if a widget constructor is called with a
path of an existing widget, a Julia object wrapping the same Tk widget is returned. However,
the constructor must correspond to the class of the existing widget. To relax this, a widget
instance can be built for an existing widget by calling the abstract constructor `TkWidget`:

```julia
w = TkWidget(interp=TclInterp(), path)
w = TkWidget(interp=TclInterp(), parent, child)
```

The latter case is equivalent to have `path = "$(parent).$(child)"` in the former case.


## Widget configuration

Widgets can be indexed by configuration option (symbolic) name:

For our example, we create a top-level window `top` with an embedded button `btn` widget as
follows:

```julia
using TclTk
tk_start()
top = TkToplevel()
btn = TkButton(top, :text => "Please push me...", :command => "puts {Button pushed!}")
TclTk.pack(Nothing, btn, :side => :top, :padx => 70, :pady => 5)
```

Configuration options of `btn` can be queried by one of the following:

```julia
julia> TclTk.eval("$btn cget -text") # as in a Tcl script
TclObj("Please push me...")

julia> TclTk.exec(btn, :cget, "-text") # each argument is a token
TclObj("Please push me...")

julia> btn(:cget, "-text") # shortcut for the above example
TclObj("Please push me...")

julia> TclTk.cget(btn, :text) # no needs to hyphen
TclObj("Please push me...")

julia> btn[:text] # no needs to hyphen
TclObj("Please push me...")

```

As can be seen all these statements yield a Tcl object whose content is the value of the
`-text`. Which syntax is preferred is a matter of taste. Beware that with the above
`TclTk.eval(...)` example, the string interpolation of `$btn` may yield some text that can be
interpreted by Tcl as several tokens. Something avoided by `TclTk.exec` for which each
argument is a token (except pairs that make 2 tokens: an option name and a value).

An optional Julia type may be specified to convert the value of the Tcl object but this is
not supported by all preceding examples:

```julia
julia> TclTk.eval(String, "$btn cget -text") # as in a Tcl script
"Please push me..."

julia> TclTk.exec(String, btn, :cget, "-text") # each argument is a token
"Please push me..."

julia> btn(String, :cget, "-text") # shortcut for the above example
"Please push me..."

julia> TclTk.cget(String, btn, :text) # no needs to hyphen
"Please push me..."

julia> String(btn[:text])
"Please push me..."

julia> btn[String, :text]
"Please push me..."

julia> btn[:text, String]
"Please push me..."

julia> btn[:text => String]
"Please push me..."

```
