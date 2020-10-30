@doc raw"""
    NelderMead(M, F [, p])
perform a nelder mead minimization problem for the cost funciton `F` on the
manifold `M`. If the initial population `p` is not given, a random set of
points is chosen.

This algorithm is adapted from the Euclidean Nelder-Mead method, see
[https://en.wikipedia.org/wiki/Nelder–Mead_method](https://en.wikipedia.org/wiki/Nelder–Mead_method)
and
[http://www.optimization-online.org/DB_FILE/2007/08/1742.pdf](http://www.optimization-online.org/DB_FILE/2007/08/1742.pdf).

# Input

* `M` – a manifold $\mathcal M$
* `F` – a cost function $F\colon\mathcal M\to\mathbb R$ to minimize
* `population` – (n+1 `random_point(M)`) an initial population of $n+1$ points, where $n$
  is the dimension of the manifold `M`.

# Optional

* `stopping_criterion` – ([`StopAfterIteration`](@ref)`(2000)`) a [`StoppingCriterion`](@ref)
* `α` – (`1.`) reflection parameter ($\alpha > 0$)
* `γ` – (`2.`) expansion parameter ($\gamma$)
* `ρ` – (`1/2`) contraction parameter, $0 < \rho \leq \frac{1}{2}$,
* `σ` – (`1/2`) shrink coefficient, $0 < \sigma \leq 1$

and the ones that are passed to [`decorate_options`](@ref) for decorators.

# Output
* either `x` the last iterate or the complete options depending on the optional
  keyword `return_options`, which is false by default (hence then only `x` is
  returned).
"""
function NelderMead(
    M::MT,
    F::TF,
    population=[random_point(M) for i in 1:(manifold_dimension(M) + 1)];
    stopping_criterion::StoppingCriterion=StopAfterIteration(200000),
    α=1.0,
    γ=2.0,
    ρ=1 / 2,
    σ=1 / 2,
    return_options=false,
    kwargs..., #collect rest
) where {MT<:Manifold,TF}
    p = CostProblem(M, F)
    o = NelderMeadOptions(population, stopping_criterion; α=α, γ=γ, ρ=ρ, σ=σ)
    o = decorate_options(o; kwargs...)
    resultO = solve(p, o)
    if return_options
        return resultO
    else
        return get_solver_result(resultO)
    end
end
#
# Solver functions
#
function initialize_solver!(p::P, o::O) where {P<:CostProblem,O<:NelderMeadOptions}
    # init cost and x
    o.costs = get_cost.(Ref(p), o.population)
    return o.x = o.population[argmin(o.costs)] # select min
end
function step_solver!(p::P, o::O, iter) where {P<:CostProblem,O<:NelderMeadOptions}
    m = mean(p.M, o.population)
    ind = sortperm(o.costs) # reordering for cost and p, i.e. minimizer is at ind[1]
    ξ = log(p.M, m, o.population[last(ind)])
    # reflect last
    xr = exp(p.M, m, -o.α * ξ)
    Costr = get_cost(p, xr)
    # is it better than the worst but not better than the best?
    if Costr >= o.costs[first(ind)] && Costr < o.costs[last(ind)]
        # store as last
        o.population[last(ind)] = xr
        o.costs[last(ind)] = Costr
    end
    # --- Expansion ---
    if Costr < o.costs[first(ind)] # reflected is better than fist -> expand
        xe = retract(p.M, m, -o.γ * o.α * ξ, o.retraction_method)
        Coste = get_cost(p, xe)
        if Coste < Costr # expanded successful
            o.population[last(ind)] = xe
            o.costs[last(ind)] = Coste
        else # expansion failed but xr is still quite good -> store
            o.population[last(ind)] = xr
            o.costs[last(ind)] = Costr
        end
    end
    # --- Contraction ---
    if Costr > o.costs[ind[end - 1]] # even worse than second worst
        if Costr < o.costs[last(ind)] # but at least better tham last
            # outside contraction
            xc = exp(p.M, m, -o.ρ * ξ)
            Costc = get_cost(p, xc)
            if Costc < Costr # better than reflected -> store as last
                o.population[last(ind)] = xr
                o.costs[last(ind)] = Costr
            end
        else # even worse than last -> inside contraction
            # outside contraction
            xc = exp(p.M, m, o.ρ * ξ)
            Costc = get_cost(p, xc)
            if Costc < o.costs[last(ind)] # better than last ? -> store
                o.population[last(ind)] = xr
                o.costs[last(ind)] = Costr
            end
        end
    end
    # --- Shrink ---
    for i in 2:length(ind)
        o.population[ind[i]] = retract(
            p.M,
            o.population[ind[1]],
            inverse_retract(
                p.M, o.population[ind[1]], o.population[ind[i]], o.inverse_retraction_method
            ),
            o.σ,
            o.retraction_method,
        )
        # update cost
        o.costs[ind[i]] = get_cost(p, o.population[ind[i]])
    end
    # store best
    return o.x = o.population[argmin(o.costs)]
end
get_solver_result(p::P, o::O) where {P<:CostProblem,O<:NelderMeadOptions} = o.x
