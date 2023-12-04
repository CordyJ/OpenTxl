% Transform Turing program to an auto-tracing version of itself.
% (Test of the new generalized [quote] in TXL.)
% If this transform were to be completed, it would also indicate values 
% of assigned and passed variables and expressions in the trace.
% J.R. Cordy, 6.12.94

#pragma -esc '\\'

include "Turing.Grammar"

keys 
	DONE__
end keys

define declarationOrStatement
	[declaration]		[opt ';] [NL] 	
    |	[variableBinding]	[opt ';] [NL] 	
    |	[statement]		[opt ';] [NL] 	[attr 'DONE__]
end define

% external rule quote X [any]

function main
    replace [program]
	DandS [repeat declarationOrStatement]
    by
	DandS [addtracing]
end function

rule addtracing
    replace [repeat declarationOrStatement]
	S [statement] _ [opt ';]
	Rest [repeat declarationOrStatement]
    construct QuoteS [stringlit]
	_ [quote S]
    by
	put ">>> ", QuoteS 	DONE__
	S			DONE__
	Rest
end rule
