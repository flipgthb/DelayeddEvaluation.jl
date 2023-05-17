# DelayedEvaluation

[![Build Status](https://github.com/flipgthb/DelayedEvaluation.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/flipgthb/DelayedEvaluation.jl/actions/workflows/CI.yml?query=branch%3Amain)

# DelayedEvaluation

This package extends the functionality of `Base.Fix1` and `Base.Fix2` to any function and
provide a syntax to build `DelayEval` objects via `delay` for callable objects.

## Usage

Use the function `delay` with `:` as a placeholders where arguments will be supplied on call.
Examples:

```julia
delay(sin,1.0)() == sin(1.0)

delay(map,:,[1,2,3])(x->x+1) = map(x->x+1,[1,2,3])

delay(mapfoldl,x->x+1,:,[1,2,3])(*) == mapfoldl(x->x+1,*,[1,2,3])
```

Keyword arguments are also supported

```julia
delay(sort; by=x->x[1])([(2,:a),(1,:b)]) == sort([(2,:a),(1,:b)]; by=x->x[1])

delay(sort; by=x->x[1])([(2,:a),(1,:b)]; by=x->x[2]) == sort([(2,:a),(1,:b)]; by=x->x[2])
```

`DelayEval <: Function`, so composition also works

```julia
(first ∘ delay(getindex,:,2))([(1,:a),(2,:b)]) == first(getindex([(1,:a),(2,:b)],2))
```

 and also indexing a `DelayEval` will create a new one

 ```julia
 delay(delay(getindex,:,2),[(1,:a),(2,:b)])() == getindex([(1,:a),(2,:b)],2)
 ```

 Broadcasting returns a container of `DelayEval`s: 

 ```julia
    delay.(sin,[0.0,1.0]) == [delay(sin,0.0), delay(sin,1.0)]
 ```

 ## Packages with similar functionality

[FixArgs.jl](https://github.com/goretkin/FixArgs.jl)
[ChainedFixes.jl](https://github.com/Tokazama/ChainedFixes.jl)