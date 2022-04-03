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

view(::NoTmpVar, i) = NoTmpVar()
getinndex(::NoTmpVar, i) = NoTmpVar()

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

"iteration over a Data/DataWithTmpVar yields an Obs Group"
function iterate(d::AbstractDataObject, i=firstindex(d))
    if i <= lastindex(d)
        return getindex(d,i), i+1
    else
        return nothing
    end
end


y(d::Union{Data,Observation}) = d.y
x(d::Union{Data,Observation}) = d.x
y(d::AbstractDataObject) = y(data(d))
x(d::AbstractDataObject) = x(data(d))

tmpvar(d::Union{DataWithTmpVar,Observation}) = d.tmpvar
tmpvar(d::ObservationGroup) = tmpvar(data(d))
data(d::AbstractDataObject) = d.data
tmpvar(::Data) = NoTmpVar()

group_ptr(d::AbstractDataObject) = group_ptr(data(d))
group_ptr(d::ObservationGroup{<:ObservationGroup}) = grouprange(data(d))


# for Data / DataWithTmpVar
groupstart( d, i) = getindex(group_ptr(d), i)
groupstop(  d, i) = groupstart(d,i+1)-1
grouplength(d, i) = groupstop(d,i) - groupstart(d,i) + 1
grouprange( d, i) = groupstart(d,i) : groupstop(d,i)

# default methods for iteration through an AbstractDataStructure
IndexStyle(::AbstractDataObject) = IndexLinear()

data(d::Data) = d
group_ptr(d::Data) = d.group_ptr
length(d::AbstractDataObject) = length(group_ptr(d))-1
firstindex(d::AbstractDataObject) = 1
lastindex(d::AbstractDataObject) = length(d)
eachindex( d::AbstractDataObject) = OneTo(lastindex(d))

length(d::DataWithTmpVar) = length(data(d))
firstindex(d::AbstractDataObject) = firstindex(data(d))

# default methods for iteration through an AbstractDataStructure
idx(g::ObservationGroup) = g.idx
groupstart( g::ObservationGroup) = groupstart( data(g), idx(g))
groupstop(  g::ObservationGroup) = groupstop(  data(g), idx(g))
grouplength(g::ObservationGroup) = grouplength(data(g), idx(g))
grouprange( g::ObservationGroup) = grouprange( data(g), idx(g))

firstindex(g::ObservationGroup) = groupstart(g)
lastindex( g::ObservationGroup) = groupstop(g)
eachindex( g::ObservationGroup) = grouprange(g)
length(    g::ObservationGroup) = grouplength(g)
getindex(  g::ObservationGroup) = Observation(data(g), idx(g))

function Observation(og::ObservationGroup)
    d  = data(og)
    rng = eachindex(og)
    t = tmpvar(og)
    yi = view(y(d), rng)
    ti = view(t   , rng)
    xi = view(x(d), :, rng)
    return Observation(yi, xi, ti)
end

function Observation(data, i)
    t = tmpvar(data)
    yi = getindex(y(data), i)
    ti = getindex(t, i)
    xi = view(x(data), :, i)
    return Observation(yi::Number, xi::AbstractVector, ti::AbstractTmpVar)
end

# for (i,unit) in dataroy  # i is 1:numy... group_ptr is 1:numy
#     for t in group_range(unit,i)   # idx = i:(i+1)-1
#         Observation(dataroy,t)
#         tmpvar(unit, t) # is tmpvar[t]
#     end
# end

# for (i,unit) in datapdxn # i is 1:numy
#     idx = ptr(unit)[i] : ptr(unit)[i+1]-1
#     Observation(datapdxn, idx)
#     tmpvar(data, idx)  # is tmpvar[idx]
# end

# for (i,unit) in datadrill  # i is 1:numy
#     idx = ptr(unit)[i] : ptr(unit)[i+1]-1
#     for t in idx
#         Observation(datadrill,t)
#         tmpvar(data, t)   # is just tmpvar 
#     end
# end



end # module
