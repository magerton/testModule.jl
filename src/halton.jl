using Primes

export HaltonSeq, HaltonSeq!, HaltonDraws!

import Base: length, eltype

"""
    HaltonSeq(base, length, skip=5000, f=identity)

Iterator generates a Halton sequence of `Rational{Int}`s 
given a prime `base` and `length`, and skipping the first
`skip` elements. Function `f`, such as `StatsFuns::norminvcdf`,
can be used to transform a Halton draw into a quasi-random draw
from a distribution

The algorithm is presented in Kolar & O'Shea (1993),
<https://doi.org/10.1016/0898-1221(93)90307-H> uses 
`Vector`s `d` and `r` to keep track of intermediate
computations. 


# this may be faster
https://github.com/milankl/BitInformation.jl
https://www.pbr-book.org/3ed-2018/Sampling_and_Reconstruction/The_Halton_Sampler#fragment-GeneraterandomdigitpermutationsforHaltonsampler-0
https://hbfs.wordpress.com/2017/09/07/halton-sequences-generating-random-sequences-vii/
https://stackoverflow.com/questions/29553133/cuda-generating-the-halton-sequence-in-parallel
https://stackoverflow.com/questions/34242785/change-bit-state-in-julia
https://stackoverflow.com/questions/746171/efficient-algorithm-for-bit-reversal-from-msb-lsb-to-lsb-msb-in-c
https://discourse.julialang.org/t/uint8-access-bits/43990/9
https://stackoverflow.com/questions/2602823/in-c-c-whats-the-simplest-way-to-reverse-the-order-of-bits-in-a-byte
https://graphics.stanford.edu/~seander/bithacks.html#BitReverseObvious
https://graphics.stanford.edu/courses/cs348b-18-spring-content/lectures/10_mc3/10_mc3_slides.pdf
https://artowen.su.domains/mc/qmcstuff.pdf
https://diginole.lib.fsu.edu/islandora/object/fsu:722493/datastream/PDF/view
"""
struct HaltonSeq
    d::Vector{Int}
    r::Vector{Rational{Int}}
    base::Int
    skip::Int
    length::Int
    invcdf::Function
    
    function HaltonSeq(base::Integer, length::Integer, skip::Integer = 5000, invcdf::Function=identity)

        isprime(base) || error("base number not prime")

        skip >= 0 || throw(DomainError(skip))
        
        # set D to get generated seq >= S
        S = skip + length
        D = ceil(Int, log(S) / log(base))
        
        # tmp vectors for remainders
        d = zeros(Int, D+1)
        r = zeros(Rational{Int}, D+1)

        # skip over initial elts, but need to update `d` and `r`
        for i in Base.OneTo(skip)
            update_halton_remainders!(d,r,base)
        end
        
        return new(d, r, base, skip, length, invcdf)
    end
end

length(H::HaltonSeq) = H.length
eltype(::HaltonSeq) = Rational{Int}

"internal function for iteration"
function update_halton_remainders!(d,r,base)
    
    # they use the index "l" here
    j = 1  
    
    while d[j] == base-1
      d[j] = 0
      j += 1
    end
    
    d[j] += 1
    
    if j >= 2
      r[j-1] = (d[j] + r[j]) // base
    end
    
    if j >= 3
      for i in (j-1) : -1 : 2
        r[i-1] = r[i] // base
      end
    end
    
    return (d[1] + r[1]) // base

end

function Base.iterate(H::HaltonSeq, state=1)
    state > length(H) && return nothing
    draw = update_halton_remainders!(H.d, H.r, H.base)
    return H.invcdf(draw), state+1
end

function HaltonSeq!(x::AbstractArray, base, args...)
    n = length(x)
    H = HaltonSeq(base, n, args...)
    copyto!(x, H)
    return x
end