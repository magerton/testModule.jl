module TestOptimFD
using Test
using ForwardDiff
using ForwardDiff: Dual, GradientConfig, Chunk, value
using TestModule
using Optim
using StatsFuns: norminvcdf
using Distributed, SharedArrays

const fd = ForwardDiff
const tm = TestModule

@testset "optimfd test" begin

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
    llm = similar(theta₀, NSIM)
    ψmat = Matrix{Float64}(undef, NSIM, NUNITS)
    tm.HaltonSeq!(ψmat, BASE, SKIP)
    map!(norminvcdf, ψmat, ψmat)

    tm.simloglik_produce!(llm, theta₀, ψmat, data)

    # Float64 Halton: 268.531 ms (445862 allocations: 12.94 MiB)
    # Rational Halton: 1.573 s (445413 allocations: 13.83 MiB)
    # @btime tm.simloglik_produce!($llm, $ψmat, $theta₀, $data)
    # @profview [(tm.simloglik_produce!(llm, ψmat, theta₀, data); nothing) for i in 1:1_000]

    cfg = tm.LLGradientConfig(theta₀)
    theta₀d = cfg.duals
    ForwardDiff.seed!(theta₀d, theta₀, cfg.seeds)


    llmd = similar(llm, eltype(cfg))
    ff(θ) = tm.simloglik_produce!(llmd, θ, ψmat, data)
    odfg = tm.LLOnceDifferentiable(ff, theta₀)

    tm.resetOnceDifferentiable!(odfg)
    res = optimize(odfg, theta₀, BFGS())
    hcat(res.minimizer, theta₀)

    # SET globals
    tm.set_simloglik_produceglobals!(llmd, ψmat, data)
    tm.set_simloglik_produceglobals_typed!(llmd, ψmat, data)

    # do with globals
    tm.simloglik_produce_globals!(theta₀d)
    tm.simloglik_produce_globals_typed!(theta₀d)

    # time these local versions
    tm.simloglik_produce!(llmd, theta₀d, ψmat, data)
    tm.simloglik_produce_globals!(theta₀d)
    tm.simloglik_produce_globals_typed!(theta₀d)
    tm.simloglik_map(theta₀d, NUNITS)

    # parallel versions
    # --------------------
    pids = addprocs(Sys.CPU_THREADS)
    @everywhere using Pkg: activate
    @everywhere activate(joinpath(@__DIR__, ".."))
    @everywhere using TestModule
    @everywhere const tm = TestModule

    @eval @everywhere tm.set_simloglik_produceglobals!($llmd, $ψmat, $data)
    @eval @everywhere tm.set_simloglik_produceglobals_typed!($llmd, $ψmat, $data)

    cpool = CachingPool(pids)
    wpool = WorkerPool(pids)
    tm.simloglik_pmap(theta₀d, NUNITS, wpool)
    tm.simloglik_pmap_typed(theta₀d, NUNITS, wpool)

    # bg = BenchmarkGroup()
    # bg["local only"]          = @benchmarkable tm.simloglik_produce!($llmd, $theta₀d, $ψmat, $data)
    # bg["local globals"]       = @benchmarkable tm.simloglik_produce_globals!($theta₀d)
    # bg["local TYPED globals"] = @benchmarkable tm.simloglik_produce_globals_typed!($theta₀d)
    # bg["local globals (map)"] = @benchmarkable tm.simloglik_map($theta₀d, $NUNITS)
    # bg["pmap Wpool globals"]        = @benchmarkable tm.simloglik_pmap(      $theta₀d, $NUNITS, $wpool)
    # bg["pmap Wpool TYPED globals"]  = @benchmarkable tm.simloglik_pmap_typed($theta₀d, $NUNITS, $wpool)
    # bg["pmap Cpool globals"]        = @benchmarkable tm.simloglik_pmap(      $theta₀d, $NUNITS, $cpool)
    # bg["pmap Cpool TYPED globals"]  = @benchmarkable tm.simloglik_pmap_typed($theta₀d, $NUNITS, $cpool)

    # bgresults = run(bg, verbose=true)

end # testset
end # module