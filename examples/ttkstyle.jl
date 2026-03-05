# ttkstyle.jl --
#
# This demonstration script creates a toplevel window containing several simple Ttk widgets,
# such as labels, labelframes, buttons, checkbuttons and radiobuttons.
#
# Adapted from Tcl/Tk widget demo (file `ttkbut.tcl`).

interp = tk_start()
w = ".ttkstyle"
interp.eval("catch {destroy $w}")
top = TkToplevel(interp, w)
wm.title(top, "Simple Ttk Widgets")
wm.iconname(top, "ttkstyle")

# TtkLabel can replace TkMessage.
msg = TtkLabel(top, #=font=$font,=# wraplength="4i", justify=:left, padding=(5, 3),
               text="Ttk is the new Tk themed widget set. This is a Ttk themed label, and below are three groups of Ttk widgets in Ttk labelframes. The first group are all buttons that set the current application theme when pressed. The second group contains three sets of checkbuttons, with a separator widget between the sets. Note that the \u201cEnabled\u201d button controls whether all the other themed widgets in this toplevel are in the disabled state. The third group has a collection of linked radiobuttons.")
msg.pack(side=:top, fill=:x)

## See Code / Dismiss
#pack [addSeeDismiss $w.seeDismiss $w {enabled cheese tomato basil oregano happiness}]\
#  -side bottom -fill x

## Add buttons for setting the theme
buttons = TtkLabelframe(top, text="Buttons")
for theme in interp.eval(Vector{String}, "ttk::themes")
    local btn = TtkButton(buttons, text=theme, command="ttk::setTheme $theme")
    btn.pack(pady=2)
end

## Helper procedure for the top checkbutton
setState(interp::TclInterp, args::TclObj) =
    setState(interp, args[2 => String], args[3 => Vector{String}], args[4 => String])

function setState(interp::TclInterp, rootWidget, exceptThese, value)
    rootWidget ∈ exceptThese && return
    ## Non-Ttk widgets (e.g. the toplevel) will fail, so make it silent
    interp.eval("catch {$rootWidget state $value}")
    ## Recursively invoke on all children of this root that are in the same
    ## toplevel widget
    rootToplevel = interp(String, :winfo, :toplevel, rootWidget)
    for w in interp(Vector{String}, :winfo, :children, rootWidget)
	if interp(String, :winfo, :toplevel, w) == rootToplevel
	    setState(interp, w, exceptThese, value)
	end
    end
end
setState_ = TclTk.Callback(setState, interp, "setState")
enabled = TclTk.Variable{Bool}("enabled")
enabled[] = true

## Set up the checkbutton group
checks = TtkLabelframe(top, text="Checkbuttons")
e = TtkCheckbutton(checks, text="Enabled", variable="enabled")
e[:command] = "setState $top $e [expr {\$enabled ? \"!disabled\" : \"disabled\"}]"

## See ttk_widget(n) for other possible state flags
sep1 = TtkSeparator(checks)
c1 = TtkCheckbutton(checks, text="Cheese", variable="cheese")
c2 = TtkCheckbutton(checks, text="Tomato", variable="tomato")
sep2 = TtkSeparator(checks)
c3 = TtkCheckbutton(checks, text="Basil", variable="basil")
c4 = TtkCheckbutton(checks, text="Oregano", variable="oregano")
TclTk.pack(e, sep1, c1, c2, sep2, c3, c4, fill=:x, pady=2)

## Set up the radiobutton group
radios = TtkLabelframe(top, text="Radiobuttons")
r1 = TtkRadiobutton(radios, text="Great", variable="happiness", value="great")
r2 = TtkRadiobutton(radios, text="Good",  variable="happiness", value="good")
r3 = TtkRadiobutton(radios, text="OK",    variable="happiness", value="ok")
r4 = TtkRadiobutton(radios, text="Poor",  variable="happiness", value="poor")
r5 = TtkRadiobutton(radios, text="Awful", variable="happiness", value="awful")
TclTk.pack(r1, r2, r3, r4, r5, fill=:x, padx=3, pady=2)

## Arrange things neatly
f = TtkFrame(top)
f.pack(fill="both", expand=true)
interp(:lower, f)
TclTk.grid(buttons, checks, radios, in=f, sticky="nwe", pady=2, padx=3)
TclTk.grid(:columnconfigure, f, (0, 1, 2), weight=1, uniform=true)
