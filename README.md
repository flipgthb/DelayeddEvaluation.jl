# DelayedEvaluation

[![Build Status](https://github.com/flipgthb/DelayedEvaluation.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/flipgthb/DelayedEvaluation.jl/actions/workflows/CI.yml?query=branch%3Amain)

# DelayedEvaluation

This package extends the functionality of `Base.Fix1` and `Base.Fix2` to any function and provide a syntax to build `DelayEval` objects via `getindex` for callable objects, similar to `DataFrames` indexing. To achieve this, this package relies on type piracy, defining `Base.getindex` for `Base.Callable`. 

## Usage

Simply index a function using a `!` as a placeholder where arguments will be supplied on call. Examples:

`sin[1.0]() == sin(1.0)`

`map[!,[1,2,3]](x->x+1) = map(x->x+1,[1,2,3])`

`mapfoldl[x->x+1,!,[1,2,3]](*) == mapfoldl(x->x+1,*,[1,2,3])`

Keyword arguments are also supported

`sort[by=x->x[1]]([(2,:a),(1,:b)]) == sort([(2,:a),(1,:b)]; by=x->x[1])`

`sort[by=x->x[1]]([(2,:a),(1,:b)]; by=x->x[2]) == sort([(2,:a),(1,:b)]; by=x->x[2])`

`DelayEval <: Function`, so composition also works

`(first ∘ getindex[!,2])([(1,:a),(2,:b)]) == first(getindex([(1,:a),(2,:b)],2))`

 and also indexing a `DelayEval` will create a new one

 `getindex[!,2][[(1,:a),(2,:b)]]() == getindex([(1,:a),(2,:b)],2)`