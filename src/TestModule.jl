module TestModule

import Base: length

export flow, flowdθ, flowdσ, flowdψ

# -----------------------------------------
# need these to run
# -----------------------------------------

using StatsFuns: logistic

abstract type AbstractUnitProblem end
struct unitProblem <: AbstractUnitProblem end

_sgnext(wp::AbstractUnitProblem, i::Integer) = i == 2
_sgnext(wp,i,d) = _sgnext(wp,i) && d == 0
_Dgt0(wp,i) = i > 2


@inline _ρ(θρ::Real) = logistic(θρ)
@inline _dρdθρ(θρ::Real) = (z = logistic(θρ); z*(1-z) )
@inline _ρ2(θρ::Real) = _ρ(θρ)^2
_dρdσ = _dρdθρ # alias

# -----------------------------------------
# so we can change these...
# -----------------------------------------

const ref_STARTING_σ_ψ      = Ref{Float64}(0x1.47b9927764a96p-2) # 0x1.baddbb87af68ap-2 # = 0.432
const ref_STARTING_log_ogip = Ref{Float64}(0x1.6df0926ff0ac4p-1) # 0x1.670bf3d5b282dp-1 # = 0.701
const ref_STARTING_t        = Ref{Float64}(2*0.042/(2016-2003))

function set_STARTING_σ_ψ(x::Float64)
    ref_STARTING_σ_ψ[] = x
end
function set_STARTING_log_ogip(x::Float64)
    ref_STARTING_log_ogip[] = x
end
function set_STARTING_t(x::Float64)
    ref_STARTING_t[] = x
end

STARTING_σ_ψ()      = ref_STARTING_σ_ψ[]
STARTING_log_ogip() = ref_STARTING_log_ogip[]
STARTING_t()        = ref_STARTING_t[]


# -----------------------------------------
# big types
# -----------------------------------------

# Static Payoff
abstract type AbstractPayoffFunction end
abstract type AbstractStaticPayoffs   <: AbstractPayoffFunction end
abstract type AbstractPayoffComponent <: AbstractPayoffFunction end

# payoff components
abstract type AbstractDrillingRevenue <: AbstractPayoffComponent end
abstract type AbstractDrillingCost    <: AbstractPayoffComponent end
abstract type AbstractExtensionCost   <: AbstractPayoffComponent end

# -------------------------------------------
# Drilling payoff has 3 parts
# -------------------------------------------

struct StaticDrillingPayoff{R<:AbstractDrillingRevenue,C<:AbstractDrillingCost,E<:AbstractExtensionCost} <: AbstractStaticPayoffs
    revenue::R
    drillingcost::C
    extensioncost::E
end

@inline length(x::StaticDrillingPayoff) = length(x.revenue) + length(x.drillingcost) + length(x.extensioncost)
@inline lengths(x::StaticDrillingPayoff) = (length(x.revenue), length(x.drillingcost), length(x.extensioncost),)

# coeficient ranges
@inline coef_range_revenue(x::StaticDrillingPayoff) =                                                        1:length(x.revenue)
@inline coef_range_drillingcost(x::StaticDrillingPayoff)  = length(x.revenue)                            .+ (1:length(x.drillingcost))
@inline coef_range_extensioncost(x::StaticDrillingPayoff) = (length(x.revenue) + length(x.drillingcost)) .+ (1:length(x.extensioncost))
@inline coef_ranges(x::StaticDrillingPayoff) = coef_range_revenue(x), coef_range_drillingcost(x), coef_range_extensioncost(x)

@inline check_coef_length(x::StaticDrillingPayoff, θ) = length(x) == length(θ) || throw(DimensionMismatch())

# flow???(
#     x::AbstractStaticPayoffs, k::Integer,             # which function
#     θ::AbstractVector, σ::T,                          # parms
#     wp::AbstractUnitProblem, i::Integer, d::Integer,  # follows sprime(wp,i,d)
#     z::Tuple, ψ::T, geoid::Real, roy::T                # other states
# )

