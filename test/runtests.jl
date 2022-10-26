using DelayedEvaluation
using Test

@testset "Util: ReplaceColon" begin
    @test (DelayedEvaluation.ReplaceColon((:a,:,:,:d),(:b,:c,:e))...,) == (:a,:b,:c,:d,:e)
end

@testset "Main functionality: DelayEval and getindex" begin
    @test sin[1.0]() == sin(1.0)
    @test map[:,[1,2,3]](x->x+1) == map(x->x+1,[1,2,3])
    @test sort[by=x->x[1]]([(2,:a),(1,:b)]) == sort([(2,:a),(1,:b)]; by=x->x[1])
end
