using Revise

module CompileTestModule
    using TestModule
end # module


module TestModule_Test
using Test
using TestModule
using TestModule: tmpvar, y, x

k,n = 2,4
d = DataTest(rand(n), rand(k,n))

for (i,o) in enumerate(d)
    println(i, o)
end

@test size(tmpvar(d).xbeta) == size(y(d))

dtv = DataWithTmpVar(d)
for (i, otv) in enumerate(dtv)
    @test data(otv) === getindex(d, i)
    @test tmpvar(otv) === tmpvar(dtv)
end


end # module
