"""
    TclTk.exists(interp=TclInterp(), name)
    haskey(interp, name)

Return whether global variable `name` is defined in Tcl interpreter `interp` or in the
shared interpreter of the calling thread if this argument is omitted. `name` may be a
2-tuple `(part1, part2)`.

# See also

[`TclTk.getvar`](@ref), [`TclTk.setvar!`](@ref), and [`TclTk.unsetvar!`](@ref).

"""
function exists end

const exists_default_flags = TCL_GLOBAL_ONLY

exists(name::VarName; kwds...) = exists(TclInterp(), name; kwds...)

function exists(interp::TclInterp, name::Name;
                flags::Integer = exists_default_flags)
    GC.@preserve interp name begin
        return !isnull(unsafe_getvar(interp, name, flags))
    end
end

function exists(interp::TclInterp, (part1, part2)::NTuple{2,Name};
                flags::Integer = exists_default_flags)
    GC.@preserve interp part1 part2 begin
        return !isnull(unsafe_getvar(interp, part1, part2, flags))
    end
end

"""
    TclTk.getvar(T=TclObj, interp=TclInterp(), name) -> val::T
    interp[name] -> val::TclObj
    interp[T::Type, name] -> val::T

Return the value of the global variable `name` in Tcl interpreter `interp` or in the shared
interpreter of the calling thread if this argument is omitted. `name` may be a 2-tuple
`(part1, part2)`.

Optional argument `T` (`TclObj` by default) can be used to specify the type of the returned
value. Some possibilities are:

* If `T` is `TclObj` (the default), a managed Tcl object is returned. This is the most
  efficient if the returned value is intended to be used in a Tcl list or as an argument of
  a Tcl script or command.

* If `T` is `Bool`, a boolean value is returned.

* If `T` is `String`, a string is returned.

* If `T` is `Char`, a single character is returned (an exception is thrown if Tcl object is
  not a single character string).

* If `T <: Integer`, an integer value of type `T` is returned.

* If `T <: AbstractFloat`, a floating-point value of type `T` is returned.

Note that, except if `T` is `TclObj`, a conversion of the Tcl object stored by the variable
may be needed.

# See also

[`TclTk.exists`](@ref), [`TclTk.setvar!`](@ref), and [`TclTk.unsetvar!`](@ref).

"""
function getvar end

const getvar_default_flags = (TCL_GLOBAL_ONLY|TCL_LEAVE_ERR_MSG);

getvar(name::VarName; kwds...) = getvar(TclInterp(), name; kwds...)

getvar(::Type{T}, name::VarName; kwds...) where {T} = getvar(T, TclInterp(), name; kwds...)

getvar(interp::TclInterp, name::VarName; kwds...) = getvar(TclObj, interp, name; kwds...)

function getvar(::Type{T}, interp::TclInterp, name::Name;
                flags::Integer = getvar_default_flags) where {T}
    GC.@preserve interp name begin
        value_ptr = unsafe_getvar(interp, name, flags)
        isnull(value_ptr) && getvar_error(interp, name, flags)
        return unsafe_get(T, value_ptr)
    end
end

function getvar(::Type{T}, interp::TclInterp, (part1, part2)::NTuple{2,Name};
                flags::Integer = getvar_default_flags) where {T}
    GC.@preserve interp part1 part2 begin
        value_ptr = unsafe_getvar(interp, part1, part2, flags)
        isnull(value_ptr) && getvar_error(interp, (part1, part2), flags)
        return unsafe_get(T, value_ptr)
    end
end

@noinline function getvar_error(interp::TclInterp, name::VarName, flags::Integer)
    local mesg
    if iszero(flags & TCL_LEAVE_ERR_MSG)
        varname = variable_name(name)
        mesg = "Tcl variable \"$varname\" does not exist"
    else
        mesg = getresult(String, interp)
    end
    tcl_error(mesg)
end

variable_name(name::String) = name
variable_name(name::Name) = string(name)
variable_name((part1,part2)::Tuple{Name,Name}) = "$(part1)($(part2))"

"""
    TclTk.setvar!(interp=TclInterp(), name, value) -> nothing
    interp[name] = value

    TclTk.setvar!(T, interp=TclInterp(), name, value) -> val::T

Set global variable `name` or `part1(part2)` to be `value` in Tcl interpreter `interp` or in
the shared interpreter of the calling thread if this argument is omitted. `name` may be a
2-tuple `(part1, part2)`.

The Tcl variable is deleted if `value` is `unset`, the singleton provided by the
`UnsetIndex` package and exported by the `Tcl` package.

In the last case, the new value of the variable is returned as an instance of type `T` (can
be `TclObj`). The new value may be different from `value` because of trace(s) associated to
this variable.

# See also

[`TclTk.getvar`](@ref), [`TclTk.exists`](@ref), and [`TclTk.unsetvar!`](@ref).

"""
function setvar! end

