baremodule TclTk

# TclTk is a bare module because it implements its own `eval` function.
function eval end
using Base

"""

`TclTk.Impl` module hosts the implementation of the `TclTk` package.

"""
module Impl

import ..TclTk

using Tcl_jll, Tk_jll
using CEnum
using ColorTypes
using Colors
using FixedPointNumbers
using Neutrals
using TypeUtils
using UnsetIndex: Unset, unset

if isdefined(Base, :Memory)
    const BasicVector{T} = Union{Vector{T},Memory{T}}
else
    const Memory{T} = Vector{T}
    const BasicVector{T} = Vector{T}
end

include("libtcl.jl")
include("libtk.jl")
include("types.jl")
include("utils.jl")
include("objects.jl")
include("lists.jl")
include("interpreters.jl")
include("variables.jl")
include("callbacks.jl")
include("events.jl")
include("colors.jl")
include("widgets.jl")
include("dialogs.jl")
include("images.jl")

@deprecate getinterp(args...; kwds...) TclInterp(args...; kwds...) false

@deprecate setvar(args...; kwds...) setvar!(args...; kwds...) false
@deprecate unsetvar(args...; kwds...) unsetvar!(args...; kwds...) false

@deprecate exists(part1::Name, part2::Name) exists((part1, part2)) false
@deprecate exists(interp::TclInterp, part1::Name, part2::Name) exists(interp, (part1, part2)) false

@deprecate getvar(part1::Name, part2::Name; kwds...) getvar((part1, part2); kwds...) false
@deprecate getvar(T::Type, part1::Name, part2::Name; kwds...) getvar(T, (part1, part2); kwds...) false
@deprecate getvar(interp::TclInterp, part1::Name, part2::Name; kwds...) getvar(interp, (part1, part2); kwds...) false
@deprecate getvar(T::Type, interp::TclInterp, part1::Name, part2::Name; kwds...) getvar(T, interp, (part1, part2); kwds...) false

@deprecate setvar!(part1::Name, part2::Name, value; kwds...) setvar!((part1, part2), value; kwds...) false
@deprecate setvar!(T::Type, part1::Name, part2::Name, value; kwds...) setvar!(T, (part1, part2), value; kwds...) false
@deprecate setvar!(interp::TclInterp, part1::Name, part2::Name, value; kwds...) setvar!(interp, (part1, part2), value; kwds...) false
@deprecate setvar!(T::Type, interp::TclInterp, part1::Name, part2::Name, value; kwds...) setvar!(T, interp, (part1, part2), value; kwds...) false

@deprecate unsetvar!(part1::Name, part2::Name; kwds...) unsetvar!((part1, part2); kwds...) false
@deprecate unsetvar!(interp::TclInterp, part1::Name, part2::Name; kwds...) setvar!(interp, (part1, part2); kwds...) false

function __init__()
    # Check that package was built with the same version as the dynamic library.
    version = tcl_version()
    (version.major, version.minor) == (TCL_MAJOR_VERSION, TCL_MINOR_VERSION) || assertion_error(
        "`TclTk` package assumes Tcl $(TCL_MAJOR_VERSION).$(TCL_MINOR_VERSION) while loaded library ",
        "has version $(version), `Project.toml` must be adjusted")

    # Many things do not work properly (segmentation fault when freeing a Tcl object,
    # initialization of Tcl interpreters, etc.) if Tcl internals (encodings, sub-systems,
    # etc.) are not properly initialized. This is done by the following call.
    @ccall libtcl.Tcl_FindExecutable(joinpath(Sys.BINDIR, "julia")::Cstring)::Cvoid

    # The table of known types is updated while objects of new types are created because
    # seeking for an existing type is much faster than creating the mutable TclObj
    # structure. Nevertheless, we know in advance that objects with NULL object type are
    # strings.
    unsafe_register_new_typename(ObjTypePtr(0))

    # Compile C functions for callbacks.
    release_object_proc[] = @cfunction(unsafe_release, Cvoid, (Ptr{Cvoid},))
    eval_command_proc[] = @cfunction(eval_command, TclStatus,
                                     (ClientData, Ptr{Tcl_Interp},
                                      Cint, Ptr{Ptr{Tcl_Obj}}))
    return nothing
