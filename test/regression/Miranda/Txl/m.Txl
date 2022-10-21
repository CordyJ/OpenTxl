% This is the main Txl program for the CISC 499 project done by
% Russell Halliday
% January - April, 1995

% The most important part of this module is resolveExpression, which is the
% recursive function that evaluates the Miranda expressions given.

include "Miranda.Grammar"

include "primitives.Txl"
include "functions.Txl"
include "patterns.Txl"
include "boolean.Txl"
include "comparisons.Txl"
include "lists.Txl"
include "generators.Txl"

redefine exp
	[exp1] [repeat infix_exp]
   |	[number]
end redefine

redefine negative
        '-
end redefine

redefine reprefix
        [prefix1]
   |    [negative]
end redefine


function main
	replace [program]
		P [program]

	deconstruct P
		Decs [repeat declaration]
		Exp [exp]

	construct Indent [stringlit]
		'""

	by
		Exp [resolveExpression Decs Indent]
end function

rule changeStringsBack
	replace [simple]
		'[ EList [opt exp_list] ']

	deconstruct * [stringlit] EList 
		_ [stringlit]

	deconstruct EList
		ListE [list expression]

	construct String [stringlit]
		_ [addEachString each ListE]

	by
		String
end rule

function addEachString Exp [expression]
	replace [stringlit]
		String [stringlit]

	deconstruct * [stringlit] Exp
		String2 [stringlit]

	by
		String [+ String2]
end function

rule changeStringsToLists
	replace [simple]
		String [stringlit]

	construct Number [number]
		_ [# String] [- 2]

	where not
		Number [= 1]

	construct Simple [simple]
		String

	by
		Simple [changeLongerStrings]
		       [changeEmptyString]
end rule

function changeLongerStrings
	replace [simple]
		S [simple]

	deconstruct * [stringlit] S
		String [stringlit]

	construct Number [number]
		_ [# String] [- 2]

	where
		Number [> 1]

	construct ListOfChars [repeat expression]
		_ [changeToList String]

	construct List [list expression]
		_ [, each ListOfChars]

	by
		'[ List ']
end function

function changeEmptyString
	replace [simple]
		S [simple]

	deconstruct * [stringlit] S
		'""

	by
		'[']
end function

function changeToList String [stringlit]
	replace [repeat expression]
		List [repeat expression]

	construct Number [number]
		_ [# String] [- 2]

	construct GetFirstChar [stringlit]
		String [: 1 1]

	construct GetRestExpns [repeat expression]
		_ [getRest String Number]

	construct Expression [expression]
		GetFirstChar

	by
		List [. Expression] [. GetRestExpns] 
end function
	
function getRest String [stringlit] Number [number]
	replace [repeat expression]
		List [repeat expression]
	
	where
		Number [> 1]

	construct Rest [stringlit]
		String [: 2 Number]

	by
		List [changeToList Rest]		
end function

% resolveExpression is to be used for breaking down the expression
% into its component parts, then to evaluate the expression.

rule resolveExpression Decs [repeat declaration] Indent [stringlit]
	replace [exp]
		EXP [exp]

	construct Spaces [stringlit]
		'"  "

	construct NewExp [exp]
		EXP [evaluateParens Decs Indent] 
		    [evaluateGenerators Decs Indent]
		    [expandFunctions Decs Indent]
		    [doListOperations Decs Indent] 
		    [mergePrefixes] 
		    [normalizeBinaryOps]
		    [evaluateMultDiv Decs Indent] 
		    [evaluatePlusMinus Decs Indent] 
		    [evaluateComparators Decs Indent] 
		    [evaluateAnd Decs Indent] 
		    [evaluateOr Decs Indent] 
		    [evaluateEquality] 

	where not
		NewExp [= EXP]
	by
		NewExp
end rule

function normalizeBinaryOps
	replace [exp]
		EXP [exp]

	by
		EXP [caseInfix]
		    [caseInfixSimple]
		    [caseSimpleInfix]
end function

function caseInfix
	replace * [exp]
		'( List [opt exp_list] ') 
		Simple1 [simple]
		Simple2 [simple]
		Rest [repeat infix_exp]

	deconstruct List 
		ListExpression [list expression]

	deconstruct ListExpression
		Expression [expression]

	deconstruct Expression
		Infix [infix]

	construct NewExp [exp]
		Simple2

	construct NewInfixExp [infix_exp]
		Infix NewExp
	
	construct NewRepeatInfixExp [repeat infix_exp]
		NewInfixExp
		Rest

	construct NewExp1 [exp1]
		Simple1

	by
		NewExp1 NewRepeatInfixExp
end function

function caseInfixSimple
	replace * [exp]
		( I [infix1] EXP [exp] )
		Simple [simple]
		Rest [repeat infix_exp]

	construct NewInfixExp [infix_exp]
		I EXP

	construct NewRepeatInfixExp [repeat infix_exp]
		NewInfixExp
		Rest

	construct NewExp1 [exp1]
		Simple

	by
		NewExp1 NewRepeatInfixExp
end function

function caseSimpleInfix
	replace * [exp]
		( EXP [exp] Infix [infix] )
		Simple [simple]
		Rest [repeat infix_exp]

	construct NewExp [exp]
		Simple

	construct NewInfixExp [infix_exp]
		Infix NewExp

	construct NewRepeatInfixExp [repeat infix_exp]
		NewInfixExp
		Rest
	
	construct NewSimple [simple]
		'( EXP ')
	
	construct NewExp1 [exp1]
		NewSimple

	by
		NewExp1 NewRepeatInfixExp
end function
		
	
