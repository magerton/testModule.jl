using Test

module CompileTestModule
    using TestModule
end # module

include("data-structure.jl")
include("optim-fd.jl")
include("partials.jl")