function gradient!(f::AbstractPayoffFunction, x::AbstractVector, g::AbstractVector, args...)
    K = length(f)
    K == length(x) == length(g) || throw(DimensionMismatch())
    for k = 1:K
        g[k] = flowdθ(f,k,x, args...)
    end
end


@inline function flow(x::StaticDrillingPayoff, θ::AbstractVector{T}, σ::T, wp::AbstractUnitProblem, i::Integer, d::Integer, z::Tuple, ψ::T, geoid::Real, roy::T) where {T}
    if d == 0
        @views u = flow(x.extensioncost, θ[coef_range_extensioncost(x)], σ, wp, i, d, z, ψ, geoid, roy)
    else
        @views r = flow(x.revenue,       θ[coef_range_revenue(x)],       σ, wp, i, d, z, ψ, geoid, roy)
        @views c = flow(x.drillingcost,  θ[coef_range_drillingcost(x)],  σ, wp, i, d, z, ψ, geoid, roy)
        u = r+c
    end
    return u::T
end

@inline function flowdθ(x::StaticDrillingPayoff, k::Integer, θ::AbstractVector{T}, σ::T, wp::AbstractUnitProblem, i::Integer, d::Integer, z::Tuple, ψ::T, geoid::Real, roy::T)::T where {T}
    d == 0 && !_sgnext(wp,i) && return zero(T)

    kr, kc, ke = lengths(x)

    # revenue
    k < 0              && throw(DomainError(k))
    k <= kr            && return flowdθ(x.revenue,       k,       θ[coef_range_revenue(x)],       σ, wp, i, d, z, ψ, geoid, roy)
    k <= kr + kc       && return flowdθ(x.drillingcost,  k-kr,    θ[coef_range_drillingcost(x)],  σ, wp, i, d, z, ψ, geoid, roy)
    k <= kr + kc + ke  && return flowdθ(x.extensioncost, k-kr-kc, θ[coef_range_extensioncost(x)], σ, wp, i, d, z, ψ, geoid, roy)
    throw(DomainError(k))
end


# -------------------------------------------
# Extension
# -------------------------------------------

@inline flowdσ(::AbstractExtensionCost, θ::AbstractVector{T}, σ::T, wp::AbstractUnitProblem, i::Integer, d::Integer, z::Tuple, ψ::T, geoid::Real, roy::Real) where {T} = zero(T)
@inline flowdψ(::AbstractExtensionCost, θ::AbstractVector{T}, σ::T, wp::AbstractUnitProblem, i::Integer, d::Integer, z::Tuple, ψ::T, geoid::Real, roy::Real) where {T} = zero(T)

"No extension cost"
struct ExtensionCost_Zero <: AbstractExtensionCost end
length(::ExtensionCost_Zero) = 0
@inline flow(  ::ExtensionCost_Zero,             θ::AbstractVector{T}, σ::T, wp::AbstractUnitProblem, i::Integer, d::Integer, z::Tuple, ψ::T, geoid::Real, roy::Real) where {T} = zero(T)
@inline flowdθ(::ExtensionCost_Zero, k::Integer, θ::AbstractVector{T}, σ::T, wp::AbstractUnitProblem, i::Integer, d::Integer, z::Tuple, ψ::T, geoid::Real, roy::Real) where {T} = nothing

"Constant extension cost"
struct ExtensionCost_Constant <: AbstractExtensionCost end
length(::ExtensionCost_Constant) = 1
@inline flow(  ::ExtensionCost_Constant,             θ::AbstractVector{T}, σ::T, wp::AbstractUnitProblem, i::Integer, d::Integer, z::Tuple, ψ::T, geoid::Real, roy::Real) where {T} = _sgnext(wp,i,d) ? θ[1]   : zero(T)
@inline flowdθ(::ExtensionCost_Constant, k::Integer, θ::AbstractVector{T}, σ::T, wp::AbstractUnitProblem, i::Integer, d::Integer, z::Tuple, ψ::T, geoid::Real, roy::Real) where {T} = _sgnext(wp,i,d) ? one(T) : zero(T)

