# ----------------------------
# to send vars to remotes
# ----------------------------

@GenGlobal GData
@GenGlobal GTmp

# ----------------------------
# to control duals
# ----------------------------

using Optim.NLSolversBase.DiffResults: DiffResult
using Optim.NLSolversBase: x_of_nans, alloc_DF

const LLTag = Val{:loglik}()

@noinline LLChunk(x::AbstractVector) = Chunk(length(x), length(x))

"GradientConfig to prep Duals for loglik where we can specify the tag"
function LLGradientConfig(x::AbstractVector, chnk=LLChunk(x))
    cfg = GradientConfig(nothing, x, chnk, LLTag)
    return cfg
end

function LLOnceDifferentiable(f, x::AbstractVector)
    T = eltype(x)
    cfg = LLGradientConfig(x)

    F = real(zero(eltype(x)))
    DF = alloc_DF(x,F)
   
    g!(df, x) = gradient!(df, f, x, cfg)
    
    function fg!(out, x)
        gr_res = DiffResult(zero(T), out)
        gradient!(gr_res, f, x, cfg)
        return DiffResults.value(gr_res)
    end

    x_f, x_df = x_of_nans(x), x_of_nans(x)

    f_calls, df_calls = zeros(Int,1), zeros(Int,1)
    
    odfg = OnceDifferentiable(
        f, g!, fg!,
        copy(F), copy(DF), 
        x_f, x_df,
        f_calls, df_calls
    )
    
    return odfg
end

function resetOnceDifferentiable!(odfg)
    fill!(odfg.f_calls, 0)
    fill!(odfg.df_calls, 0)
    fill!(odfg.x_f, NaN)
    fill!(odfg.x_f, NaN)
    return nothing
end