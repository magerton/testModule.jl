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

struct ObservationGroup{D,I}
    d::D
    idx::I
    function ObservationGroup(d,i)
        N = Level(d)
        new
    end
end



end # module
