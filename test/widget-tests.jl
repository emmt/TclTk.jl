module TkWidgetTests

using TclTk
using Test
using Colors
using Colors: FixedPointNumbers

@testset "Tk Widgets" begin
    w = @inferred TkToplevel(".")
    @test TclTk.isrunning()

    # Properties and winfo fields.
    @test :atomname ∉ propertynames(w)
    id = 1
    name = @inferred w.atomname(id)
    @test name isa String
    #
    @test :atom ∉ propertynames(w)
    @test @inferred(w.atom(name)) === UInt32(id)
    #
    @test :cells ∈ propertynames(w)
    @test w.cells isa Int
    #
    @test :children ∈ propertynames(w)
    @test w.children isa Vector{String}
    #
    @test :colormapfull ∈ propertynames(w)
    @test w.colormapfull isa Bool
    #
    @test :containing ∉ propertynames(w)
    @test @inferred(w.containing(0, 0)) isa String
    #
    @test :depth ∈ propertynames(w)
    @test w.depth isa Int
    #
    @test :exists ∈ propertynames(w)
    @test w.exists isa Bool
    #
    @test :fpixels ∉ propertynames(w)
    @test @inferred(w.fpixels(234)) isa Float64
    #
    @test :geometry ∈ propertynames(w)
    @test w.geometry isa String
    #
    @test :height ∈ propertynames(w)
    @test w.height isa Int
    #
    @test :id ∈ propertynames(w)
    @test w.id isa UInt32
    #
    @test :interp ∈ propertynames(w)
    @test w.interp isa TclInterp
    #
    @test :interps ∈ propertynames(w)
    @test w.interps isa Vector{String}
    #
    @test :ismapped ∈ propertynames(w)
    @test w.ismapped isa Bool
    #
    @test :manager ∈ propertynames(w)
    @test w.manager isa Symbol
    #
    @test :name ∈ propertynames(w)
    @test w.name isa String
    #
    @test :parent ∈ propertynames(w)
    @test w.parent isa String
    #
    @test :path ∈ propertynames(w)
    @test w.path isa TclObj
    #
    @test :pathname ∉ propertynames(w)
    @test @inferred(w.pathname(w.id)) isa String
    @test @inferred(w.pathname(w.id)) == w.path
    #
    @test :pixels ∉ propertynames(w)
    @test @inferred(w.pixels(123.4)) isa Int
    #
    @test :pointerx ∈ propertynames(w)
    @test w.pointerx isa Int
    #
    @test :pointerxy ∈ propertynames(w)
    @test w.pointerxy isa Tuple{Int,Int}
    #
    @test :pointery ∈ propertynames(w)
    @test w.pointery isa Int
    #
    @test :reqheight ∈ propertynames(w)
    @test w.reqheight isa Int
    #
    @test :reqwidth ∈ propertynames(w)
    @test w.reqwidth isa Int
    #
    @test :rgb ∉ propertynames(w)
    @test @inferred(w.rgb("cyan")) isa NTuple{3,UInt16}
    #
    @test :rootx ∈ propertynames(w)
    @test w.rootx isa Int
    #
    @test :rooty ∈ propertynames(w)
    @test w.rooty isa Int
    #
    @test :screen ∈ propertynames(w)
    @test w.screen isa String
    #
    @test :screencells ∈ propertynames(w)
    @test w.screencells isa Int
    #
    @test :screendepth ∈ propertynames(w)
    @test w.screendepth isa Int
    #
    @test :screenheight ∈ propertynames(w)
    @test w.screenheight isa Int
    #
    @test :screenmmheight ∈ propertynames(w)
    @test w.screenmmheight isa Float64
    #
    @test :screenmmwidth ∈ propertynames(w)
    @test w.screenmmwidth isa Float64
    #
    @test :screenvisual ∈ propertynames(w)
    @test w.screenvisual isa Symbol
    #
    @test :screenwidth ∈ propertynames(w)
    @test w.screenwidth isa Int
    #
    @test :server ∈ propertynames(w)
    @test w.server isa String
    #
    @test :toplevel ∈ propertynames(w)
    @test w.toplevel isa String
    #
    @test :viewable ∈ propertynames(w)
    @test w.viewable isa Bool
    #
    @test :visual ∈ propertynames(w)
    @test w.visual isa Symbol
    #
    @test :visualid ∈ propertynames(w)
    @test w.visualid isa UInt32
    #
    @test :visualsavailable ∈ propertynames(w)
    @test w.visualsavailable isa Vector{Tuple{Symbol, Int}}
    #
    @test :visualsavailable_includeids ∈ propertynames(w)
    @test w.visualsavailable_includeids isa Vector{Tuple{Symbol, Int, UInt32}}
    #
    @test :vrootheight ∈ propertynames(w)
    @test w.vrootheight isa Int
    #
    @test :vrootwidth ∈ propertynames(w)
    @test w.vrootwidth isa Int
    #
    @test :vrootx ∈ propertynames(w)
    @test w.vrootx isa Int
    #
    @test :vrooty ∈ propertynames(w)
    @test w.vrooty isa Int
    #
    @test :width ∈ propertynames(w)
    @test w.width isa Int
    #
    @test :x ∈ propertynames(w)
    @test w.x isa Int
    #
    @test :y ∈ propertynames(w)
    @test w.y isa Int

end

end # module
