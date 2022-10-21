%%
%%	T.C. Nicholas Graham
%%	GMD Karlsruhe
%%	21 August 1992
%%
%%
%%	Takes the patterns out of lambda abstractions.  Abstractions
%%	of the form:
%%
%%		fn P -> E end fn
%%
%%	go to:
%%
%%		fn v ->
%%		    let P = v in E end let
%%		end fn
%%
%%
%%
%%


function depattern
    replace [program]
	P [program]
    by
	P [depattern1] [decommandPatterns]
end function

rule depattern1
    replace [lambdaAbstraction]
	'fn P [pattern] -> 
	    E [expression] 
	'end 'fn
    construct X [lowerupperid]
	'patternVar
    construct NewX [lowerupperid]
	X [!]
    by
	'fn NewX ->
	    'let P = NewX 'in
		E
	    'end 'let
	'end 'fn
end rule



%  Take out !'s and ?'s from patterns:
rule decommandPatterns
    replace [pattern]
	C [upperlowerid] S [directiveSymbol] Ps [repeat simplePattern]
    by
	C Ps
end rule
