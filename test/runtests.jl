using TestModule
using Test
using Calculus

problem = TestModule.StaticDrillingPayoff(
    TestModule.DrillingRevenue(),
    TestModule.DrillingCost_constant(),
    TestModule.ExtensionCost_Constant()
)

wp = TestModule.unitProblem()

θ = fill(0.25, length(problem))
σ = 0.75

TestModule.check_coef_length(problem, θ)





function test_grad!(f::TestModule.AbstractPayoffFunction, thet::AbstractVector, fd::AbstractVector, g::AbstractVector, myargs... )
    f_for_fd(x) = flow(f, x, myargs...)
    Calculus.finite_difference!(f_for_fd, thet, fd, :central)
    TestModule.gradient!(f, thet, g, myargs...)
    @test fd ≈ g
end




let z = (2.5,2010), ψ = 1.0, geoid = 4.5, roy = 0.25
    rng_r, rng_c, rng_e = TestModule.coef_ranges(problem)

    fdr = zeros(Float64, length(rng_r))
    fdc = zeros(Float64, length(rng_c))
    fde = zeros(Float64, length(rng_e))
    fdp = zeros(Float64, length(problem))

    gr = zeros(Float64, length(rng_r))
    gc = zeros(Float64, length(rng_c))
    ge = zeros(Float64, length(rng_e))
    gp = zeros(Float64, length(problem))

    for (d,i) in Iterators.product(0:2, 1:3)
        sgnext = TestModule._sgnext(wp,i)
        Dgt0 = TestModule._Dgt0(wp,i)
        myargs = σ, wp, i, d, z, ψ, geoid, roy

        r(thet) = flow(problem.revenue,       thet, myargs...)
        c(thet) = flow(problem.drillingcost,  thet, myargs...)
        e(thet) = flow(problem.extensioncost, thet, myargs...)
        p(thet) = flow(problem,               thet, myargs...)

        @show (d, i, sgnext, Dgt0, r(θ[rng_r]), c(θ[rng_c]), e(θ[rng_e]), p(θ),)


        Calculus.finite_difference!(c, θ[rng_c], fdc, :central)
        TestModule.gradient!(problem.drillingcost, θ[rng_c], gc, myargs...)
        @test fdr ≈ gr

        test_grad!(problem.revenue,       θ[rng_r], fdr, gr, myargs... )
        test_grad!(problem.drillingcost,  θ[rng_c], fdc, gc, myargs... )
        test_grad!(problem.extensioncost, θ[rng_e], fde, ge, myargs... )
        # test_grad!(problem,               θ,        fdp, gp, myargs... )
    end
end


# include("state-space.jl")

# # detect if using SLURM
# const IN_SLURM = "SLURM_JOBID" in keys(ENV)
#
# using Distributed
# IN_SLURM && using ClusterManagers
# using SharedArrays
#
# using testModule
#
# pids = IN_SLURM ? SLURM_CPUS_PER_TASKaddprocs_slurm(parse(Int, ENV["SLURM_CPUS_PER_TASK"])-1) : addprocs(2)
# println("")
# @show pids
# println("")
#
# println("loading libraries")
# @everywhere begin
#     using testModule
#     size_v() = size(get_g_v())
#     size_sv() = size(get_g_sv())
#     getindex_v() = getindex(get_g_v(), 1)
#     getindex_sv() = getindex(get_g_sv(), 1)
# end
#
# v = rand(5)
# sv = SharedVector{eltype(v)}(5; pids=pids)
# sv .= v*5
#
# println("setting up data")
# @eval @everywhere begin
#     set_g_v($v)
#     set_g_sv($sv)
# end
#
# println("remotecall_fetching getuvsize")
# for w in pids
#     workerid = remotecall_fetch(myid, w)
#     println("i am worker $workerid")
#     println(remotecall_fetch(size_v, w))
#     println(remotecall_fetch(size_sv, w))
#     println(remotecall_fetch(getindex_v, w))
#     println(remotecall_fetch(getindex_sv, w))
# end
