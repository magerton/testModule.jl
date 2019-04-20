using testModule
using LinearAlgebra
using BenchmarkTools
using Random

Random.seed!(1234)

trial_k = 1:20

# for k in trial_k
#     y = zeros(Float64, k)
#     A = rand(Float64, k,k)
#     x = rand(Float64, k)
#
#     println("Benchmarking gemv! for $k...")
#     println("gemv!")
#     @btime mygemv!($y, $A, $x)
#     @btime BLAS.gemv!('N', 1.0, $A, $x, 1.0, $y)
# end

for k in trial_k
    y = zeros(Float64, k)
    A = rand(Float64, k,k)
    x = rand(Float64, k)

    println("Benchmarking ger! for $k...")
    @btime myger!($A, 2.0, $x, $x)
    @btime BLAS.ger!(2.0, $x, $x, $A)
end
