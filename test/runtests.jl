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
using Distributed, SharedArrays

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

# CachingPool(workers())

tm.set_simloglik_produceglobals!(llmd, ψmat, data)

@descend_code_warntype tm.simloglik_alloc_llm_map(theta₀d, NUNITS)
typeof(llms)

bigllm = Matrix{eltype(first(llms))}(undef, length(first(llms)), length(llms))
for i in 1:NUNITS
    bigllm[:, i] .= llms[i]
end

# pids = addprocs(Sys.CPU_THREADS)
# @everywhere using Pkg: activate
# @everywhere activate(joinpath(@__DIR__, ".."))
# @everywhere using TestModule
# @everywhere const tm = TestModule
# llmd_dist = SharedMatrix{eltype(llmd)}(size(llmd); pids=pids)
# @eval @everywhere tm.set_simloglik_produceglobals!($llmd_dist, $ψmat, $data)

# cpool = CachingPool(pids)
# @btime tm.simloglik_produce_pmap!($llmd_dist, $theta₀d, $cpool)
# @btime tm.simloglik_produce!(llmd, ψmat, theta₀d, data)

# tm.simloglik_produce_pmap!(llmd, theta₀d, CachingPool(pids))
# tm.simloglik_produce_globals!(theta₀d)

# @btime tm.simloglik_produce_globals!($theta₀d)
# @btime tm.simloglik_produce!($llmd, $ψmat, $theta₀d, $data)

# pids = start_up_workers(ENV; nprocs=8)
# @everywhere using ShaleDrillingLikelihood
# println_time_flush("Library loaded on workers")
