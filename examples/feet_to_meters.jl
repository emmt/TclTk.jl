# Adapted from https://tkdocs.com/tutorial/firstexample.html

using TclTk

function calc_function(interp::TclInterp, args::TclObj)
    feet = convert(Float64, interp["feet"])
    resolution = 1e3
    interp["meters"] = round(feet*0.3048*resolution)/resolution
end
calc_callback = TclTk.Callback(calc_function)

interp = tk_start()

top = TkToplevel(interp)
interp(Nothing, :wm, :title, top, "Feet to Meters")

frame = TtkFrame(top, padding=(3, 3, 12, 12))
frame.grid(Nothing, column=0, row=0, sticky="nwes")

feet = TtkEntry(frame, width=7, textvariable="feet")
feet.grid(Nothing, column=2, row=1, sticky="we")

meters = TtkLabel(frame, textvariable="meters")
meters.grid(Nothing, column=2, row=2, sticky="we")

calc = TtkButton(frame, text="Calculate", command=calc_callback.name)
calc.grid(Nothing, column=3, row=3, sticky="w")

flbl = TtkLabel(frame, text="feet")
flbl.grid(Nothing, column=3, row=1, sticky="w")

islbl = TtkLabel(frame, text="is equivalent to")
islbl.grid(Nothing, column=1, row=2, sticky="e")

mlbl = TtkLabel(frame, text="meters")
mlbl.grid(Nothing, column=3, row=2, sticky="w")

interp(Nothing, :grid, :columnconfigure, top, 0, weight=1)
interp(Nothing, :grid, :rowconfigure, top, 0, weight=1)
interp(Nothing, :grid, :columnconfigure, frame, 2, weight=1)
for w in interp(:winfo, :children, frame)
    interp(Nothing, :grid, :configure, w, padx=5, pady=5)
end
interp(Nothing, :focus, feet)
interp(Nothing, :bind, top, "<Return>", calc_callback.name)
