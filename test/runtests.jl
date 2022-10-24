using Test

module CompileTestModule
    using TestModule
end # module

include("data-structure.jl")


using ForwardDiff
using ForwardDiff: Dual, GradientConfig, Chunk, value
using TestModule
using Optim
using StatsFuns: norminvcdf

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

NSIM = 500
NUNITS = 1_000
BASE = 2
SKIP = 5000

data = tm.makedata(;nunits=NUNITS, maxobsperunit=8)
theta₀ = vcat(data.beta, data.alpha, 1/data.sigma)
tm.simloglik_produce(vcat(data.beta, data.alpha, 1000), data)
tm.simloglik_produce(vcat(data.beta, data.alpha, 1), data)
tm.simloglik_produce(vcat(data.beta, data.alpha, 0.01), data)

llm = similar(theta₀, NSIM, NUNITS)
ψmat = Matrix{Float64}(undef, NSIM, NUNITS)
tm.HaltonSeq!(ψmat, BASE, SKIP)
map!(norminvcdf, ψmat, ψmat)

tm.simloglik_produce!(llm, ψmat, theta₀, data)

# Float64 Halton: 268.531 ms (445862 allocations: 12.94 MiB)
# Rational Halton: 1.573 s (445413 allocations: 13.83 MiB)
# @btime tm.simloglik_produce!($llm, $ψmat, $theta₀, $data)
# @profview [(tm.simloglik_produce!(llm, ψmat, theta₀, data); nothing) for i in 1:1_000]

cfg = tm.LLGradientConfig(theta₀)
theta₀d = cfg.duals
ForwardDiff.seed!(theta₀d, theta₀, cfg.seeds)


llmd = similar(llm, eltype(cfg))
ff(θ) = tm.simloglik_produce!(llmd, ψmat, θ, data)
odfg = tm.LLOnceDifferentiable(ff, theta₀)

tm.resetOnceDifferentiable!(odfg)
res = optimize(odfg, theta₀, BFGS())
hcat(res.minimizer, theta₀)


tm.set_simloglik_produceglobals!(llmd, ψmat, data)
tm.simloglik_produce_globals!(theta₀d)
tm.simloglik_produce!(llmd, ψmat, theta₀d, data)
@test tm.simloglik_produce_globals!(theta₀d) == tm.simloglik_produce!(llmd, ψmat, theta₀d, data)

# @btime tm.simloglik_produce_globals!($theta₀d)
# @btime tm.simloglik_produce!($llmd, $ψmat, $theta₀d, $data)


