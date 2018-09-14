# using Distributed
# using testModule
#
# pid = addprocs()
# @everywhere using testModule
#
# @show testModule.testfun()

using Random
using LinearAlgebra

Random.seed!(1234)

x = rand(5,5)
eyemat = Matrix{Float64}(I,size(x))

xinv1 = x \ I
xinv2 = x \ eyemat
xinv3 = inv(x)

inv(x) == inv(lu(x))
lu(x) \ eyemat == x \ eyemat

@which x \ I
@which x \ eyemat
@which inv(x)

xinv1 .- xinv2
xinv2 .- xinv3
xinv1 .- xinv3
