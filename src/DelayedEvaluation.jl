module DelayedEvaluation

export DelayEval

"""
This module extends the idea behind `Base.Fix1` and `Base.Fix2` to any function and a
simple indexing syntax, similar to array indexing, to create delayed evaluation function objects.
This package relies on type piracy, defining `Base.getindex` for `Base.Callable`.

Examples:

    `sin[1.0]() == sin(1.0)`

    `map[:,[1,2,3]](x->x+1) == map(x->x+1,[1,2,3])`

    `map[:][[1,2,3]]() == map(x->x+1,[1,2,3])`

    `sort[by=x->x[1]]([(2,:a),(1,:b)]) == sort([(2,:a),(1,:b)];by=x->x[1])`
"""
DelayedEvaluation

"""`DelayEval{F,T}(f,x,kw)` returns an object for the delayed evaluation of
`f` with variables `x` and keyword args `kw`. The syntax for building such an
object is `f[x1,x2,...,xn,k1=v1,k2=v2,...,km=vm]`, i.e., indexing a function
with the fixed arguments and keyword arguments. Like an array, using `:` (`Colon()`)
will leave a blank for extra arguments to be supplied on call.

Examples:

    `sin[1.0]() == sin(1.0)`

    `map[:,[1,2,3]](x->x+1) == map(x->x+1,[1,2,3])`

    `map[:][[1,2,3]]() == map(x->x+1,[1,2,3])`

    `sort[by=x->x[1]]([(2,:a),(1,:b)]) == sort([(2,:a),(1,:b)];by=x->x[1])`
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

    `sin[1.0]() == sin(1.0)`

    `map[:,[1,2,3]](x->x+1) == map(x->x+1,[1,2,3])`

    `map[:][[1,2,3]]() == map(x->x+1,[1,2,3])`

    `sort[by=x->x[1]]([(2,:a),(1,:b)]) == sort([(2,:a),(1,:b)];by=x->x[1])`
"""
Base.getindex(f::F,x...; kw...) where {F<:Base.Callable} = DelayEval(f,x,kw)

function Base.display(f::DelayEval) 
    xs = join(map(string∘(x->x==Colon() ? ":" : x),f.x),", ")
    kw = map(collect(f.kw)) do (;first,second)
            second isa Function ? "$first = $second (some function)" : "$first = $second"
        end|>x->join(x,", ")
    kw = kw != "" ? "; $kw" : "" 
    println("delayed evaluation: $(f.f)[$(xs...)$(kw...)]")
end

(f::DelayEval)(ys...;kwargs...) = f.f(ReplaceColon(f.x,ys)...;f.kw...,kwargs...)

"""`ReplaceColon` is an iterator to supply call arguments for a DelayEval function
in the positions where its fixed args are `:` (`Colon()`) or as extra trainling arguments. 

Example:

    `(ReplaceColon((:a,:,:,:d),(:b,:c,:e))...,) == (:a,:b,:c,:d,:e)`
"""
struct ReplaceColon
    fixedargs
    callargs
end

function Base.iterate(r::ReplaceColon,(fixedstate,callstate)=(1,1))
    nf = length(r.fixedargs)
    nc = length(r.callargs)
    if fixedstate > nf && callstate > nc  # both sources exausted: finish
        return nothing
    elseif callstate > nc  # only call args are exausted: return next fixed arg
        item,fixedstate_new = iterate(r.fixedargs,fixedstate)
        return (item,(fixedstate_new,callstate))
    elseif fixedstate > nf  # only fixed args exausted: return next call arg
        item,callstate_new = iterate(r.callargs,callstate)
        return (item,(fixedstate,callstate_new))
    else  # general case: return next non Colon() arg, with priority for fixed args
        item,fixedstate_new = iterate(r.fixedargs,fixedstate)
        callstate_new = callstate
        if item==Colon()
            item,callstate_new = iterate(r.callargs,callstate)
        end
        return (item,(fixedstate_new,callstate_new))
    end
end

Base.length(r::ReplaceColon) = length(r.fixedargs) + length(r.callargs)

end