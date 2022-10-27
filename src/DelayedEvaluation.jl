module DelayedEvaluation

export DelayEval

"""
# DelayedEvaluation

This package extends the functionality of `Base.Fix1` and `Base.Fix2` to any function and provide a syntax to build `DelayEval` objects via `getindex` for callable objects, similar to `DataFrames` indexing. To achieve this, this package relies on type piracy, defining `Base.getindex` for `Base.Callable`. 

## Usage

Simply index a function using a `!` as a placeholder where arguments will be supplied on call. Examples:

```julia
sin[1.0]() == sin(1.0)

map[!,[1,2,3]](x->x+1) = map(x->x+1,[1,2,3])

mapfoldl[x->x+1,!,[1,2,3]](*) == mapfoldl(x->x+1,*,[1,2,3])
```

Keyword arguments are also supported

```julia
sort[by=x->x[1]]([(2,:a),(1,:b)]) == sort([(2,:a),(1,:b)]; by=x->x[1])

sort[by=x->x[1]]([(2,:a),(1,:b)]; by=x->x[2]) == sort([(2,:a),(1,:b)]; by=x->x[2])
```

`DelayEval <: Function`, so composition also works

```julia
(first ∘ getindex[!,2])([(1,:a),(2,:b)]) == first(getindex([(1,:a),(2,:b)],2))
```

 and also indexing a `DelayEval` will create a new one

 ```julia
 getindex[!,2][[(1,:a),(2,:b)]]() == getindex([(1,:a),(2,:b)],2)
 ```

 Unfortunately, broadcast via indexing syntax sugar is invalid

 ```julia
    sin.[[0.0,1.0]]
    #-> ERROR: syntax: invalid syntax "sin.[[1, 0]]" around ...
 ```
"""
DelayedEvaluation

"""`DelayEval{F,T}(f,x,kw)` returns an object for the delayed evaluation of
`f` with variables `x` and keyword args `kw`. The syntax for building such an
object is `f[x1,x2,...,xn,k1=v1,k2=v2,...,km=vm]`, i.e., indexing a function
with the fixed arguments and keyword arguments. Analogous to a `DataFrame`, 
you can use `!` as a placeholder for extra arguments to be supplied on call.

Examples:

```julia
sin[1.0]() == sin(1.0)

map[!,[1,2,3]](x->x+1) = map(x->x+1,[1,2,3])

mapfoldl[x->x+1,!,[1,2,3]](*) == mapfoldl(x->x+1,*,[1,2,3])
```

Keyword arguments are also supported

```julia
sort[by=x->x[1]]([(2,:a),(1,:b)]) == sort([(2,:a),(1,:b)]; by=x->x[1])

sort[by=x->x[1]]([(2,:a),(1,:b)]; by=x->x[2]) == sort([(2,:a),(1,:b)]; by=x->x[2])
```

`DelayEval <: Function`, so composition also works

```julia
(first ∘ getindex[!,2])([(1,:a),(2,:b)]) == first(getindex([(1,:a),(2,:b)],2))
```

 and also indexing a `DelayEval` will create a new one

 ```julia
 getindex[!,2][[(1,:a),(2,:b)]]() == getindex([(1,:a),(2,:b)],2)
 ```

 Unfortunately, broadcast via indexing syntax sugar is invalid

 ```julia
    sin.[[0.0,1.0]]
    #-> ERROR: syntax: invalid syntax "sin.[[1, 0]]" around ...
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
`getindex(f::F,x...,kw...) where {F<:Base.Callable} -> DelayEval(f,x,kw)`

Build a `DelayEval` object for function `f`. See `DelayEval`.

Examples:

```julia
sin[1.0]() == sin(1.0)

map[!,[1,2,3]](x->x+1) = map(x->x+1,[1,2,3])

mapfoldl[x->x+1,!,[1,2,3]](*) == mapfoldl(x->x+1,*,[1,2,3])
```

Keyword arguments are also supported

```julia
sort[by=x->x[1]]([(2,:a),(1,:b)]) == sort([(2,:a),(1,:b)]; by=x->x[1])

sort[by=x->x[1]]([(2,:a),(1,:b)]; by=x->x[2]) == sort([(2,:a),(1,:b)]; by=x->x[2])
```

`DelayEval <: Function`, so composition also works

```julia
(first ∘ getindex[!,2])([(1,:a),(2,:b)]) == first(getindex([(1,:a),(2,:b)],2))
```

 and also indexing a `DelayEval` will create a new one

 ```julia
 getindex[!,2][[(1,:a),(2,:b)]]() == getindex([(1,:a),(2,:b)],2)
 ```

 Unfortunately, broadcast via indexing syntax sugar is invalid

 ```julia
    sin.[[0.0,1.0]]
    #-> ERROR: syntax: invalid syntax "sin.[[1, 0]]" around ...
 ```
"""
Base.getindex(f::F,x...; kw...) where {F<:Base.Callable} = DelayEval(f,x,kw)

function Base.display(f::DelayEval) 
    xs = join(map(string∘(x->x == (!) ? "!" : x),f.x),", ")
    kw = map(collect(f.kw)) do (;first,second)
            second isa Function ? "$first = $second (some function)" : "$first = $second"
        end|>x->join(x,", ")
    println("delayed evaluation: $(f.f)[$(xs)$(isempty(kw) ? kw : string(", ",kw))]")
end

(f::DelayEval)(ys...;kwargs...) = f.f(FillPlaceHolder(f,ys)...;f.kw...,kwargs...)

"""`FillPlaceHolder` is an iterator to supply call arguments for a DelayEval function
in the positions where its fixed args are `!` or as extra trainling arguments. 

Example:
    `(ReplaceColon((:a,!,!,:d),(:b,:c,:e))...,) == (:a,:b,:c,:d,:e)`
"""
struct FillPlaceHolder
    fixedargs
    callargs
end

FillPlaceHolder(f::DelayEval,callargs) = FillPlaceHolder(f.x,callargs)

function Base.iterate(a::FillPlaceHolder,(fixedstate,callstate)=(1,1))
    endfixed = fixedstate > length(a.fixedargs)
    endcall = callstate > length(a.callargs)
    if endfixed && endcall  # both sources exausted: finish
        return nothing
    elseif endcall  # only call args are exausted: return next fixed arg
        item,fixedstate_new = iterate(a.fixedargs,fixedstate)
        return (item,(fixedstate_new,callstate))
    elseif endfixed  # only fixed args exausted: return next call arg
        item,callstate_new = iterate(a.callargs,callstate)
        return (item,(fixedstate,callstate_new))
    else  # general case: return next non X arg, with priority for fixed args
        item,fixedstate_new = iterate(a.fixedargs,fixedstate)
        callstate_new = callstate
        if item == (!)
            item,callstate_new = iterate(a.callargs,callstate)
        end
        return (item,(fixedstate_new,callstate_new))
    end
end

Base.length(r::FillPlaceHolder) = length(r.fixedargs) + length(r.callargs) - count(==(!),r.fixedargs)

end