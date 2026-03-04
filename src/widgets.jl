#
# widgets.jl -
#
# Implement Tk (and TTk) widgets
#

"""
    @TkWidget type class command prefix

Define structure `type` for widget `class` based on Tk `command` and using `prefix` for
automatically defined widget names. If `prefix` starts with a dot, a top-level widget is
assumed. `class` is the class name as given by the Tk command `winfo class \$w` and is
needed to uniquely identify Julia widget type given its Tk class. For now, `command` and
`prefix` must be string literals.

"""
macro TkWidget(structname, class, command, prefix)

    type = esc(structname) # constructor must be in the caller's module
    class isa Union{Symbol,String} || error("`class` must be a symbol or a string literal")
    class isa String || (class = String(class)::String)
    command isa String || error("`command` must be a string literal")
    prefix isa String || error("`prefix` must be a string literal")

    quote
        # Define structure an inner constructor.
        struct $type <: TkWidget
            interp::TclInterp
            path::TclObj # Tk window path and Tcl widget command
            $type(interp::TclInterp, path::Verified{<:Name}) = new(interp, path.value)
        end

        # Build instance.
        $type(args...; kwds...) = build($type, $class, $command, $prefix, args...; kwds...)

        # Make the widget callable. FIXME make this at the TkWidget level
        (w::$type)(args...; kwds...) = exec(w, args...; kwds...)

        # Register widget class.
        register_widget_class($class, $type)
    end
end

const widget_classes = Dict{String,Type{<:TkWidget}}()

function register_widget_class(class::String, ::Type{T}) where {T<:TkWidget}
    if haskey(widget_classes, class)
        S = widget_classes[class]
        isequal(S, T) || error("attempt to register widget class `$class` for type `$T` ",
                               "while already registered for type `$S`")
    else
        widget_classes[class] = T
    end
    return nothing
end

function widget_constructor_from_path(interp::TclInterp, path::Name)
    return widget_constructor_from_class(winfo_class(interp, path))
end

function widget_constructor_from_class(class::Name)
    # In the database of widget classes, the class is a string.
    class isa AbstractString || (class = String(class)::String)
    constructor = get(widget_classes, class, nothing)
    isnothing(constructor) && argument_error("unregistered widget class \"$class\"")
    return constructor
end

# Top-level widgets.
@TkWidget TkToplevel      Toplevel      "::toplevel"          ".top"
@TkWidget TkMenu          Menu          "::menu"              ".mnu"

# Classic Tk widgets.
@TkWidget TkButton        Button        "::button"            "btn"
@TkWidget TkCanvas        Canvas        "::canvas"            "cnv"
@TkWidget TkCheckbutton   Checkbutton   "::checkbutton"       "cbt"
@TkWidget TkEntry         Entry         "::entry"             "ent"
@TkWidget TkFrame         Frame         "::frame"             "frm"
@TkWidget TkLabel         Label         "::label"             "lab"
@TkWidget TkLabelframe    Labelframe    "::labelframe"        "lfr"
@TkWidget TkListbox       Listbox       "::listbox"           "lbx"
@TkWidget TkMenubutton    Menubutton    "::menubutton"        "mbt"
@TkWidget TkMessage       Message       "::message"           "msg"
@TkWidget TkPanedwindow   Panedwindow   "::panedwindow"       "pwn"
@TkWidget TkRadiobutton   Radiobutton   "::radiobutton"       "rbt"
@TkWidget TkScale         Scale         "::scale"             "scl"
@TkWidget TkScrollbar     Scrollbar     "::scrollbar"         "sbr"
@TkWidget TkSpinbox       Spinbox       "::spinbox"           "sbx"
@TkWidget TkText          Text          "::text"              "txt"

