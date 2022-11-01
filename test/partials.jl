module TestPartials

using Test
using ForwardDiff
using TestModule
using Random
using ForwardDiff: Dual, Partials

const fd = ForwardDiff
const tm = TestModule

@testset "dual type overloading (poss piracy)" begin

    pm = (1.0, 2.0)
    pn = (1.0, 2.0, 3.0, 4.0, 5.0)
    dm = fd.Dual{Val{:f}}(1.0, pm)
    dn = fd.Dual{Val{:f}}(2.0, pn)

    # can add tuples with diff lengths
    @test tm.add_tuples(pm,pn)  == (pm[1:2].+pn[1:2]..., pn[3:end]...)

    # but not where first tuple is longer than 2nd
    @test_throws "must have M<=N" tm.add_tuples(pn,pm)

    # this means we can ALSO add dual numbers with diff lengths
    @test +(dm, dn) == fd.Dual{Val{:f}}(3.0, tm.add_tuples(pm,pn))

    # but these dual nubmers MUST have the same tag
    @test_throws "Cannot determine ordering of Dual tags Val{:g} and Val{:f}" fd.Dual{Val{:f}}(1.0, pm) + fd.Dual{Val{:g}}(2.0, pn)

    # check::we can do addition
    addduals = DrillDual(1.0, pm) + AllDual(2.0, pn)
    @test AllDual(3.0, Partials(pm) + Partials(pn)) ==  addduals

    # though it's not comutative
    @test_throws "Cannot determine ordering of Dual tags Val{:drill} and Val{:all}" AllDual(2.0, pn) + DrillDual(1.0, pm)

    # we can make a drill dual from an all dual
    @test DrillDual{2}(AllDual(2.0, pn)) == DrillDual(2.0, pn[1:2])


    let N = 3,
        M = 2,
        k = 5,
        V = Float64
        randalldual = collect(rand(AllDual{V,N}) for i in 1:k)
        drilldual = Vector{DrillDual{V,2}}(undef, k)
        
        copyto!(drilldual, randalldual)
        @test drilldual == DrillDual{M}.(randalldual)

        @test randalldual[1] isa AllDual
        @test convert(DrillDual{V,M}, randalldual[1]) isa DrillDual{V,M}

        let tmp = randalldual[1]
            randalldual[1] = drilldual[1] + randalldual[1]
            @test randalldual[1] != tmp
            @test fd.partials(randalldual[1]).values[end] == fd.partials(tmp).values[end]
        end
    end
end


end