# Widget information

A number of information can be obtained for a widget `w` with the [`TclTk.winfo`](@ref)
command or with the `w.key` syntax for widget property `key` or with the `w.key(args...)`
syntax for information `key` of widget `w` that requires additional arguments `args...`.

Possible forms are:

- `w.atom(name)` yields the identifier (an unsigned integer) of atom named `name` for the
  display of `w`.

- `w.atomname(id)` yields the name of the atom whose identifier is `id` for the display of
  `w`.

- `w.cells` yields the number of cells in the color map of `w`.

- `w.children` yields a vector of the names of the children of `w`.

- `w.class` yields the symbolic name of the class of `w`.

- `w.colormapfull` yields whether the color map for `w` is known to be full.

- `w.containing(x, y)` yields the path name of the widget containing the pixel at coordinate
  `(x, y)` in the screen of `w`.

- `w.depth` yields the number of bits per pixel for `w`.

- `w.exists` yields whether Tk window associated with `w` exists (otherwise it means that
  the window has been destroyed).

- `w.fpixels(d)` yields the number of pixels (as a floating-point value) in `w`
  corresponding to the distance `d`. The distance `d` may have units; for example, `"1i"` is
  one inch, `"2m"` is two millimeters, and `"3c"` is three centimeters. If `d` has no units,
  pixels are assumed.

- `w.geometry` yields the geometry for `w`, in the form `"$(width)x$(height)+$(x)+$(y)"`.
  All dimensions are in pixels.

- `w.height` yields the height of `w` in pixels.

- `w.id` yields the identifier (an unsigned integer) of `w`. This identifier can be used to,
  e.g., draw in `w` with another program.

- `w.interp` yields the Tcl interpreter (a `TclInterp` object) where `w` lives.

- `w.interps` yields the names (a vector of strings) of existing Tcl interpreters for the
  display of `w`.

- `w.ismapped` yields whether `w` is mapped.

- `w.manager` yields the symbolic name of the geometry manager in charge of `w`. One of
  `:wm` (for a top-level widget), `:grid`, `:place`, or `:pack`.

- `w.name` yields the name of `w`, that is its name within its parent, as opposed to its
  full path name given by `w.path`.

- `w.parent` yields the full path name of the parent of `w`, or an empty string if `w` is
  the main window.

- `w.path` yields the full path name of `w`. For efficiency in calls involving `w`, `w.path`
  is a `TclObj` (not a `String`) but it can be compared to strings (and symbols) by the `==`
  operator and by the `isequal` method.

- `w.pathname(id)` yields the full path of the Tk window whose identifier is `id`. As a
  consequence, the identity `w.pathname(w.id) == w.path` shall hold.

- `w.pixels(d)` is similar to `w.fpixels(d)` except that it yields a result rounded to the
  nearest integer number of pixels.

- `w.pointerx` yields the pointer's `x` coordinate, measured in pixels in the screen's root
  window of `w`. If a virtual root window is in use on the screen, the position is measured
  in the virtual root. If the mouse pointer is not on the same screen as `w`, then `-1` is
  returned.

- `w.pointerxy` yields the 2-tuple `(w.pointerx, w.pointery)`.

- `w.pointery` is similar to `w.pointerx` but for the pointer's `y` coordinate.

- `w.reqheight` yields the height, in pixels, requested for `w`. This is the value used by
  window's geometry manager to compute its geometry.

- `w.reqwidth` is similar to `w.reqheight` but for the width.

- `w.rgb(color)` yields a 3-tuple of 16-bit unsigned integers with the read, green, and blue
  intensities of `color`.

- `w.rootx` yields the `x`-coordinate, in the root window of the screen, of the upper-left
  corner of the border of `w` (or of `w` if it has no border).

- `w.rooty` yields the `y`-coordinate, in the root window of the screen, of the upper-left
  corner of the border of `w` (or of `w` if it has no border).

- `w.screen` yields the name of the screen associated with `w` in the form
  `"$(displayname).$(screenindex)"`.

- `w.screencells` yields the number of cells in the default color map for the screen of `w`.

- `w.screendepth` yields the number of bits per pixel of the root window of the screen of `w`.

- `w.screenheight` yields the height, in pixels, of the screen of `w`.

- `w.screenmmheight` yields the height, in millimeters, of the screen of `w`.

- `w.screenmmwidth` yields the width, in millimeters, of the screen of `w`.

- `w.screenvisual` yields the symbolic name of the default visual for the screen of `w`, one
  of `:directcolor`, `:grayscale`, `:pseudocolor`, `:staticcolor`, `:staticgray`, or
  `:truecolor`.

- `w.screenwidth` yields the width, in pixels, of the screen of `w`.

- `w.server` yields a string containing information about the server for the display of `w`.

- `w.toplevel` yields the path name of the top-of-hierarchy window containing `w`. In
  standard Tk this will always be a top-level widget, but extensions may create other kinds
  of top-of-hierarchy widgets.

- `w.viewable` yields whether `w` and all of its ancestors up through the nearest top-level
  window are mapped.

- `w.visual` yields the visual class for `w`, one of `:directcolor`, `:grayscale`,
  `:pseudocolor`, `:staticcolor`, `:staticgray`, or `:truecolor`.

- `w.visualid` yields the identifier of the visual of `w`.

- `w.visualsavailable` yields a vector of `(visual::Symbol, depth::Int)` tuples describing the visuals
  available for the screen of `w`.

- `w.visualsavailable_includeids` is similar to `w.visualsavailable` but yields a vector of
  `(visual::Symbol, depth::Int, id::UInt32)` tuples.

- `w.vrootheight` yields the height of the virtual root window associated with `w` if there
  is one; otherwise returns the height of the screen of `w`.

- `w.vrootwidth` yields the width of the virtual root window associated with `w` if there is
  one; otherwise returns the width of the screen of `w`.

- `w.vrootx` yields the `x`-offset of the virtual root window associated with `w`, relative
  to the root window of its screen. This is normally either zero or negative. Returns `0` if
  there is no virtual root window for `w`.

- `w.vrooty` yields the yields the `y`-offset of the virtual root window associated with
  `w`, relative to the root window of its screen. This is normally either zero or negative.
  Returns `0` if there is no virtual root window for `w`.

- `w.width` yields the width of `w` in pixels.

- `w.x` yields the `x`-coordinate, in the parent of `w`, of the upper-left corner of the
  border of `w` (or of `w` if it has no border).

- `w.y` yields the `y`-coordinate, in the parent of `w`, of the upper-left corner of the
  border of `w` (or of `w` if it has no border).
