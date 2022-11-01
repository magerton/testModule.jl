module TestModule

using Base: OneTo
using ForwardDiff
using Optim
# using HaltonSequences
using Primes: isprime
using StatsFuns
using Distributed, SharedArrays, ClusterManagers

const FD = ForwardDiff
using ForwardDiff: Dual, GradientConfig, Chunk, value, gradient!, Partials


include("data-structure.jl")
include("genglobal.jl")
include("halton.jl")
include("optim-fd.jl")
include("partials.jl")


end # module
