% CISC 499
% Russell Halliday
% Jan - April, 1995

% This module contains all the list primitives for the Miranda programming
% language.  Included by 'main.Txl'

% This function specifies the order in which list operations should be done.
% At the time of writing, this appears to be a complete list of functions.

function doListOperations Decs [repeat declaration] Indent [stringlit]
	replace [exp]
		Exp [exp]

	construct NewDecs [repeat declaration]
		Decs % [changeStringsToLists]

	by
		Exp % [changeStringsToLists]
		    [changeNumDotDotNum]
		    [PlusPlus Decs Indent]
		    [Concat]
		    [Head]
		    [Tail]
		    [Init]
	            [Last]
		    [Take]
		    [Drop]
		    [Reverse]
		    [Zip]
		    [Indexing]
		    [InfiniteIndexing Decs Indent]
		    [MinusMinus]
		    [Map]
		    [indexFunction]
		    [Colon]
		    [And Decs Indent]
		    [Or Decs Indent]
		    % [changeStringsBack]
end function

function changeNumDotDotNum
	replace [exp]
		'[ Ex1 [expression] .. OEx2 [opt expression] ']

	deconstruct OEx2
		Ex2 [expression]

	deconstruct * [number] Ex1
		Num1 [number]

	deconstruct * [number] Ex2
		Num2 [number]

	construct NumList [list expression]
		_ [generateNums Num1 Num2]

	construct EList [opt exp_list]
		NumList

	by
		'[ EList ']
end function

function generateNums Num1 [number] Num2 [number]
	replace [list expression]
		List [list expression]

	where not
		Num1 [> Num2]

	construct Simple [simple]
		Num1

	construct Exp1 [exp1]
		Simple
		
	construct Expression [expression]
		Exp1

	construct NumPlus1 [number]
		Num1 [+ 1]

	by
		List [, Expression] [generateNums NumPlus1 Num2]
end function

function indexFunction
       replace [exp]
                FId [id] Params [repeat simple]
		Rest [repeat infix_exp]

        deconstruct FId
                'index

        deconstruct Params
                List [simple]

	deconstruct List
		'[ OList [opt exp_list] ']

	deconstruct OList
		EList [list expression]

	construct Zero [number]
		0

	construct StopHere [number]
		Zero [stopit]

	construct RepExpn [repeat expression]
		_ [. each EList]

	construct ListNums [list expression]
		_ [generateIndices Zero RepExpn]

	construct NewExp1 [exp1]
		'[ ListNums ']

        by
                NewExp1
end function

function stopit
	replace [number]
		Num [number]

	by
		Num
end function

function generateIndices Number [number] TheList [repeat expression]
	replace [list expression]
		List [list expression]

	deconstruct TheList
		First [expression]
		Rest [repeat expression]

        construct Simple [simple]
                Number

        construct Exp1 [exp1]
                Simple

        construct Expression [expression]
                Exp1

	construct NewNum [number]
		Number [+ 1]

	by
		List [, Expression] [generateIndices NewNum Rest]
end function

function PlusPlus Decs [repeat declaration] Indent [stringlit]
	replace [exp]
		E [exp]

	deconstruct E
		Exp1 [exp1] Rest [repeat infix_exp]

	deconstruct Rest 
		I [infix] Exp [exp]
		RestOfInfix_Exps [repeat infix_exp]

	deconstruct Exp
		Exp2 [exp1] Rest2 [repeat infix_exp]

	where
		I [?isPlusPlus]

	construct NExp [exp]
		Exp1

	construct NewIndent [stringlit]
		Indent [+ '"  "]

	construct FExp1 [exp]
		NExp [ifTheresAnIdExpandIt Decs NewIndent]

	construct NExp2 [exp]
		Exp2

	construct FExp2 [exp]
		NExp2 	[ifTheresAnIdExpandIt Decs NewIndent]

	deconstruct FExp1
		'[ EList [opt exp_list] ']

	deconstruct FExp2
		'[ E2List [opt exp_list] ']

	deconstruct EList
		ListE1 [list expression]

	deconstruct E2List
		ListE2 [list expression]

	construct Result [list expression]
		ListE1 [, each ListE2]

	construct Simple [simple]
		'[ Result ']

	construct NewExp [exp1]
		Simple

	by
		NewExp Rest2
end function

function ifTheresAnIdExpandIt Decs [repeat declaration] NewIndent [stringlit]
	replace [exp]
		Exp [exp]

	where
		Exp [?hasAnId]

	by
		Exp % [changeStringsBack]		
		    [resolveExpression Decs NewIndent]
		    % [changeStringsToLists]
