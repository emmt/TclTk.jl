module TclImageTests

using TclTk
using Test
using Colors
using Colors: FixedPointNumbers

function compute_significant_bits(::Type{T}) where {T<:AbstractFloat}
    isbitstype(T) || throw(ArgumentError("type `$T` is not a bits type"))
    nmax = 8*sizeof(T) - 1 # at least one bit for sign
    for nbits in 0:nmax
        try
            i = one(Int128) << nbits
            x = convert(T, i)
            x == i && x - one(x) == i - one(i) || return nbits - 1
        catch ex
            return nbits - 1
        end
    end
    error("cannot determine the number of bits in the mantissa of `$T`")
end

@testset "Tk Utilities" begin
    @test compute_significant_bits(Float16) == TclTk.Impl.significant_bits(Float16)
    @test compute_significant_bits(Float32) == TclTk.Impl.significant_bits(Float32)
    @test compute_significant_bits(Float64) == TclTk.Impl.significant_bits(Float64)
    @test typemax(Int128) == TclTk.Impl.max_exact_int(BigFloat)
end

@testset "Tk Images" begin
    interp = @inferred tk_start()
    img = @inferred TkPhoto(interp, "m51", :file => joinpath(@__DIR__, "m51-tiny.png"))
    @test img isa TkPhoto
    @test img.type === :photo
    @test img.interp === interp
    @test img.inuse === false
    @test img.name == "m51"
    @test img.width == 48
    @test img.height == 64
    @test img.size == (48, 64)
    @test @inferred(size(img)) == (48, 64)
    @test @inferred(eltype(img)) == RGBA{FixedPointNumbers.N0f8}
end

end # module
