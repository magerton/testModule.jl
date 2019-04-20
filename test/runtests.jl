using TestModule
using Test

problem = TestModule.StaticDrillingPayoff{TestModule.DrillingRevenue_WithTaxes, TestModule.DrillingCost_TimeFE_2008_2012, TestModule.ExtensionCost_Constant}()

@show TestModule.coefgroups(problem)

@test_throws ErrorException TestModule.length(TestModule.AbstractDrillingCost)

wp = TestModule.unitProblem()

θ = collect(1.0:5.0)
σ = 0.75

TestModule.DrillingCost_TimeFE_2008_2012()(θ, wp, 1, 1, (1.0, 2010))

@show TestModule.ExtensionCost_ψ()(θ, 1.0)

@show TestModule.DrillingRevenue_WithTaxes()(θ, σ, wp, 1, (1.0,2.0,2010), 0.0, 4.5, 0.25)

let i = 0, z = (1.0,2010), ψ = 1.0, d = 0, geoid = 4.5, roy = 0.25
    @show TestModule.flow(problem, wp, 0, θ, σ, z, ψ, d, geoid, roy)
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
