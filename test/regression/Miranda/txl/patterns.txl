% Russell Halliday
% CISC 499 - January - April, 1995

% This module contains the functions necessary to deal with some of the
% pattern-matching that Miranda uses in function evaluation.

function fixPattern Decs [repeat declaration] Indent [stringlit] F [formal] P [simple]
	replace [repeat simple]
		Simples [repeat simple]

	construct NewSimple [simple]
		P [fixAdditionPattern F Decs Indent]

	by
		Simples [. NewSimple]
end function

function fixAdditionPattern F [formal] Decs [repeat declaration] Indent [stringlit]
	deconstruct * [pat] F
		Pat2 [pat] '+ Num [number] 

	replace [simple]
		S [simple]

	construct NewSimple [simple]
		((S) - Num)

	construct NewExp [exp]
		NewSimple

	construct FinalExp [exp]	
		NewExp [resolveExpression Decs Indent]

	deconstruct FinalExp 
		FinalSimple [simple]

	by
		FinalSimple
end function

rule fixListPattern1 F [formal] P [simple]
	deconstruct F
		'( List [opt pat_list] ')

	deconstruct List
		Pat [pat]

	deconstruct Pat
		P1 [pat] : P2 [pat]

	replace * [simple]
		Id [id]

	where
		P1 [?contains Id]

	deconstruct P
		'[ ExpList [opt exp_list] ']

	deconstruct ExpList
		ListExps [list expression]

	construct RepList [repeat expression]
		_ [. each ListExps]

	deconstruct RepList
		First [expression]
		Rest [repeat expression]

	deconstruct * [simple] First
		Simple [simple]

	by
		Simple
end rule

rule fixListPattern2 F [formal] P [simple]
        deconstruct F
                '( List [opt pat_list] ')

        deconstruct List
                Pat [pat]

        deconstruct Pat
                P1 [pat] : P2 [pat]

        replace * [simple]
                Id [id]

        where
                P2 [?contains Id]

        deconstruct P
                '[ ExpList [opt exp_list] ']

        deconstruct ExpList
                ListExps [list expression]

        construct RepList [repeat expression]
                _ [. each ListExps]

        deconstruct RepList
                First [expression]
                Rest [repeat expression]

	construct NewList [list expression]
		_ [, each Rest]

	construct Simple [simple]
		'[ NewList ']

        by
                Simple
end rule
