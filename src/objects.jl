"""
    TclObj(val) -> obj

Return a Tcl object storing value `val`. The initial type of the Tcl object, given by
`obj.type`, depends on the type of `val`:

- A string, symbol, or character is stored as a Tcl `:string`.

- A Boolean or integer is stored as a Tcl `:int` or `:wideInt`.

- A non-integer real is stored as a Tcl `:double`.

- A dense vector of bytes (`UInt8`) is stored as a Tcl `:bytearray`.

- A tuple is stored as a Tcl `:list`.

- A Tcl object is returned unchanged. Call `copy` to have an independent copy.

If the content of a Tcl object is valid as a list, the object may be indexed, elements may
be added, deleted, etc.

# Properties

Tcl objects have the following properties:

- `obj.refcnt` yields the reference count of `obj`. If `obj.refcnt > 1`, the object is
  shared and must be copied before being modified.

- `obj.ptr` yields the pointer to the Tcl object, this is the same as `pointer(obj)`.

- `obj.type` yields the *current internal type* of `obj` as a symbol. This type may change
  depending on how the object is used by Tcl. For example, after having evaluated a script
  in a Tcl string object, the object internal state becomes `:bytecode` to reflect that it
  now stores compiled byte code.

# Conversion

Call `convert(T, obj)` to get a value of type `T` from Tcl object `obj`. The content of a
Tcl object may always be converted into a string by calling `convert(String, obj)`,
`string(obj)`, or `String(obj)` which all yield a copy of this string.

# See also

[`TclTk.list`](@ref) or [`TclTk.concat`](@ref) for building Tcl objects to efficiently store
arguments of Tcl commands.

Methods [`TclTk.Impl.value_type`](@ref) and [`TclTk.Impl.new_object`](@ref) may be extended to
convert other types of value to Tcl object.

"""
TclObj(obj::TclObj) = obj
TclObj() = TclObj(null(ObjPtr))
TclObj(val) = _TclObj(new_object(val))
TclObj(objptr::ObjPtr) = _TclObj(objptr)

function Base.copy(obj::TclObj)
    local objptr
    GC.@preserve obj begin
        objptr = unsafe_duplicate(pointer(obj))
    end
    return _TclObj(objptr)
end

function unsafe_duplicate(objptr::ObjPtr)
    if isnull(objptr) || Tcl_GetRefCount(objptr) < 𝟙
        return objptr
    else
        return Tcl_DuplicateObj(objptr)
    end
end

Base.string(obj::TclObj) = String(obj)
Base.String(obj::TclObj) = convert(String, obj)

Base.convert(::Type{TclObj}, obj::TclObj) = obj
function Base.convert(::Type{T}, obj::TclObj) where {T}
    GC.@preserve obj begin
        val = unsafe_value(value_type(T), checked_pointer(obj))
        return convert(T, val)::T
    end
end
for type in (isdefined(Base, :Memory) ? (:Vector, :Memory) : (:Vector,))
    @eval begin
        Base.convert(::Type{$type{T}}, obj::TclObj) where {T} = $type{T}(obj)::$type{T}
        function Base.$type{T}(list::TclObj) where {T}
            GC.@preserve list begin
                objc, objv = unsafe_get_list_elements(pointer(list))
                vec = $type{T}(undef, objc)
                for i in 𝟙:objc
                    vec[i] = unsafe_value(T, unsafe_load(objv, i))
                end
                return vec
            end
        end
    end
end

Base.:(==)(A::TclObj, B::TclObj) = isequal(A, B)
Base.:(==)(A::TclObj, B::Union{AbstractString,Symbol}) = isequal(A, B)
Base.:(==)(A::Union{AbstractString,Symbol}, B::TclObj) = isequal(A, B)

function Base.isequal(A::TclObj, B::TclObj)
    # TODO Optimize depending on internal representation?
    GC.@preserve A B begin
        A_ptr = pointer(A)
        B_ptr = pointer(B)
        (A_ptr == B_ptr) && return true
        (isnull(A_ptr) || isnull(B_ptr)) && return false
        A_len = Ref{Tcl_Size}()
        A_buf = Tcl_GetStringFromObj(A_ptr, A_len)
        B_len = Ref{Tcl_Size}()
        B_buf = Tcl_GetStringFromObj(B_ptr, B_len)
        (A_len[] == B_len[]) || return false
        return iszero(unsafe_memcmp(A_buf, B_buf, B_len[]))
    end
