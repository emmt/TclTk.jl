# Define shortcuts for Tcl/Tk methods.
#
# Usage:
#
#     using TclTk
#     using TclTk.ShortNames
#

module ShortNames

using ...Tcl

export
    cget,
    configure,
    getparent,
    getpath,
    grid,
    list,
    pack,
    place,

    Button,
    Canvas,
    Checkbutton,
    Entry,
    Frame,
    Label,
    Labelframe,
    Listbox,
    Menu,
    Menubutton,
    Message,
    Panedwindow,
    Radiobutton,
    Scale,
    Scrollbar,
    Spinbox,
    TButton,
    TCheckbutton,
    TCombobox,
    TEntry,
    TFrame,
    TLabel,
    TLabelframe,
    TMenubutton,
    TNotebook,
    TPanedwindow,
    TProgressbar,
    TRadiobutton,
    TScale,
    TScrollbar,
    TSeparator,
    TSizegrip,
    TSpinbox,
    Text,
    Toplevel,
    Treeview

const cget          = TclTk.cget
const configure     = TclTk.configure
const getparent     = TclTk.getparent
const getpath       = TclTk.getpath
const grid          = TclTk.grid
const list          = TclTk.list
const pack          = TclTk.pack
const place         = TclTk.place

# Use the same short names as the Tk class names given by `winfo class $w`.
const Button        = TkButton
const Canvas        = TkCanvas
const Checkbutton   = TkCheckbutton
const Entry         = TkEntry
const Frame         = TkFrame
const Label         = TkLabel
const Labelframe    = TkLabelframe
const Listbox       = TkListbox
const Menu          = TkMenu
const Menubutton    = TkMenubutton
const Message       = TkMessage
const Panedwindow   = TkPanedwindow
const Radiobutton   = TkRadiobutton
const Scale         = TkScale
const Scrollbar     = TkScrollbar
const Spinbox       = TkSpinbox
const TButton       = TtkButton
const TCheckbutton  = TtkCheckbutton
const TCombobox     = TtkCombobox
const TEntry        = TtkEntry
const TFrame        = TtkFrame
const TLabel        = TtkLabel
const TLabelframe   = TtkLabelframe
const TMenubutton   = TtkMenubutton
const TNotebook     = TtkNotebook
const TPanedwindow  = TtkPanedwindow
const TProgressbar  = TtkProgressbar
const TRadiobutton  = TtkRadiobutton
const TScale        = TtkScale
const TScrollbar    = TtkScrollbar
const TSeparator    = TtkSeparator
const TSizegrip     = TtkSizegrip
const TSpinbox      = TtkSpinbox
const Text          = TkText
const Toplevel      = TkToplevel
const Treeview      = TtkTreeview

end #module
