module TestDataStructure

using Test
using Base: OneTo
using TestModule
using TestModule: y, x, data, group_ptr, idx, tmpvar,
    Observation, ObservationGet, ObservationView,
    ObservationGroup, Data, DataWithTmpVar, TmpVar,
    NoTmpVar, AbstractObservationIterator, ObservationGenerator

@testset begin "Testing overall data interface" 

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

    @test eltype(tmpvF) == Float64
    @test eltype(tmpvC) == ComplexF64

    dsca     = Data(_y,_x)
    dvec     = Data(_y,_x,_ptr)
    dsca_tmp = DataWithTmpVar(dsca , tmpvC)
    dvec_tmp = DataWithTmpVar(dvec , tmpvC)

    datasets = (dsca, dvec, dsca_tmp, dvec_tmp)

    for d in datasets
        
        @test d isa AbstractDataObject

        # @test nobs(d) == n
        og  = ObservationGroup(d, 1)
        @test getindex(d, 1) == og

        @test first(d) isa ObservationGroup
        @test first(first(d)) isa ObservationGroup
        @test first(first(first(d))) isa ObservationGroup
        
        @test last(d) isa ObservationGroup
        @test last(last(d)) isa ObservationGroup

    end

    @test group_ptr(dsca_tmp) == group_ptr(dsca) == OneTo(n+1)
    @test group_ptr(dvec_tmp) == group_ptr(dvec) == _ptr

    for d in (dsca, dsca_tmp)
        @test eachindex(first(d)) == 1:1
        @test length(first(d)) == 1

        @test eachindex(last(d)) == 4:4
        @test length(last(d)) == 1
    end

    for d in (dvec, dvec_tmp)
        @test eachindex(first(d)) == 1:1
        @test length(first(d)) == 1

        @test eachindex(last(d)) == 2:4
        @test length(last(d)) == 3
    end

    for d in (dsca, dvec)
        for (i,og) in enumerate(d)
            @test idx(og) == i
        end
    end

    # For raw data
    for d in (dsca, dvec)
        t = 1
        dtmp = DataWithTmpVar(d)
        for (i,og0) in enumerate(d)
            idxs = eachindex(og0)
            obs0 = Observation(og0)
            
            @test obs0 == ObservationView(dtmp,idxs)
            @test y(obs0) === view(_y, idxs)
            @test x(obs0) === view(_x, :, idxs)
            @test tmpvar(obs0) === view(tmpvar(dtmp), idxs)
            
            for obs1 in ObservationGenerator(og0)
                # println("t = $t, i=$(idx(og0)), j=$(idx(og1))")
                @test obs1 isa Observation
                @test obs1 == ObservationGet(dtmp,t)
                @test y(obs1) === getindex(_y, t)
                @test x(obs1) === view(_x, :, t)
                @test tmpvar(obs0) === getindex(tmpvar(dtmp), t)
                t+=1
            end
        end
    end

    # For raw data with tmpvars
    for d in (dsca_tmp, dvec_tmp)
        t = 1
        for (i,og0) in enumerate(d)
            idxs = eachindex(og0)
            obs0 = Observation(og0)

            @test obs0 == ObservationView(d, idxs)
            @test y(obs0) === view(_y, idxs)
            @test x(obs0) === view(_x, :, idxs)
            @test tmpvar(obs0) === view(tmpvar(d), idxs)
            
            for obs1 in ObservationGenerator(og0)
                # println("t = $t, i=$(idx(og0)), j=$(idx(og1))")
                @test obs1 isa Observation
                @test obs1 == ObservationGet(d,t)
                @test y(obs1) === getindex(_y, t)
                @test x(obs1) === view(_x, :, t)
                @test tmpvar(obs1) === getindex(tmpvar(d), t)
                t+=1
            end
        end
    end

end # testset

end # module