const setvar_default_flags = (TCL_GLOBAL_ONLY|TCL_LEAVE_ERR_MSG);

setvar!(name::VarName, value; kwds...) = setvar!(TclInterp(), name, value; kwds...)

setvar!(::Type{T}, name::VarName, value; kwds...) where {T} =
    setvar!(T, TclInterp(), name, value; kwds...)

setvar!(interp::TclInterp, name::VarName, value; kwds...) =
    setvar!(Nothing, interp, name, value; kwds...)

setvar!(interp::TclInterp, name::VarName, ::Unset; kwds...) =
    unsetvar!(interp, name; nocomplain=true, kwds...)

function setvar!(::Type{T}, interp::TclInterp, name::Name, value;
                 flags::Integer = setvar_default_flags) where {T}
    GC.@preserve interp name value begin
        interp_ptr = checked_pointer(interp)
        name_ptr = null(ObjPtr)
        value_ptr = null(ObjPtr)
        try
            # Retrieve pointers and increment reference counts.
            name_ptr = Tcl_IncrRefCount(unsafe_objptr(name, "Tcl variable name"))::ObjPtr
            value_ptr = Tcl_IncrRefCount(unsafe_objptr(value, "Tcl variable value"))::ObjPtr
            # Call C function (can only throw if `flags` is not a valid `Cint`).
            new_value_ptr = Tcl_ObjSetVar2(interp_ptr, name_ptr, null(ObjPtr), value_ptr, flags)
            isnull(new_value_ptr) && setvar_error(interp, name, flags)
            if T == Nothing
                return nothing
            else
                return unsafe_get(T, new_value_ptr)
            end
        finally
            # Decrement reference counts.
            isnull(name_ptr) || Tcl_DecrRefCount(name_ptr)
            isnull(value_ptr) || Tcl_DecrRefCount(value_ptr)
        end
    end
end

function setvar!(::Type{T}, interp::TclInterp, (part1, part2)::NTuple{2,Name}, value;
                 flags::Integer = setvar_default_flags) where {T}
    GC.@preserve interp part1 part2 value begin
        interp_ptr = checked_pointer(interp)
        part1_ptr = null(ObjPtr)
        part2_ptr = null(ObjPtr)
        value_ptr = null(ObjPtr)
        try
            # Retrieve pointers and increment reference counts.
            part1_ptr = Tcl_IncrRefCount(unsafe_objptr(part1, "Tcl array name"))::ObjPtr
            part2_ptr = Tcl_IncrRefCount(unsafe_objptr(part2, "Tcl array index"))::ObjPtr
            value_ptr = Tcl_IncrRefCount(unsafe_objptr(value, "Tcl array value"))::ObjPtr
            # Call C function (can only throw if `flags` is not a valid `Cint`).
            new_value_ptr = Tcl_ObjSetVar2(interp_ptr, part1_ptr, part2_ptr, value_ptr, flags)
            isnull(new_value_ptr) && setvar_error(interp, (part1, part2), flags)
            if T == Nothing
                return nothing
            else
                return unsafe_get(T, new_value_ptr)
            end
        finally
            # Decrement reference counts.
            isnull(part2_ptr) || Tcl_DecrRefCount(part1_ptr)
            isnull(part1_ptr) || Tcl_DecrRefCount(part2_ptr)
            isnull(value_ptr) || Tcl_DecrRefCount(value_ptr)
        end
    end
end

@noinline function setvar_error(interp::TclInterp, name::VarName, flags::Integer)
    local mesg::String
    if iszero(flags & TCL_LEAVE_ERR_MSG)
        varname = variable_name(name)
        mesg = "cannot set Tcl variable \"$varname\""
    else
        mesg = getresult(String, interp)
    end
    tcl_error(mesg)
end

"""
    TclTk.unsetvar!(interp=TclInterp(), name)
    interp[name] = unset
    delete!(interp, name) -> interp

Delete global variable `name` in Tcl interpreter `interp` or in the shared interpreter of
the thread if this argument is omitted. `name` may be a 2-tuple `(part1, part2)`. Above,
`unset` is the singleton provided by the `UnsetIndex` package and exported by the `TclTk`
package.

# Keywords

Keyword `nocomplain` can be set true to ignore errors. By default, `nocomplain=false`.

Keyword `flag` can be set with bits such as `TCL_GLOBAL_ONLY` (set by default) and
`TCL_LEAVE_ERR_MSG` (set by default unless `nocomplain` is true).

# See also

[`TclTk.getvar`](@ref), [`TclTk.exists`](@ref), and [`TclTk.setvar!`](@ref).

"""
function unsetvar! end

