module TestModule

# extend these methods
import Base: length, size, iterate,
    firstindex, lastindex, eachindex, getindex, IndexStyle,
    view, ==, eltype, +, -, isless,
    fill!,string, show, convert, eltype,
    step

using Base: OneTo


export DataWithTmpVar, tmpvar, data, model

include("abstract-types.jl")

struct DataWithTmpVar{D<:AbstractData, V<:AbstractTmpVars} <: AbstractDataSetWithTmpvar
    data::D
    tmpvar::V
end


data(  d::DataWithTmpVar) = d.data
tmpvar(d::DataWithTmpVar) = d.tmpvar
DataWithTmpVar(d, θ) = DataWithTmpVar(d, tmpvar(d, θ))
DataWithTmpVar(dtv::DataWithTmpVar) = dtv
length(dtv::DataWithTmpVar) = length(data(dtv))
# iterate( d::DataWithTmpVar, i=firstindex(data(d))) = iterate(data(d),i)

function getindex(dtv::DataWithTmpVar, i)
    d = getindex(data(dtv), i)
    return DataWithTmpVar(d, tmpvar(dtv))
end



export ObservationGroup, Observation

"""
Observation Groups help us iterate through a panel. They simply augment
the base dataset `D` with an index `i`

Examples:
- A vector of production from a well
- The full set of leases before or after 1st well drilled
- The set of actions associated w/ 1 lease
"""
struct ObservationGroup{D<:AbstractDataStructure,I} <: AbstractObservationGroup
    data::D
    i::I
    function ObservationGroup(data::D, i::I) where {D<:AbstractDataStructure,I}
        i in eachindex(data) || throw(BoundsError(data,i))
        return new{D,I}(data,i)
    end
end

const ObservationGroupEmpty = ObservationGroup{EmptyDataSet}

# Functions for these data structures
#-----------------------

# ObservationGroup
length(o::AbstractObservation) = length(y(o))

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

data(     d::AbstractDataSet) = d
group_ptr(d::AbstractDataSet) = d.group_ptr
obs_ptr(  d::AbstractDataSet) = d.obs_ptr

# default method
length(  d::AbstractDataSet) = length(group_ptr(d))-1
num_obs( d::AbstractDataSet) = length(obs_ptr(d))-1

groupstart( d::AbstractDataSet, i::Integer) = getindex(group_ptr(d), i)
groupstop(  d::AbstractDataSet, i::Integer) = groupstart(d,i+1)-1
grouplength(d::AbstractDataSet, i::Integer) = groupstop(d,i) - groupstart(d,i) + 1
grouprange( d::AbstractDataSet, i::Integer) = groupstart(d,i) : groupstop(d,i)

obsstart( d::AbstractDataSet, j::Integer) = getindex(obs_ptr(d),j)
obsstop(  d::AbstractDataSet, j::Integer) = obsstart(d,j+1)-1
obslength(d::AbstractDataSet, j::Integer) = obsstop(d,j) - obsstart(d,j) + 1
obsrange( d::AbstractDataSet, j::Integer) = obsstart(d,j) : obsstop(d,j)

# DataSet or Observation
model(d::DataOrObs) = d.model
y(    d::DataOrObs) = d.y
x(    d::DataOrObs) = d.x
num_x(d::DataOrObs) = size(x(d), 1)
xbeta(d::DataOrObs) = d.xbeta

@deprecate model(d::AbstractDataStructure) _model(d)
@deprecate _y(d::AbstractDataStructure) y(d)
@deprecate _x(d::AbstractDataStructure) x(d)
@deprecate _num_x(d::AbstractDataStructure) num_x(d)
@deprecate _xbeta(d) xbeta(d)

# ObservationGroup iteration utilties
#------------------------------------------

data( g::AbstractObservationGroup) = g.data
i(    g::AbstractObservationGroup) = g.i
num_x(g::AbstractObservationGroup) = num_x(data(g))
nparm(g::AbstractObservationGroup) = nparm(data(g))
model(g::AbstractObservationGroup) = model(data(g))

length(    g::AbstractObservationGroup) = grouplength(data(g), i(g))
grouprange(g::AbstractObservationGroup) = grouprange( data(g), i(g))

obsstart( g::AbstractObservationGroup, k) = obsstart( data(g), getindex(grouprange(g), k))
obsrange( g::AbstractObservationGroup, k) = obsrange( data(g), getindex(grouprange(g), k))
obslength(g::AbstractObservationGroup, k) = obslength(data(g), getindex(grouprange(g), k))







export DataTest, ObservationTest

struct ObservationTest{M<:NoModel, YT,XT} <: AbstractObservation
    model::M
    y::YT
    x::XT
end

struct DataTest{M<:NoModel} <: AbstractDataSet
    model::M
    y::Vector{Float64}
    x::Matrix{Float64}
end

DataTest(y,x) = DataTest(NoModel(), y, x)

function Observation(d, i)
    yi     = getindex(y(d), i)
    xi     = view(x(d), :, i)
    return ObservationTest(model(d), yi, xi)
end

struct TmpVarTest{R} <: AbstractTmpVars{R}
    xbeta::Vector{R}
end
xbeta(t::TmpVarTest) = t.xbeta
getindex(t::TmpVarTest, i) = getindex(xbeta(t), i)


length(d::DataTest) = length(y(d))
group_ptr(d::DataTest) = OneTo(length(d))
obs_ptr(  d::DataTest) = OneTo(length(d))
getindex(d::DataTest, i) = Observation(d, i)

tmpvar(d::AbstractData, theta=eltype(y(d))) = TmpVarTest(similar(y(d), eltype(theta)))
DataWithTmpVar(d::AbstractData, args...) = DataWithTmpVar(d, tmpvar(d, args...))




export GroupedDataTest, GroupedObservationTest

struct GroupedObservationTest{M<:NoModel, V<:AbstractVector} <: AbstractObservation
    model::M
    y::Float64
    x::V
end

struct GroupedDataTest{M<:NoModel} <: AbstractDataSet
    model::M
    y::Vector{Float64}
    x::Matrix{Float64}
    group_ptr::Vector{Int}
    obs_ptr::Vector{Int}
end

GroupedDataTest(y,x, grp_ptr, obs_ptr) = GroupedDataTest(NoModel(), y, x, grp_ptr, obs_ptr)

function Observation(d::GroupedDataTest, j::Integer)
    trng = obsrange(d, j)
    yi   = getindex(y(d), trng)
    xi   = view(x(d), :, trng)
    return ObservationTest(model(d), yi, xi)
end

getindex(g::ObservationGroup{<:GroupedDataTest}, k) = Observation(data(g), grouprange(g)[k])


tmpvar(d::DataTest, θ) = TmpVarTest(similar(y(d)))
DataWithTmpVar(d::DataTest) = DataWithTmpVar(d, tmpvar(d))








end # module
