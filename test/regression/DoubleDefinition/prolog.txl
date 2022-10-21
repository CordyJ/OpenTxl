define program
    [LogicBase]
    '<
    [NL]
    [LogicNode]
end define

define logicProgram
    [repeat clause]
end define

define clause
    [id]
end define 

define atom
    [lowerupperid]
end define

define LogicBase
    [repeat LogicNode]
end define

define LogicBase
    [repeat LogicNode]
end define

define LogicNode
    [atom]		%% functor
    [number]		%% arity
    [logicProgram]	%% clauses defining the functor with give arity
    [NL]
end define

function main
    replace [program]
	LB [LogicBase] '< LN [LogicNode]
    by
	LB '< LN [extractDB LB]
end function

function extractDB LB [LogicBase]
    replace [LogicNode]
	A [atom] N [number]
    deconstruct * [LogicNode] LB
	A [atom]
	N [number]
	L [logicProgram]
    by
	A N L
end function

