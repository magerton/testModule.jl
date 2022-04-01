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

"""
we give a liklihood evaluation a DataSet/ObsGroup/Observation
object with a `AbstractTmpVar`
"""
struct DataWithTmpVar{D<:AbstractData, T<:AbstractTmpVar} <: AbstractData
    data::D
    tmpvar::T
end

"wrap a DataSet/DataWithTmpVar/ObsGroup/Observation with an index"
struct ObservationGroup{D,I} <: AbstractObservationGroup
    data::D
    idx::I
end

"Observation we use inside a likelihood"
struct Observation{YT,XT} <: AbstractObservation
    y::YT
    x::XT
end

struct TmpVar{R} <: AbstractTmpVar
    xbeta::Vector{R}
end 

abstract type AbstractObservationType end
struct ScalarObs end
struct VectorObs end

"default to scalar"
obstype(::AbstractDataSet) = ScalarObs()

"An Observation/ObsGroup is just a scalar"
struct DataScalar <: AbstractDataSet
    y::Vector{Float64}
    x::Matrix{Float64}
    function DataSingle(y,x)
        k,n = size(x)
        n == length(y)
        return new(y,x)
    end
end


"An Observation/ObsGroup is a vector"
struct DataVector <: AbstractDataSet
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

obstype(::DataVector) = VectorObs()

"An ObsGroup is a vector... but we have to go over Observations as scalars"
struct DataVectorByScalar <: AbstractDataSet
    y::Vector{Float64}
    x::Matrix{Float64}
    ptr::Vector{Int}
    function DataDrill(y,x,ptr)
        k,n = size(x)
        n == length(y) == length(ptr) || throw(DimensionMismatch())
        first(ptr) == 1 || throw(error())
        last(ptr)-1 == n || throw(error())
        return new(y,x,ptr)
    end
end

y(d::AbstractData) = d.y
x(d::AbstractData) = d.x

nobs(d::AbstractData) = length(y(d))
length(d::DataScalar) = length(y(d))
ptr(d::DataScalar) = OneTo(length(y(d)))

function Observation(d::DataScalar, i)
    yi = y(d)[i]
    xi = view(x(d),i)
    Observation
end

getorview(d::DataSingle,i) = getindex(y(d), i)
getorview(d::DataMult,i)   = view(    y(d), i)

"spits out data for observation `i`, be it length 1 or length n"
function Observation(d::AbstractDataSet, i) 
    yi = getorview(d, i)
    xi = view(x(d), :, i)
    return Observation(yi, xi)
end






# ObservationGroup
length(o::AbstractObservation) = length(_y(o))

# default methods for iteration through an AbstractDataStructure
firstindex(d::AbstractDataStructure) = 1
lastindex( d::AbstractDataStructure) = length(d)
IndexStyle(d::AbstractDataStructure) = IndexLinear()
eachindex( d::AbstractDataStructure) = OneTo(length(d))

# Default iteration method is to create an ObservationGroup
getindex(  d::AbstractDataStructure, i) = ObservationGroup(d,i)

function iterate(d::AbstractDataStructure, i=firstindex(d))
    if i <= lastindex(d)
        return getindex(d,i), i+1
    else
        return nothing
    end
end

# AbstractDataSet iteration utilties
#------------------------------------------

_data(d::AbstractDataSet) = d

group_ptr(d::AbstractDataSet) = throw(error("group_ptr not defined for $(typeof(d))"))
obs_ptr(  d::AbstractDataSet) = throw(error("obs_ptr not defined for $(typeof(d))"))

# default method
length(   d::AbstractDataSet) = length(group_ptr(d))-1
_num_obs( d::AbstractDataSet) = length(obs_ptr(d))-1

groupstart( d::AbstractDataSet, i::Integer) = getindex(group_ptr(d), i)
groupstop(  d::AbstractDataSet, i::Integer) = groupstart(d,i+1)-1
grouplength(d::AbstractDataSet, i::Integer) = groupstop(d,i) - groupstart(d,i) + 1
grouprange( d::AbstractDataSet, i::Integer) = groupstart(d,i) : groupstop(d,i)

obsstart( d::AbstractDataSet, j::Integer) = getindex(obs_ptr(d),j)
obsstop(  d::AbstractDataSet, j::Integer) = obsstart(d,j+1)-1
obslength(d::AbstractDataSet, j::Integer) = obsstop(d,j) - obsstart(d,j) + 1
obsrange( d::AbstractDataSet, j::Integer) = obsstart(d,j) : obsstop(d,j)

# DataSet or Observation
_model(d::DataOrObs) = d.model
_y(    d::DataOrObs) = d.y
_x(    d::DataOrObs) = d.x
_num_x(d::DataOrObs) = size(_x(d), 1)

# ObservationGroup iteration utilties
#------------------------------------------

_data( g::AbstractObservationGroup) = g.data
_i(    g::AbstractObservationGroup) = g.i
_num_x(g::AbstractObservationGroup) = _num_x(_data(g))
_nparm(g::AbstractObservationGroup) = _nparm(_data(g))
_model(g::AbstractObservationGroup) = _model(_data(g))

length(    g::AbstractObservationGroup) = grouplength(_data(g), _i(g))
grouprange(g::AbstractObservationGroup) = grouprange( _data(g), _i(g))

obsstart( g::AbstractObservationGroup, k) = obsstart( _data(g), getindex(grouprange(g), k))
obsrange( g::AbstractObservationGroup, k) = obsrange( _data(g), getindex(grouprange(g), k))
obslength(g::AbstractObservationGroup, k) = obslength(_data(g), getindex(grouprange(g), k))














(::Type{T})(x::AbstractTmpVar) where {T<:AbstractTmpVar} = x

getindex(d::AbstractData,i) = ObservationGroup(d,i)

y(d::AbstractData) = d.y
x(d::AbstractData) = d.x

ptr(d::AbstractDataSet) = d.ptr
ptr(d::DataSingle) = nothing
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
