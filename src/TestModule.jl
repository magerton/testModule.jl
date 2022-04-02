module TestModule

# extend these methods
import Base: length, size, iterate,
    firstindex, lastindex, eachindex, getindex, IndexStyle,
    view, ==, eltype

using Base: OneTo

abstract type AbstractDataObject end
abstract type AbstractTmpVar{R}         <: AbstractDataObject end
abstract type AbstractData              <: AbstractDataObject end
abstract type AbstractObservation       <: AbstractDataObject end

"""
we give a liklihood evaluation a DataSet/ObsGroup/Observation
object with a `AbstractTmpVar`
"""
struct DataWithTmpVar{D<:AbstractData, T<:AbstractTmpVar} <: AbstractDataObject
    data::D
    tmpvar::T
end

"wrap a DataSet/DataWithTmpVar/ObsGroup/Observation with an index"
struct ObservationGroup{D,I} <: AbstractDataObject
    data::D
    idx::I
end

"Observation we use inside a likelihood"
struct Observation{YT,XT,T} <: AbstractObservation
    y::YT
    x::XT
    tmpvar::T
end

struct NoTmpVar{R} <: AbstractTmpVar{R}
    NoTmpVar() = new{Nothing}()
end

struct TmpVar{R} <: AbstractTmpVar{R}
    xbeta::Vector{R}
end 

# abstract type AbstractOutcomeType end
# struct ScalarOutcome end
# struct VectorOutcome end

"An Observation/ObsGroup is just a scalar"
struct DataScalar <: AbstractData
    y::Vector{Float64}
    x::Matrix{Float64}
    function DataScalar(y,x)
        k,n = size(x)
        n == length(y)
        return new(y,x)
    end
end


"An Observation/ObsGroup is a vector"
struct DataVector <: AbstractData
    y::Vector{Float64}
    x::Matrix{Float64}
    ptr::Vector{Int}
    function DataVector(y,x,ptr)
        k,n = size(x)
        n == length(y)   || throw(DimensionMismatch())
        first(ptr) == 1  || throw(error())
        last(ptr)-1 == n || throw(error())
        return new(y,x,ptr)
    end
end

"An ObsGroup is a vector... but we have to go over Observations as scalars"
struct DataVectorByScalar <: AbstractData
    y::Vector{Float64}
    x::Matrix{Float64}
    ptr::Vector{Int}
    function DataVectorByScalar(y,x,ptr)
        k,n = size(x)
        n == length(y)   || throw(DimensionMismatch())
        first(ptr) == 1  || throw(error())
        last(ptr)-1 == n || throw(error())
        return new(y,x,ptr)
    end
end

const DataOrObs = Union{AbstractData, AbstractObservation}

data(d::DataOrObs) = d
y(d::DataOrObs) = d.y
x(d::DataOrObs) = d.x

data(d::AbstractDataObject) = d.data
y(d::AbstractDataObject) = y(data(d))
x(d::AbstractDataObject) = y(data(d))

tmpvar(d::AbstractDataObject) = d.tmpvar
tmpvar(d::AbstractData) = NoTmpVar()

nobs(d::AbstractData) = length(y(d))
length(d::AbstractDataObject) = length(ptr(d))-1

ptr(d) = ptr(data(d))
ptr( d::AbstractData) = d.ptr
ptr(d::DataScalar)    = OneTo(nobs(d)+1)

ptrstart( d, i) = getindex(ptr(d),  i)
ptrstop(  d, i) = ptrstart(ptr(d),i+1)-1
ptrlength(d, i) = ptrstop(d,i) - ptrstart(d,i) + 1
ptrrange( d, i) = ptrstart(d,i) : ptrstop(d,i)

# default to making ObsGroups
getindex(d::AbstractDataObject, i) = ObservationGroup(d,i)

function iterate(d::AbstractDataObject, i=firstindex(d))
    if i <= lastindex(d)
        return getindex(d,i), i+1
    else
        return nothing
    end
end

firstindex(d::AbstractDataObject) = 1
lastindex(d::AbstractDataObject) = length(d)

# idx(d::DataScalar) = ptr(d)
idx(o::ObservationGroup) = o.idx
# idx(d::AbstractData) = ptr(d)
# firstindex(o::AbstractDataObject) = ptrstart( data(o), idx(o))
# lastindex( o::AbstractDataObject) = ptrstop(  data(o), idx(o))
# length(    o::AbstractDataObject) = ptrlength(data(o), idx(o))

# Observation(og::ObservationGroup) = Observation(DataSetType(og),og)

function Observation(::Type{DataScalar}, og::ObservationGroup)
    d  = data(og)
    i = idx(og)
    t = tmpvar(og)
    yi = getindex(y(d), i)::Number
    ti = getindex(t   , i)::AbstractVector
    xi = view(x(d), :, i)::AbstractTmpVar
    return Observation(yi, xi, ti)
end

function Observation(::Type{DataVector}, og::ObservationGroup)
    d  = data(og)
    t = tmpvar(og)
    i = idx(og)
    rng = ptrrange(d, i)
    yi = view(y(d), rng)
    ti = view(t   , rng)
    xi = view(x(d), :, rng) 
    return Observation(yi, xi, ti)
end

function Observation(::Type{DataVectorByScalar}, og::ObservationGroup{<:ObservationGroup})
    d  = data(og)
    t = tmpvar(og)
    yi = getindex(y(d), i)
    ti = getindex(t   , i)
    xi = view(x(d), :, i) 
    return Observation(yi, xi, ti)
end


end # module
