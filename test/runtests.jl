using Revise, Test

module CompileTestModule
    using TestModule
end # module

using Base: OneTo
using TestModule
using TestModule: y, x, data, group_ptr, idx,
    Observation, ObservationGet, ObservationView,
    ObservationGroup, Data, DataWithTmpVar, TmpVar,
    NoTmpVar

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

    for d in (dsca, dvec)
        t = 1
        dtmp = (d isa Data ? dvec : dvec_tmp )
        for (i,og0) in enumerate(d)
            @test Observation(og0) == ObservationView(dtmp,eachindex(og0))
            for og1 in og0
                # println("t = $t, i=$(idx(og0)), j=$(idx(og1))")
                @test idx(og1) == t
                @test Observation(og1) == ObservationGet(dtmp,t)
                t+=1
            end
        end
    end


end # testset
