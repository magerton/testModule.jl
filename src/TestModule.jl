module TestModule

using Base: OneTo
using ForwardDiff
using Optim
using HaltonSequences
using StatsFuns

const FD = ForwardDiff
using ForwardDiff: Dual, GradientConfig, Chunk, value, gradient!


include("data-structure.jl")
include("genglobal.jl")
include("optim-fd.jl")


end # module
