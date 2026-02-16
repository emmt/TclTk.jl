# Processing of Tcl/Tk events. The function `do_events` must be repeatedly called to process
# events when Tk is loaded.

"""
    TclTk.isrunning() -> bool

Return whether the processing of Tcl/Tk events is running.

# See also

[`TclTk.suspend`](@ref), [`TclTk.resume`](@ref), and [`TclTk.do_one_event`](@ref), and
[`TclTk.do_events`](@ref).

"""
isrunning() = (isdefined(runner, 1) && isopen(runner[]))

# Runner called at regular time interval by Julia to process Tcl events.
const runner = Ref{Timer}()

"""
    TclTk.resume(delay=0.1, interval=0.05) -> nothing

Resume or start the processing of Tcl/Tk events with a given `delay` and `interval` both in
seconds. This manages to repeatedly call function [`TclTk.do_events`](@ref). The method
[`TclTk.suspend`](@ref) can be called to suspend the processing of events.

Calling `TclTk.resume` is mandatory when Tk extension is loaded. Thus, the recommended way to
load the Tk package is:

```julia
TclTk.eval(interp, "package require Tk")
TclTk.resume()
```

or alternatively:

```julia
tk_start()
```

can be called to do that.

"""
function resume(delay::Real=0.1, interval::Real=0.05)
    if !isrunning()
        if VERSION ≥ v"1.12"
            # We want the callback to run in the calling thread.
            runner[] = Timer(do_events, delay; interval=interval, spawn=false)
        else
            runner[] = Timer(do_events, delay; interval=interval)
        end
    end
    return nothing
end

"""
    TclTk.suspend() -> nothing

Suspend the processing of Tcl/Tk events for all interpreters. The method
[`TclTk.resume`](@ref) can be called to resume the processing of events.

"""
function suspend()
    isrunning() && close(runner[])
    return nothing
end

"""
    TclTk.do_events(flags = TCL_DONT_WAIT|TCL_ALL_EVENTS) -> num::Int

Process Tcl/Tk events for all interpreters by calling [`TclTk.do_one_event(flags)`](@ref)
until there are no events matching `flags` and return the number of processed events.
Normally this is automatically called by the timer set by [`TclTk.resume`](@ref).

"""
do_events(::Timer) = do_events()

function do_events(flags::Integer = default_event_flags)
    num = 0
    while do_one_event(flags)
        num += 1
    end
    return num
end

@deprecate doevents(args...; kwds...) do_events(args...; kwds...)

const default_event_flags = TCL_DONT_WAIT|TCL_ALL_EVENTS

"""
    TclTk.do_one_event(flags = TCL_DONT_WAIT|TCL_ALL_EVENTS) -> bool

Process at most one Tcl/Tk event for all interpreters matching `flags` and return whether
one such event was processed. This function is called by [`TclTk.do_events`](@ref).

"""
do_one_event(flags::Integer = default_event_flags) = !iszero(Tcl_DoOneEvent(flags))