end function

function isPlusPlus
	match * [infix1]
		++
end function

function Concat
	replace [exp]
		FId [id] Params [repeat simple]		
		Rest [repeat infix_exp]

	deconstruct FId
		'concat

	deconstruct Params
		'[ ExpList [opt exp_list] ']

	deconstruct ExpList
		List [list expression]

	construct Result [list expression]
		_ [AddEach each List]	

	construct NewResult [opt exp_list]
		Result

	construct Simple [simple]
		'[ NewResult ']

	construct NewExp1 [exp1]
		Simple

	by
		NewExp1 Rest
end function

function AddEach List [expression]
	replace [list expression]
		Exps [list expression]

	deconstruct * [opt exp_list] List
		EList [opt exp_list]

	deconstruct EList
		NList [list expression]

	by
		Exps [, each NList]
end function

function Head 
        replace [exp]
                FId [id] Params [repeat simple]
		RestInfixExps [repeat infix_exp]

        deconstruct FId
                'hd

        deconstruct Params
                '[ ExpList [opt exp_list] ']

        deconstruct ExpList
                List [list expression]

	construct Elements [repeat expression]
		_ [. each List]

	deconstruct Elements
		First [expression]
		Rest [repeat expression]

	deconstruct * [exp1] First
		Result [exp1]

        by
                Result RestInfixExps
end function

function Tail
        replace [exp]          
                FId [id] Params [repeat simple]         
		RestInfixExps [repeat infix_exp]

        deconstruct FId         
                'tl

        deconstruct Params              
                '[ ExpList [opt exp_list] ']            

        deconstruct ExpList             
                List [list expression]          

        construct Elements [repeat expression]
                _ [. each List]

        deconstruct Elements
                First [expression]
                Rest [repeat expression]

	construct ListElements [list expression]
		_ [, each Rest]

        construct NewResult [opt exp_list]
                ListElements

        construct Simple [simple]
                '[ NewResult ']

        construct NewExp1 [exp1]
                Simple

        by
                NewExp1 RestInfixExps
end function

function Init
        replace [exp]
                FId [id] Params [repeat simple]
		Rest [repeat infix_exp]

        deconstruct FId
                'init

        deconstruct Params
                '[ ExpList [opt exp_list] ']

        deconstruct ExpList
                List [list expression]

        construct Elements [repeat expression]
                _ [. each List]

        construct InitElements [repeat expression]
		_ [IterateThroughList Elements]

        construct ListElements [list expression]
                _ [, each InitElements]

        construct NewResult [opt exp_list]
                ListElements

        construct Simple [simple]
                '[ NewResult ']

        construct NewExp1 [exp1]
                Simple

        by
                NewExp1 Rest
end function

function IterateThroughList Elements [repeat expression]
	deconstruct Elements
		First [expression]
		Second [expression]
		Rest [repeat expression]

	replace [repeat expression]
		Exps [repeat expression]

	construct NewElements [repeat expression]
		Second 
		Rest

	by
		Exps [. First] [IterateThroughList NewElements]
end function

function Last
        replace [exp]
                FId [id] Params [repeat simple]
		Rest [repeat infix_exp]

        deconstruct FId
                'last

        deconstruct Params
                '[ ExpList [opt exp_list] ']

        deconstruct ExpList
                List [list expression]

        construct Elements [repeat expression]
                _ [. each List]

	construct Zero [number]
		0

	construct LengthList [number]
		Zero [length Elements]

        construct Element [repeat expression]
                Elements [select LengthList LengthList]

	deconstruct Element
		Final [expression]

        construct NewResult [opt exp_list]
                Final

        construct Simple [simple]
                '[ NewResult ']

        construct NewExp1 [exp1]
                Simple

        by
                NewExp1 Rest
end function

function Take
       replace [exp]
                FId [id] Params [repeat simple]
		Rest [repeat infix_exp]

        deconstruct FId
                'take

        deconstruct Params
		Lit [lit]
                '[ ExpList [opt exp_list] ']

	deconstruct * [number] Lit
		Number [number]

        deconstruct ExpList
                List [list expression]

        construct Elements [repeat expression]
                _ [. each List]

	construct NewList [repeat expression]
		Elements [getFirstNElements Number]

	construct FinalList [list expression]
		_ [, each NewList]

        construct NewResult [opt exp_list]
                FinalList

        construct Simple [simple]
                '[ NewResult ']

	construct NewExp1 [exp1]
                Simple

        by
                NewExp1 Rest
end function