"Extension cost depends on ψ"
struct ExtensionCost_ψ <: AbstractExtensionCost end
length(::ExtensionCost_ψ) = 2
@inline flow(  ::ExtensionCost_ψ,             θ::AbstractVector{T}, σ::T, wp::AbstractUnitProblem, i::Integer, d::Integer, z::Tuple, ψ::T, geoid::Real, roy::Real) where {T} = θ[1] + θ[2]*ψ
@inline flowdθ(::ExtensionCost_ψ, k::Integer, θ::AbstractVector{T}, σ::T, wp::AbstractUnitProblem, i::Integer, d::Integer, z::Tuple, ψ::T, geoid::Real, roy::Real) where {T} = k == 1 ? one(T) : ψ
@inline flowdψ(::ExtensionCost_ψ,             θ::AbstractVector{T}, σ::T, wp::AbstractUnitProblem, i::Integer, d::Integer, z::Tuple, ψ::T, geoid::Real, roy::Real) where {T} = θ[2]

# -------------------------------------------
# Drilling Cost
# -------------------------------------------

@inline flowdσ(::AbstractDrillingCost, θ::AbstractVector{T}, σ::T, wp::AbstractUnitProblem, i::Integer, d::Integer, z::Tuple, ψ::T, geoid::Real, roy::Real) where {T} = zero(T)
@inline flowdψ(::AbstractDrillingCost, θ::AbstractVector{T}, σ::T, wp::AbstractUnitProblem, i::Integer, d::Integer, z::Tuple, ψ::T, geoid::Real, roy::Real) where {T} = zero(T)

"Single drilling cost"
struct DrillingCost_constant <: AbstractDrillingCost end
@inline length(x::DrillingCost_constant) = 1
@inline flow(  u::DrillingCost_constant,             θ::AbstractVector{T}, σ::T, wp::AbstractUnitProblem, i::Integer, d::Integer, z::Tuple{T,<:Integer}, ψ::T, geoid::Real, roy::Real) where {T} = d*θ[1]
@inline flowdθ(u::DrillingCost_constant, k::Integer, θ::AbstractVector{T}, σ::T, wp::AbstractUnitProblem, i::Integer, d::Integer, z::Tuple{T,<:Integer}, ψ::T, geoid::Real, roy::Real) where {T} = T(d)

"Abstract Type for Costs w Fixed Effects"
abstract type AbstractDrillingCost_TimeFE <: AbstractDrillingCost end
@inline start(x::AbstractDrillingCost_TimeFE) = x.start
@inline stop(x::AbstractDrillingCost_TimeFE) = x.stop
@inline time_idx(x::AbstractDrillingCost_TimeFE, t) = clamp(t, start(x), stop(x)) - start(x)

"Time FE for 2008-2012"
struct DrillingCost_TimeFE <: AbstractDrillingCost_TimeFE
    start::Int16
    stop::Int16
end
@inline length(x::DrillingCost_TimeFE) = 2 + stop(x) - start(x)
@inline function flow(u::DrillingCost_TimeFE, θ::AbstractVector{T}, σ::T, wp::AbstractUnitProblem, i::Integer, d::Integer, z::Tuple{T,<:Integer}, ψ::T, geoid::Real, roy::Real)::T where {T}
    d == 1 && return    θ[time_idx(u,last(z))]
    d  > 1 && return d*(θ[time_idx(u,last(z))] + θ[length(u)])
    d  < 1 && return zero(T)
end

"Time FE w rig rates for 2008-2012"
struct DrillingCost_TimeFE_rigrate <: AbstractDrillingCost_TimeFE
    start::Int16
    stop::Int16
