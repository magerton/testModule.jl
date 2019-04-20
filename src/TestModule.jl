module TestModule

import Base: length

abstract type AbstractUnitProblem end

struct unitProblem <: AbstractUnitProblem end

# Static Payoff
abstract type AbstractStaticPayoffs   end
abstract type AbstractPayoffComponent end

# payoff components
abstract type AbstractDrillingRevenue <: AbstractPayoffComponent end
abstract type AbstractDrillingCost    <: AbstractPayoffComponent end
abstract type AbstractExtensionCost   <: AbstractPayoffComponent end

length(::Type{T}) where {T<:AbstractPayoffComponent} = throw(error("No length defined for $T")) # typemin(Int)
# (::Type{AEC})(θ::AbstractVector{T}, ψ::T) where {AEC,T} = typemin(T)


# -------------------------------------------
# Drilling payoff has 3 parts
# -------------------------------------------

struct StaticDrillingPayoff{R<:AbstractDrillingRevenue,C<:AbstractDrillingCost,E<:AbstractExtensionCost} <: AbstractStaticPayoffs
end


# -------------------------------------------
# Extension
# -------------------------------------------

"Constant extension cost"
struct ExtensionCost_Constant <: AbstractExtensionCost end
length(::Type{ExtensionCost_Constant}) = 1
@inline (::ExtensionCost_Constant)(θ::AbstractVector{T}, ψ) where {T} = θ[1]

"Extension cost depends on ψ"
struct ExtensionCost_ψ <: AbstractExtensionCost end
length(::Type{ExtensionCost_ψ}) = 2
@inline (::ExtensionCost_ψ)(θ::AbstractVector, ψ) = θ[1] + θ[2]*ψ


# -------------------------------------------
# Cost
# -------------------------------------------


"Time FE for 2008-2012"
struct DrillingCost_TimeFE_2008_2012 <: AbstractDrillingCost end
length(::Type{DrillingCost_TimeFE_2008_2012}) = 5
@inline function (::DrillingCost_TimeFE_2008_2012)(θ::AbstractVector{T}, wp::AbstractUnitProblem, i::Integer, d::Integer, z::Tuple{T,<:Integer})::T where {T}
    d == 1 && return θ[clamp(last(z),2008,2012)-2008]
    d  > 1 && return θ[clamp(last(z),2008,2012)-2008] + θ[length(DrillingCost_TimeFE_2008_2012)]
    d  < 1 && return zero(T)
end


"Time FE w rig rates for 2008-2012"
struct DrillingCost_TimeFE_2008_2012_rigrates <: AbstractDrillingCost end
length(::Type{DrillingCost_TimeFE_2008_2012_rigrates}) = 6
@inline function (::DrillingCost_TimeFE_2008_2012_rigrates)(θ::AbstractVector{T}, wp::AbstractUnitProblem, i::Integer, d::Integer, z::Tuple{T,T,<:Integer})::T where {T}
    d == 1 && return θ[clamp(last(z),2008,2012)-2008] +                                                       θ[length(DrillingCost_TimeFE_2008_2012_rigrates)]*exp(z[2])
    d  > 1 && return θ[clamp(last(z),2008,2012)-2008] + θ[length(DrillingCost_TimeFE_2008_2012_rigrates)-1] + θ[length(DrillingCost_TimeFE_2008_2012_rigrates)]*exp(z[2])
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


Eexpψ(a,b,c,d) = a
_sgnext(wp,i) = true
_Dgt0(wp,i) = false

"Revenue with taxes and stuff"
struct DrillingRevenue_WithTaxes <: AbstractDrillingRevenue end
length(::Type{DrillingRevenue_WithTaxes}) = 3
@inline function (::DrillingRevenue_WithTaxes)(θ::AbstractVector{T}, σ::T, wp::AbstractUnitProblem, i::Integer, z::Tuple, ψ::T, geoid::Real, roy::Real)::T where {T}
    Dgt0 = _Dgt0(wp,i)
    return ONE_MINUS_MARGINAL_TAX_RATE * (1-roy) * exp(θ[1] + θ[2]*geoid + Eexpψ(θ[3], σ, ψ, Dgt0)) * (exp(z[1]) - C_PER_MCF)
end

# @inline net_revdσ(θ, σ, z, ψ, geoid, roy) = net_rev(θ,σ,z,ψ,false,geoid,roy) * (ψ*θ[3] - θ[3]^2*_ρ(σ)) * _dρdσ(σ)
# @inline net_revdψ(θ, σ, z, ψ, geoid, roy) = net_rev(θ,σ,z,ψ,false,geoid,roy) * θ[3] * _ρ(σ)





function coefgroups(::StaticDrillingPayoff{R,C,E}) where {R,C,E}
    1:length(R)
end


function flow(::StaticDrillingPayoff{R,C,E}, wp::AbstractUnitProblem, i::Integer, θ::AbstractVector{T}, σ::T, z::Tuple, ψ::T, d::Integer, geoid::Real, roy::T) where {T,R,C,E}
    if d == 0
        _sgnext(wp,i) && return E()(θ,ψ)
        return zero(T)
    end
    return d * (R()(θ, σ, wp, i, z, ψ, geoid, roy) + C()(θ, wp, i, d, z) )
end


end
