export AbstractDataStructure, AbstractDataSetofSets,
    AbstractDataSet, AbstractObservationGroup, AbstractObservation,
    EmptyDataSet, AbstractDataSetWithTmpvar, AbstractData

# for modeling
abstract type AbstractModelObject end
abstract type AbstractModel <: AbstractModelObject end

"Royalty rates"
abstract type AbstractRoyaltyModel       <: AbstractModel end
abstract type AbstractProductionModel    <: AbstractModel end
abstract type AbstractDrillModel         <: AbstractModel end
abstract type AbstractDynamicDrillModel  <: AbstractDrillModel end
abstract type AbstractStaticDrillModel   <: AbstractDrillModel end

abstract type AbstractModelVariations <: AbstractModelObject end

"No model"
struct NoModel <: AbstractModel end
length(::NoModel) = 0
nparm(::NoModel) = 0
@deprecate _nparm(m) nparm(m)



# For data structures
# "Collection of data on a particular outcome for individuals `i`"
# "What we feed into a likelihood"
# "Group of observations"
abstract type AbstractDataStructure end

abstract type AbstractTmpVars{R} end # note, we can't place limits on R<:Real
eltype(::AbstractTmpVars{R}) where {R} = R
(::Type{T})(x::T) where {T<:AbstractTmpVars} = x


# these hold data
"holds AbstractData + associated tmpvar"
abstract type AbstractDataSetWithTmpvar{N} <: AbstractDataStructure end
eltype(x::AbstractDataSetWithTmpvar) = eltype(tmpvar(x))
Level(::AbstractDataSetWithTmpvar{N}) where {N} = N


abstract type AbstractDataSetofSets     <: AbstractDataStructure end

abstract type AbstractData{N}              <: AbstractDataStructure end
abstract type AbstractDataSet{N}           <: AbstractData{N} end
abstract type AbstractObservationGroup{N}  <: AbstractData{N} end
abstract type AbstractObservation{N}       <: AbstractData{N} end

Level(::AbstractData{N}) where {N} = N

"Empty Data Set"
struct EmptyDataSet{N} <: AbstractDataSet{N} end
length(d::EmptyDataSet) = 0
eachindex(d::EmptyDataSet) = 1:typemax(Int)
nparm(d::EmptyDataSet) = 0
model(d::EmptyDataSet) = NoModel()
coefnames(d::EmptyDataSet) = Vector{String}(undef,0)

EmptyDataSet() = EmptyDataSet{0}()
Observation(d::AbstractData{0}, args...) = d

export ObservationGroup, Observation

"""
Observation Groups help us iterate through a panel. They simply augment
the base dataset `D` with an index `i`

Examples:
- A vector of production from a well
- The full set of leases before or after 1st well drilled
- The set of actions associated w/ 1 lease
"""
struct ObservationGroup{N, D<:AbstractDataStructure, I} <: AbstractObservationGroup{N}
    data::D  # data
    i::I     # index
    function ObservationGroup(data::D, i::I) where {D<:AbstractDataStructure,I}
        i in eachindex(data) || throw(BoundsError(data,i))
        N = Level(D)
        return new{N-1,D,I}(data,i)
    end
end

const ObservationGroupEmpty = ObservationGroup{0,EmptyDataSet}

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
# when there are no levels left, we create an observation
getindex(d::AbstractData{N}, i) = ObservationGroup(d,i)
getindex(d::AbstractData{0}, i) = Observation(d,i)


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
model(d::AbstractData) = d.model
y(    d::AbstractData) = d.y
x(    d::AbstractData) = d.x
num_x(d::AbstractData) = size(x(d), 1)
xbeta(d::AbstractData) = d.xbeta

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





export DataWithTmpVar, tmpvar, data, model


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

