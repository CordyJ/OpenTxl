% Loop expression lifting

% Based on Tplus basis grammar
include "Tplus.Grammar"


% Find and improve common subexpressions in loops

function main
    replace [program]
	C [compilation]
    by
	C [liftExpressions]
end function

rule liftExpressions
    replace [repeat declarationOrStatement]
	loop
	    Body [repeat declarationOrStatement]
	'end loop
	Rest [repeat declarationOrStatement]
    construct AllExpressions [repeat expn]
	_ [^ Body]
    construct LiftedLoop [repeat declarationOrStatement]
	loop
	    Body
	'end loop
    where
	LiftedLoop [?lift each AllExpressions]
    by
	LiftedLoop [lift each AllExpressions]
	[. Rest]
end rule

function lift Expression [expn]
    deconstruct * [binaryOperator] Expression
	_ [binaryOperator]
    replace [repeat declarationOrStatement]
	Scope [repeat declarationOrStatement]
    construct LE [id]
	'E
    construct LiftedExpnId [id]
	LE [!]
    construct LiftedExpn [expn]
	LiftedExpnId
    by
	const LiftedExpnId := Expression
	Scope [$ Expression LiftedExpn]
end function
