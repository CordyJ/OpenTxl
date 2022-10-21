%%
%%	T.C. Nicholas Graham
%%	GMD Karlsruhe
%%	Aug 21 1992
%%
%%
%%	Include file to unravel function definitions.  Takes
%%	definitions of the form:
%%
%%		f x y z = e.
%%
%%	and produces:
%%
%%		f = fn x -> fn y -> fn z -> e end fn end fn end fn.
%%
%%


function unravelFunDefs
    replace [program]
	Ds [program]
    by
	Ds [unravelFunDefs1]
end function

function unravelFunDefs1
    replace [program]
	Ds [program]
    by
	Ds [unravelSimpleFunDef] [unravelFunDef] [unravelLambdaAbstractions]
end function

rule unravelSimpleFunDef
    replace [equation]
	F [functionName] V [variable] = E [expression] .
    by
	F = 'fn V -> E 'end 'fn .
end rule

rule unravelFunDef
    replace [equation]
	F [functionName] P [headPattern] = E [expression] .
    by
	F = 'fn P -> E 'end 'fn .
end rule

rule unravelLambdaAbstractions
    replace [repeat definition]
	Ds [repeat definition]
    deconstruct * [lambdaAbstraction] Ds
	L [patternLambdaAbstraction]
    by
	Ds [unravelOneArgV] [unravelOneArg]
	   [unravelMultiArgsV] [unravelMultiArgs]
end rule

rule unravelOneArgV
    replace [lambdaAbstraction]
	'fn P [simplePattern] ->
	    E [expression]
	'end 'fn
    deconstruct P
	V [variable]
    construct L [simpleLambdaAbstraction]
	'fn V ->
	    E
	'end 'fn
    by
	L
end rule

rule unravelOneArg
    replace [lambdaAbstraction]
	L [patternLambdaAbstraction]
    deconstruct L
	'fn P [simplePattern] ->
	    E [expression]
	'end 'fn
    construct Pp [pattern]
	P
    construct Lp [onePatternLambdaAbstraction]
	'fn Pp ->
	    E
	'end 'fn
    by
	Lp
end rule

rule unravelMultiArgsV
    replace [lambdaAbstraction]
	'fn V1 [variable] Ps [repeat simplePattern+] ->
	    E [expression]
	'end 'fn
    by
	'fn V1 ->
	    'fn Ps ->
		E
	    'end 'fn
	'end 'fn
end rule

rule unravelMultiArgs
    replace [lambdaAbstraction]
	'fn P1 [simplePattern] Ps [repeat simplePattern+] ->
	    E [expression]
	'end 'fn
    construct P1p [pattern]
	P1
    construct Lp [onePatternLambdaAbstraction]
	'fn P1p ->
	    'fn Ps ->
		E
	    'end 'fn
	'end 'fn
    by
	Lp
end rule