# Themed Tk widgets.
@TkWidget TtkButton       TButton       "::ttk::button"       "btn"
@TkWidget TtkCheckbutton  TCheckbutton  "::ttk::checkbutton"  "cbt"
@TkWidget TtkCombobox     TCombobox     "::ttk::combobox"     "cbx"
@TkWidget TtkEntry        TEntry        "::ttk::entry"        "ent"
@TkWidget TtkFrame        TFrame        "::ttk::frame"        "frm"
@TkWidget TtkLabel        TLabel        "::ttk::label"        "lab"
@TkWidget TtkLabelframe   TLabelframe   "::ttk::labelframe"   "lfr"
@TkWidget TtkMenubutton   TMenubutton   "::ttk::menubutton"   "mbt"
@TkWidget TtkNotebook     TNotebook     "::ttk::notebook"     "nbk"
@TkWidget TtkPanedwindow  TPanedwindow  "::ttk::panedwindow"  "pwn"
@TkWidget TtkProgressbar  TProgressbar  "::ttk::progressbar"  "pgb"
@TkWidget TtkRadiobutton  TRadiobutton  "::ttk::radiobutton"  "rbt"
@TkWidget TtkScale        TScale        "::ttk::scale"        "scl"
@TkWidget TtkScrollbar    TScrollbar    "::ttk::scrollbar"    "sbr"
@TkWidget TtkSeparator    TSeparator    "::ttk::separator"    "sep"
@TkWidget TtkSizegrip     TSizegrip     "::ttk::sizegrip"     "szg"
@TkWidget TtkSpinbox      TSpinbox      "::ttk::spinbox"      "sbx"
@TkWidget TtkTreeview     Treeview      "::ttk::treeview"     "trv"

# Window "." has a special class in Tk.
register_widget_class("Tk", TkToplevel)

"""
    TkWidget(interp=TclInterp(), path)

Return a widget for the given Tk window `path` in interpreter `interp`. The type of the
widget is inferred from the class of the Tk window.

"""
TkWidget(path::Name, interp::TclInterp = TclInterp()) = TkWidget(interp, path)
function TkWidget(interp::TclInterp, path::Name)
    # The following requires that `path` be a Tcl object or a string, not a symbol.
    (path isa Union{AbstractString,TclObj}) || (path = String(path)::String)
    winfo_exists(interp, path) || argument_error(
        "\"$path\" is not the path of an existing Tk widget")
    # Now we can get the widget class and hence find its registered constructor.
    T = widget_constructor_from_path(interp, path)
    return T(interp, Verified(path))
end

winfo_exists(w::TkWidget) = winfo_exists(w.interp, w.path)
winfo_exists(interp::TclInterp, path::Name) = interp.exec(Bool, :winfo, :exists, path)

winfo_parent(w::TkWidget) = winfo_parent(w.interp, w.path)
winfo_parent(interp::TclInterp, path::Name) = interp.exec(:winfo, :parent, path)

winfo_name(w::TkWidget) = winfo_name(w.interp, w.path)
winfo_name(interp::TclInterp, path::Name) = interp.exec(:winfo, :name, path)

winfo_class(w::TkWidget) = winfo_class(w.interp, w.path)
function winfo_class(interp::TclInterp, path::Name)
    # `winfo class .` yields the name of the application which is not what we want. So, we
    # must specifically consider the case of the "." window.
    return winfo_isroot(path) ? TclObj(:Toplevel) : interp.exec(:winfo, :class, path)
    # TODO for Tix widgets, we may instead use: class = string(interp(path, :configure, "-class")[4])
end

"""
    TclTk.Impl.winfo_isroot(w) -> bool

Return whether `w` is the Tk root widget of window path.

This is to cope with that, in many situations, the case of the "." window must be considered
specifically. For example, `winfo parent .` yields an empty result while `winfo class .`
yields the name of the application.

"""
winfo_isroot(path::Symbol) = (path == :(.))
winfo_isroot(path::Name) = path == "."
winfo_isroot(w::TkToplevel) = winfo_isroot(w.path)
winfo_isroot(w::TkWidget) = false

# Supply interpreter.
function build(::Type{T}, class::String, command::String, prefix::String,
               pairs::Pair...; kwds...) where {T<:TkWidget}
    return build(T, class, command, prefix, TclInterp(), pairs...; kwds...)
end
function build(::Type{T}, class::String, command::String, prefix::String,
               path::Name, pairs::Pair...; kwds...) where {T<:TkWidget}
    return build(T, class, command, prefix, TclInterp(), path, pairs...; kwds...)
end

# Build a top-level widget with automatic name.
function build(::Type{T}, class::String, command::String, prefix::String,
               interp::TclInterp, pairs::Pair...; kwds...) where {T<:TkWidget}
    startswith(prefix, '.') || argument_error("missing parent widget")
    tk_start() # make sure Tk has been loaded
    path = interp(command, widget_auto_path(interp, "", prefix), pairs...; kwds...)
    return T(interp, Verified(path))
end

