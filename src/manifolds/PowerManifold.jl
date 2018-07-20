#
#      Powermanifold – an array of points of _one_ manifold
#
# Manopt.jl, R. Bergmann, 2018-06-26
import Base: exp, log, show

export PowerManifold, PowMPoint, PowTVector
export distance, dot, exp, log, manifoldDimension, norm, parallelTransport
export show, getValue
doc"""
    PowerManifold{M<:Manifold} <: Manifold
a power manifold $\mathcal M = \mathcal N^m$, where $m$ can be an integer or an
integer vector. Its abbreviatio is `Pow`.
"""
struct PowerManifold{M<:Manifold} <: Manifold
  name::String
  manifold::M
  dims::Array{Int,1}
  dimension::Int
  abbreviation::String
  PowerManifold{M}(mv::M,dims::Array{Int,1}) where {M<:Manifold} = new(string("A Power Manifold of ",mv.name,"."),
    mv,dims,prod(dims)*manifoldDimension(mv),string("Pow(",m.abbreviation,",",repr(dims),")") )
end
doc"""
    PowMPoint <: MPoint
A point on the power manifold $\mathcal M = \mathcal N^m$ represented by a vector or array of [`MPoint`](@ref)s.
"""
struct PowMPoint <: MPoint
  value::Array{T,N} where N where T<:MPoint
  PowMPoint(v::Array{T,N} where N where T<:MPoint) = new(v)
end
getValue(x::PowMPoint) = x.value;

doc"""
    PowTVector <: TVector
A tangent vector on the power manifold $\mathcal M = \mathcal N^m$ represented by a vector of [`TVector`](@ref)s.
"""
struct PowTVector <: TVector
  value::Array{T,N} where N where T <: TVector
  PowTVector(value::Array{T,N} where N where T <: TVector) = new(value)
end
getValue(ξ::PowTVector) = ξ.value
# Functions
# ---
"""
    addNoise(M,x,δ)
computes a vectorized version of addNoise, and returns the noisy [`PowMPoint`](@ref).
"""
addNoise(M::PowerManifold, x::PowMPoint,σ) = PowMPoint([addNoise.(M.manifold,p.value,σ)])
"""
    distance(M,x,y)
computes a vectorized version of distance, and the induced norm from the metric [`dot`](@ref).
"""
distance(M::PowerManifold, x::PowMPoint, y::PowMPoint) = sqrt(sum( distance.(M.manifold, getValue(x), getValue(y) ).^2 ))
"""
    dot(M,x,ξ,ν)
computes the inner product as sum of the component inner products on the [`PowerManifold`](@ref).
"""
dot(M::PowerManifold, x::PowMPoint, ξ::PowTVector, ν::PowTVector) = sum(dot.(M.manifold,getValue(x), getValue(ξ), getValue(ν) ))
"""
    exp(M,x,ξ)
computes the product exponential map on the [`PowerManifold`](@ref) and returns the corresponding [`PowMPoint`](@ref).
"""
exp(M::PowerManifold, x::PowMPoint, ξ::PowTVector, t::Number=1.0) = PowMPoint( exp.(M.manifold, getValue(p) , getValue(ξ) ))
"""
   log(M,x,y)
computes the product logarithmic map on the [`PowerManifold`](@ref) and returns the corresponding [`PowTVector`](@ref).
"""
log(M::PowerManifold, x::PowMPoint, y::PowMPoint)::PowTVector = ProdTVector(log.(M.manifold, getValue(p), getValue(q) ))
"""
    manifoldDimension(x)
returns the (product of) dimension(s) of the [`PowerManifold`](@ref) the [`PowMPoint`](@ref)`x` belongs to.
"""
manifoldDimension(p::PowMPoint) = prod(manifoldDimension.( getValue(p) ) )
"""
    manifoldDimension(M)
returns the (product of) dimension(s) of the [`PowerManifold`](@ref)` M`.
"""
manifoldDimension(M::PowerManifold) = prod( M.dims * manifoldDimension(M.manifold) )
"""
    norm(M,x,ξ)
norm of the [`PowTVector`]` ξ` induced by the metric on the manifold components
of the [`PowerManifold`](@ref)` M`.
"""
norm(M::PowerManifold, ξ::PowTVector) = sqrt( dot(M,ξ,ξ) )
"""
    parallelTransport(M,x,ξ)
computes the product parallelTransport map on the [`PowerManifold`](@ref) and returns the corresponding [`PowTVector`](@ref).
"""
parallelTransport(M::PowerManifold, x::PowMPoint, y::PowMPoint, ξ::PowTVector) = PowTVector( parallelTransport.(M.manifold, getValue(x), getValue(y), getValue(ξ)) )
#
#
# Display functions for the structs
show(io::IO, M::PowerManifold) = print(io,string("The Power Manifold of ",repr(M.manifold), " of size ",repr(M.dims),".") );
show(io::IO, p::PowMPoint) = print(io,string("PowM[",join(repr.(p.value),", "),"]"));
show(io::IO, ξ::PowTVector) = print(io,String("ProdMT[", join(repr.(ξ.value),", "),"]"));
