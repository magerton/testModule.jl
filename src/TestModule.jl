module TestModule

# extend these methods
import Base: length, size, iterate,
    firstindex, lastindex, eachindex, getindex, IndexStyle,
    view, ==, eltype

using Base: OneTo

abstract type AbstractDataObject end
abstract type AbstractTmpVar{R} <: AbstractDataObject end
abstract type AbstractData       <: AbstractDataObject end
abstract type AbstractDataSet           <: AbstractData end
abstract type AbstractObservationGroup  <: AbstractData end
abstract type AbstractObservation       <: AbstractData end

struct DataWithTmpVar{D<:AbstractData, T<:AbstractTmpVar} <: AbstractData
    data::D
    tmpvar::T
end

struct ObservationGroup{D,I} <: AbstractObservationGroup
    data::D
    idx::I
end

struct Observation{YT,XT} <: AbstractObservation
    y::YT
    x::XT
end

struct DataSingle <: AbstractDataSet
    y::Vector{Float64}
    x::Matrix{Float64}
    function DataSingle(y,x)
        k,n = size(x)
        n == length(y) == length(ptr) || throw(DimensionMismatch())
        first(ptr) == 1 || throw(error())
        last(ptr)-1 == n || throw(error())
        return new(y,x,ptr)
    end
end

struct DataMult <: AbstractDataSet
    y::Vector{Float64}
    x::Matrix{Float64}
    ptr::Vector{Int}
    function DataMult(y,x,ptr)
        k,n = size(x)
        n == length(y) == length(ptr) || throw(DimensionMismatch())
        first(ptr) == 1 || throw(error())
        last(ptr)-1 == n || throw(error())
        return new(y,x,ptr)
    end
end

struct TmpVar{R} <: AbstractTmpVar
    xbeta::Vector{R}
end 

(::Type{T})(x::AbstractTmpVar) where {T<:AbstractTmpVar} = x

getindex(d::AbstractData,i) = ObservationGroup(d,i)

y(d::AbstractData) = d.y
x(d::AbstractData) = d.x

ptr(d::AbstractDataSet) = d.ptr
ptr(d::DataSingle) = OneTo(length(y(d)))
length(d::AbstractDataSet)  = length(ptr(d))
length(o::Observation) = length(y(o))

data(x::AbstractObservationGroup) = x.data
idx( x::AbstractObservationGroup) = x.idx

getorview(d::DataSingle,i) = getindex(y(d), i)
getorview(d::DataMult,i)   = view(    y(d), i)

"spits out data for observation `i`, be it length 1 or length n"
function Observation(d::AbstractDataSet, i) 
    yi = getorview(d, i)
    xi = view(x(d), :, i)
    return Observation(yi, xi)
end

"retrieves "
function Observation(obsgrp::ObservationGroup{<:AbstractDataSet}) 
    d = data(obsgrp)
    i = index(obsgrp)
    return Observation(d, i) 
end

function Observation(obsgrp::ObservationGroup{<:DataWithTmpVar}) 
    dtv = data(obsgrp)
    i = index(obsgrp)
    tv  = TmpVar(obsgrp)
    obs = Observation(data(dtv), i)
    return DataWithTmpVar(tv, obs)
end


function TmpVar(d::AbstractDataSet, θ)
    n = length(y(d))
    R = eltype(θ)
    xbeta = Vector{R}(undef, n)
    return TmpVar(xbeta)
end

getorview(d::TmpVar, i::Integer) = getindex(xbeta(d), i)
getorview(d::TmpVar, i::AbstractVector) = view(xbeta(d), i)

function TmpVar(d::AbstractObservationGroup)
    dtv = data(d)
    i = idx(d)
    tmpv = tmpvar(dtv)
    return getorview(tmpv, i)
end


end # module
