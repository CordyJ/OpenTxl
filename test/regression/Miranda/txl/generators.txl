% Russell Halliday
% Generators.Txl
% CISC 499 - Janurary - April, 1995

% This module contains the code to evaluate expressions containing list
% comperehensions (generators) in Miranda.


function evaluateGenerators Decs [repeat declaration] Indent [stringlit]
	replace [exp]
		'[ Expn [expression] '| Qualifs [qualifs] ']

	construct NewExpressions [repeat expression]
		_ [checkBaseCase1 Expn Qualifs Decs Indent]
		  [checkBaseCase2 Expn Qualifs Decs Indent]
		  [checkGeneralCase Expn Qualifs Decs Indent]

	construct ListExpn [list expression]
		_ [, each NewExpressions]

	by
		'[ ListExpn ']
end function

function checkBaseCase1 Expn [expression] Qualifs [qualifs] Decs [repeat declaration] Indent [stringlit]
	deconstruct Qualifs
		Qualifier [qualifier] Rest [repeat semiQualifier]

	deconstruct Rest
		E [empty]

        deconstruct Qualifier
                Generator [generator]

	replace [repeat expression]
		OldExpns [repeat expression]

	deconstruct Generator
		PatList [pat_list] <- GenExpn [expression]

	deconstruct * [exp] GenExpn
		GenExp [exp]

	construct NewExp [exp]
		GenExp [resolveExpression Decs Indent]
		
	deconstruct * [simple] NewExp
		'[ EList [opt exp_list] ']

	construct Items [repeat simple]
		_ [getItems EList]

	deconstruct * [id] PatList
		Id [id]

	construct NewList [repeat expression]
		_ [buildNewList Expn Id Decs Indent each Items]

	by
		NewList
end function

function checkBaseCase2 OldExpn [expression] Qualifs [qualifs] Decs [repeat declaration] Indent [stringlit]
	deconstruct Qualifs
                Qualifier [qualifier] Rest [repeat semiQualifier]

        deconstruct Rest
                E [empty]

        deconstruct Qualifier
		Expn [expression]

        replace [repeat expression]
                ExpnList [repeat expression]

        deconstruct Expn
                Exp [exp]

        construct BoolExp [exp]
                Exp [resolveExpression Decs Indent]

        deconstruct * [boolean] BoolExp
                TrueOrFalse [boolean]

        construct Truth [boolean]
                'True

        where
                TrueOrFalse [= Truth]

        by
                ExpnList [. OldExpn]
end function

function getItems EList [opt exp_list]
	deconstruct * [list expression] EList
		ListExp [list expression]

	replace [repeat simple]
		Simples [repeat simple]

	construct NewSimples [repeat simple]
		_ [changeEach each ListExp]

	by
		NewSimples
end function

function changeEach Exp [expression]
	replace [repeat simple]
		Simples [repeat simple]

	deconstruct * [simple] Exp
		S [simple]

	by
		Simples [. S]
end function

function buildNewList Expn [expression] Id [id] Decs [repeat declaration] Indent [stringlit] Simple [simple]
	replace [repeat expression]
		Expressions [repeat expression]

	deconstruct Expn
		Exp [exp]

	construct NewSimple [simple]
		Id

	construct NewExp [exp]
		Exp [$ NewSimple Simple]

	construct FinalExpression [expression]
		NewExp

	by
		Expressions [. FinalExpression]
end function

function checkGeneralCase Expn [expression] Qualifs [qualifs] Decs [repeat declaration] Indent [stringlit]
        deconstruct Qualifs
                Qualifier [qualifier] Rest [repeat semiQualifier]

	deconstruct Rest
		FirstSemi [semiQualifier]
		RestSemis [repeat semiQualifier]

        replace [repeat expression]
                OldExpns [repeat expression]

	deconstruct Qualifier
		Generator [generator]

        deconstruct Generator
                PatList [pat_list] <- GenExpn [expression]

        deconstruct * [exp] GenExpn
                GenExp [exp]

        construct NewExp [exp]
                GenExp [resolveExpression Decs Indent]

        deconstruct * [simple] NewExp
                '[ EList [opt exp_list] ']

        construct Items [repeat simple]
                _ [getItems EList]

        deconstruct * [id] PatList
                Id [id]

        construct NewList [repeat expression]
                _ [buildGeneralList Expn Id Decs Indent Rest each Items]

        by
		NewList
