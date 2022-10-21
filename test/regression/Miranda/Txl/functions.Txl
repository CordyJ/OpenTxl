% Russell Halliday
% Functions.Txl
% CISC 499 - January - April, 1995

% This module contains the transforms necessary to evaluate Miranda functions.


redefine expression
        [exp]
   |    [infix]
   |    [prefix1]
   |	'Dummy
end redefine	

redefine cases
        [repeat altSemiEquals+]
        [lastcase] [opt ';]
end redefine

define altSemiEquals
        [alt] [opt ';] '=
end define


function expandFunctions Decs [repeat declaration] Indent [stringlit]
	replace [exp]
		FId [id] Params [repeat simple]
		Rest [repeat infix_exp]

	construct FDecs [repeat declaration]
		_ [extractFunction FId Decs]

	where not
	 	FDecs [?isEmpty]

	construct Dummy [exp]
		DuMmieE 

	construct Exp [exp]
		FId Params

	construct Base [stringlit]
		Indent [checkForId Exp '"Expanding the function call: "]

	construct FunctionResult [exp]
		Dummy [getFunctionResult Decs FDecs FId Params Indent]

	where not
		FunctionResult [= Dummy]

	construct NewMessage [stringlit]
		Indent [checkForId2 Exp FunctionResult '"Result of function call: "]

%	construct NewId [id]
%		_ [getid]

	by
		FunctionResult
end function

function isEmpty
	replace [repeat declaration]
		E [empty]

	by
		E
end function

function extractFunction FId [id] Decs [repeat declaration]
	replace [repeat declaration]
		FDecs [repeat declaration]

	deconstruct * [repeat declaration] Decs
		FId Formals [repeat formal] '= RHS [rhs]
		Rest [repeat declaration]

	construct Dec [declaration]
		FId Formals '= RHS

	by
		FDecs [. Dec] [extractFunction FId Rest]
end function
		
function getFunctionResult Decs [repeat declaration] FDecs [repeat declaration] Id [id] Params [repeat simple] Indent [stringlit]
	replace [exp]
		E [exp]

	construct Ex [expression]
		E 

	construct replacement [expression]
		Ex [replaceFunctionBody Decs Ex Id Params Indent each FDecs]

	where not
		replacement [= Ex]

	deconstruct replacement
		Final [exp]

	by
		Final
end function

function replaceFunctionBody Decs [repeat declaration] Exp [expression] Id [id] Params [repeat simple] Indent [stringlit] Dec [declaration]
	replace [expression]
		Ex [expression]

	where 
		Exp [= Ex]

	deconstruct Dec
		Id Formals [repeat formal] '= RHS [rhs]

	construct NewParams [repeat simple]
		_ [resolveEach Decs Indent each Params]
		
% This next line sounds cryptic, but I need to make sure that all
% the formals match the parameters.  In TXL, 'each' means an 'or'.
% I am applying DeMorgan's Laws here to create an 'and'.
	where not
		Ex [?AllFormalsAreNotGood each Formals NewParams]

	construct Expression [expression]
		Ex [getExpSimple_rhs Decs Id RHS Formals NewParams Indent]
		   [getExpCases Decs Id RHS Formals NewParams Indent]

	where not
		Expression [= Ex]

	by
		Expression
end function

function resolveEach Decs [repeat declaration] Indent [stringlit] P [simple]
	replace [repeat simple]
		Simples [repeat simple]

	construct Exp [exp]
		P

	construct NewIndent [stringlit]
		Indent [+ '"  "]

	construct ResolvedExp [exp]
		Exp [resolveExpression Decs NewIndent]

	deconstruct * [simple] ResolvedExp 
		Simple [simple]

	by
		Simples [. Simple]
end function
	

function AllFormalsAreNotGood F [formal] P [simple]
	replace [expression]
		Ex [expression]

	where not
		F [?containsAnId]

	where not
		F [?matchesWith P]

	by
		Ex
end function

function containsAnId
	replace * [id]
		Id [id]

	by
		Id
end function

function matchesWith P [simple]
	replace [formal]
		F [formal]

	construct SF [stringlit]
		_ [quote F]

	construct SP [stringlit]
		_ [quote P]

	where
		SF [= SP]

	by
		F
end function

function getExpSimple_rhs Decs [repeat declaration] Id [id] RHS [rhs] F [repeat formal] P [repeat simple] Indent [stringlit]
	replace [expression]
		Ex [expression]

	deconstruct RHS
		S [simple_rhs] Semi [opt ';]

        construct Message [stringlit]
                Indent [+ '"   using definition: "] [quote Id] [+ '" "]
		       [quote F] [+ '" = "] [quote S] [print]

	deconstruct S
		E [expression]
		OW [opt whdefs]

	construct NewParams [repeat simple]
		_ [fixPattern Decs Indent each F P]

	by
		E [fixListPattern1 each F NewParams]
		  [fixListPattern2 each F NewParams]
		  [replaceAllFormals each F NewParams]
		  [resolveWhereDefs OW F NewParams Indent]
end function

function replaceAllFormals F [formal] P [simple]
        replace [expression]
		E [expression] 

	deconstruct * [id] F
		Id [id]

	construct NewSimple [simple]	
		Id

        by
                E [$ NewSimple P] 
end function

function contains Id [id]
	match * [id]	
		Id
end function


rule resolveWhereDefs OW [opt whdefs] F [repeat formal] P [repeat simple] Indent [stringlit]
	replace [exp]
                Id [id] Params [repeat simple]
		Rest [repeat infix_exp]

	where
		OW [?contains Id]

	deconstruct * [repeat definition+] OW
		Defs [repeat definition+]

	construct Decs [repeat declaration] 
		_ [changeToDecs each Defs]

	construct FDecs [repeat declaration] 
		_ [extractFunction Id Decs]
		  [tackOn F]

        construct Dummy [exp]
                DuMmieE

	construct NewParams [repeat simple]
		Params [. P]

        construct FunctionResult [exp]
                Dummy [getFunctionResult Decs FDecs Id NewParams Indent]

        where not
                FunctionResult [= Dummy]

        construct Message [stringlit]
                Indent [+ '"      where: "] [quote Defs] [print]

        by
                ( FunctionResult )
end rule

function changeToDecs Def [definition]
	replace [repeat declaration]
		Decs [repeat declaration]

	construct NewDec [declaration]
		Def

	by
		Decs [. NewDec]
end function
			
function tackOn F [repeat formal]
	replace [repeat declaration]
                FId [id] Formals [repeat formal] '= RHS [rhs]
		Rest [repeat declaration]

	by
		FId Formals [. F] '= RHS
		Rest [tackOn F]
end function

function getExpCases Decs [repeat declaration] Id [id] RHS [rhs] F [repeat formal] P [repeat simple] Indent [stringlit]
	replace [expression]
		Exp [expression]

	deconstruct RHS
		C [cases]

	deconstruct * [opt whdefs] RHS
		OW [opt whdefs]

	deconstruct RHS
		Alts [repeat altSemiEquals+]
		Last [lastcase] Semi [opt ';]

	construct Expn [expression]
		Exp [getExpnToEvaluate Id Decs OW Exp F P Indent each Alts]
		    [checkLastCase Id Decs Exp F P Last Indent]

        construct NewParams [repeat simple]
                _ [fixPattern Decs Indent each F P]

	by
                Expn [fixListPattern1 each F NewParams]
		     [fixListPattern2 each F NewParams]
		     [replaceAllFormals each F NewParams]
                     [resolveWhereDefs OW F NewParams Indent]
end function
	
function getExpnToEvaluate Id [id] Decs [repeat declaration] OW [opt whdefs] Exp [expression] F [repeat formal] P [repeat simple] Indent [stringlit] Alt [altSemiEquals]
	replace [expression]
		E [expression]

	where
		E [= Exp]

	deconstruct Alt
		A [alt] Semi [opt ';] '=

	deconstruct A
		Expn [expression] ', I [opt 'if] Bool [expression]

        construct NewParams [repeat simple]
                _ [fixPattern Decs Indent each F P]

	construct NewIndent [stringlit]
		Indent [+ '"  "]

        construct NewE [expression]
                Bool [fixListPattern1 each F NewParams]
		     [fixListPattern2 each F NewParams]
		     [replaceAllFormals each F NewParams]
                     [resolveWhereDefs OW F NewParams Indent]
		     [resolveExpression Decs NewIndent]

	deconstruct * [boolean] NewE
		TrueOrFalse [boolean]

	construct Test1 [boolean]
		'True

	where
		TrueOrFalse [= Test1]

        construct Message [stringlit]
                Indent [+ '"   using definition: "] [quote Id] [+ '" "]
		       [quote F] [+ '" = "] [quote A] [print]

	by
		Expn
end function

function checkLastCase Id [id] Decs [repeat declaration] Exp [expression] F [repeat formal] P [repeat simple] Last [lastcase] Indent [stringlit]
        replace [expression]
                E [expression]

        where
                E [= Exp]

        deconstruct Last
		LastAlt [lastalt]
		OW [opt whdefs]

	construct TestExpn [expression]
		E [GetExpnIfCase Decs OW F P LastAlt Indent]
		  [GetExpnOtherwiseCase Decs OW F P LastAlt]

	where not
		TestExpn [= E]

        construct Message [stringlit]
                Indent [+ '"   using definition: "] [quote Id] [+ '" "]
                       [quote F] [+ '" = "] [quote LastAlt] [print]

        by
                TestExpn
end function

function GetExpnIfCase Decs [repeat declaration] OW [opt whdefs] F [repeat formal] P [repeat simple] LastAlt [lastalt] Indent [stringlit]
        replace [expression]
                E [expression]

        deconstruct LastAlt
                Expn [expression] ', I [opt 'if] Bool [expression]

        construct NewParams [repeat simple]
                _ [fixPattern Decs Indent each F P]

	construct NewIndent [stringlit]
		Indent [+ '" "]

        construct NewE [expression]
                Bool [fixListPattern1 each F NewParams]
		     [fixListPattern2 each F NewParams]
		     [replaceAllFormals each F NewParams]
                     [resolveWhereDefs OW F P Indent]
                     [resolveExpression Decs NewIndent]

	deconstruct * [boolean] NewE
		TrueOrFalse [boolean]

        construct Test1 [boolean]
                'True

        where
                TrueOrFalse [= Test1]

        by
                Expn
end function

function GetExpnOtherwiseCase Decs [repeat declaration] OW [opt whdefs] F [repeat formal] P [repeat simple] LastAlt [lastalt]
	replace [expression]
		E [expression]

	deconstruct LastAlt
		Expn [expression] ', 'otherwise

	by
		Expn
end function 