function getFirstNElements Number [number]
	replace [repeat expression]
		Exps [repeat expression]

	construct One [number]
		1

	construct LengthList [number]
		One [length Exps]

	where
		LengthList [> Number]

	by
		Exps [select One Number]
end function

function removeFirstNElements Number [number]
	replace [repeat expression]
		Exps [repeat expression]

	construct One [number]
		1

	construct LengthList [number]
		One [length Exps]

	where
		LengthList [> Number]

	construct NumberPlus1 [number]
		Number [+ One]

	by
		Exps [select NumberPlus1 LengthList]
end function

function Drop
       replace [exp]
                FId [id] Params [repeat simple]
		Rest [repeat infix_exp]

        deconstruct FId
                'drop

        deconstruct Params
                Lit [lit]
                '[ ExpList [opt exp_list] ']

        deconstruct * [number] Lit
                Number [number]

        deconstruct ExpList
                List [list expression]

        construct Elements [repeat expression]
                _ [. each List]

        construct NewList [repeat expression]
                Elements [removeFirstNElements Number]

        construct FinalList [list expression]
                _ [, each NewList]

        construct NewResult [opt exp_list]
                FinalList

        construct Simple [simple]
                '[ NewResult ']

        construct NewExp1 [exp1]
                Simple

        by
                NewExp1 Rest
end function

function Reverse
       replace [exp]
                FId [id] Params [repeat simple]
		Rest [repeat infix_exp]

        deconstruct FId
                'reverse

        deconstruct Params
                '[ ExpList [opt exp_list] ']

        deconstruct ExpList
                List [list expression]

        construct Elements [repeat expression]
                _ [. each List]

        construct NewList [repeat expression]
                _  [reverseThem each Elements]

        construct FinalList [list expression]
                _ [, each NewList]

        construct NewResult [opt exp_list]
                FinalList

        construct Simple [simple]
                '[ NewResult ']

        construct NewExp1 [exp1]
                Simple

        by
                NewExp1 Rest
end function
	
function reverseThem Exp [expression]
	replace [repeat expression]		
		Exps [repeat expression]

	by
		Exp
		Exps
end function

function Zip 
       replace [exp]
                FId [id] Params [repeat simple]
		Rest [repeat infix_exp]

        deconstruct FId
                'zip

        deconstruct Params
                '( ListPair [opt exp_list] ')

	deconstruct ListPair
		First [expression] , Second [expression]

        deconstruct * [list expression] First 
                FList [list expression]

        deconstruct * [list expression] Second 
                SList [list expression]

        construct NewList [list expression]
                _ [makeListOfPairs each FList SList]

        construct NewResult [opt exp_list]
                NewList

        construct Simple [simple]
                '[ NewResult ']

        construct NewExp1 [exp1]
                Simple

        by
                NewExp1 Rest
end function

function makeListOfPairs First [expression] Second [expression]
	replace [list expression]
		List [list expression]

	construct Element [simple]
		'( First, Second ')

	construct Exp1 [exp1]
		Element

	construct Expn [expression]
		Exp1

	by
		List [, Expn]
end function 

function Indexing
	replace [exp]
                Exp1 [exp1] Rest [repeat infix_exp]

        deconstruct Rest
                I [infix] Exp [exp]
                RestOfInfix_Exps [repeat infix_exp]

        deconstruct Exp
                Exp2 [exp1] Rest2 [repeat infix_exp]

	deconstruct * [infix1] I
		'!

	deconstruct * [simple] Exp1
		'[ ExpList [opt exp_list] ']

	deconstruct * [number] Exp2
		Number [number]

        deconstruct ExpList
                List [list expression]

	construct ChkList [repeat expression]
		_ [. each List]

	construct Zero [number]
		0

	construct LengthOfList [number]
		Zero [countList ChkList] [- 1]

	where
		Number [< LengthOfList] [= LengthOfList]

	construct EffectiveNum [number]
		Number [+ 1]

        construct Elements [repeat expression]
                ChkList [select EffectiveNum EffectiveNum]

	deconstruct Elements
		Element [expression]
		RestOfExps [repeat expression]

	deconstruct Element
		NewExp1 [exp1]

        by
                NewExp1 Rest2
end function

