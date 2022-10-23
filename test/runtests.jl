using Test

module CompileTestModule
    using TestModule
end # module

include("data-structure.jl")


using ForwardDiff
using ForwardDiff: Dual, GradientConfig, Chunk, value
using TestModule
using Optim

const fd = ForwardDiff
const tm = TestModule



@testset "oncedifferentiable" begin
    f(x) = x[1]^2 + x[2]^2

    N = 2
    x = rand(N)

    cfg = tm.LLGradientConfig(x);
    eltype(cfg)
    @test eltype(cfg) == Dual{Val{:loglik}, Float64, N}
    @test eltype(cfg) != Dual{tm.LLTag, Float64, N}

    odfg = tm.LLOnceDifferentiable(f, x)
    tm.resetOnceDifferentiable!(odfg)
    res = optimize(odfg, x, BFGS(), autodiff = :forward)
    @test res.minimizer ≈ [0.0, 0.0]
end

