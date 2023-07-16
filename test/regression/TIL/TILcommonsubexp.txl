% TXL transformation to recognize and optimize commond subexpressions
% Jim Cordy, March 2007

% This program finds subexpressions that are used two or more times without
% intervening changes to the variables used in it, and introduces a new
% temporary variable to optimize it to a single computation.

% Based on the TIL base grammar
include "TIL.grm"

% Preserve comments, we're probably going to maintain the result
include "TILCommentOverrides.grm"

% Override grammar to abstract compound statements
redefine statement
	[compound_statement]
    |	...
end redefine

define compound_statement
	[if_statement]
    |	[while_statement]
    |	[for_statement]
end define

redefine statement 
	...
    |	[statement] [attr 'NEW]
end redefine

% Main function

function main
    replace [program]
        P [program]
    by
        P [optimizeSubexpressions]
end function

rule optimizeSubexpressions
    replace [statement*]
        S1 [statement]
	SS [statement*]
    deconstruct not * [attr 'NEW] S1
    	'NEW
    deconstruct * [expression] S1
    	E [expression]
    deconstruct * [op]  E
    	_ [op]
    deconstruct * [expression] SS
    	E
    where
    	SS [?replaceExpnCopies S1 E 'T]
    construct T [id]
    	_ [unquote "temp"] [!]
    construct NewS [statement*]
	'var T; 'NEW
	T := E; 'NEW
    	S1 [replaceExpn E T]
	SS [replaceExpnCopies S1 E T]
    by
	NewS 
end rule

function replaceExpnCopies S1 [statement] E [expression] T [id]
    construct Eids [id*]
        _ [^ E]
    where not
    	S1 [assigns each Eids]
    replace [statement*]
        S [statement]
	SS [statement*]
    where not all
    	S [assignsOne Eids]
	  [isCompoundStatement]
    by
        S [replaceExpn E T]
	SS [replaceExpnCopies S E T]
end function

function assignsOne Eids [id*]
    match [statement]
        S [statement]
    where 
	S [assigns each Eids]
end function

function isCompoundStatement
    match [statement]
        _ [compound_statement]
end function

rule replaceExpn E [expression] T [id]
    replace [expression]
    	E
    by
	T
end rule

function assigns Id [id]
    match * [statement]
        Id := _ [expression] ;
end function
