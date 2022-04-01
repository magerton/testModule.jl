module TestModule

# extend these methods
import Base: length, size, iterate,
    firstindex, lastindex, eachindex, getindex, IndexStyle,
    view, ==, eltype, +, -, isless,
    fill!,string, show, convert, eltype,
    step

using Base: OneTo

include("abstract-types.jl")


# export DataTest, ObservationTest

# # ------------------------

# "basic observation"
# struct ObservationTest{M<:NoModel, YT,XT} <: AbstractObservation
#     model::M
#     y::YT
#     x::XT
# end

# "basic data"
# struct DataTest{M<:NoModel} <: AbstractDataSet
#     model::M
#     y::Vector{Float64}
#     x::Matrix{Float64}
# end

# struct TmpVarTest{R} <: AbstractTmpVars{R}
#     xbeta::Vector{R}
# end

# xbeta(t::TmpVarTest) = t.xbeta
# getindex(t::TmpVarTest, i) = getindex(xbeta(t), i)

# # ---------------------------------------

# DataTest(y,x) = DataTest(NoModel(), y, x)

# function Observation(d, i)
#     yi     = getindex(y(d), i)
#     xi     = view(x(d), :, i)
#     return ObservationTest(model(d), yi, xi)
# end



# length(   d::DataTest)    = length(y(d))
# group_ptr(d::DataTest)    = OneTo(length(d)+1)
# obs_ptr(  d::DataTest)    = OneTo(length(d)+1)
# getindex( d::DataTest, i) = Observation(d, i)

# tmpvar(d::AbstractData, theta=eltype(y(d))) = TmpVarTest(similar(y(d), eltype(theta)))
# DataWithTmpVar(d::AbstractData, args...) = DataWithTmpVar(d, tmpvar(d, args...))




# export GroupedDataTest, GroupedObservationTest

# struct GroupedObservationTest{M<:NoModel, V<:AbstractVector} <: AbstractObservation
#     model::M
#     y::Float64
#     x::V
# end

# struct GroupedDataTest{M<:NoModel} <: AbstractDataSet
#     model::M
#     y::Vector{Float64}
#     x::Matrix{Float64}
#     group_ptr::Vector{Int}
#     obs_ptr::Vector{Int}
# end

# GroupedDataTest(y,x, grp_ptr, obs_ptr) = GroupedDataTest(NoModel(), y, x, grp_ptr, obs_ptr)

# function Observation(d::GroupedDataTest, j::Integer)
#     trng = obsrange(d, j)
#     yi   = getindex(y(d), trng)
#     xi   = view(x(d), :, trng)
#     return ObservationTest(model(d), yi, xi)
# end

# getindex(g::ObservationGroup{<:GroupedDataTest}, k) = Observation(data(g), grouprange(g)[k])


# tmpvar(d::DataTest, θ) = TmpVarTest(similar(y(d)))
# DataWithTmpVar(d::DataTest) = DataWithTmpVar(d, tmpvar(d))


# export AbstractJnkIterator, JnkBase, JnkGroup, Level

# abstract type AbstractJnkIterator{N} end

# struct JnkBase{N,T} <: AbstractJnkIterator{N}
#     x::T
# end

# JnkBase(x::T) where {T} = JnkBase{1,T}(x)

# struct JnkGroup{N,J<:AbstractJnkIterator} <: AbstractJnkIterator{N}
#     jnk::J
#     i::Int
# end

# Level(::AbstractJnkIterator{N}) where {N} = N

# function JnkGroup(g::AbstractJnkIterator, i=g.i)
#     N = Level(g)
#     J = typeof(g)
#     return JnkGroup{N-1,J}(g,i)
# end

# JnkGroup(g::AbstractJnkIterator{0}, args...) = "done"



end # module
