module TclBaseTests

using TclTk
using Colors
using Test

# We need some irrational constants.
const π = MathConstants.π
const φ = MathConstants.φ

@enum Fruit apple=1 orange=2 kiwi=3

@testset "Utilities" begin
    # Version number.
    version = @inferred tcl_version()
    @test version.major == TCL_MAJOR_VERSION
    @test version.minor == TCL_MINOR_VERSION

    # Convert to Boolean.
    @test @inferred(TclTk.bool(true)) === true
    @test @inferred(TclTk.bool(false)) === false
    @test @inferred(TclTk.bool("0")) === false
    @test @inferred(TclTk.bool("0.0")) === false
    @test @inferred(TclTk.bool(0)) === false
    @test @inferred(TclTk.bool(0x00)) === false
    @test @inferred(TclTk.bool(0//1)) === false
    @test @inferred(TclTk.bool(0.0)) === false
    @test @inferred(TclTk.bool(-0.0)) === false
    @test @inferred(TclTk.bool(1)) === true
    @test @inferred(TclTk.bool(-1234)) === true
    @test @inferred(TclTk.bool(π)) === true
    @test @inferred(TclTk.bool(Inf)) === true
    @test @inferred(TclTk.bool("1")) === true
    @test @inferred(TclTk.bool("4.2")) === true
    @test @inferred(TclTk.bool(:true)) === true
    @test @inferred(TclTk.bool(:True)) === true
    @test @inferred(TclTk.bool(:TRUE)) === true
    @test @inferred(TclTk.bool(:yes)) === true
    @test @inferred(TclTk.bool(:Yes)) === true
    @test @inferred(TclTk.bool(:YES)) === true
    @test @inferred(TclTk.bool(:on)) === true
    @test @inferred(TclTk.bool(:On)) === true
    @test @inferred(TclTk.bool(:ON)) === true
    @test @inferred(TclTk.bool(:false)) === false
    @test @inferred(TclTk.bool(:False)) === false
    @test @inferred(TclTk.bool(:FALSE)) === false
    @test @inferred(TclTk.bool(:no)) === false
    @test @inferred(TclTk.bool(:No)) === false
    @test @inferred(TclTk.bool(:NO)) === false
    @test @inferred(TclTk.bool(:off)) === false
    @test @inferred(TclTk.bool(:Off)) === false
    @test @inferred(TclTk.bool(:OFF)) === false
    @test_throws ArgumentError TclTk.bool("")
    @test_throws ArgumentError TclTk.bool("oui")
    @test_throws ArgumentError TclTk.bool("maybe")
    @test @inferred(TclTk.bool(TclObj(true))) === true
    @test @inferred(TclTk.bool(TclObj(false))) === false
end

@testset "Tcl Objects" begin
    script = "puts {hello world!}"
    symbolic_script = Symbol(script)
    x = @inferred TclObj(script)
    @test x isa TclObj
    @test length(propertynames(x)) == 3
    @test hasproperty(x, :ptr)
    @test hasproperty(x, :refcnt)
    @test hasproperty(x, :type)
    @test x.type == :string
    @test isone(x.refcnt)
    @test isreadable(x)
    @test iswritable(x)
    @test x.ptr === @inferred(pointer(x))
    @test script == @inferred string(x)
    @test script == @inferred String(x)
    @test script == @inferred convert(String, x)
    @test x == x
    @test x == script
    @test script == x
    @test x == symbolic_script
    @test symbolic_script == x
    @test isequal(x, x)
    @test isequal(x, script)
    @test isequal(script, x)
    @test isequal(x, symbolic_script)
    @test isequal(symbolic_script, x)

    # copy() yields same but distinct objects
    y = @inferred copy(x)
    @test y isa TclObj
    @test y.type == :string
    @test isone(y.refcnt) && isone(x.refcnt)
    @test y.ptr !== x.ptr
    @test x == y
    @test isequal(x, y)

    # length() converts object into a list
    @test length(y) === 2 # there are 2 tokens in the script
    @test y.type == :list
    @test firstindex(y) === 1
    @test lastindex(y) === length(y)
    @test @inferred(eltype(y)) === TclObj
    @test @inferred(eltype(typeof(y))) === TclObj
    @test y[1] == "puts"
    @test y[2] == "hello world!"

    # `boolean` type.
    x = @inferred TclObj("true")
    @test x.type == :string
    @test @inferred(repr(x)) == "TclObj(\"true\")"
    @test convert(Bool, x) === true
    @test x.type == :boolean
    @test @inferred(repr(x)) == "TclObj(true)"
    x = @inferred TclObj("false")
    @test x.type == :string
    @test @inferred(repr(x)) == "TclObj(\"false\")"
    @test convert(Bool, x) === false
    @test x.type == :boolean
    @test @inferred(repr(x)) == "TclObj(false)"

    # Destroy object and then calling the garbage collector must not throw.
    z = TclObj(0)
    z = 0 # no longer a Tcl object
    @test try GC.gc(); true; catch; false; end

    # Conversions. NOTE Tcl conversion rules are more restricted than Julia.
    # TODO Test unsigned integers.
    values = (true, false, -1, 0x03, Int16(8), Int32(-217),
              typemin(Int8), typemax(Int8),
              typemin(Int16), typemax(Int16),
              typemin(Int32), typemax(Int32),
              typemin(Int64), typemax(Int64),
              0.0f0, 1.0, 2//3, π, big(1.3))
    types = (Bool, Int8, Int16, Int32, Int64, Integer, Float32, Float64, AbstractFloat)
    @testset "Conversion of $x::$(typeof(x)) to $T" for x in values, T in types
        y = @inferred TclObj(x)
        if x isa Integer
            @test y.type ∈ (:int, :wideInt)
        else
            @test y.type == :double
        end
        if T == Bool
            @test (@inferred Bool convert(Bool, y)) == !iszero(x)
        elseif T <: Integer
            if !(x isa Integer)
                # Floating-point to non-Boolean integer is not allowed by TclTk.
                @test_throws TclError convert(T, y)
            else
                S = (isconcretetype(T) ? T : TclTk.WideInt)
                if typemin(S) ≤ x ≤ typemax(S)
                    @test (@inferred S convert(T, y)) == convert(S, x)
                else
                    @test_throws Union{TclError,InexactError} convert(T, y)
                end
            end
        else # T is non-integer real
            S = (T === AbstractFloat ? Float64 : T)
            @test (@inferred S convert(T, y)) == convert(S, x)
        end
    end

    # Tuples.
    x = @inferred TclObj(:hello)
    @test x.type == :string
    @test x == :hello
    @test x == "hello"
    t = (2, -3, x, 8.0)
    @test x.refcnt == 1
    y = @inferred TclObj(t)
    @test x.refcnt == 2
    @test y.type == :list
    @test length(y) == length(t)
    # TODO @test y == t

    # Colors.
    c = @inferred TclObj TclObj(colorant"pink")
    @test TclObj(colorant"red") ∈ ("#FF0000", "#ff0000")
end

@testset "Tcl Interpreters" begin
    # Constructor.
    interp = @inferred TclInterp()
    shared = @inferred TclInterp(:shared)
    private = @inferred TclInterp(:private)
    @test interp === shared
    @test private != shared
    @test !isequal(private, shared)
    @test startswith(sprint(show, interp), "Tcl interpreter (address:")
    @test startswith(sprint(show, MIME"text/plain"(), interp), "Tcl interpreter (address:")
    @test (@inferred TclTk.isactive(private)) isa Bool
    @test (@inferred TclTk.isdeleted(private)) isa Bool
    @test (@inferred TclTk.issafe(private)) isa Bool

    # Interpreter result.
    val = "hello world!"
    interp[] = val
    x = @inferred interp[]
    y = @inferred interp.result()
    z = @inferred TclTk.getresult()
    @test x isa TclObj
    @test y isa TclObj
    @test z isa TclObj
    @test val == x
    @test val == y
    @test val == z
    val = -12345 # must be a bit type
    interp[] = val
    x = @inferred interp[typeof(val)]
    y = @inferred interp.result(typeof(val))
    z = @inferred TclTk.getresult(typeof(val))
    @test x isa typeof(val)
    @test y isa typeof(val)
    @test z isa typeof(val)
    @test val === x
    @test val === y
    @test val === z
    val += 1
    TclTk.setresult!(val)
    z = @inferred TclTk.getresult(typeof(val))
    @test z isa typeof(val)
    @test val == z

    # Properties.
    @test :concat   ∈ @inferred propertynames(interp)
    @test :eval     ∈ @inferred propertynames(interp)
    @test :exec     ∈ @inferred propertynames(interp)
    @test :list     ∈ @inferred propertynames(interp)
    @test :ptr      ∈ @inferred propertynames(interp)
    @test :result   ∈ @inferred propertynames(interp)
    @test :threadid ∈ @inferred propertynames(interp)
    @test TclInterp().threadid == Threads.threadid()
    @test TclInterp().ptr == @inferred pointer(interp)
    @test_throws KeyError TclInterp().non_existing_property
    @test_throws KeyError TclInterp().non_existing_property = 3
    @test_throws ErrorException TclInterp().result = 3

    # Lists.
    t = (1, "a b {c d}", 0)
    x = @inferred interp.list(t...)
    y = @inferred interp.concat(t...)
    @test x isa TclObj
    @test x.type == :list
    @test length(x) == 3
    @test y isa TclObj
    @test length(y) == 5
    @test x == TclTk.list(t...)
    @test y == TclTk.concat(t...)

    # Global variables.
    name, val = "some_name", -12345
    private[name] = val
    @test haskey(private, name)
    @test (@inferred private[name]) isa TclObj
    @test TclObj(val) == @inferred private[name]
    delete!(private, name)
    @test !haskey(private, name)
    name, val = "some_other_name", -13/4
    private[name] = val
    @test haskey(private, name)
    @test TclObj(val) == @inferred private[name]
    private[name] = unset
    @test !haskey(private, name)
    delete!(private, name)

    # Evaluation of scripts.
    name, val = "globvar", 4321
    @test TclObj(val) == @inferred private.eval("set $name $val")
    @test haskey(private, name)
    @test TclObj(val) == @inferred private[name]
    delete!(private, name)
    @test_throws TclError @inferred private.eval("set $name")
    @test TCL_ERROR === @inferred private.eval(TclStatus, "set $name")

    # Execution of commands.
    name, val = "arr(1)", 789
    @test TclObj(val) == @inferred private.exec(:set, name, val)
    @test haskey(private, name)
    @test TclObj(val) == @inferred private[name]
    delete!(private, name)
    @test_throws TclError private.exec(:set, name)
    @test TCL_ERROR === @inferred private.exec(TclStatus, "set", name)
    @test TclObj(val) == @inferred private(:set, name, val)
    @test haskey(private, name)
    @test TclObj(val) == @inferred private[name]
    delete!(private, name)
    @test_throws TclError private(:set, name)
    @test TCL_ERROR === @inferred private(TclStatus, "set", name)
    @test_throws TclError private(:continue)
    @test_throws TclError private("break")

    # Options and enumeration.
    @test TCL_OK === @inferred private(TclStatus, :return, :code => TCL_OK)
    @test TCL_ERROR === @inferred private(TclStatus, :return, :code => TCL_ERROR)
    @test apple === @inferred private(Fruit, :set, "fruit", apple)
    @test kiwi === @inferred private.eval(Fruit, "set fruit $(Integer(kiwi))")

    # Explicitly delete private interpreter to call finalizer.
    private = 0
    GC.gc()
end

@testset "Events" begin
    # Make sure event handler is not running.
    TclTk.isrunning() && TclTk.suspend()
    @test (@inferred TclTk.isrunning()) === false
    # Create some delayed task.
    TclTk.eval("set jl_counter 0")
    id = TclTk.exec(:after, 1, "incr jl_counter")
    sleep(0.1)
    @test TclTk.eval("set jl_counter") == "0"
    TclTk.resume()
    @test (@inferred TclTk.isrunning()) === true
    sleep(0.1) # sleep for a while so that events can be processed
    @test TclTk.eval("set jl_counter") == "1"
    TclTk.suspend()
    @test (@inferred TclTk.isrunning()) === false
end

@testset "Tcl Variables" begin
    # Get default interpreter.
    interp = @inferred TclInterp()

    # Accessing or deleting a non-existing variable is an error.
    TclTk.unsetvar!("non_existing_variable"; nocomplain=true)
    TclTk.unsetvar!("non_existing_array"; nocomplain=true)
    @test_throws TclError TclTk.getvar("non_existing_variable")
    @test_throws TclError TclTk.getvar("non_existing_variable"; flags=TCL_GLOBAL_ONLY)
    @test_throws TclError TclTk.getvar(:non_existing_variable)
    @test_throws TclError TclTk.getvar(:non_existing_variable; flags=TCL_GLOBAL_ONLY)
    @test_throws TclError TclTk.getvar(("non_existing_array", 1))
    @test_throws TclError TclTk.getvar(("non_existing_array", 1); flags=TCL_GLOBAL_ONLY)
    @test_throws TclError TclTk.getvar(:non_existing_variable)
    @test_throws TclError TclTk.getvar(:non_existing_variable; flags=TCL_GLOBAL_ONLY)
    @test_throws TclError TclTk.unsetvar!(:non_existing_variable)
    @test_throws TclError TclTk.unsetvar!(:non_existing_variable; flags=TCL_GLOBAL_ONLY)

    # Manage to make any operation on a variable fail. NOTE Errors in `unset` traces are
    # ignored.
    name = "some_name"
    for (op, trace) in TclTk.exec(:trace, :info, :variable, name)
        # Remove all existing traces.
        TclTk.exec(Nothing, :trace, :remove, :variable, name, op, trace)
    end
    trace = "forbidden_operation_on_variable"
    TclTk.eval(Nothing, """
proc $trace {name1 name2 op} {
    if {\$name2 eq ""} {
        set name "\$name1"
    } else {
        set name "\${name1}(\${name2})"
    }
    error "attempt to \$op variable \\"\$name\\""
}
""")
    TclTk.setvar!(name, "some_value")
    TclTk.exec(Nothing, :trace, :add, :variable, name, :read, trace)
    @test_throws TclError TclTk.getvar(name)
    TclTk.exec(Nothing, :trace, :add, :variable, name, :write, trace)
    @test_throws TclError TclTk.setvar!(name, "some_other_value")
    TclTk.unsetvar!(name) # this also deletes all traces

    @test_deprecated TclTk.setvar("some_name", "some_value")
    @test interp["some_name"] == "some_value"
    @test_deprecated TclTk.unsetvar("some_name")
    @test !haskey(interp, "some_name")

    for (name, value) in (("a", 42),
                          ("1", 1),
                          ("", "empty"),
                          ("π", π),
                          ("world is beautiful!", true),
                          # 2-part variable names.
                          (("a", "i"), 42),
                          (("1", "2"), 12),
                          (("", ""), "really empty"),
                          (("π", "φ"), π),
                          (("world is", "beautiful!"), true))

        # First unset variable.
        if name isa Tuple
            @inferred TclTk.exec(TclStatus, "array", "unset", first(name))
        else
            @inferred TclTk.exec(TclStatus, "array", "unset", name)
        end

        # Symbolic variable name.
        key = name isa Tuple ? map(Symbol, name) : Symbol(name)

        # Set variable.
        if name isa Tuple
            @test_deprecated TclTk.setvar!(name..., value)
            @test_deprecated TclTk.unsetvar!(name...)
        end
        @test nothing === @inferred TclTk.setvar!(name, value)
        obj = @inferred TclTk.setvar!(TclObj, name, value)
        @test obj isa TclObj
        @test obj == TclObj(value)

        # Get variable.
        T = typeof(value)
        obj = @inferred TclTk.getvar(name)
        @test obj isa TclObj
        @test obj == @inferred interp[name]
        @test obj == @inferred interp[key]
        if name isa Tuple
            part1, part2 = name
            x = @inferred interp["$(part1)($(part2))"]
            @test x isa TclObj
            @test obj == x
            y = @test_deprecated TclTk.getvar(part1, part2)
            @test y isa TclObj
            @test obj == y
        end
        if value isa Union{String,Integer}
            x = @inferred TclTk.getvar(T, name)
            @test x isa T
            @test value == x
            y = @inferred interp[T, name]
            @test y isa T
            @test value == y
        elseif value isa AbstractFloat
            x = @inferred TclTk.getvar(T, name)
            @test x isa T
            @test value ≈ x
            y = @inferred interp[T, name]
            @test y isa T
            @test value ≈ y
            @test x == y
        end

        # Test existence and delete variable.
        @test TclTk.exists(name)
        @test haskey(interp, name)
        @test haskey(interp, key)
        TclTk.unsetvar!(name)
        @test !TclTk.exists(name)
        @test !haskey(interp, name)
        @test !haskey(interp, key)

        # Delete with `delete!`.
        interp[name] = value
        @test haskey(interp, name)
        delete!(interp, name)
        @test !haskey(interp, name)

        # Delete with `unset`.
        interp[name] = value
        @test haskey(interp, name)
        interp[name] = unset
        @test !haskey(interp, name)

    end

end

@testset "Tcl Lists" begin
    # NULL object pointer yields empty list.
    objc, objv = @inferred TclTk.Impl.unsafe_get_list_elements(Ptr{TclTk.Impl.Tcl_Obj}(0))
    @test objc === 0
    @test objv === Ptr{Ptr{TclTk.Impl.Tcl_Obj}}(0)

    # Tcl "list".
    wa = ("", 1, "hello world!", (true, false), -3.75, π)
    wf = (1, "hello", "world!", true, false, -3.75, π) # "concat" version
    wb = @inferred TclTk.list(wa...)
    wc = @inferred TclObj(wa)
    @test wb isa TclObj
    @test wc isa TclObj
    @test wb.type == :list
    @test wc.type == :list
    @test @inferred(length(wb)) == length(wa)
    @test @inferred(length(wc)) == length(wa)
    @test wb == wc
    @test all(wb .== wc)
    @test all([wb[i] == TclObj(wa[i]) for i in 1:length(wa)])
    @test all([wc[i] == TclObj(wa[i]) for i in 1:length(wa)])
    @test wb[4].type == :list
    @test wc[4].type == :list
    @test wb[4][1] == TclObj(wa[4][1])
    @test wc[4][2] == TclObj(wa[4][2])

    # Out of range index yield "missing".
    @test missing === @inferred Missing wb[0]
    @test missing === @inferred Missing wb[length(wb)+1]

    # Set index in list.
    wb[1] = 3
    wb[3] = wc[4]
    wb_1 = @inferred TclObj wb[1]
    @test wb_1 isa TclObj
    wb_3 = @inferred TclObj wb[3]
    @test wb_3 isa TclObj
    wc_4 = @inferred TclObj wc[4]
    @test wc_4 isa TclObj
    @test wb_1 == TclObj(3)
    @test wb_3 == wc_4

    # Tcl "concat".
    wd = @inferred TclTk.concat(wa...)
    @test wd isa TclObj
    @test wd.type == :list
    @test @inferred(length(wd)) == length(wf)
    @test all([wd[i] == TclObj(wf[i]) for i in 1:length(wf)])

    # List to vectors.
    t = (-1:3...,)
    o = @inferred TclObj(t)
    @test o isa TclObj
    v = @inferred convert(Vector{Int16}, o)
    @test v isa Vector{Int16}
    @test Tuple(v) == t
    v = @inferred convert(Vector{String}, o)
    @test v isa Vector{String}
    @test Tuple(v) == map(string, t)

end

end # module