end

Base.isequal(A::Union{AbstractString,Symbol}, B::TclObj) = isequal(B, A)

Base.isequal(A::TclObj, B::AbstractString) = isequal(A, String(B)::String)

function Base.isequal(A::TclObj, B::FastString)
    GC.@preserve A B begin
        A_ptr = pointer(A)
        isnull(A_ptr) && return false
        A_len = Ref{Tcl_Size}()
        A_buf = Tcl_GetStringFromObj(A_ptr, A_len)
        B_len = sizeof(B) # number of bytes in B
        (A_len[] == B_len) || return false
        return iszero(unsafe_memcmp(A_buf, B, B_len))
    end
end

# Extend `print` so that string interpolation for Tcl objects works as in Tcl scripts.
function Base.print(io::IO, obj::TclObj)
    write(io, obj)
    return nothing
end

function Base.write(io::IO, obj::TclObj)
    return GC.@preserve obj unsafe_write(io, pointer(obj))
end

function Base.unsafe_write(io::IO, objptr::ObjPtr)
    isnull(objptr) && return 0
    len = Ref{Tcl_Size}()
    buf = Tcl_GetStringFromObj(objptr, len)
    return Int(unsafe_write(io, buf, len[]))::Int
end

# Extend base methods for objects.
function Base.summary(io::IO, obj::TclObj)
    print(io, "TclObj: ")
    show_value(io, obj)
end
function Base.summary(obj::TclObj)
    io = IOBuffer()
    summary(io, obj)
    return String(take!(io))
end

function Base.repr(obj::TclObj)
    io = IOBuffer()
    show(io, obj)
    return String(take!(io))
end

Base.show(io::IO, ::MIME"text/plain", obj::TclObj) = show(io, obj)
function Base.show(io::IO, obj::TclObj)
    print(io, "TclObj(")
    show_value(io, obj)
    print(io, ")")
end

function show_value(io::IO, obj::TclObj; maxlen::Integer=50)
    maxlen = max(3, Int(maxlen)::Int)
    halfmaxlen = div(maxlen - 1, 2)
    type = obj.type
    if type ∈ (:int, :wideInt)
        print(io, convert(WideInt, obj))
    elseif type == :double
        print(io, convert(Cdouble, obj))
    elseif type == :bytearray
        print(io, "UInt8[")
        GC.@preserve obj begin
            len = Ref{Tcl_Size}()
            ptr = Tcl_GetByteArrayFromObj(obj, len)
            len = Int(len[])::Int
            if len ≤ maxlen
                for i in 1:len
                    i > 1 && print(io, ", ")
                    show(io, unsafe_load(ptr, i))
                end
            else
                for i in 1:halfmaxlen
                    i > 1 && print(io, ", ")
                    show(io, unsafe_load(ptr, i))
                end
                print(io, ", ...")
                for i in len-halfmaxlen+1:len
                    print(io, ", ")
                    show(io, unsafe_load(ptr, i))
                end
            end
        end
        print(io, "]")
    elseif type == :list
        print(io, "(")
        len = length(obj)
        if len ≤ maxlen
            for i in 1:len
                i > 1 && print(io, ", ")
                show_value(io, obj[i])
            end
        else
            for i in 1:halfmaxlen
                i > 1 && print(io, ", ")
                show_value(io, obj[i])
            end
            print(io, ", ...")
            for i in len-halfmaxlen+1:len
                print(io, ", ")
                show_value(io, obj[i])
            end
        end
        print(io, ",)")
    elseif type == :boolean
        write(io, obj)
    elseif type == :null
        print(io, "#= NULL =#")
    else
        show(io, string(obj))
    end
end

# It is forbidden to access to the fields of a `TclObj` by the `obj.key` syntax.
Base.propertynames(obj::TclObj) = (:ptr, :refcnt, :type)
@inline Base.getproperty(obj::TclObj, key::Symbol) = _getproperty(obj, Val(key))
@inline Base.setproperty!(obj::TclObj, key::Symbol, val) = _setproperty!(obj, Val(key), val)

_getproperty(obj::TclObj, ::Val{key}) where {key} = throw(KeyError(key))
_setproperty!(obj::TclObj, key::Symbol, val) = throw(KeyError(key))

function _getproperty(obj::TclObj, ::Val{:refcnt})
    GC.@preserve obj begin
        ptr = pointer(obj)
        return isnull(ptr) ? -one(Tcl_Obj_refCount_type) : Tcl_GetRefCount(ptr)
    end
