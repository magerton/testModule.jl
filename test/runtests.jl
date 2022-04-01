using Revise

module CompileTestModule
    using TestModule
end # module


# module TestModule_Test
using Test
using TestModule
using TestModule: tmpvar, y, x,
    obsrange, grouprange,
    group_ptr, obs_ptr,
    TmpVarTest,
    xbeta

# @testset "DataTest" begin
    k,n = 2,4
    d = DataTest(rand(n), rand(k,n))

    for (i,o) in enumerate(d)
        @test o isa  AbstractObservation
        @test isa(o, AbstractObservationGroup) == false
    end

    @test size(tmpvar(d).xbeta) == size(y(d))

    dtv = DataWithTmpVar(d)
    for (i, otv) in enumerate(dtv)
        @test data(otv) === getindex(d, i)
        @test tmpvar(otv) === tmpvar(dtv)
    end

    println(typeof(tmpvar(d)))
# end

# @testset "GroupedDataTest" begin
    gptr = [1, 2, 2, 7]
    tptr = [1, 2, 2, 5, 8, 9, 11]
    n = last(tptr)-1
    k = 2

    d = GroupedDataTest(rand(n), rand(k,n), gptr, tptr)
    # @test getindex(d,1) isa ObservationGroup
    println(typeof(getindex(d,1)))

    @test gptr === group_ptr(d)
    @test tptr === obs_ptr(d)

    @test grouprange(d,length(d)) == gptr[end-1]: gptr[end]-1
    @test obsrange(d, 6) == 9:10

    ti = 1
    for (i,g) in enumerate(d)
        @test grouprange(d,i) == gptr[i]: gptr[i+1]-1
        for (j,o) in enumerate(g)
            @test obsrange(g,j) == tptr[ti] : tptr[ti+1]-1
            @test y(o) == y(d)[obsrange(g,j)]
            ti += 1
        end
    end

    dtv = DataWithTmpVar(d)
    dtvint = DataWithTmpVar(d, 1)
    @assert eltype(dtv) == Float64 == eltype(tmpvar(dtv))
    @assert eltype(dtvint) == Int == eltype(tmpvar(dtvint))

    tmpv = tmpvar(dtv)
    @test tmpv isa TmpVarTest
    @test tmpvar(dtv) === TmpVarTest(tmpv)
    @test tmpvar(dtv) === TmpVarTest(tmpvar(dtv))

    @test getindex(tmpv, 1) == xbeta(tmpv)[1]

    # for (i, gt) in enumerate(dtv)
    #     @test tmpvar(gt) === tmpvar(dtv)
        # @test getindex(dtv, i) == ObservationGroup(dtv,i)
    # end

# end

jb = JnkBase{2,Int}(1)
jg1 = JnkGroup(jb,1)
jg2 = JnkGroup(jg1)
jg3 = JnkGroup(jg2)

# end # module