# Build a widget given its full path.
function build(::Type{T}, class::String, command::String, prefix::String,
               interp::TclInterp, path::Name, pairs::Pair...; kwds...) where {T<:TkWidget}
    # If top-level widget, make sure Tk has been loaded.
    startswith(prefix, '.') && tk_start()
    if winfo_exists(interp, path)
        # Re-use existing widget.
        trueclass = winfo_class(interp, path)
        class == trueclass || argument_error(
            "attempt to wrap a widget with class `", class, "` on top of existing widget \"",
            path, "\" whose class is `", trueclass, "`")
        w = T(interp, Verified(path))
        (isempty(pairs) && isempty(kwds)) || w.configure(pairs...; kwds...)
        return w
    else
        # Create a new widget.
        path = interp(command, path, pairs...; kwds...)
        return T(interp, Verified(path))
    end
end

# Build a child widget given its parent and its name.
function build(::Type{T}, class::String, command::String, prefix::String,
               parent::TkWidget, name::Name, pairs::Pair...; kwds...) where {T<:TkWidget}
    name isa String || (name = String(name)::String)
    isempty(match(r"^[A-Z_a-z][0-9A-Z_a-z]*$", name)) && argument_error(
        "invalid widget child name \"$name\"")
    root = String(parent.path)::String
    path = (root == "." ? root*name : root*"."*name)::String
    return build(T, class, command, prefix, parent.interp, path, pairs...; kwds...)
end

# Build a child widget given its parent and with automatic name.
function build(::Type{T}, class::String, command::String, prefix::String,
               parent::TkWidget, pairs::Pair...; kwds...) where {T<:TkWidget}
    interp = parent.interp
    path = widget_auto_path(interp, String(parent.path)::String, prefix)
    return build(T, class, command, prefix, interp, path, pairs...; kwds...)
end

# Return the path of a non-existing widget.
function widget_auto_path(interp::TclInterp, parent::String, prefix::String)
    i, j = firstindex(prefix), lastindex(prefix)
    key = SubString(prefix, (i ≤ j && prefix[i] == '.' ? nextind(prefix, i) : i), j)
    base = (parent == "." ? "."*key : parent*"."*key)::String
    T = valtype(auto_name_dict)
    n = get(auto_name_dict, key, zero(T)) + one(T)
    while true
        # NOTE `s*string(i)` is faster than `string(s,i)` or, equivalently, `"$s$i"
        path = base*string(n)
        if !winfo_exists(interp, path)
            auto_name_dict[key] = n
            return path
        end
        n += one(n)
    end
end

"""
    TkToplevel(interp=TclInterp(), ".")

Return the top-level Tk window for Tcl interpreter `interp`. This also takes care of loading
Tk extension in the interpreter and starting the event loop.

To create a new top-level widget:

    TkToplevel(interp=TclInterp(), pairs...; kwds...)
    TkToplevel(interp=TclInterp(), path, pairs...; kwds...)

with `path` the optional name of the widget (must start with a dot). Arguments `pairs...`
and keywords `kwds...` are to specify configuration options.

""" TkToplevel

# Accessors.
TclInterp(w::TkWidget) = w.interp
Base.parent(w::TkWidget) = winfo_parent(w)
# FIXME Base.parent(::TkRootWidget) = nothing
TclObj(w::TkWidget) = w.path
Base.convert(::Type{TclObj}, w::TkWidget) = TclObj(w)::TclObj
# FIXME Base.convert(::Type{String}, w::TkWidget) = ...
unsafe_objptr(w::TkWidget) = unsafe_objptr(TclObj(w), "Tk widget") # used in `exec`

exec(w::TkWidget, args...; kwds...) =
    exec(w.interp, w.path, args...; kwds...)
exec(w::TkWidget, ::Type{T}, args...; kwds...) where {T} =
    exec(T, w.interp, w.path, args...; kwds...)
exec(::Type{T}, w::TkWidget, args...; kwds...) where {T} =
    exec(T, w.interp, w.path, args...; kwds...)

# We want to have the object type and path both printed in the REPL but want
# only the object path with the `string` method or for string interpolation.
# Note that: "$w" calls `string(w)` while "anything $w" calls `show(io, w)`.
Base.print(io::IO, w::TkWidget) = write(io, w.path)

Base.show(io::IO, ::MIME"text/plain", w::TkWidget) = show(io, w)

function Base.show(io::IO, w::T) where {T<:TkWidget}
    print(io, T, "(\"")
    write(io, w.path)
    print(io, "\")")
    return nothing
end

for f in (:isequal, :(==))
    @eval function Base.$f(a::T, b::T) where {T<:TkWidget}
        return $f(a.interp, b.interp) && $f(a.path, b.path)
    end
end

