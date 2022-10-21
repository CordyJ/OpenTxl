%%
%%	T.C. Nicholas Graham
%%	GMD Karlsruhe
%%	Aug 21 1992
%%
%%
%%	Include file to coalesce function definitions.  Takes
%%	definitions of the form:
%%
%%		f = fn p1 -> e1.
%%		...
%%		f = fn pn -> en.
%%
%%	and produces:
%%
%%		f = fn X -> case X of
%%		                p1 -> e1
%%			      | ...
%%			      | pn -> en
%%                           end case
%%                  end fn.
%%
%%

rule coalesceEquations
    replace [repeat definition]
	F [functionName] = 'fn P [pattern] -> E [expression] 'end 'fn .
	Ds [repeat definition]
    construct I [lowerupperid]
	'mmm
    construct M [variable]
	I [!]
    construct CEqn [equation]
	F = 'fn M ->
		'case M 'of
		    P -> E
		'end 'case
	    'end 'fn .
    by
	CEqn [addEquations F Ds] Ds [removeEqn F]
end rule

function addEquations F [functionName] Eqns [repeat definition]
    replace [equation]
	CEqn [equation]
    by
	CEqn [addEquation F each Eqns]
end function

function addEquation F [functionName] SEqn [definition]
    replace [equation]
	CEqn [equation]
    by
	CEqn [addEquation1 F SEqn] [addEquation2 F SEqn]
end function

function addEquation1 F [functionName] SEqn [definition]
    deconstruct SEqn
	F = 'fn P [pattern] ->
		E [expression]
	    'end 'fn .
    replace [equation]
	F = 'fn V [variable] ->
		'case V 'of
		    A [alternative]
		    As [repeat alternatives]
		'end 'case
	    'end 'fn .
    construct NewA [alternatives]
	    '| P -> E
    by
	F = 'fn V ->
		'case V 'of
		    A
		    As [. NewA]
		'end 'case
	    'end 'fn .
end function

function addEquation2 F [functionName] SEqn [definition]
    deconstruct SEqn
	F = 'fn V1 [variable] ->
		E [expression]
	    'end 'fn .
    replace [equation]
	F = 'fn V [variable] ->
		'case V 'of
		    A [alternative]
		    As [repeat alternatives]
		'end 'case
	    'end 'fn .
    construct NewA [alternatives]
	    '| V1 -> E
    by
	F = 'fn V ->
		'case V 'of
		    A
		    As [. NewA]
		'end 'case
	    'end 'fn .
end function

rule removeEqn F [functionName]
    replace [repeat definition]
	F = E [expression] .
	Ds [repeat definition]
    by
	Ds
end rule