end
@inline length(x::DrillingCost_TimeFE_rigrate) = 3 + stop(x) - start(x)
@inline function flow(u::DrillingCost_TimeFE_rigrate, θ::AbstractVector{T}, σ::T, wp::AbstractUnitProblem, i::Integer, d::Integer, z::Tuple{T,T,<:Integer}, ψ::T, geoid::Real, roy::Real)::T where {T}
    d == 1 && return     θ[time_idx(u,last(z))] +                  θ[length(u)]*exp(z[2]  )
    d  > 1 && return d*( θ[time_idx(u,last(z))] + θ[length(u)-1] + θ[length(u)]*exp(z[2]) )
    d  < 1 && return zero(T)
end

# -------------------------------------------
# Revenue
# -------------------------------------------

# From Gulen et al (2015) "Production scenarios for the Haynesville..."
const GATH_COMP_TRTMT_PER_MCF   = 0.42 + 0.07
const MARGINAL_TAX_RATE = 0.42
const ONE_MINUS_MARGINAL_TAX_RATE = 1 - MARGINAL_TAX_RATE

# other calculations
const REAL_DISCOUNT_AND_DECLINE = 0x1.89279c9f3217dp-1   # computed from time FE in monthly pdxn
const C_PER_MCF = GATH_COMP_TRTMT_PER_MCF * REAL_DISCOUNT_AND_DECLINE

function Eexpψ(θ4::T, σ::Number, ψ::Number, Dgt0::Bool)::T where {T}
    if Dgt0
        return θ4*ψ
    else
        ρ = _ρ(σ)
        return θ4*(ψ*ρ + θ4*0.5*(one(T)-ρ^2))
    end
end

@inline function revenue(θ1::T, θ2::T, θ3::T, σ::T, wp::AbstractUnitProblem, i::Integer, d::Integer, z::Tuple, ψ::Real, geoid::Real, roy::Real) where {T}
    u = d*(one(T)-roy) * exp(θ1 + first(z) + θ2*geoid + Eexpψ(θ3, σ, ψ, _Dgt0(wp,i)))
    return u::T
end

@inline function revenue_with_tax(θ1::T, θ2::T, θ3::T, σ::T, wp::AbstractUnitProblem, i::Integer, d::Integer, z::Tuple, ψ::Real, geoid::Real, roy::Real) where {T}
    u = d*ONE_MINUS_MARGINAL_TAX_RATE*(one(T)-roy) * exp(θ1 + θ2*geoid + Eexpψ(θ3, σ, ψ, _Dgt0(wp,i))) * (exp(z[1]) - C_PER_MCF)
    return u::T
end

# ----------------------------------------------------------------
# Drilling revenue
# ----------------------------------------------------------------

abstract type AbstractUnconstrainedDrillingRevenue <: AbstractDrillingRevenue end
length(x::AbstractUnconstrainedDrillingRevenue) = 3

@inline function flowdθ(x::AbstractUnconstrainedDrillingRevenue, k::Integer, θ::AbstractVector{T}, σ::T, wp::AbstractUnitProblem, i::Integer, d::Integer, z::Tuple, ψ::T, geoid::Real, roy::Real)::T where {T}
    rev = flow(x, θ, σ, wp, i, d, z, ψ, geoid, roy)
    k == 1 && return rev
    k == 2 && return rev*geoid
    k == 3 && return rev*( _Dgt0(wp,i) ? ψ : ψ*_ρ(σ) + θ[3]*(1-_ρ2(σ)))
    throw(DomainError(k))
end

@inline function flowdσ(x::AbstractUnconstrainedDrillingRevenue, θ::AbstractVector{T}, σ::T, wp::AbstractUnitProblem, i::Integer, d::Integer, z::Tuple, ψ::T, geoid::Real, roy::Real)::T where {T}
    if !_Dgt0(wp,i) && d > 0
        return flow(x, θ, σ, wp, i, d, z, ψ, geoid, roy) * (ψ*θ[3] - θ[3]^2*_ρ(σ)) * _dρdσ(σ)
    end
    return zero(T)
