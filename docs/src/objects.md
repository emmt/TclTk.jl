# Tcl objects

Anything in Tcl can be equivalently expressed as a string but, for efficiency, everything is
stored in Tcl objects. Such objects can be manipulated directly in Julia, as instances of
[`TclObj`](@ref), and may be converted to Julia values (strings, integers, floats, or
vectors of these) as needed. By avoiding systematic string conversion, faster communication
with Tcl/Tk is achieved.

## Creation of Tcl objects

Many functions of `TclTk` may return a Tcl object. But Tcl objects may be explicitly created
by calling the [`TclObj`](@ref) constructor:

```julia
obj = TclObj(val)
```

which yields a Tcl object storing the value `val`. The initial type of the Tcl object, given
by `obj.type`, depends on the type of `val`:

- A string, symbol, or character is stored as a Tcl `:string`.

- A Boolean or integer is stored as a Tcl `:int` or `:wideInt`.

- A non-integer real is stored as a Tcl `:double`.

- A dense vector of bytes (`UInt8`) is stored as a Tcl `:bytearray`.

- A tuple is stored as a Tcl `:list`.

- A Tcl object is returned unchanged. Call `copy` to have an independent copy.

If the content of a Tcl object is valid as a list (in this respect a Tcl `:double` object is
also a single element list), the object may be indexed, elements may be added, deleted, etc.

## Properties of Tcl objects

Tcl objects have the following properties:

- `obj.refcnt` yields the reference count of `obj`. If `obj.refcnt > 1`, the object is
  shared and must be copied before being modified.

- `obj.ptr` yields the pointer to the Tcl object, this is the same as `pointer(obj)`. Using
  this property to call a C function is *unsafe* (the object must be preserved from being
  garbage collected).

- `obj.type` yields the *current internal type* of `obj` as a symbol. This type may change
  depending on how the object is used by Tcl. For example, after having evaluated a script
  in a Tcl string object, the object internal state becomes `:bytecode` to reflect that it
  now stores compiled byte code.


## Conversion of Tcl objects

Simply call `convert(T, obj)` to get a value of type `T` from a Tcl object `obj`. For
example:

```julia-repl
julia> x = TclObj("1.234")
TclObj("1.234")

julia> x.type
:string

julia> convert(Int, x)
ERROR: Tcl/Tk error: cannot convert Tcl object to `Int64` value
…

julia> convert(Float32, x)
1.234f0

julia> convert(Bool, TclObj("yes")) # "yes", "on", and "true" are considered as true in Tcl
true

julia> convert(Bool, TclObj("off")) # "no", "off", and "false" are considered as true in Tcl
false

```

The above error shows that the conversion must make sense. However, the content of a Tcl
object may always be converted into a string by calling `convert(String, obj)`,
`string(obj)`, or `String(obj)` which all yield a copy of this string. For example:

```julia-repl
julia> x = TclObj(1.234)
TclObj(1.234)

julia> x.type
:double

julia> string(x)
"1.234"

julia> convert(String, x)
"1.234"

```

Conversion of a Tcl object to a n-tuple or to a vector is also supported. For basic vector
types (`Vector` or `Memory`), conversion by the constructor is also implemented. If the
element type is `UInt8`, a vector of bytes representing the raw content of the Tcl object is
returned. For other element types, the Tcl object is treated as a list whose elements are
converted to the element type. For example:

```julia-repl
julia> t = (false, true, -1, 12)
(false, true, -1, 12)

julia> x = TclObj(t)
TclObj((0, 1, -1, 12,))

julia> convert(NTuple{4,Integer}, x)
(0, 1, -1, 12)

julia> convert(Tuple{Bool,Bool,Int,Int}, x)
(false, true, -1, 12)

julia> Vector{Int16}(x)
4-element Vector{Int16}:
  0
  1
 -1
 12

julia> Vector{String}(x)
4-element Vector{String}:
 "0"
 "1"
 "-1"
 "12"

julia> v = Vector{UInt8}(x) # conversion to bytes yields raw object content...
9-element Vector{UInt8}:
 0x30
 0x20
 0x31
 0x20
 0x2d
 0x31
 0x20
 0x31
 0x32

julia> s = "$x"
"0 1 -1 12"

julia> codeunits(s) # ... which is like the string representation in this case
9-element Base.CodeUnits{UInt8, String}:
 0x30
 0x20
 0x31
 0x20
 0x2d
 0x31
 0x20
 0x31
 0x32

julia> Memory{Float64}(TclObj(1.25))
1-element Memory{Float64}:
 1.25

julia> Memory{UInt8}(TclObj(1.25))
4-element Memory{UInt8}:
 0x31
 0x2e
 0x32
 0x35

julia> codeunits("1.25")
4-element Base.CodeUnits{UInt8, String}:
 0x31
 0x2e
 0x32
 0x35

julia> b = TclObj([0x01,0xff,0x00,0x3c]) # an array of raw bytes...
TclObj(UInt8[0x01, 0xff, 0x00, 0x3c])

julia> Vector{UInt8}(b) # ... is stored unchanged by the Tcl object
4-element Vector{UInt8}:
 0x01
 0xff
 0x00
 0x3c

```

As shown above, conversion of a Tcl object to an array of bytes is similar to the code units
of the string representation of the object except for `:bytearray` Tcl objects where the raw
byte values are preserved.


## Comparisons with Tcl objects

Base methods `isequal(a, b)` and `a == b` yield whether Tcl objects `a` and `b` have the
same value. Since any kind of Tcl object is equivalent to a string, Tcl objects may also be
compared to strings and symbols for equality:

```julia-repl
julia> a = TclObj(1.234)
TclObj(1.234)

julia> b = TclObj(string(a))
TclObj("1.234")

julia> a.type
:double

julia> b.type
:string

julia> a == b
true

julia> a == "1.234"
true

julia> b == "1.234"
true

julia> c = TclObj("green")
TclObj("green")

julia> c == :green
true

julia> c == "GREEN"
false

```