end

function _getproperty(obj::TclObj, ::Val{:type})
    GC.@preserve obj begin
        return unsafe_get_typename(pointer(obj))
    end
end

"""
    iswritable(obj) -> bool

Return whether Tcl object `obj` is writable, that is whether its pointer is non-null and it
has at most one reference.

"""
Base.isreadable(obj::TclObj) = isreadable(pointer(obj))
Base.isreadable(objptr::ObjPtr) = !isnull(objptr)

function assert_readable(objptr::ObjPtr)
    isnull(objptr) && assertion_error("null Tcl object has no value")
    return objptr
end

"""
    iswritable(obj) -> bool

Return whether Tcl object `obj` is writable, that is whether its pointer is non-null and it
has at most one reference.

"""
Base.iswritable(obj::TclObj) = iswritable(pointer(obj))
Base.iswritable(objptr::ObjPtr) = !isnull(objptr) && Tcl_GetRefCount(objptr) ≤ 𝟙

function assert_writable(objptr::ObjPtr)
    isnull(objptr) && assertion_error("null Tcl object is not writable")
    Tcl_GetRefCount(objptr) > 𝟙 && assertion_error("shared Tcl object is not writable")
    return objptr
end

function finalize(obj::TclObj)
    obj.ptr = null(ObjPtr)
    return nothing
end

function _getproperty(obj::TclObj, ::Val{:ptr})
    return getfield(obj, :ptr)
end

function _setproperty!(obj::TclObj, ::Val{:ptr}, newptr::ObjPtr)
    oldptr = getfield(obj, :ptr)
    if newptr != oldptr
        isnull(newptr) || Tcl_IncrRefCount(newptr)
        isnull(oldptr) || Tcl_DecrRefCount(oldptr)
        setfield!(obj, :ptr, newptr)
    end
    nothing
end

"""
    TclTk.Impl.unsafe_objptr(arg) -> objptr
    TclTk.Impl.unsafe_objptr(arg, descr) -> objptr

Return a pointer to a Tcl object from `arg`. If `arg` is an instance of `TclObj`,
`pointer(arg)` is returned throwing an error if this pointer is null. Otherwise, a new Tcl
object is created from `arg` and the caller is responsible for managing this object so that
it is correctly released when no longer in use. In any case, the returned pointer is
guaranteed to be non-null but may only remain valid while `arg` is not garbage collected.

Optional `descr` provides a description of the argument `arg` for error messages.

# See also

[`TclObj`](@ref), [`TclTk.Impl.WrappedObject`](@ref), and [`TclTk.Impl.new_object`](@ref),

"""
unsafe_objptr(obj::TclObj) = checked_pointer(obj)
function unsafe_objptr(obj::TclObj, descr::AbstractString)
    ptr = pointer(obj)
    isnull(ptr) && unexpected_null(descr)
    return ptr
end

unsafe_objptr(val::Any) = new_object(val)
unsafe_objptr(val::Any, descr::AbstractString) = unsafe_objptr(val)

"""
    TclTk.Impl.value_type(x)
    TclTk.Impl.value_type(typeof(x))

Return the suitable type for storing a Julia object `x` in a Tcl object.

# See also

[`TclTk.Impl.new_object`](@ref) and [`TclTk.Impl.new_list`](@ref).

"""
value_type(x) = value_type(typeof(x))

"""
    TclTk.Impl.new_object(x) -> ptr

Return a pointer to a new Tcl object storing value `x`. The new object has a reference count
of `0`.

# See also

[`TclObj`](@ref), [`TclTk.Impl.new_list`](@ref), [`TclTk.Impl.value_type`](@ref),
[`TclTk.Impl.Tcl_GetRefCount`](@ref), [`TclTk.Impl.Tcl_IncrRefCount`](@ref), and
[`TclTk.Impl.Tcl_DecrRefCount`](@ref).

"""
new_object

"""
    TclTk.Impl.unsafe_value(T, objptr) -> val
    TclTk.Impl.unsafe_value(T, interp, objptr) -> val

Get a value of type `T` from Tcl object pointer `objptr`. Optional argument `interp` is a
pointer to a Tcl interpreter which, if non-null, may be used for error messages.

The reference count of `objptr` is left unchanged. Caller shall increment before and
decrement after the reference count of `objptr` to have it automatically preserved and/or
deleted.

!!! warning
    Unsafe function: object pointer must not be null and must remain valid during the call
    to this function, if non-null, `interp` must also remain valid during the call to this
    function.

"""
unsafe_value(::Type{TclObj}, objptr::ObjPtr) = _TclObj(objptr)
function unsafe_value(::Type{T}, interp::InterpPtr, obj::ObjPtr) where {T<:TclObj}
    return unsafe_value(T, obj) # `interp` not needed
