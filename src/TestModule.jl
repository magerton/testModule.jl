module TestModule

using Base: OneTo
using ForwardDiff
using Optim
# using HaltonSequences
using Primes: isprime
using StatsFuns

const FD = ForwardDiff
using ForwardDiff: Dual, GradientConfig, Chunk, value, gradient!


include("data-structure.jl")
include("genglobal.jl")
include("halton.jl")
include("optim-fd.jl")


end # module
