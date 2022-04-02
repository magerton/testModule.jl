module TestModule

# extend these methods
import Base: length, size, iterate,
    firstindex, lastindex, eachindex, getindex, IndexStyle,
    view, ==, eltype

using Base: OneTo

export AbstractDataObject,
    AbstractTmpVar, AbstractData, AbstractObservation,
    DataWithTmpVar, ObservationGroup, Observation,
    NoTmpVar, TmpVar, Data

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

struct TmpVar{R,V<:AbstractVector{R}} <: AbstractTmpVar{R}
    xbeta::V
end 

"group_ptr defines groups of observations"
struct Data{Y<:Vector,X<:Matrix,P<:AbstractVector} <: AbstractData
    y::Y
    x::X
    group_ptr::P
    function Data(y::Y, x::X, group_ptr::P=OneTo(length(y)+1)) where {Y,X,P}
        return new{Y,X,P}(y,x,group_ptr)
    end
end

getindex(  d::AbstractDataObject, i) = ObservationGroup(d,i)

function iterate(d::AbstractDataObject, i=firstindex(d))
    if i <= lastindex(d)
        return getindex(d,i), i+1
    else
        return nothing
    end
end


y(d::AbstractDataObject) = d.y
x(d::AbstractDataObject) = d.x

data(d::ObservationGroup) = d.data
data(d::DataWithTmpVar) = d.data
data(d::Data) = d

group_ptr(d::Data) = d.group_ptr
group_ptr(d::DataWithTmpVar) = group_ptr(data(d))
group_ptr(d::ObservationGroup) = group_ptr(data(data(d)))

# for Data / DataWithTmpVar
groupstart( d, i) = getindex(group_ptr(d), i)
groupstop(  d, i) = groupstart(d,i+1)-1
grouplength(d, i) = groupstop(d,i) - groupstart(d,i) + 1
grouprange( d, i) = groupstart(d,i) : groupstop(d,i)

# for ObservationGroup
idx(g::ObservationGroup) = g.idx
groupstart( d) = groupstart( data(d), idx(d))
groupstop(  d) = groupstop(  data(d), idx(d))
grouplength(d) = grouplength(data(d), idx(d))
grouprange( d) = grouprange( data(d), idx(d))

# group_ptr(d::AbstractDataObject) = throw(error("group_ptr not defined for $(typeof(d))"))
length(d::Data) = length(group_ptr(d))-1
length(d::DataWithTmpVar) = length(data(d))
length(d::ObservationGroup) = grouplength(d)

# default methods for iteration through an AbstractDataStructure
firstindex(d::Data) = 1
firstindex(d::AbstractDataObject) = firstindex(data(d))
lastindex( d::AbstractDataObject) = length(data(d))
IndexStyle(d::AbstractDataObject) = IndexLinear()
eachindex( d::AbstractDataObject) = OneTo(length(d))

# default methods for iteration through an AbstractDataStructure
firstindex(d::ObservationGroup) = groupstart(d)
eachindex( d::ObservationGroup) = grouprange(d)



function Observation(og::ObservationGroup)
    d  = data(og)
    i = idx(og)
    t = tmpvar(og)
    yi = getindex(y(d), i)::Number
    ti = getindex(t   , i)::AbstractVector
    xi = view(x(d), :, i)::AbstractTmpVar
    return Observation(yi, xi, ti)
end



# for (i,unit) in dataroy  # i is 1:numy... group_ptr is 1:numy
#     for t in idx(unit)   # idx = i:(i+1)-1
#         Observation(dataroy,t)
#         tmpvar(unit, t) # is tmpvar[t]
#     end
# end

# for (i,unit) in datapdxn # i is 1:numy
#     Observation(datapdxn, idx(unit)) # idx is group_ptr[i] : group_ptr[i+1]-1
#     tmpvar(unit, idx(unit))  # is tmpvar[idx]
# end

# for (i,unit) in datadrill  # i is 1:numy
#     for t in idx(unit)     # idx is group_ptr[i] : group_ptr[i+1]-1
#         Observation(datadrill,t)
#         tmpvar(unit, t)   # is just tmpvar 
#     end
# end



end # module
