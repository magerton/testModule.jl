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


TestModule.showtypetree(TestModule.AbstractPayoffFunction)

println("")

types_to_test = (
    # map((x) -> x(2008,2012), subtypes(TestModule.AbstractDrillingCost_TimeFE))...,
    TestModule.DrillingCost_TimeFE(2008,2012),
    TestModule.DrillingCost_TimeFE(2009,2011),
    TestModule.DrillingCost_constant(),
    TestModule.DrillingRevenue_WithTaxes(),
    TestModule.DrillingRevenue(),
    TestModule.ConstrainedDrillingRevenue_WithTaxes(),
    TestModule.ConstrainedDrillingRevenue_WithTaxes(),
    TestModule.ExtensionCost_Zero(),
    TestModule.ExtensionCost_Constant(),
    TestModule.ExtensionCost_ψ(),
    TestModule.StaticDrillingPayoff(TestModule.DrillingRevenue(),TestModule.DrillingCost_TimeFE(2009,2011),TestModule.ExtensionCost_Constant()),
    TestModule.UnconstrainedProblem(TestModule.StaticDrillingPayoff(TestModule.DrillingRevenue(),TestModule.DrillingCost_TimeFE(2009,2011),TestModule.ExtensionCost_Constant()) ),
    TestModule.ConstrainedProblem(TestModule.StaticDrillingPayoff(TestModule.DrillingRevenue(),TestModule.DrillingCost_TimeFE(2009,2011),TestModule.ExtensionCost_Constant()) ),
)

for f in types_to_test
    println("Testing fct $f")
    let z = (2.5,2010), ψ = 1.0, geoid = 4.5, roy = 0.25

        n = length(f)
        θ0 = rand(n)
        fd = zeros(Float64, n)
        g = zeros(Float64, n)

        for (d,i) in Iterators.product(0:2, 1:3)
            sgnext = TestModule._sgnext(wp,i)
            myargs = σ, wp, i, d, z, ψ, geoid, roy

            fct(thet) = flow(f, thet, myargs...)

            # test ∂f/∂θ
            Calculus.finite_difference!(fct, θ0, fd, :central)
            TestModule.gradient!(f, θ0, g, myargs...)
            @test g ≈ fd

            # test ∂f/∂ψ
            fdpsi = Calculus.derivative((psi) -> flow(f, θ0, σ, wp, i, d, z, psi, geoid, roy), ψ)
            gpsi = flowdψ(f, θ0, σ, wp, i, d, z, ψ, geoid, roy)
            @test fdpsi ≈ gpsi

            # test ∂f/∂σ
            fdsig = Calculus.derivative((sig) -> flow(f, θ0, sig, wp, i, d, z, ψ, geoid, roy), σ)
            gsig = flowdσ(f, θ0, σ, wp, i, d, z, ψ, geoid, roy)
            @test fdsig ≈ gsig
        end
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
