using DelayedEvaluation
import DelayedEvaluation: fillholes
using Test

@testset "Testing `fillholes`" begin
    @test fillholes((),()) == ()
    @test fillholes((),(10,)) == (10,)
    @test fillholes((:,20),(10,)) == (10,20)
    @test fillholes((10,),()) == (10,)
    @test fillholes((10,),(20,30)) == (10,20,30)
    @test fillholes((:,20,:,40),(10,30,50)) == (10,20,30,40,50)
    @test fillholes((!,20),(10,30); placeholder=(!)) == (10,20,30)
end

@testset "Testing `delay`" begin
    @test delay(sin,1.0)() == sin(1.0)
    @test delay(map,:,[1,2,3])(x->x+1) == map(x->x+1,[1,2,3])
    @test delay(mapfoldl,x->x+1,:,[1,2,3])(*) == mapfoldl(x->x+1,*,[1,2,3])
    @test delay(sort; by=x->x[1])([(2,:a),(1,:b)]) == sort([(2,:a),(1,:b)]; by=x->x[1])
    @test delay(sort; by=x->x[1])([(2,:a),(1,:b)]; by=x->x[2]) == sort([(2,:a),(1,:b)]; by=x->x[2])
    @test (first ∘ delay(getindex,:,2))([(1,:a),(2,:b)]) == first(getindex([(1,:a),(2,:b)],2))
    @test delay(delay(getindex,:,2),[(1,:a),(2,:b)])() == getindex([(1,:a),(2,:b)],2)
    @test delay.(sin,[0.0,1.0]) == [delay(sin,0.0), delay(sin,1.0)]
    @test delay(max,!,1.0)(2.0; placeholder=(!)) == max(2.0,1.0)
end

;