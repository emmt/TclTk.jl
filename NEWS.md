# User visible changes in `Tcl`

This page describes the most important changes in `Tcl`. The format is based on [Keep a
Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic
Versioning](https://semver.org).

## Unreleased

### Changed

- `TclTk.setvar!` and `TclTk.unsetvar!` replace `TclTk.setvar` and `TclTk.unsetvar` which
  are deprecated.

- 2-part Tcl variable names (a.k.a. Tcl *arrays*) are specified as 2-tuple on the Julia
  side. Specifying such names as two arguments has been deprecated. This was needed for the
  coherence of base methods like `haskey` or `delete!`.

- The default type when retrieving the result stored by an interpreter is `TclObj` (was
  `String`).

- The package uses artifacts `Tcl_jll` and `Tk_jll` to avoid a build step.

### Added

- Abstract vector API for lists of Tcl objects.

- `interp[] = result` to set interpreter's result.

- Checking for equality of instances of `TclInterp`, `TkWidget`, and `TkImage`.

- Non-exported public functions `TclTk.isactive`, `TclTk.isdeleted`, and `TclTk.issafe`.


### Fixed

- Indexation of lists of Tcl objects by a vector of Booleans.

- Getting value of a global Tcl variable with a 2-part name.

- Names of Tcl global variables can also be a (real) number.


## Version 0.2.0 (2026-02-17)

### Breaking changes

- Instances of `TclObj` no longer have a type parameter as the *type* of a Tcl object
  reflects a cached internal state that may change for efficiency.

- `Tcl.getvalue(obj)` has been replaced by `convert(T, obj)` to get a value of given type
  `T` from Tcl object `obj`.

- List-specialized methods (`llength`, `lappend!`, and `lindex`) have been suppressed in
  favor of the Julia API for collections. Thus, `length`, `append!`, `push!`, `delete!`,
  `getindex`, and `setindex!` shall be used to access Tcl objects as if they are lists.

- `Tcl.getinterp()` has been replaced by `TclInterp()`.

- `Tcl.setresult` has been replaced by `Tcl.setresult!`.

- Tcl/Tk options `-key val` in scripts or commands are produced by `key => val` pairs in
  Julia code where `key` is a string, a symbol, or a Tcl object. Previously it was done for
  keywords in function calls but, then, `key` cannot be a reserved Julia keyword.

### Fixed

- Raw pointers in C calls are protected by having their owner object preserved from being
  garbage collected.

- Getting a single char from a Tcl object works for multi-byte sequences.

- To protect the content of shared objects, Tcl imposes a strict copy-on-write policy. Not
  following this policy causes Tcl to panic (i.e., abort the program). To avoid this,
  attempts to modify a shared Tcl object are detected and forbidden by throwing an
  exception.

### Changed

- By default, the package uses artifacts `Tcl_jll` and `Tk_jll`. To use other libraries, one
  can set the environment variables `ENV["JL_TLIBTCL"]` and `ENV["JL_TLIBTK"]` to the
  absolute paths of these libraries before calling `pkg> update Tcl` and `pkg> build Tcl`.

- `Tcl.doevents` has been deprecated and replaced by `Tcl.do_events` which returns the
  number of processed events.

- Following Tcl behavior, `obj[i]` yields `missing` if index `i` is out of range.

### Added

- `interp(args...)`, `interp.exec(args...)`, and `Tcl.exec(interp, args...)` execute a Tcl
  command. thing.

- `interp.eval(args...)` and `Tcl.eval(interp, args...)` concatenate arguments and evaluate
  a Tcl script.

- `Tcl.do_one_event(flags)` to process any pending events matching `flags`.

- `TclInterp` constructor can yield the shared interpreted for the thread of the caller or a
  new private interpreter.

- `Tcl.quote_string(str)` yields a proper double-quoted string that can be inserted directly
  in Tcl scripts.

- A Tcl variable may be unset (or deleted) by meany different means (at the user
  convenience). For example: `Tcl.unset(interp, name)`, `Base.delete!(interp, name)`, or
  `interp[name] = unset` (where `unset` is the singleton provided by the `UnsetIndex`
  package and exported by the `Tcl` package).
