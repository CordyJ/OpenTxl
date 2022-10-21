% Russell Halliday
% CISC 499
% January - April, 1995

% The following function implement Miranda primitive operations.


function evaluateParens Decs [repeat declaration] Indent [stringlit]
	replace [exp]
		Pattern [exp]

	deconstruct Pattern
		'( Exp [exp] ')

	construct Message [stringlit]
		Indent [checkForId Pattern '"Expanding the expression:"]

	construct NewIndent [stringlit]
		Indent [+ '"  "]

	construct NewExp [exp]
		Exp [resolveExpression Decs NewIndent]

	construct Message2 [stringlit]
		Indent [checkForId2 Pattern NewExp '"Result of expression:"]

	by
		NewExp
end function

redefine IndentedExp
	[id] [exp]
end redefine

function checkForId Expn [exp] PutString [stringlit]
	replace [stringlit]
		String [stringlit]

	where
		Expn [?hasAnId]

	construct NewString [stringlit]
		String [+ PutString] [print]

	construct Id [id]
		_ [unquote String]

	construct NewExpn [IndentedExp]
		Id Expn 

	construct FinalExpn [IndentedExp]
		NewExpn [print]

	by
		NewString 
end function

function checkForId2 Expn [exp] Simple [exp] PutString [stringlit]
        replace [stringlit]
                String [stringlit]

        where
                Expn [?hasAnId]

        construct NewString [stringlit]
                String [+ PutString] [print]

	construct IndentedId [id]
		_ [unquote String]

	construct NewExpn [IndentedExp]
		IndentedId Expn 

	construct PNewExpn [IndentedExp]
		NewExpn [print]

	construct Id [id]
		IndentedId [+ 'is]

	construct PrintId [id]
		Id [print]

	construct NewSimple [IndentedExp]
		IndentedId Simple

	construct PNewSimple [IndentedExp]
		NewSimple [print]

	by
		NewString
end function

function hasAnId
	match * [id]
		Id [id]
end function

function mergePrefixes
	replace * [exp1]
		P [prefix] E [exp]

	construct Exp1 [exp1]
		P E

	by
		Exp1 [applyNegation]
		     [applyLogicalNot]
end function

function applyNegation
	replace [exp1]
		P [prefix] E [exp]

	deconstruct P
		'- % N [negative]

	deconstruct E
		Num [number]

	construct Zero [number]
		0

	construct NewNum [number]
		Zero [- Num]

	construct L [lit]
		NewNum
		
	construct Simple [simple]
		L

	construct Simples [repeat simple+]
		Simple

	by
		Simples
end function

function applyLogicalNot
	replace [exp1]
		P [prefix] E [exp]

	deconstruct * [prefix1] P
		'~

	deconstruct * [boolean] E
		Bool [boolean]

	construct DummyBool [boolean]
		'False

	construct NewBool [boolean]
		DummyBool [notFalse Bool]

	construct Simple [simple]
		NewBool

	construct NewExp1 [exp1]
		Simple
	
	by
		Simple
end function

function notFalse Bool [boolean]
	replace [boolean]
		OldBool [boolean]

	where
		Bool [= OldBool]

	by
		'True
end function
		

rule evaluateMultDiv Decs [repeat declaration] Indent [stringlit]
	replace [exp]
		Exp1 [exp1] Rest [repeat infix_exp]

	deconstruct Rest
		I [infix] Exp [exp]
		RestOfInfix_Exps [repeat infix_exp]

	where
		I [?isMult]
		  [?isDiv]

	deconstruct Exp
		Exp2 [exp1] Rest2 [repeat infix_exp]

	construct NewExp [exp]
		Exp1 I Exp2

	construct Message [stringlit]
		Indent [checkForId NewExp '"Applying binary operation: "] 

	construct Num1 [number] 
		_ [extractNum Exp1 Decs Indent]

	construct Num2 [number]
		_ [extractNum Exp2 Decs Indent]

	construct Result [number] 
		Num1 [multiply Num2 I]
		     [divide Num2 I]

	construct Simple [simple]
		Result

	construct NewExp1 [exp]
		Simple Rest2

	construct Message2 [stringlit]
		Indent [checkForId2 NewExp NewExp1 '"Result of binary operation:"] 

	by
		NewExp1
end rule

function isMult
	match * [infix1]
		'*
end function

function isDiv
	match * [infix1]
		'/
end function

function isAdd
	match * [infix1]
		'+
end function

function isSubtract
	match * [infix]
		'-
end function

function evaluatePlusMinus Decs [repeat declaration] Indent [stringlit]
	replace [exp]
                Exp1 [exp1] Rest [repeat infix_exp]

        deconstruct Rest
                I [infix] Exp [exp]
                RestOfInfix_Exps [repeat infix_exp]

	where
		I [?isAdd]
		  [?isSubtract]

        deconstruct Exp
                Exp2 [exp1] Rest2 [repeat infix_exp]

	construct NewExp [exp]
		Exp1 I Exp2

        construct Message [stringlit]
                Indent [checkForId NewExp '"Applying binary operation:"]

        construct Num1 [number]
                _ [extractNum Exp1 Decs Indent]

        construct Num2 [number]
                _ [extractNum Exp2 Decs Indent]

        construct Result [number]
                Num1 [Add Num2 I]
                     [Subtract Num2 I]

	construct Simple [simple]
		Result

	construct NewExp1 [exp]
		Simple Rest2

	construct Message2 [stringlit]
		Indent [checkForId2 NewExp NewExp1 '"Result of binary operation: "] 

        by
		NewExp1 
end function


function extractNum Exp [exp1] Decs [repeat declaration] Indent [stringlit]
	replace [number]
		OldNum [number]

	construct NewExp [exp]
		Exp

	construct NewIndent [stringlit]
		Indent [+ '"  "]

	construct ResolvedExp [exp]
		NewExp [resolveExpression Decs NewIndent]

	deconstruct ResolvedExp
		Simples [repeat simple+]

	deconstruct * [number] Simples
		Num [number]

	by
		Num 
end function

function multiply Num2 [number] I [infix]
	replace [number]
		Num [number]

	deconstruct I
		I1 [infix1]

	deconstruct I1
		'*

	by
		Num [* Num2]
end function

function divide Num2 [number] I [infix]
	replace [number]
		Num [number]

	deconstruct I
		I1 [infix1]

	deconstruct I1
		'/

	by
		Num [/ Num2]
end function

function Add Num2 [number] I [infix]
        replace [number]
                Num [number]

        deconstruct I
                I1 [infix1]

        deconstruct I1
                '+

        by
                Num [+ Num2]
end function

function Subtract Num2 [number] I [infix]
        replace [number]
                Num [number]

        deconstruct I
                '-

        by
                Num [- Num2]
end function

rule absoluteValue
       replace [exp1]
                FId [id] Params [repeat simple]

        deconstruct FId
                'abs

        deconstruct Params
		First [simple]

	deconstruct * [number] First
		Number [number]
	
	construct NewNum [number]
		Number [invertIfNegative]

	construct Simple [simple]
		NewNum
		
	construct NewExp1 [exp1]
		Simple
	
        by
                NewExp1
end rule

function invertIfNegative
	replace [number]
		Num [number]

	construct Zero [number]
		0

	where
		Num [< Zero]

	by
		Zero [- Num]
end function
