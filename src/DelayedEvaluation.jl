module DelayedEvaluation

export DelayEval, delay

"""
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
"""
DelayedEvaluation

"""`DelayEval{F,T}(f,x,kw)` returns an object for the delayed evaluation of
`f` with variables `x` and keyword args `kw`. Use `delay` instead for building
such an object: `delay(f,x1,x2,...,xn,k1=v1,k2=v2,...,km=vm)`, creates a
function with the fixed arguments and keyword arguments. Analogous to a arrays, 
you can use `:` as a placeholder for extra arguments to be supplied on call.

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
"""
struct DelayEval{F,T} <: Function
    f::F
    x::T
    kw::Base.Pairs

    DelayEval(f::F,x,kw) where {F} = new{F,_stable_typeof(x)}(f, x, kw)
    DelayEval(f::Type{F},x,kw) where {F} = new{Type{F},_stable_typeof(x)}(f, x, kw)
end

_stable_typeof(x) = typeof(x)
_stable_typeof(::Type{T}) where {T} = @isdefined(T) ? Type{T} : DataType

"""
`delay(f,x1,x2,...,xn,k1=v1,k2=v2,...,km=vm)` creates function with the fixed
arguments and keyword arguments. Analogous to a arrays, 
you can use `:` as a placeholder for extra arguments to be supplied on call.

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
"""
delay(f::F,x...; kw...) where {F<:Base.Callable} = DelayEval(f,x,kw)

function Base.display(f::DelayEval) 
    xs = join(map(string∘(x->x == Colon() ? ":" : x),f.x),", ")
    kw = map(collect(f.kw)) do (;first,second)
            second isa Function ? "$first = $second (some function)" : "$first = $second"
        end|>x->join(x,", ")
    println("delayed evaluation: $(f.f)($(xs)$(isempty(kw) ? kw : string(", ",kw)))")
end

(f::DelayEval)(ys...;kwargs...) = f.f(fillholes(f.x,ys)...;f.kw...,kwargs...)

"""
Replaces `Colon()` in `tobefilled` by values in `supplier`, appending remaining values to 
the end.
"""
function fillholes(filled,tobefilled,supplier)
    i = findfirst(==(Colon()),tobefilled)
    if isnothing(i) || isempty(supplier) || isempty(tobefilled)
        return (filled...,tobefilled...,supplier...)
    else
        x,ys... = supplier
        return fillholes((filled...,tobefilled[1:i-1]...,x),tobefilled[i+1:end],ys)
    end
end

"""
Replaces `Colon()` in `tobefilled` by values in `supplier`, appending remaining values to 
the end.
"""
fillholes(tobefilled,supplier) = fillholes((),tobefilled,supplier)

end