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
using Base: OneTo
using TestModule
using TestModule: y, x, data, group_ptr, idx,
    groupstart, groupstop, grouplength, grouprange
    # ptr, ptrlength, ptrstart, ptrstop, ptrrange

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

dsca     = Data(_y,_x)
dvec     = Data(_y,_x,_ptr)
dsca_tmp = DataWithTmpVar(dsca , tmpvC)
dvec_tmp = DataWithTmpVar(dvec , tmpvC)

datasets = (dsca, dvec, dsca_tmp, dvec_tmp)
for d in datasets
    
    @test d isa AbstractDataObject

    # @test nobs(d) == n
    og  = ObservationGroup(d, 1)
    ogC  = ObservationGroup(d, 1)
    ogF  = ObservationGroup(d, 1)
        
    @test first(d) isa ObservationGroup
    @test first(first(d)) isa ObservationGroup
    @test first(first(first(d))) isa ObservationGroup
    @test first(first(first(first(d)))) isa ObservationGroup
    
    @test last(d) isa ObservationGroup
    @test last(last(d)) isa ObservationGroup
end

@test group_ptr(dsca_tmp) == group_ptr(dsca) == OneTo(n+1)
@test group_ptr(dvec_tmp) == group_ptr(dvec) == _ptr

group_ptr(first(first(dsca)))

@test grouprange(last(dsca)) == 4:4
@test grouprange(last(dvec)) == 2:4

groupstop(first(first(dsca)))
groupstop(last(last(dsca)))

grouprange(first(first(dvec)))
grouprange(last(last(dvec)))

groupstart(last(dvec))
groupstop(last(dvec))

grouprange(last(dsca))
grouprange(last(last(dsca)))
grouprange(last(last(dsca)))

og = last(dvec)
ogog = last(og)

data(ogog)


for (i,og) in enumerate(dsca_tmp)
    println((idx(og), grouprange(og)))
end

for (i,og) in enumerate(first(dvec))
    println((idx(og), grouprange(og)))
end


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
