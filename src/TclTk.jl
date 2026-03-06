baremodule TclTk

export
    # Types.
    TclInterp,
    TclObj,

    # Methods.
    tcl_library,
    tk_start,

    # Error and status.
    TCL_BREAK,
    TCL_CONTINUE,
    TCL_ERROR,
    TCL_OK,
    TCL_RETURN,
    TclError,
    TclStatus,
    tcl_error,

    # Version.
    tcl_version,
    TCL_MAJOR_VERSION,
    TCL_MINOR_VERSION,

    # Constants for events.
    TCL_DONT_WAIT,
    TCL_WINDOW_EVENTS,
    TCL_FILE_EVENTS,
    TCL_TIMER_EVENTS,
    TCL_IDLE_EVENTS,
    TCL_ALL_EVENTS,

    # Constants for variables.
    TCL_GLOBAL_ONLY,
    TCL_NAMESPACE_ONLY,
    TCL_APPEND_VALUE,
    TCL_LIST_ELEMENT,
    TCL_LEAVE_ERR_MSG,

    # Tk images.
    TkBitmap,
    TkImage,
    TkPhoto,

    # Widgets.
    TkWidget,
    Button,
    Canvas,
    Checkbutton,
    Combobox,
    Entry,
    Frame,
    Label,
    Labelframe,
    Listbox,
    Menu,
    Menubutton,
    Message,
    Notebook,
    Panedwindow,
    Progressbar,
    Radiobutton,
    Scale,
    Scrollbar,
    Separator,
    Sizegrip,
    Spinbox,
    Text,
    Toplevel,
    Treeview,

    # Re-export from UnsetIndex.
    unset

using Base
using UnsetIndex


# TclTk is a bare module because it implements its own `eval` function.
function eval end

# Being a bare module, we must define our `include` function.
include(file) = Base.include(@__MODULE__, file)

include("api.jl")

include("Impl.jl")
import .Impl:
    # Modules.
    Tk,
    Ttk,

    # Types.
    TclError,
    TclInterp,
    TclObj,
    TclStatus,

    # Tk images.
    TkBitmap,
    TkImage,
    TkPhoto,

    # Widgets.
    TkWidget,
    Button,
    Canvas,
    Checkbutton,
    Combobox,
    Entry,
    Frame,
    Label,
    Labelframe,
    Listbox,
    Menu,
    Menubutton,
    Message, # use Ttk.Label
    Notebook,
    Panedwindow,
    Progressbar,
    Radiobutton,
    Scale,
    Scrollbar,
    Separator,
    Sizegrip,
    Spinbox,
    Text,
    Toplevel,
    Treeview,

    # Version.
    TCL_MAJOR_VERSION,
    TCL_MINOR_VERSION,

    # Status constants.
    TCL_OK,
    TCL_ERROR,
    TCL_RETURN,
    TCL_BREAK,
    TCL_CONTINUE,

    # Constants for events.
    TCL_DONT_WAIT,
    TCL_WINDOW_EVENTS,
    TCL_FILE_EVENTS,
    TCL_TIMER_EVENTS,
    TCL_IDLE_EVENTS,
    TCL_ALL_EVENTS,

    # Constants for variables.
    TCL_GLOBAL_ONLY,
    TCL_NAMESPACE_ONLY,
    TCL_APPEND_VALUE,
    TCL_LIST_ELEMENT,
    TCL_LEAVE_ERR_MSG,

    # Methods.
    tcl_error,
    tcl_library,
    tcl_version,
    tk_start

# Non-exported public symbols.
for sym in (
    # Modules.
    :Tk,
    :Ttk,

    # Types.
    :Callback,
    :Value,
    :Variable,
    :WideInt,

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
    :unsetvar!,
    :unsetvar, # FIXME deprecated
    :winfo,

    # Tk widgets.
    #=
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
=#
    # Tk dialogs.
    :tk_chooseColor,
    :tk_chooseDirectory,
    :tk_getOpenFile,
    :tk_getSaveFile,
    :tk_messageBox,
    )

    # Import public symbols from the `Impl` module, export those prefixed with `Tcl`,
    # `TCL_`, `Tk`, `@Tk`, `Ttk` or `TK_`, and declare the others as "public".
    if sym ∉ (:eval, :Tk, :Ttk)
        @eval import .Impl: $sym
    end
    if VERSION ≥ v"1.11.0-DEV.469"
        @eval $(Base.Expr(:public, sym))
    end
end

end # module
