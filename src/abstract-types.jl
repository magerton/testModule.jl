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
abstract type AbstractTmpVars{R<:Real} end

eltype(::AbstractTmpVars{R}) where {R} = R

# these hold data
"holds AbstractData + associated tmpvar"
abstract type AbstractDataSetWithTmpvar <: AbstractDataStructure end
abstract type AbstractData              <: AbstractDataStructure end

abstract type AbstractDataSetofSets     <: AbstractData end
abstract type AbstractDataSet           <: AbstractData end
abstract type AbstractObservationGroup  <: AbstractData end
abstract type AbstractObservation       <: AbstractData end

const DataOrObs      = AbstractData
const DataGroupOrObs = AbstractData

"Empty Data Set"
struct EmptyDataSet <: AbstractDataSet end
length(d::EmptyDataSet) = 0
eachindex(d::EmptyDataSet) = 1:typemax(Int)
nparm(d::EmptyDataSet) = 0
model(d::EmptyDataSet) = NoModel()
coefnames(d::EmptyDataSet) = Vector{String}(undef,0)
