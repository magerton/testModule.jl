import ForwardDiff: add_tuples
import Base: +, convert

const DrillTag = Val{:drill}
const AllTag = Val{:all}

DrillDual{V,N} = FD.Dual{DrillTag,V,N}
AllDual{V,N}   = FD.Dual{AllTag,V,N}

export DrillDual, AllDual

@inline Base.:+(a::Partials{M}, b::Partials{N}) where {M,N} = Partials(add_tuples(a.values, b.values))

@inline function Base.:+(a::DrillDual{V,M}, b::AllDual{V,N}) where {V,M,N} 
    return AllDual{V,N}( FD.value(a) + FD.value(b), FD.partials(a) + FD.partials(b))
end

@inline function DrillDual{M}(x::AllDual) where {M}
    pa = FD.partials(x)
    pd = Partials( NTuple{M}(pa.values) )
    return DrillDual(FD.value(x), pd)
end

@inline function convert(::Type{DrillDual{V,M}}, x::AllDual) where {V,M}
    return DrillDual{M}(x)
end

function tupexpr2(f, M, g, N, NM)
    if M <= N
        ex = Expr(:tuple, [f(i) for i=1:M]..., [g(j) for j=1:NM]...)
        return quote
            $(Expr(:meta, :inline))
            @inbounds return $ex
        end
    else
        throw(error("must have M<=N"))
    end
end

@generated function add_tuples(a::NTuple{M,T}, b::NTuple{N,T})  where {M,N,T}
    return tupexpr2(
        i -> :(a[$i] + b[$i]),
        M,
        j -> :(b[$(j+M)]), 
        N,
        N-M
    )
end

@generated function NTuple{M}(b::NTuple{N})  where {M,N}
    return tupexpr2(
        i -> :(b[$i]),
        M,
        j -> nothing, 
        N,
        0
    )
end

import Random: rand

function rand(::Type{Dual{T,V,N}}) where {T <: Union{DrillTag,AllTag}, V,N}
    v = rand(V)
    t = ntuple((i) -> rand(V), Val(N))
    p = Partials(t)
    return Dual{T}(v,p)
end