function unsetvar_default_flags(nocomplain::Bool)
    return nocomplain ? TCL_GLOBAL_ONLY : (TCL_GLOBAL_ONLY|TCL_LEAVE_ERR_MSG)
end

unsetvar!(name::VarName; kwds...) = unsetvar!(TclInterp(), name; kwds...)

# In <tcl.h> unsetting a variable requires its name part(s) as string(s). This conversion is
# automatically done for `ccall` by `Base.cconvert` and `Base.unsafe_convert`.
function unsetvar!(interp::TclInterp, name::Name; nocomplain::Bool = false,
                   flags::Integer = unsetvar_default_flags(nocomplain))
    status = Tcl_UnsetVar(interp, name, flags)
    status == TCL_OK || nocomplain || unsetvar_error(interp, name, flags)
    return nothing
end
function unsetvar!(interp::TclInterp, (part1, part2)::NTuple{2,Name};
                   nocomplain::Bool = false,
                   flags::Integer = unsetvar_default_flags(nocomplain))
    status = Tcl_UnsetVar2(interp, part1, part2, flags)
    status == TCL_OK || nocomplain || unsetvar_error(interp, (part1, part2), flags)
    return nothing
end

@noinline function unsetvar_error(interp::TclInterp, name::VarName, flags::Integer)
    local mesg::String
    if iszero(flags & TCL_LEAVE_ERR_MSG)
        varname = variable_name(name)
        mesg = "Tcl variable \"$varname\" does not exist"
    else
        mesg = getresult(String, interp)
    end
    tcl_error(mesg)
end

"""
    TclTk.Impl.unsafe_getvar(interp, name, flags) -> value_ptr
    TclTk.Impl.unsafe_getvar(interp, part1, part2, flags) -> value_ptr

Private function to get the value of a Tcl variable. Return a pointer `value_ptr` to the Tcl
object storing the value or *null* if the variable does not exists.

This method is *unsafe* because the pointer `value_ptr` to the variable value is only valid
while the interpreter is not deleted. Furthermore, the variable name part(s) must be valid.
Hence, the caller shall have preserved the interpreter and the variable name part(s) from
being deleted.

# See also

[`TclTk.getvar`](@ref), [`TclTk.exists`](@ref), and [`TclTk.Impl.unsafe_setvar!`](@ref).

"""
function unsafe_getvar end

# Private function `unsafe_getvar` is called to fetch a Tcl variable and get a value pointer
# which may be NULL if variable does not exist, otherwise its reference count is left
# unchanged.
#
# We always call Tcl_ObjGetVar2 to fetch a variable value because it is the most efficient.
# We have to take care of converting variable name parts to temporary Tcl objects as needed
# and manage their reference counts.

function unsafe_getvar(interp::TclInterp, name::FastString, flags::Integer)
    return Tcl_GetVar2Ex(interp, name, C_NULL, flags)
end

function unsafe_getvar(interp::TclInterp, name::Name, flags::Integer)
    # Make sure `flags` is a valid `Cint` to avoid any chance that `Tcl_ObjGetVar2` may
    # throw.
    flags = Cint(flags)::Cint
    interp_ptr = checked_pointer(interp)
    name_ptr = Tcl_IncrRefCount(unsafe_objptr(name, "Tcl variable name"))
    value_ptr = Tcl_ObjGetVar2(interp_ptr, name_ptr, null(ObjPtr), flags)
    Tcl_DecrRefCount(name_ptr)
    return value_ptr
end

function unsafe_getvar(interp::TclInterp, part1::FastString, part2::FastString,
                       flags::Integer)
    return Tcl_GetVar2Ex(interp, part1, part2, flags)
end

function unsafe_getvar(interp::TclInterp, part1::Name, part2::Name, flags::Integer)
    # In a comment of Tcl C code for `Tcl_ObjGetVar2`, it is written that "Callers must incr
    # part2Ptr if they plan to decr it."
    interp_ptr = checked_pointer(interp)
    part1_ptr = null(ObjPtr)
    part2_ptr = null(ObjPtr)
    try
        # Retrieve pointers and increment reference counts.
        part1_ptr = Tcl_IncrRefCount(unsafe_objptr(part1, "Tcl array name"))::ObjPtr
        part2_ptr = Tcl_IncrRefCount(unsafe_objptr(part2, "Tcl array index"))::ObjPtr
        # Call C function.
        return Tcl_ObjGetVar2(interp_ptr, part1_ptr, part2_ptr, flags)
    finally
        # Decrement reference counts.
        isnull(part1_ptr) || Tcl_DecrRefCount(part1_ptr)
        isnull(part2_ptr) || Tcl_DecrRefCount(part2_ptr)
    end
end