end function

function buildGeneralList Expn [expression] Id [id] Decs [repeat declaration] Indent [stringlit] SemiQualifs [repeat semiQualifier] Item [simple]
	replace [repeat expression]
		Expressions [repeat expression]

        construct Simple [simple]
                Id

	construct NewSemiQualifs [repeat semiQualifier]
		SemiQualifs [$ Simple Item]

	construct NewRepeatExpn [repeat expression]
		_ [stepThroughGenerators Expn Id Decs Indent Item NewSemiQualifs]

	by
		Expressions [. NewRepeatExpn]
end function

function stepThroughGenerators Expn [expression] Id [id] Decs [repeat declaration] Indent [stringlit] Item [simple] SemiQualifs [repeat semiQualifier]
	replace [repeat expression]
		Expressions [repeat expression]

	construct NewExpns [repeat expression]
		_ [qualifierIsExpression Expn SemiQualifs Indent Decs Id Item]
		  [qualifierIsGenerator Expn SemiQualifs Indent Decs Id Item]

	by
		Expressions [. NewExpns]
end function

function qualifierIsExpression OldExpn [expression] Qualifiers [repeat semiQualifier] Indent [stringlit] Decs [repeat declaration] Id [id] Item [simple]
	deconstruct Qualifiers
		'; Qualifier [qualifier]
		Rest [repeat semiQualifier]

	deconstruct Qualifier
		Expn [expression]

	replace [repeat expression]
		ExpnList [repeat expression]

	deconstruct Expn
		Exp [exp]

	construct BoolExp [exp]
		Exp [resolveExpression Decs Indent]

	deconstruct * [boolean] BoolExp
		TrueOrFalse [boolean]

	construct Truth [boolean]
		'True

	where
		TrueOrFalse [= Truth]

	construct NewSimple [simple]
		Id

	construct NewExpn [expression]
		OldExpn [$ NewSimple Item]

	construct NewQualifs [qualifs]
		_ [buildNewQualifsFrom Rest]

	construct NewList [repeat expression]
		_ [checkEmptyRest NewExpn NewQualifs]
		  [checkBaseCase1 NewExpn NewQualifs Decs Indent]
		  [checkBaseCase2 NewExpn NewQualifs Decs Indent]
		  [checkGeneralCase NewExpn NewQualifs Decs Indent]

	by
		ExpnList [. NewList]
end function

function buildNewQualifsFrom Qualifs [repeat semiQualifier]
	deconstruct Qualifs
		'; First [qualifier]
		Rest [semiQualifier]

	replace [qualifs]
		OlQualifs [qualifs]

	by
		First Rest
end function

function checkEmptyRest Expn [expression] NewQualifs [qualifs]
	deconstruct NewQualifs
		E [empty]

	replace [repeat expression]
		List [repeat expression]

	by
		List [. Expn]
end function

function qualifierIsGenerator OldExpn [expression] Qualifiers [repeat semiQualifier] Indent [stringlit] Decs [repeat declaration] Id [id] Item [simple]
        deconstruct Qualifiers
                '; Qualifier [qualifier]
		Rest [repeat semiQualifier]

	deconstruct Qualifier
		Generator [generator]

        replace [repeat expression]
                ExpnList [repeat expression]

	construct NewSimple [simple]
		Id

	construct NewExpn [expression]
		OldExpn [$ NewSimple Item]

	construct NewQualifs [qualifs]
		Qualifier
		Rest 

        construct NewList [repeat expression]
                _ [checkBaseCase1 NewExpn NewQualifs Decs Indent]
                  [checkBaseCase2 NewExpn NewQualifs Decs Indent]
                  [checkGeneralCase NewExpn NewQualifs Decs Indent]

        by
                ExpnList [. NewList]
end function
