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

"typed so that we can ensure tmpvars are generate w/ same type as parameter vector. useful for autodiff"
abstract type AbstractTmpVar{R}   <: AbstractDataObject end
abstract type AbstractData        <: AbstractDataObject end
abstract type AbstractObservation <: AbstractDataObject end

eltype(::AbstractTmpVar{R}) where {R} = R

"Placeholder tmpvar"
struct NoTmpVar{R} <: AbstractTmpVar{R}
    NoTmpVar() = new{Nothing}()
end

struct TmpVar{R,V<:AbstractVector{R}} <: AbstractTmpVar{R}
    xbeta::V
end

"""
we give a liklihood evaluation a DataSet/ObsGroup/Observation
object with a `AbstractTmpVar`
"""
struct DataWithTmpVar{D<:AbstractData, T<:AbstractTmpVar} <: AbstractDataObject
    data::D
    tmpvar::T
    # inner constructor defaults to a placeholder
    function DataWithTmpVar(d::D,t::T=NoTmpVar()) where {D,T}
        return new{D,T}(d,t)
    end
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

# tmpvars
view(    ::NoTmpVar, i) = NoTmpVar()
getindex(::NoTmpVar, i) = NoTmpVar()

xbeta(   t::TmpVar) = t.xbeta
view(    t::TmpVar, i)  = view(xbeta(t), i)
getindex(t::TmpVar, i)  = getindex(xbeta(t), i)

# default methods apply more than one type
y(d::AbstractDataObject) = data(d).y
x(d::AbstractDataObject) = data(d).x
data(d::AbstractDataObject) = d.data
group_ptr(d::AbstractDataObject) = group_ptr(data(d))
tmpvar(d::AbstractDataObject)     = d.tmpvar

# type-specific methods
# --------------------------

# AbstractData
data(d::AbstractData) = d
group_ptr(d::AbstractData) = d.group_ptr
firstindex(d::AbstractData) = 1
lastindex(d::AbstractData) = length(d.group_ptr)-1
eachindex(d::AbstractData) = OneTo(lastindex(d))
length(d::AbstractData) = lastindex(d)
tmpvar(::AbstractData) = NoTmpVar()

# DataWithTmpVar methods access inner d.data
firstindex(d::DataWithTmpVar) = firstindex(data(d))
lastindex(d::DataWithTmpVar)  = lastindex(data(d))
eachindex(d::DataWithTmpVar)  = eachindex(data(d))
length(d::DataWithTmpVar)     = length(data(d))

# ObservationGroup specifies iteration through
# subset of data
idx(g::ObservationGroup) = g.idx
firstindex(g::ObservationGroup) = getindex(group_ptr(g), idx(g))
lastindex( g::ObservationGroup) = getindex(group_ptr(g), idx(g)+1)-1
eachindex( g::ObservationGroup) = firstindex(g) : lastindex(g)
length(g::ObservationGroup) = lastindex(g) - firstindex(g) + 1
tmpvar(g::ObservationGroup) = tmpvar(data(g))

# Observation specific methods
data(o::Observation) = o
tmpvar(o::Observation) = o.tmpvar



"grab just 1 row so that y,tmpvar are both scalar"
Observation(d::DataWithTmpVar, i::Number)         = ObservationGet( d, i)
"grab multiple rows so that y, tmpvar are views/vectors"
Observation(d::DataWithTmpVar, i::AbstractVector) = ObservationView(d, i)
"convenience wrapper"
Observation(d::AbstractData, i) = Observation(DataWithTmpVar(d), i)

# This is a tad awkward
"grabs obs in rows ptr[idx(g)] : ptr[idx(g)+1]-1"
Observation(g::ObservationGroup{<:Union{DataWithTmpVar,Data}})   = ObservationView(data(g), eachindex(g))
"grabs obs in idx(g) only"
Observation(g::ObservationGroup{<:ObservationGroup}) = ObservationGet( data(data(g)), idx(g))

"iterating over any kind of data object yields an obs group"
getindex(d::AbstractDataObject, i) = ObservationGroup(d, i)

"iteration over a Data/DataWithTmpVar yields an Obs Group"
function iterate(d::AbstractDataObject, i=firstindex(d))
    if i <= lastindex(d)
        return getindex(d,i), i+1
    else
        return nothing
    end
end

"grabs obs in idx(g) only"
function ObservationGet(data,i)
    t = tmpvar(data)
    yi = getindex(y(data), i)
    ti = getindex(t   , i)
    xi = view(x(data), :, i)
    return Observation(yi, xi, ti)
end

"grabs obs in rows ptr[idx(g)] : ptr[idx(g)+1]-1"
function ObservationView(data, idx)
    t = tmpvar(data)
    yi = view(y(data), idx)
    ti = view(t, idx)
    xi = view(x(data), :, idx)
    return Observation(yi, xi, ti)
end


end # module