end

# Supply pointer (possibly NULL) to interpreter.
unsafe_value(::Type{T}, objptr::ObjPtr) where {T} =
    unsafe_value(T, null(InterpPtr), objptr)
unsafe_value(::Type{T}, interp::TclInterp, objptr::ObjPtr) where {T} =
    unsafe_value(T, null_or_checked_pointer(interp), objptr)

# NOTE `value_type`, `new_object`, and `unsafe_value` must be consistent.
#
# Strings.
#
#     Julia strings and symbols are assumed to be Tcl strings. Julia characters are assumed
#     to Tcl strings of length 1.
#
#     There are two alternatives to create Tcl string objects: `Tcl_NewStringObj` or
#     `Tcl_NewUnicodeObj`. After some testings, the following works correctly. To build a
#     Tcl object from a Julia string, use `Ptr{UInt8}` instead of `Cstring` and provide the
#     number of bytes with `ncodeunit(str)`.
#
value_type(::Type{<:AbstractString}) = String
new_object(str::AbstractString) = new_object(String(str))
function new_object(str::Union{String,SubString{String}})
    # We must preserve `str` because we direct pass its address and size.
    GC.@preserve str begin
        return Tcl_NewStringObj(pointer(str), ncodeunits(str))
    end
end
function unsafe_value(::Type{T}, interp::InterpPtr, obj::ObjPtr) where {T<:String}
    return unsafe_value(T, obj) # `interp` not needed
end
function unsafe_value(::Type{String}, obj::ObjPtr)
    # NOTE `unsafe_string` catches that `ptr` must not be null so we do not check that.
    len = Ref{Tcl_Size}()
    return unsafe_string(Tcl_GetStringFromObj(obj, len), len[])
end
#
# Symbols are considered as Tcl strings.
#
value_type(::Type{Symbol}) = String
function new_object(sym::Symbol)
    return Tcl_NewStringObj(sym, -1)
end
#
# Characters are equivalent to Tcl strings of unit length.
#
value_type(::Type{<:AbstractChar}) = String
new_object(str::AbstractChar) = new_object(string(char))
function unsafe_value(::Type{T}, obj::ObjPtr) where {T<:AbstractChar}
    # FIXME Optimize this.
    str = unsafe_value(String, obj)
    length(str) == 1 || tcl_error("cannot convert Tcl object to `$T` value")
    return first(str)
end
#
# Booleans.
#
#     Despite that it is possible to create boolean objects with `Tcl_NewBooleanObj`, Tcl
#     stores Booleans as `Cint`s and Booleans are retrieved as `Cint` objects.
#
value_type(::Type{Bool}) = Bool
new_object(val::Bool) = Tcl_NewBooleanObj(val)
function unsafe_value(::Type{Bool}, interp::InterpPtr, obj::ObjPtr)
    val = Ref{Cint}()
    status = Tcl_GetBooleanFromObj(interp, obj, val)
    status == TCL_OK || unsafe_error(interp, "cannot convert Tcl object to `Bool` value")
    return !iszero(val[])
end
#
# Integers.
#
#     For each integer type, we choose the Tcl integer which is large enough to store a
#     value of that type. Small unsigned integers may be problematic, but not so much as the
#     smallest Tcl integer type is `Cint` which is at least 32 bits.
#
# `Clong` type.
#
value_type(::Type{Clong}) = Clong
new_object(val::Clong) = Tcl_NewLongObj(val)
function unsafe_value(::Type{Clong}, interp::InterpPtr, obj::ObjPtr)
    val = Ref{Clong}()
    status = Tcl_GetLongFromObj(interp, obj, val)
    status == TCL_OK || unsafe_error(interp, "cannot convert Tcl object to `$Clong` value")
    return val[]
end
#
# `Cint` if not the same thing as `Clong`.
#
if Cint != Clong
    value_type(::Type{Cint}) = Cint
    new_object(val::Cint) = Tcl_NewIntObj(val)
    function unsafe_value(::Type{Cint}, interp::InterpPtr, obj::ObjPtr)
        val = Ref{Cint}()
        status = Tcl_GetIntFromObj(interp, obj, val)
        status == TCL_OK || unsafe_error(interp, "cannot convert Tcl object to `$Cint` value")
        return val[]
    end