function InfiniteIndexing Decs [repeat declaration] Indent [stringlit]
        replace [exp]
                Exp1 [exp1] Rest [repeat infix_exp]

        deconstruct Rest
                I [infix] Exp [exp]
                RestOfInfix_Exps [repeat infix_exp]

        deconstruct * [infix1] I
                '!

        deconstruct * [simple] Exp1
                '[ E [expression] .. ']

        deconstruct Exp
                Exp2 [exp1] Rest2 [repeat infix_exp]

        deconstruct * [number] Exp2
                IndexNum [number]

	deconstruct E
		UnresolvedExp [exp]

	construct ResolvedExp [exp]
		UnresolvedExp [resolveExpression Decs Indent]

        deconstruct * [number] ResolvedExp
                Value [number]

	construct NewValue [number]
		Value [+ IndexNum] [- 1]

	construct NewExp1 [exp1]
		NewValue

        by
                NewExp1 Rest2
end function

function countList ChkList [repeat expression]
	replace [number]
		Num [number]

	deconstruct ChkList
		First [expression]
		Rest [repeat expression]
	
	by
		Num [+ 1] [countList Rest]
end function

function MinusMinus
        replace  [exp]
                Exp1 [exp1] Rest [repeat infix_exp]

        deconstruct Rest
                I [infix] Exp [exp]
                RestOfInfix_Exps [repeat infix_exp]

        deconstruct Exp
                Exp2 [exp1] Rest2 [repeat infix_exp]

        where
                I [?isMinusMinus]

        deconstruct Exp1
                '[ EList [opt exp_list] ']

	deconstruct Exp2
		'[ E2List [opt exp_list] ']


	deconstruct EList
		ListE1 [list expression]

	deconstruct E2List
		ListE2 [list expression]

	construct RepeatE1 [repeat expression]
		_ [. each ListE1]

	construct RepeatList [repeat expression]
		RepeatE1 [deleteEach each ListE2]

	construct FinalList [list expression]
		_ [, each RepeatList]

	construct Result [opt exp_list]
		FinalList

        construct Simple [simple]
                '[ Result ']

        construct NewExp1 [exp1]
                Simple

        by
                NewExp1 Rest2
end function

function isMinusMinus
        match * [infix1]
                --
end function

function deleteEach E2 [expression]
	replace * [repeat expression]
		E2	
		Rest [repeat expression]

	by
		Rest
end function

function Colon
        replace [exp]
                Exp1 [exp1] Rest [repeat infix_exp]

        deconstruct Rest
                I [infix] Exp [exp]
                RestOfInfix_Exps [repeat infix_exp]

        deconstruct Exp
                Exp2 [exp1] Rest2 [repeat infix_exp]

	deconstruct * [infix1] I
		':

        deconstruct * [simple] Exp1
                Element [simple]

        deconstruct Exp2
                '[ EList [opt exp_list] ']

	construct Expn [expression]
		Element

	construct ListExpn [list expression]
		Expn

	deconstruct EList
		OldList [list expression]

        construct Result [list expression]
                ListExpn [, each OldList]

        construct ListExp [opt exp_list]
                Result

        construct Simple [simple]
                '[ Result ']

        construct NewExp1 [exp1]
                Simple

        by
                NewExp1 Rest2
end function

function Map
       replace [exp]
                FId [id] Params [repeat simple]
		Rest [repeat infix_exp]

	deconstruct FId
		'map

        deconstruct Params
		FunctionName [simple] 
		List [simple]

	construct NewId [id]
		FId [!]

        construct NewResult [simple]
		'[ FunctionName NewId '| NewId <- List ']

        construct NewExp1 [exp1]
                NewResult

        by
                NewExp1 Rest
end function

function And Decs [repeat declaration] Indent [stringlit] 
	replace [exp]
		'and Params [repeat simple]
		RestI [repeat infix_exp]

	deconstruct Params
		List [simple]
		Rest [repeat simple]

        construct Exp [exp]
                List

        construct NewExp [exp]
                Exp [resolveExpression Decs Indent]

	construct Bool [boolean]
		'False

	where not
		NewExp [hasBool Bool]

	construct Simple [simple]
		'True

	construct NewExp1 [exp1]
		Simple

	by
		NewExp1 RestI
end function

function hasBool Bool [boolean]
	match * [boolean]
		Bool
end function

function Or Decs [repeat declaration] Indent [stringlit]
	replace [exp]
		'or Params [repeat simple]
		RestI [repeat infix_exp]

        deconstruct Params
		List [simple]
		Rest [repeat simple]

	construct Exp [exp]
		List

	construct NewExp [exp]
		Exp [resolveExpression Decs Indent]

        construct Bool [boolean]
                'True

        where 
                NewExp [hasBool Bool]

        construct Simple [simple]
                'True

        construct NewExp1 [exp1]
                Simple

        by
                NewExp1 RestI
end function