end

end # module

# Public symbols. Only those with recognizable prefixes (like "Tcl", "TCL_", "Tk", etc.)
# are exported, the other must be explicitly imported or used with the `TclTk.` prefix.
for sym in (
    # Types.
    :Callback,
    :TclError,
    :TclInterp,
    :TclObj,
    :TclStatus,
    :WideInt,

    # Version.
    :TCL_MAJOR_VERSION,
    :TCL_MINOR_VERSION,

    # Status constants.
    :TCL_OK,
    :TCL_ERROR,
    :TCL_RETURN,
    :TCL_BREAK,
    :TCL_CONTINUE,

    # Constants for events.
    :TCL_DONT_WAIT,
    :TCL_WINDOW_EVENTS,
    :TCL_FILE_EVENTS,
    :TCL_TIMER_EVENTS,
    :TCL_IDLE_EVENTS,
    :TCL_ALL_EVENTS,

    # Constants for variables.
    :TCL_GLOBAL_ONLY,
    :TCL_NAMESPACE_ONLY,
    :TCL_APPEND_VALUE,
    :TCL_LIST_ELEMENT,
    :TCL_LEAVE_ERR_MSG,

    # Methods.
    :bool,
    :cget,
    :concat,
    :configure,
    :deletecommand,
    :do_events,
    :do_one_event,
    :eval,
    :exec,
    :exists,
    :getresult,
    :getvar,
    :grid,
    :isactive,
    :isdeleted,
    :isrunning,
    :issafe,
    :list,
    :pack,
    :place,
    :quote_string,
    :resume,
    :setresult!,
    :setvar!,
    :setvar, # FIXME deprecated
    :suspend,
    :tcl_error,
    :tcl_library,
    :tcl_version,
    :tk_start,
    :unsetvar!,
    :unsetvar, # FIXME deprecated

    # Tk images.
    :TkBitmap,
    :TkImage,
    :TkPhoto,
    :TkPixmap,

    # Tk widgets.
    :TkButton,
    :TkCanvas,
    :TkCheckbutton,
    :TkEntry,
    :TkFrame,
    :TkLabel,
    :TkLabelframe,
    :TkListbox,
    :TkMenu,
    :TkMenubutton,
    :TkMessage,
    :TkPanedwindow,
    :TkRadiobutton,
    :TkRootWidget,
    :TkScale,
    :TkScrollbar,
    :TkSpinbox,
    :TkText,
    :TkToplevel,
    :TkWidget,
    Symbol("@TkWidget"),

    # Ttk (Themed Tk) widgets.
    :TtkButton,
    :TtkCheckbutton,
    :TtkCombobox,
    :TtkEntry,
    :TtkFrame,
    :TtkLabel,
    :TtkLabelframe,
    :TtkMenubutton,
    :TtkNotebook,
    :TtkPanedwindow,
    :TtkProgressbar,
    :TtkRadiobutton,
    :TtkScale,
    :TtkScrollbar,
    :TtkSeparator,
    :TtkSizegrip,
    :TtkSpinbox,
    :TtkTreeview,

    # Tk dialogs.
    :tk_chooseColor,
    :tk_chooseDirectory,
    :tk_getOpenFile,
    :tk_getSaveFile,
    :tk_messageBox,
    )

    # Import public symbols from the `Impl` module, export those prefixed with `Tcl`,
    # `TCL_`, `Tk`, `@Tk`, `Ttk` or `TK_`, and declare the others as "public".
    if sym != :eval
        @eval import .Impl: $sym
    end
    name = string(sym)
    if startswith(name, r"@?(Tcl|tcl_|TCL_|Tt?k|tk_)")
        @eval export $sym
    elseif VERSION ≥ v"1.11.0-DEV.469"
        @eval $(Base.Expr(:public, sym))
    end
end

# Re-export from UnsetIndex.
using UnsetIndex
export unset

end # module