end
#
# `WideInt` if not the same thing as `Clong` or `Cint`.
#
if WideInt != Clong && WideInt != Cint
    value_type(::Type{WideInt}) = WideInt
    new_object(val::WideInt) = Tcl_NewWideIntObj(val)
    function unsafe_value(::Type{WideInt}, interp::InterpPtr, obj::ObjPtr)
        val = Ref{WideInt}()
        status = Tcl_GetWideIntFromObj(interp, obj, val)
        status == TCL_OK || unsafe_error(interp, "cannot convert Tcl object to `$WideInt` value")
        return val[]
    end
end
#
# Other integer types.
#
function value_type(::Type{T}) where {T<:Integer}
    if isbitstype(T)
        sizeof(T) ≤ sizeof(Cint) && return Cint
        sizeof(T) ≤ sizeof(Clong) && return Clong
    end
    return WideInt
end
function new_object(val::T) where {T<:Integer}
    S = value_type(T)
    T <: S && assertion_error("conversion must change value's type")
    return new_object(convert(S, val)::S)
end
function unsafe_value(::Type{T}, interp::InterpPtr, obj::ObjPtr) where {T<:Integer}
    S = value_type(T)
    T <: S && assertion_error("conversion must change object's type")
    return convert(T, unsafe_value(S, interp, obj))::T
end
#
# Enumeration are like integers.
#
const Enumeration{T} = Union{Enum{T}, CEnum.Cenum{T}}
value_type(::Type{<:Enumeration{T}}) where {T} = value_type(T)
new_object(val::Enumeration{T}) where {T} = new_object(Integer(val))
function unsafe_value(::Type{T}, interp::InterpPtr, obj::ObjPtr) where {S,T<:Enumeration{S}}
    return T(unsafe_value(S, interp, obj))::T
end
#
# Floats.
#
#     Non-integer reals are considered as double precision floating-point numbers.
#
value_type(::Type{<:Real}) = Cdouble
new_object(val::Real) = Tcl_NewDoubleObj(val)
function unsafe_value(::Type{Cdouble}, interp::InterpPtr, obj::ObjPtr)
    val = Ref{Cdouble}()
    status = Tcl_GetDoubleFromObj(interp, obj, val)
    status == TCL_OK || unsafe_error(interp, "cannot convert Tcl object to `$Cdouble` value")
    return val[]
end
function unsafe_value(::Type{T}, interp::InterpPtr, obj::ObjPtr) where {T<:AbstractFloat}
    return convert(T, unsafe_value(Cdouble, interp, obj))::T
end
#
# Tuples are stored as Tcl lists.
#
function new_object(tup::Tuple)
    list = new_list()
    try
        for item in tup
            unsafe_append_element(list, item)
        end
    catch
        Tcl_DecrRefCount(list)
        rethrow()
    end
    return list
end
#
# Dense vector of bytes are stored as Tcl `bytearray` object.
#
value_type(::Type{T}) where {T<:DenseVector{UInt8}} = T
new_object(arr::DenseVector{UInt8}) = Tcl_NewByteArrayObj(arr, length(arr))
function unsafe_value(::Type{T}, interp::InterpPtr,
                    obj::ObjPtr) where {T<:Union{Vector{UInt8},Memory{UInt8}}}
    return unsafe_value(T, obj) # `interp` not needed
end
function unsafe_value(::Type{T}, obj::ObjPtr) where {T<:Union{Vector{UInt8},Memory{UInt8}}}
    len = Ref{Tcl_Size}()
    ptr = Tcl_GetByteArrayFromObj(obj, len)
    len = Int(len[])::Int
    arr = T(undef, len)
    len > 0 && Libc.memcpy(arr, ptr, len)
    return arr
end
#
# Error catchers for unsupported Julia types.
#
@noinline value_type(::Type{T}) where {T} =
    tcl_error("unknown Tcl object type for Julia objects of type `$T`")
@noinline new_object(val::T) where {T} =
    tcl_error("cannot convert an instance of type `$T` into a Tcl object")
@noinline unsafe_value(::Type{T}, interp::InterpPtr, obj::ObjPtr) where {T} =
    tcl_error("retrieving an instance of type `$T` from a Tcl object is not unsupported")
