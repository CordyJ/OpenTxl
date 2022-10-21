% Comparisons.Txl
% Used as part of Miranda interpreter
% Russell Halliday
% February, 1995

% Note, the '=' and '~=' cases are handled separately, since they can be 
% applied to any type.

% The following set of comparisons are used for the numeric operations

function evaluateEquality
	replace * [exp]
		Exp1 [exp1] Rest [repeat infix_exp]

	deconstruct Rest
		I [infix] Exp [exp]
		RestOfInfix_Exps [repeat infix_exp]

	where
		I [?isEqual]
		  [?isNotEqual]

	deconstruct Exp
		Exp2 [exp1] Rest2 [repeat infix_exp]

	construct AssumeFalse [boolean]
		'False

	construct Answer [boolean]
		AssumeFalse [checkIfEqual Exp1 Exp2]

        construct Simple [simple]
                Answer

        construct NewExp1 [simple]
                Simple

        by
                NewExp1 Rest2
end function

function isEqual 
	match * [infix1]
		'=
end function

function isNotEqual
	match * [infix1]
		'~=
end function

function checkIfEqual Exp1 [exp1] Exp2 [exp1]
	replace [boolean]
		Temp [boolean]

	where
		Exp1 [= Exp2]

	by
		'True
end function
	

function evaluateComparators Decs [repeat declaration] Indent [stringlit]
	replace * [exp]
		Exp1 [exp1] Rest [repeat infix_exp]

	deconstruct Rest
		I [infix] Exp [exp]
		RestOfInfix_Exps [repeat infix_exp]

	deconstruct Exp
		Exp2 [exp1] Rest2 [repeat infix_exp]

	construct Dummy [number]
		0

	construct Num1 [number]
		Dummy [extractNum Exp1 Decs Indent]

	construct Num2 [number]
		Dummy [extractNum Exp2 Decs Indent]

	where
		I [?isGreaterThan]
		  [?isGreaterThanEqual]
		  [?isLessThan]
		  [?isLessThanEqual]

	construct DumBool [boolean]
		'False

	construct Answer [boolean]
% Note for later:  If it should become a problem, space can be saved by 
% deleting LessThan and LessThanEqual, and simply use GreaterThan and 
% GreaterThanEqual with the arguments reversed.  They are left here for
% clarity.
		DumBool [GreaterThan Num1 Num2 I]
			[GreaterThanEqual Num1 Num2 I]
			[LessThan Num1 Num2 I]
			[LessThanEqual Num1 Num2 I]

	construct Simple [simple]
		Answer

	construct NewExp1 [simple]
		Simple

	by
		NewExp1 Rest2
end function

function isGreaterThan
        match * [infix1]
                '>
end function

function isGreaterThanEqual
        match * [infix1]
                >=
end function

function isLessThan
        match * [infix1]
                '<
end function

function isLessThanEqual
        match * [infix1]
                <=
end function

function GreaterThan Num1 [number] Num2 [number] I [infix]
	replace [boolean]
		Bool [boolean]

        deconstruct I
                I1 [infix1]

        deconstruct I1
                '>

	where
		Num1 [> Num2]

	by
		'True
end function

function GreaterThanEqual Num1 [number] Num2 [number] I [infix]
        replace [boolean]
                Bool [boolean]

        deconstruct I
                I1 [infix1]

        deconstruct I1
                '>=

        where
                Num1 [> Num2] [= Num2]

        by
                'True
end function

function LessThan Num1 [number] Num2 [number] I [infix]
        replace [boolean]
                Bool [boolean]

        deconstruct I
                I1 [infix1]

        deconstruct I1
                '<

        where
                Num1 [< Num2]

        by
                'True
end function

function LessThanEqual Num1 [number] Num2 [number] I [infix]
        replace [boolean]
                Bool [boolean]

        deconstruct I
                I1 [infix1]

        deconstruct I1
                '<=

        where
                Num1 [< Num2] [= Num2]

        by
                'True
end function
