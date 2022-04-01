using Revise

module CompileTestModule
    using TestModule
end # module


# # module TestModule_Test
# using Test
# using TestModule
# using TestModule: tmpvar, y, x,
#     obsrange, grouprange,
#     group_ptr, obs_ptr,
#     TmpVarTest,
#     xbeta


for data in (datascalar, datascalar_wtmpvar)
    for (i,grp) in data
        obs = Observation(grp)
        @test obs == Observation(data,i)
        @test y(obs) isa Number
        @test y(obs) === y(data)[i]
        @test x(obs) isa SubArray
        @test x(obs) === view(x(data), :, i)
    end
end

for data in (datavec, datavec_wtmpvar)
    for (i,grp) in data
        
        obsptr = ptr(data)
        obs = Observation(grp)

        @test idx = obsptr[i] : obsptr[i+1]-1
        @test ptr(grp) == idx
        @test obs == Observation(data,i)
        @test y(obs) isa SubArray
        @test y(obs) === view(y(data), idx)
        @test x(obs) isa SubArray
        @test x(obs) === view(x(data), :, idx)
    
    end
end

for data in (datavecbysca, datavecbysca_wtmpvar)
    for (i,grp) in data
        
        obsptr = ptr(data)
        idx = obsptr[i] : obsptr[i+1]-1
        @test ptr(grp) == idx
        
        for (t,obs) in grp
            @test obs == Observation(data,t)
            @test y(obs) isa Number
            @test y(obs) === getindex(y(data), t)
            @test x(obs) isa SubArray
            @test x(obs) === view(x(data), :, t)
        end
    end
end








# end # module
