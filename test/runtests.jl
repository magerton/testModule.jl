# detect if using SLURM
const IN_SLURM = "SLURM_JOBID" in keys(ENV)

using Distributed
IN_SLURM && using ClusterManagers
using SharedArrays

using testModule

pids = IN_SLURM ? addprocs_slurm(parse(Int, ENV["SLURM_NTASKS"])) : addprocs(2)
println("")
@show pids
println("")

println("loading libraries")
@everywhere begin
    using testModule
    size_v() = size(get_g_v())
    size_sv() = size(get_g_sv())
    getindex_v() = getindex(get_g_v(), 1)
    getindex_sv() = getindex(get_g_sv(), 1)
end

v = rand(5)
sv = SharedVector{eltype(v)}(5; pids=pids)
sv .= v*5

println("setting up data")
@eval @everywhere begin
    set_g_v($v)
    set_g_sv($sv)
end

println("remotecall_fetching getuvsize")
for w in pids
    workerid = remotecall_fetch(myid, w)
    println("i am worker $workerid")
    println(remotecall_fetch(size_v, w))
    println(remotecall_fetch(size_sv, w))
    println(remotecall_fetch(getindex_v, w))
    println(remotecall_fetch(getindex_sv, w))
end
