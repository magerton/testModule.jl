using Revise, Test

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
using TestModule
using TestModule: DataScalar, DataVector, DataVectorByScalar,
    AbstractDataObject,
    Observation,
    ObservationGroup,
    ptr, y, x, idx,
    TmpVar, tmpvar,
    DataWithTmpVar,
    nobs,
    data

# make stuff
k, n = 2,4
_ptr = [1,2,2,5]
_y = rand(n)
_x = rand(k,n)
_betF = rand(k)
_betC = complex(_betF)
_xbF  = _x' *_betF
_xbC  = _x' *_betC
tmpvF = TmpVar(_xbF)
tmpvC = TmpVar(_xbC)

datascalar   = DataScalar(_y,_x)
datavec      = DataVector(_y,_x,_ptr)
datavecbysca = DataVectorByScalar(_y,_x,_ptr)
datascalar_wtmpvar   = DataWithTmpVar(datascalar   , tmpvC)
datavec_wtmpvar      = DataWithTmpVar(datavec      , tmpvC)
datavecbysca_wtmpvar = DataWithTmpVar(datavecbysca , tmpvC)

datasets = (datascalar, datavec, datavecbysca)
for d in datasets
    @test nobs(d) == n
    og  = ObservationGroup(d, 1)
    dtvC = DataWithTmpVar(d, tmpvC)
    dtvF = DataWithTmpVar(d, tmpvF)
    ogC  = ObservationGroup(DataWithTmpVar(d, tmpvC), 1)
    ogF  = ObservationGroup(DataWithTmpVar(d, tmpvF), 1)

    @test data(d) == d
    @test data(og) == d
    
    @test data(dtvC) == d
    @test data(dtvF) == d
    
    @test data(ogC ) != d
    @test data(ogF ) != d
    @test data(ogC ) === dtvC
    @test data(ogF ) === dtvF

end

@test datascalar isa AbstractDataObject


ptr(datascalar)

for (i, og) in enumerate(datascalar_wtmpvar)
    @test og isa ObservationGroup
    @test idx(og) == i
    obs = Observation(og)
    @test obs isa Observation
    @test y(obs) == obs.y
    @test obs.y == y(datascalar_wtmpvar)[i]
    @test data(obs) isa Observation
    @test data(obs) === obs
end
getindex(datascalar_wtmpvar, 1).data

og = first(datascalar_wtmpvar)
data(og)
idx(og)
@which Observation(og)
@which Observation(DataSetType(og), og)


Observation(datascalar_wtmpvar, 1)


@test Observation(ObservationGroup(datascalar   , 1)) == Observation(_y[1],       view(_x, :,1))
@test Observation(ObservationGroup(datavec      , 1)) == Observation(view(_y, 1), view(_x, :,1))
@test Observation(ObservationGroup(datavecbysca , 1)) == Observation(_y[1],       view(_x, :,1))

@test Observation(datascalar   , 2) == Observation(_y[1],       view(_x, :,1))
@test Observation(datavec      , 2) == Observation(view(_y, 1), view(_x, :,1))
@test Observation(datavecbysca , 2) == Observation(_y[1],       view(_x, :,1))

Observation(getindex(datascalar, 1))
Observation(getindex(datavec, 1))
Observation(getindex(datavec, 2))
Observation(getindex(datavec, 3))

ObservationGroup(datavecbysca, 1)



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

# for data in (datavec, datavec_wtmpvar)
#     for (i,grp) in data
        
#         obsptr = ptr(data)
#         obs = Observation(grp)

#         @test idx = obsptr[i] : obsptr[i+1]-1
#         @test ptr(grp) == idx
#         @test obs == Observation(data,i)
#         @test y(obs) isa SubArray
#         @test y(obs) === view(y(data), idx)
#         @test x(obs) isa SubArray
#         @test x(obs) === view(x(data), :, idx)
    
#     end
# end

# for data in (datavecbysca, datavecbysca_wtmpvar)
#     for (i,grp) in data
        
#         obsptr = ptr(data)
#         idx = obsptr[i] : obsptr[i+1]-1
#         @test ptr(grp) == idx
        
#         for (t,obs) in grp
#             @test obs == Observation(data,t)
#             @test y(obs) isa Number
#             @test y(obs) === getindex(y(data), t)
#             @test x(obs) isa SubArray
#             @test x(obs) === view(x(data), :, t)
#         end
#     end
# end








# # end # module