# Properties.
Base.propertynames(w::TkWidget) = (:class, :interp, :parent, :path)
@inline Base.getproperty(w::TkWidget, key::Symbol) = _getproperty(w, Val(key))
_getproperty(w::TkWidget, ::Val{:class}) = winfo_class(w)
_getproperty(w::TkWidget, ::Val{:interp}) = getfield(w, :interp)
_getproperty(w::TkWidget, ::Val{:parent}) = winfo_parent(w)
_getproperty(w::TkWidget, ::Val{:path}) = getfield(w, :path)

# For Tk objects, syntax `obj.comd(...)` invokes sub-command.
_getproperty(w::TkObject, ::Val{cmd}) where {cmd} = SubCommand{cmd}(w)

# Some sub-commands are special.
for cmd in (:cget, :configure)
    @eval begin
        (f::SubCommand{$(QuoteNode(cmd)),<:TkObject})(::Type{T}, args...; kwds...) where T =
            $cmd(T, f.caller, args...; kwds...)
        (f::SubCommand{$(QuoteNode(cmd)),<:TkObject})(args...; kwds...) =
            $cmd(f.caller, args...; kwds...)
    end
end
for cmd in (:grid, :pack, :place)
    @eval begin
        (f::SubCommand{$(QuoteNode(cmd)),<:TkWidget})(::Type{T}, args...; kwds...) where T =
            $cmd(T, f.caller, args...; kwds...)
        (f::SubCommand{$(QuoteNode(cmd)),<:TkWidget})(args...; kwds...) =
            $cmd(f.caller, args...; kwds...)
    end
end

"""
    tk_start(interp = TclInterp()) -> interp

Load Tk and Ttk packages in `interp` and start the event loop (for all interpreters).

!!! note
    `tk_start` also takes care of withdrawing the root window "." to avoid its destruction
    as this would terminate the Tcl application. Execute Tcl command `wm deiconify .` to
    show the root window again.

# See also

[`TclTk.resume`](@ref), [`TclInterp`](@ref), and [`TkWidget`](@ref).

"""
function tk_start(interp::TclInterp = TclInterp()) :: TclInterp
    if TclTk.eval(Int, interp, "lsearch -exact [package names] Tk") < 0
        # Initialize Tcl interpreter to find Tk library scripts. NOTE this is the same as
        # initializing global variable `tcl_library` before calling `Tcl_Init`.
        if isdefined(@__MODULE__, :Tk_jll)
            tk_library = joinpath(dirname(dirname(Tk_jll.libtk_path)), "lib",
                                  "tk$(TCL_MAJOR_VERSION).$(TCL_MINOR_VERSION)")
            ptr = Tcl_SetVar(interp, "tk_library", tk_library, TCL_GLOBAL_ONLY|TCL_LEAVE_ERR_MSG)
            isnull(ptr) && @warn "Unable to set `tk_library`: $(getresult(String, interp))"
        end
        # Load Tk and Ttk packages. It is not needed to explicitly load these packages, it
        # is sufficient to call `Tk_Init`.
        status = @ccall libtk.Tk_Init(interp::Ptr{Tcl_Interp})::TclStatus
        status == TCL_OK || @warn "Unable to initialize Tk interpreter: $(getresult(String, interp))"
        status == TCL_OK && TclTk.eval(Nothing, interp, "wm withdraw .")
    end
    isrunning() || resume()
    return interp
end

"""
    TclTk.configure(w)
    w(:configure)

Return all the options of Tk object (widget or image) `w`.

---
    TclTk.configure(w, pairs...; kwds...)
    w(:configure, pairs...; kwds...)
    w.configure(pairs...; kwds...)

Change some options of widget or image `w`. Trailing `pairs...` arguments and keywords
`kwds...` are interpreted as configuration options. Another way to change the settings is:

    w[opt1] = val1
    w[opt2] = val2

# See also

[`TclTk.cget`](@ref) and [`TkWidget`](@ref).

"""
configure(w::TkObject, pairs...; kwds...) = configure(TclObj, w, pairs...; kwds...)
configure(::Type{T}, w::TkObject, pairs...; kwds...) where {T} =
    exec(T, w, :configure, pairs...; kwds...)

