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

# ---------------------------------------------
# ---------------------------------------------
#     TYPES
# ---------------------------------------------
# ---------------------------------------------


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

DataWithTmpVar(d) = DataWithTmpVar(d, NoTmpVar())

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


# ---------------------------------------------
# ---------------------------------------------
#     FUNCTIONS
# ---------------------------------------------
# ---------------------------------------------

view(::NoTmpVar, i) = NoTmpVar()
getindex(::NoTmpVar, i) = NoTmpVar()

getindex(d::AbstractDataObject, i) = ObservationGroup(d, i)

data(d::Data) = d
group_ptr(d::Data) = d.group_ptr
firstindex(d::Data) = 1
lastindex(d::Data) = length(d.group_ptr)-1
eachindex(d::Data) = OneTo(lastindex(d))
length(d::Data) = lastindex(d)
y(d::AbstractDataObject) = data(d).y
x(d::AbstractDataObject) = data(d).x
tmpvar(d::Data) = NoTmpVar()

data(d::DataWithTmpVar) = d.data
group_ptr(d::DataWithTmpVar) = group_ptr(data(d))
firstindex(d::DataWithTmpVar) = firstindex(data(d))
lastindex(d::DataWithTmpVar) = lastindex(data(d))
eachindex(d::DataWithTmpVar) = eachindex(data(d))
length(d::DataWithTmpVar) = length(data(d))
tmpvar(d::DataWithTmpVar) = d.tmpvar

data(g::ObservationGroup) = g.data
group_ptr( g::ObservationGroup) = group_ptr(data(g))
firstindex(g::ObservationGroup) = getindex(group_ptr(g), idx(g))
lastindex( g::ObservationGroup) = getindex(group_ptr(g), idx(g)+1)-1
eachindex( g::ObservationGroup) = firstindex(g) : lastindex(g)
length(g::ObservationGroup) = lastindex(g) - firstindex(g) + 1
idx(g::ObservationGroup) = g.idx
tmpvar(g::ObservationGroup) = tmpvar(data(g))

data(o::Observation) = o
y(o::Observation) = o.y
x(o::Observation) = o.x
tmpvar(o::Observation) = o.tmpvar

Observation(d::DataWithTmpVar, i::Number)         = ObservationGet( d, i)
Observation(d::DataWithTmpVar, i::AbstractVector) = ObservationView(d, i)
Observation(d::Data, i) = Observation(DataWithTmpVar(d), i)

Observation(g::ObservationGroup{<:Union{DataWithTmpVar,Data}})   = ObservationView(data(g), eachindex(g))
Observation(g::ObservationGroup{<:ObservationGroup}) = ObservationGet( data(data(g)), idx(g))

"iteration over a Data/DataWithTmpVar yields an Obs Group"
function iterate(d::AbstractDataObject, i=firstindex(d))
    if i <= lastindex(d)
        return getindex(d,i), i+1
    else
        return nothing
    end
end

function ObservationGet(data,i)
    t = tmpvar(data)
    yi = getindex(y(data), i)
    ti = getindex(t   , i)
    xi = view(x(data), :, i)
    return Observation(yi, xi, ti)
end

function ObservationView(data, idx)
    t = tmpvar(data)
    yi = view(y(data), idx)
    ti = view(t, idx)
    xi = view(x(data), :, idx)
    return Observation(yi, xi, ti)
end


end # module
