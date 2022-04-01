module TestModule

# extend these methods
import Base: length, size, iterate,
    firstindex, lastindex, eachindex, getindex, IndexStyle,
    view, ==, eltype, +, -, isless,
    fill!,string, show, convert, eltype,
    step

using Base: OneTo

abstract type AbstractDataObject end

abstract type AbstractTmpVar{R} <: AbstractDataObject end
(::Type{T})(x::AbstractTmpVar) where {T<:AbstractTmpVar} = x

abstract type AbstractData       <: AbstractDataObject end
getindex(d::AbstractData,i) = ObservationGroup(d,i)



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

y(d::AbstractData) = d.y
x(d::AbstractData) = d.x

ptr(   d::AbstractDataSet) = d.ptr
length(d::AbstractDataSet)  = length(ptr(d))

data(x::AbstractObservationGroup) = x.data
idx( x::AbstractObservationGroup) = x.idx


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

ptr(d::DataSingle) = OneTo(length(y(d)))

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



function Observation(d::DataSingle, i) 
    yi = getindex(y(d), i)
    xi = view(x(d), :, i)
    return Observation(yi, xi)
end

function Observation(d::Datamult, i) 
    yi = view(y(d), i)
    xi = view(x(d), :, i)
    return Observation(yi, xi)
end



end # module
