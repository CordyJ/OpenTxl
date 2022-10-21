%%
%%	fixupExpressions
%%
%%	T.C. Nicholas Graham
%%	GMD Karlsruhe, 22 August 1992
%%
%%	Puts parentheses on expressions so they can be read by humans
%%	without ambiguity.
%%
%%	Disambiguates between functionNames's and variable's.
%%	Assumes everything has been parsed as a functionName, and
%%	changes to variable as necessary.
%%


function fixupExpressions
    replace [program]
	D [program]
    by
	D [fixupParens] [fixupVariables]
	  [fixupBinaryExpressions] [fixupExtraParens]
end function

rule fixupParens
    replace [application]
	Fn [simpleExpression] A [simpleExpression] As [repeat simpleExpression+]
    by
	( Fn A ) As
end rule

function fixupVariables
    replace [program]
	D [program]
    by
	D [fixVarsInFn] [fixVarsInCase] [fixVarsInLet]
end function

function fixVar V [variable]
    replace [expression]
	E [expression]
    deconstruct V
	I [lowerupperid]
    construct VE [simpleExpression]
	V
    construct F [functionName]
	I
    construct FE [simpleExpression]
	F
    by
	E [$ FE VE]
end function


rule fixVarsInFn
    replace [lambdaAbstraction]
	'fn V [variable] ->
	    E [expression]
	'end 'fn
    by
	( 'fn V =>
	    E [fixVar V]
	)
end rule

rule fixVarsInCase
    replace [alternative]
	P [pattern] -> E [expression]
    construct VarsInPattern [repeat variable]
	_ [^ P]
    by
	P : E [fixVar each VarsInPattern]
end rule

rule fixVarsInLet
    replace [letExpression]
	'let Bs [list binding+] 'in
	    E [expression]
	'end 'let
    by
	( 'let Bs 'in E [fixOneBinding each Bs]
	)
end rule

function fixOneBinding B [binding]
    replace [expression]
	E [expression]
    deconstruct B
	P [pattern] = E1 [expression]
    construct VList [repeat variable]
	_ [^ P]
    by
	E [fixVar each VList]
end function


% Puts precedence on binary expressions -- for now, hacks them
% left-to-right -- should do it properly!
rule fixupBinaryExpressions
    replace [expression]
	B1 [binarySubExpression] Op1 [binaryOp] B2 [binarySubExpression]
	    Op2 [binaryOp] B3 [binarySubExpression]
    by
	( B1 Op1 B2 ) Op2 B3
end rule

rule fixupExtraParens
    replace [simpleExpression]
	( ( E [expression] ) )
    by
	( E )
end rule