end

@inline function flowdψ(x::AbstractUnconstrainedDrillingRevenue, θ::AbstractVector{T}, σ::T, wp::AbstractUnitProblem, i::Integer, d::Integer, z::Tuple, ψ::T, geoid::Real, roy::Real)::T where {T}
    if d > 0
        dψ = flow(x, θ, σ, wp, i, d, z, ψ, geoid, roy) *  θ[3]
        return _Dgt0(wp,i) ? dψ : dψ * _ρ(σ)
    end
    return zero(T)
end

"Revenue with taxes and stuff"
struct DrillingRevenue_WithTaxes <: AbstractUnconstrainedDrillingRevenue end
flow(x::DrillingRevenue_WithTaxes, θ::AbstractVector, σ, wp, i, d, z, ψ, geoid, roy) = revenue_with_tax(θ[1], θ[2], θ[3], σ, wp, i, d, z, ψ, geoid, roy)

"Simple revenue"
struct DrillingRevenue <: AbstractUnconstrainedDrillingRevenue end
flow(x::DrillingRevenue, θ::AbstractVector, σ, wp, i, d, z, ψ, geoid, roy) = revenue(θ[1], θ[2], θ[3], σ, wp, i, d, z, ψ, geoid, roy)

# ----------------------------------------------------------------
# Constrained drilling revenue
# ----------------------------------------------------------------

abstract type AbstractConstrainedDrillingRevenue <: AbstractDrillingRevenue end
length(x::AbstractConstrainedDrillingRevenue) = 1

@inline function flowdθ(x::AbstractConstrainedDrillingRevenue, k::Integer, θ::AbstractVector{T}, σ::T, wp::AbstractUnitProblem, i::Integer, d::Integer, z::Tuple, ψ::T, geoid::Real, roy::Real)::T where {T}
    rev = flow(x, θ, σ, wp, i, d, z, ψ, geoid, roy)
    k == 1 && return rev
    throw(DomainError(k))
end

@inline function flowdσ(x::AbstractConstrainedDrillingRevenue, θ::AbstractVector{T}, σ::T, wp::AbstractUnitProblem, i::Integer, d::Integer, z::Tuple, ψ::T, geoid::Real, roy::Real)::T where {T}
    if !_Dgt0(wp,i) && d > 0
        return flow(x, θ, σ, wp, i, d, z, ψ, geoid, roy) * (ψ*STARTING_σ_ψ - STARTING_σ_ψ^2*_ρ(σ)) * _dρdσ(σ)
    end
    return zero(T)
end

@inline function flowdψ(x::AbstractConstrainedDrillingRevenue, θ::AbstractVector{T}, σ::T, wp::AbstractUnitProblem, i::Integer, d::Integer, z::Tuple, ψ::T, geoid::Real, roy::Real)::T where {T}
    if d > 0
        dψ = flow(x, θ, σ, wp, i, d, z, ψ, geoid, roy) *  STARTING_σ_ψ
        return _Dgt0(wp,i) ? dψ : dψ * _ρ(σ)
    end
    return zero(T)
end

"Constrained Revenue with taxes and stuff"
struct ConstrainedDrillingRevenue_WithTaxes <: AbstractConstrainedDrillingRevenue end
flow(x::ConstrainedDrillingRevenue_WithTaxes, θ::AbstractVector, σ, wp, i, d, z, ψ, geoid, roy) = revenue_with_tax(θ[1], STARTING_log_ogip, STARTING_σ_ψ, σ, wp, i, d, z, ψ, geoid, roy)

"Constrained Simple revenue"
struct ConstrainedDrillingRevenue <: AbstractConstrainedDrillingRevenue end
flow(x::ConstrainedDrillingRevenue, θ::AbstractVector, σ, wp, i, d, z, ψ, geoid, roy) = revenue(θ[1], STARTING_log_ogip, STARTING_σ_ψ, σ, wp, i, d, z, ψ, geoid, roy)


end
