using Test

module CompileTestModule
    using TestModule
end # module

# include("data-structure.jl")
# include("optim-fd.jl")

using ForwardDiff
using TestModule

const fd = ForwardDiff
const tm = TestModule


pm = (1.0, 2.0)
pn = (1.0, 2.0, 3.0, 4.0, 5.0)
dm = fd.Dual{Val{:f}}(1.0, pm)
dn = fd.Dual{Val{:f}}(2.0, pn)


tm.add_tuples(pm,pn)
dm+dn

@which tm._add_tuples(pm,pn)

@which +(dm, dn)