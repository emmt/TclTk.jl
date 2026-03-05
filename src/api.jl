export wm

"""
    wm(T=Nothing, cmd, w::TkWidget, args...; kwds...) -> res::T
    wm.cmd(T, w::TkWidget, args...; kwds...) -> res::T
    wm.cmd(w::TkWidget, args...; kwds...) -> res

Interact with the window manager to query or control such things as the title for widget
`w`, its geometry, etc. Argument `T` is the expected type for the result. With the syntax
`wm.cmd(w, ...)` a suitable default type that depends on `cmd` is assumed.

The window manger command `cmd` is one of ...

"""
function wm end