"""
    TclTk.cget(w, opt)

Return the value of the option `opt` for Tk object (widget or image) `w`. Option `opt` may
be specified as a string or as a `Symbol` and shall corresponds to a Tk option name (the
leading hyphen may be omitted). Another way to obtain an option value is:

    w[opt]

# See also

[`TclTk.configure`](@ref) and [`TkWidget`](@ref).

"""
cget(w::TkObject, opt::OptionName) = cget(TclObj, w, opt)
cget(w::TkObject, ::Type{T}, opt::OptionName) where {T} = cget(T, w, opt)
cget(::Type{T}, w::TkObject, opt::OptionName) where {T} = exec(T, w, :cget, with_hyphen(opt))

Base.getindex(w::TkObject, key::OptionName) = cget(w, key)
@inline Base.getindex(w::TkObject, (key,T)::Pair{<:OptionName,DataType}) = cget(T, w, key)
Base.getindex(w::TkObject, ::Type{T}, key::OptionName) where {T} = cget(T, w, key)
Base.getindex(w::TkObject, key::OptionName, ::Type{T}) where {T} = cget(T, w, key)
function Base.setindex!(w::TkObject, val, key::OptionName)
    exec(Nothing, w, :configure, key => val)
    return w
end

"""
    TclTk.grid(args...)

Call Tk *grid* geometry manager. One of the arguments must be a widget (that is an instance
of `TkWidget`). All widgets in `args...` must live in the same interpreter.


To specify the gridding options for a single widget `w`, another possible syntax is:

    w.grid(args...; kwds...)

# See also

[`TclTk.pack`](@ref) and [`TclTk.place`](@ref).

"""
function grid end

"""
    TclTk.pack(args...; kwds...)

Call Tk *packer* geometry manager. One of the arguments must be a widget (that is an
instance of `TkWidget`). All widgets in `args...` must live in the same interpreter.

To specify the packing options for a single widget `w`, another possible syntax is:

    w.pack(args...; kwds...; kwds..)

For example:

```julia
using TclTk
tk_start()
top = TkToplevel()
TclTk.exec(Nothing, :wm, :title, top, "A simple example")
btn = TtkButton(top, text = "Click me", command = "puts {ouch!}")
TclTk.pack(Nothing, btn, side = :bottom, padx = 30, pady = 5)
```

# See also

[`TclTk.grid`](@ref) and [`TclTk.place`](@ref).

"""
function pack end

"""
    TclTk.place(args...; kwds..)

Call Tk *placer* geometry manager. One of the arguments must be a widget (that is an
instance of `TkWidget`). All widgets in `args...` must live in the same interpreter.

To specify the placing options for a single widget `w`, another possible syntax is:

    w.place(args...; kwds...)

# See also

[`TclTk.grid`](@ref) and [`TclTk.pack`](@ref).

"""
function place end

for cmd in (:grid, :pack, :place)
    @eval begin
        $cmd(args...; kwds...) = $cmd(TclObj, args...; kwds...)
        function $cmd(::Type{T}, args...; kwds...) where {T}
            interp = common_interpreter(nothing, args...)
            interp == nothing && argument_error("missing a widget argument")
            return exec(T, interp, $(QuoteNode(cmd)), args...; kwds...)
        end
    end
end

common_interpreter() = nothing
common_interpreter(interp::Union{Nothing,TclInterp}) = interp
common_interpreter(interp::Union{Nothing,TclInterp}, arg::Any, args...) =
    common_interpreter(interp, args...)
common_interpreter(::Nothing, arg::TkWidget, args...) =
    common_interpreter(arg.interp, args...)
function common_interpreter(interp::TclInterp, arg::TkWidget, args...)
    pointer(interp) == pointer(arg.interp) || argument_error("not all widgets have the same interpreter")
    return common_interpreter(interp, args...)
end

# Base.bind is overloaded because it already exists for sockets, but there
# should be no conflicts.
"""
    bind(w, ...)

Bind events to widget `w` or yields bindings for widget `w`.

With a single argument:

    bind(w)

yields bindings for widget `w`; while

    bind(w, seq)

yields the specific bindings for the sequence of events `seq` and

    bind(w, seq, script)

arranges to invoke `script` whenever any event of the sequence `seq` occurs for widget `w`.
For instance:

    bind(w, "<ButtonPress>", "+puts click")

To deal with class bindings, the Tcl interpreter may be provided (otherwise the shared
interpreter of the thread will be used):

    bind([interp,] classname, args...)

where `classname` is the name of the widget class (a string or a symbol).

"""
Base.bind(arg0::TkWidget, args...) = bind(TclInterp(arg0), arg0, args...)
Base.bind(arg0::Name, args...) = bind(TclInterp(), arg0, args...)
Base.bind(interp::TclInterp, args...) = exec(interp, :bind, args...)
