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

abstract type AbstractObservation          <: AbstractDataObject end
abstract type AbstractLeveledDataObject{N} <: AbstractDataObject end
abstract type AbstractData{N}              <: AbstractLeveledDataObject{N} end
abstract type AbstractObservationGroup{N}  <: AbstractLeveledDataObject{N} end

Level(::AbstractLeveledDataObject{N}) where {N} = N

struct ObservationGroup{N,D,I} <: AbstractObservationGroup{N}
    data::D
    idx::I
    function ObservationGroup(d,idx)
        N = Level(d)
        return new{N-1,D,I}(d,idx)
    end
end

data(x::AbstractObservation) = x.data
idx(x::AbstractObservation) = x.idx

struct Data{N,Int}
    y::Vector{Float64}
    x::Matrix{Float64}
    ptrs::NTuple{N,Int}
    function Data(y,x,ptrs::NTuple{N}) where {N}
        k,n = size(x)
        length(y) == n || throw(DimensionMismatch())
        if N > 0
            @assert all(first.(ptrs) .== 1)
            lastptrs = last.(ptrs) .- 1
            @assert last(lastptrs) == n
            if N > 1
            end
        end
    end
end

getindex(d::AbstractLeveledDataObject{0},i) = Observation(d,i)
getindex(d::AbstractLeveledDataObject,i)    = ObservationGroup(d,i)


Abs


end # module
