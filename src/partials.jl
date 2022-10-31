import ForwardDiff: add_tuples
import Base: +

@inline Base.:+(a::Partials{M}, b::Partials{N}) where {M,N} = Partials(add_tuples(a.values, b.values))

# function add_partials(a::FD.Partials{M,T}, b::FD.Partials{N,T}) where {M,N,T}
#     return FD.Partials{N,T}(a.values + b.values)
# end


function tupexpr2(f, M, g, N)
    if M <= N
        ex = Expr(:tuple, [f(i) for i=1:M]..., [g(j) for j=1:N]...)
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
        N-M
    )
end

