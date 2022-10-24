using Test

module CompileTestModule
    using TestModule
end # module

include("data-structure.jl")


using ForwardDiff
using ForwardDiff: Dual, GradientConfig, Chunk, value
using TestModule
using Optim
using HaltonSequences

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

data = tm.makedata(;nunits=1_000, maxobsperunit=200)
theta₀ = vcat(data.beta, data.alpha, 1/data.sigma)
tm.simloglik_produce(vcat(data.beta, data.alpha, 1000), data)
tm.simloglik_produce(vcat(data.beta, data.alpha, 1), data)
tm.simloglik_produce(vcat(data.beta, data.alpha, 0.01), data)


@profview [tm.simloglik_produce(theta₀, data) for i in 1:10]

f(θ) = tm.simloglik_produce(θ, data)
res = optimize(f, theta₀, BFGS(), autodiff = :forward)
hcat(res.minimizer, theta₀)

tm.UnitHalton(2, 0, 10)(1)
Halton{Rational}(2, start=1, length=10)

Halton{Rational}(3,start=1, length=10)


