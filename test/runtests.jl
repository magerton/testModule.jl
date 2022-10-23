using Test

module CompileTestModule
    using TestModule
end # module

# include("data-structure.jl")


using ForwardDiff
using ForwardDiff: Dual, GradientConfig, Chunk, value
using TestModule
using Optim

const fd = ForwardDiff
const tm = TestModule

f(x) = x[1]^2 + x[2]^2

N = 2
x = rand(N)

cfg = tm.LLGradientConfig(x);
eltype(cfg)
@test eltype(cfg) == Dual{Val{:loglik}, Float64, N}
@test eltype(cfg) != Dual{tm.LLTag, Float64, N}
odfg = tm.LLOnceDifferentiable(f, zeros(2))


opt = BFGS()
@btime optimize($f, $x, $opt, autodiff = $(:forward))
@btime optimize($odfg, $x, $opt, autodiff = $(:forward))

odfg.f_calls
odfg.df_calls
tm.resetOnceDifferentiable!(odfg)
res = optimize(odfg, x, BFGS(), autodiff = :forward)
res = optimize(f, x, BFGS(), autodiff = :forward)



@descend_code_warntype tm.LLOnceDifferentiable(f, zeros(2))

# @code_warntype tm.LLGradientConfig(zeros(2))

x = zeros(2)
@code_warntype tm.LLGradientConfig(x)

@btime GradientConfig(nothing, $x)

@code_warntype GradientConfig(f, zeros(N), Chunk(N), Val{:loglik}())
xx = zeros(N)
@descend_code_warntype Chunk(xx)
@descend_code_warntype GradientConfig(nothing, xx, Chunk(xx), MyTag)

# struct GradientConfig{T,V,N,D} <: AbstractConfig{N}
#     seeds::NTuple{N,Partials{N,V}}
#     duals::D
# end

typeof(x)
# GradientConfig{T, V, N, D} where 
#   T = Val{:loglik}
#   V = Float64
#   N = 2
#   D = Vector{Dual{T,V,N}}


x.seeds
eltype(x.duals) == fd.Dual{Val{:loglik}, Float64, 2}
fd.tagtype(eltype(x.duals))

ntv = tm.NewTmpVar(rand(2))
@code_warntype tm.setTmpFloat64(ntv)
@code_warntype tm.getTmpFloat64()


@code_warntype tm.setGTmp(ntv)
@code_warntype tm.getGTmp()

