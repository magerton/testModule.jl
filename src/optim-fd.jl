# ----------------------------
# to control Dual eltype/tags
# in creation of OnceDiff'ble fcts
# for optimization
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

# ----------------------------
# data creation & iteration
# ----------------------------

getindices(ptr,i) = ptr[i] : (ptr[i+1]-1)

function makedata(;nunits=10, k=3, sigma=1.0, alpha=1.0, beta=ones(k), maxobsperunit=8)
    nobs_per_obs = rand(0:maxobsperunit, nunits)
    obs_ptr = cumsum(vcat(0,nobs_per_obs)).+1
    @assert diff(obs_ptr) == nobs_per_obs
    
    n = obs_ptr[end]-1
    X = randn(k,n)
    u = randn(n)
    ψ = randn(nunits)    

    y = X'*beta + u*sigma
    for i in 1:nunits
        idx = getindices(obs_ptr, i)
        y[idx] .+= ψ[i]*alpha
    end
    
    data  = (; y = y, X = X, ptr = obs_ptr, beta=copy(beta), sigma=sigma, alpha=alpha)
    return data

end

# ----------------------------
# loglik
# ----------------------------

"""
update llmᵢ += logL( (y-xβ-αψ*ψ₂ᵢ)/σᵤ | ψ₂ᵢ )
"""
@noinline function simloglik_produce!(llm::AbstractMatrix{T}, ψmat::AbstractMatrix, theta::AbstractVector{T}, data::NamedTuple, i::Int) where {T}
    
    nsim, nunits = size(llm)
    size(llm) == size(ψmat) || throw(DimensionMismatch())
    length(data.ptr) == nunits+1 || throw(DimensionMismatch("data.ptr must have nunits+1 elements"))

    idx = getindices(data.ptr, i)
    n = length(idx)

    if n > 0
        beta = theta[1:end-2]
        αψ = theta[end-1]
        invsigma = theta[end]
        invsigsq = invsigma^2
        
        x = view(data.X, :, idx)
        y = view(data.y,    idx)
        ψi = view(ψmat, :, i)
        llmi = view(llm, :, i)

        v = muladd(x', -beta, y)
        vsum = reduce(+, v)
        vsumsq = mapreduce(xi -> xi^2, +, v) # ; init=vzero)
        
        a = -(n*(log2π - log(invsigsq)) + vsumsq*invsigsq)/2
        b = αψ*vsum*invsigsq
        c = -n*αψ^2*invsigsq/2

        f(ψi) = a + (b + c*ψi)*ψi
        
        for (m,ψim) in enumerate(ψi)
            llmi[m] = f(ψim)
        end
        return nothing
    end

    return nothing
end

@noinline function simloglik_produce!(llm::AbstractMatrix, ψmat::AbstractMatrix, theta::AbstractVector, data::NamedTuple)
    nunits = length(data.ptr)-1
    fill!(llm, 0)
    for i in 1:nunits
        simloglik_produce!(llm, ψmat, theta, data, i)
    end
    SLL = sum(logsumexp(llm,dims=1))
    return -SLL
end

function simloglik_produce(theta, data; nsim=500)
    nunits = length(data.ptr)-1
    T = eltype(theta)
    llm = zeros(T, nsim, nunits)
    ψmat = Matrix{Float64}(undef, nsim, nunits)
    HaltonSeq!(ψmat, 2, 5000)
    map!(norminvcdf, ψmat, ψmat)
    return simloglik_produce!(llm, ψmat, theta, data)
end

# ----------------------------
# to send vars to remotes
# ----------------------------

@GenGlobal GData
@GenGlobal GPsi
@GenGlobal GLLMat

function set_simloglik_produceglobals!(llm, ψmat, data)
    set_GData!(data)
    set_GLLMat!(llm)
    set_GPsi!(ψmat)
    return nothing
end

function simloglik_produce_globals!(theta::AbstractVector)
    llm = get_GLLMat()
    ψmat = get_GPsi()
    data = get_GData()
    return simloglik_produce!(llm, ψmat, theta, data)
end

