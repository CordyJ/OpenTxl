% Boolean.Txl
% Russ Halliday
% CISC 499 - January - April, 1995

% This module contains the primitive boolean operations.  It is included
% by the file 'main.Txl'



redefine simple
   	[boolean]
   |    [id]
   |    [lit]
   |    'readvals
   |    'show
   |    ( [infix1] [exp] )
   |    ( [exp] [infix] )
   |    ( [opt exp_list] )
   |    '[ [opt exp_list] ']
   |    '[ [expression] .. [opt expression] ']
   |    '[ [expression] ', [expression] .. [opt expression] ']
   |    '[ [expression] '| [qualifs] ']
   |    '[ [expression] // [qualifs] ']
end redefine

redefine boolean
	'True
   |	'False
end redefine


function evaluateAnd Decs [repeat declaration] Indent [stringlit]
	replace * [exp]
		Exp1 [exp1] Rest [repeat infix_exp]

	deconstruct Rest
		I [infix] Exp [exp]
		RestOfInfix_Exps [repeat infix_exp]

	deconstruct Exp
		Exp2 [exp1] Rest2 [repeat infix_exp]

        construct Dummy [boolean]
                'False

        construct Bool1 [boolean]
                Dummy [extractBool Exp1 Decs Indent]

        construct Bool2 [boolean]
                Dummy [extractBool Exp2 Decs Indent]

        where
                I [?isAnd]

        construct Result [boolean]
                Bool1 [logicalAnd Bool2 I]

        construct Simple [simple]
                Result

        construct NewExp1 [exp1]
                Simple

        by
                NewExp1 Rest2
end function

function evaluateOr Decs [repeat declaration] Indent [stringlit]
        replace * [exp]
                Exp1 [exp1] Rest [repeat infix_exp]

        deconstruct Rest
                I [infix] Exp [exp]
                RestOfInfix_Exps [repeat infix_exp]

        deconstruct Exp
                Exp2 [exp1] Rest2 [repeat infix_exp]

        construct Dummy [boolean]
                'False

        construct Bool1 [boolean]
                Dummy [extractBool Exp1 Decs Indent]

        construct Bool2 [boolean]
                Dummy [extractBool Exp2 Decs Indent]

        where
                I [?isOr]

        construct Result [boolean]
                Bool1 [logicalOr Bool2 I]

        construct Simple [simple]
                Result

        construct NewExp1 [exp1]
                Simple

        by
                NewExp1 Rest2
end function

function isAnd
	match * [infix1]
		'&
end function

function isOr
	match * [infix1]
		\/
end function

function extractBool Exp [exp1] Decs [repeat declaration] Indent [stringlit]
        replace [boolean]
                OldBool [boolean]

	construct NewExp [exp1]
		Exp [resolveExpression Decs Indent]

        deconstruct Exp
                Simples [repeat simple+]

        deconstruct * [boolean] Exp
                Bool [boolean]

        by
                Bool
end function

function logicalAnd Bool2 [boolean] I [infix]
	replace [boolean]
		Bool [boolean]

	deconstruct I
		I1 [infix1]

	deconstruct I1
		'&

	construct DefResult [boolean]
		'False

	by
		DefResult [AndTrueTrue Bool2 Bool]
		% since only the 'and' of two 'trues' can result in
		% a 'true'
end function

function AndTrueTrue Bool2 [boolean] Bool [boolean]
	deconstruct Bool2
		'True

	replace [boolean]
		B [boolean]

	deconstruct Bool
		'True

	by
		'True
end function

function logicalOr Bool2 [boolean] I [infix]
        replace [boolean]
                Bool [boolean]

        deconstruct I
                I1 [infix1]

        deconstruct I1
                '\/

        construct DefResult [boolean]
                'True

        by
                DefResult [OrFalseFalse Bool2 Bool]
                % since only the 'or' of two 'falses' can result in
                % a 'false'
end function

function OrFalseFalse Bool2 [boolean] Bool [boolean]
        deconstruct Bool2
                'False

        replace [boolean]
                B [boolean]

        deconstruct Bool
                'False

        by
                'False
end function
