% Count the kinds of statements in an ANSI or K-R C program
% Copyright 1993 by J.R. Cordy

include "ANSIC.Grammar"

% Slight modifications to C grammar to assist in counting

% Avoid copying whole function bodies when counting
% (This would all be trivial if we had attributes in TXL!)
define function_definition
	[opt functionmark] [opt decl_specifiers] [declarator]
	    [opt NL_declarations] 			% old style functions
	    [compound_statement]
end define

define functionmark
    	'MARK
end define

% Avoid copying whole declarations
define declaration
    	[opt declarationmark] [linkage_specification]
    |	[opt declarationmark] [struct_or_union_definition]
    |	[opt declarationmark] [decl_specifiers] [opt declarator_list] ;	[NL]	
end define

define declarationmark 
	'MARK
end define

% Avoid copying whole statements
define statement
        [opt statementmark] [opt compoundmark] [repeat label] [compound_statement]
    |	[opt statementmark] [opt expressionmark] [repeat label] [expression_statement]	
    |	[opt statementmark] [opt selectionmark] [repeat label] [selection_statement]	
    |	[opt statementmark] [opt iterationmark] [repeat label] [iteration_statement]	
    |	[opt statementmark] [repeat label] [jump_statement]	
    |	[opt statementmark] [repeat label] [null_statement]	
end define

define statementmark 
	'MARK
end define

define compoundmark 
	'MARK
end define

define expressionmark 
	'MARK
end define

define selectionmark 
	'MARK
end define

define iterationmark 
	'MARK
end define


% External and helper functions 

function count A [any]
    replace [number]
	N [number]
    by
	N [+1]
end function

% % external function print
% % external function unquote S [stringlit]

define id_or_number
	[id] | [number]
end define

function printf S [stringlit] 
    match [number]
	N [number]
    construct IdS [id]
	_ [unquote S]
    construct Output [repeat id_or_number]
	IdS N
    construct Print [repeat id_or_number]
	Output [print]
end function

function nl
    match [number]
	N [number]
    construct Nothing [repeat id]
	% empty
    construct Print [repeat id]
	Nothing [print]
end function


% Function that does the work
% We use the extract built-in function to count by grammatical nonterminal 

function main
    replace [program]
	UnmarkedP [program]

    construct P [program]
	UnmarkedP [markup]

    construct PPs [repeat preprocessor]
	_ [^ P]
    construct NPPs [number]
	_ [count each PPs]     [nl]	[printf '"Preprocessor directives  "] [nl]

    construct Decls [repeat declarationmark]
	_ [^ P] 
    construct NDecls [number]
	_ [count each Decls] 	[printf '"Declarations  "] [nl]

    construct Fcts [repeat functionmark]
	_ [^ P]
    construct NFcts [number]
	_ [count each Fcts] 	[printf '"Function definitions  "] [nl]

    construct Stmts [repeat statementmark]
	_ [^ P]
    construct NStmts [number]
	_ [count each Stmts] 	[printf '"Statements    "]

    construct ExtractMoreFacts [program]
	P [extractmorefacts]

    by
	% nada
end function

function extractmorefacts
    match [program]
	P [program]

    construct ExpnStmts [repeat expressionmark]
	_ [^ P]
    construct NExpnStmts [number]
	_ [count each ExpnStmts] 	[printf '"    expression statements  "] 

    construct Selections [repeat selectionmark]
	_ [^ P]
    construct NSelections [number]
	_ [count each Selections] 	[printf '"    selection statements   "] 

    construct Iterations [repeat iterationmark]
	_ [^ P]
    construct NIterations [number]
	_ [count each Iterations] 	[printf '"    iteration statements   "] 

    construct Compounds [repeat compoundmark]
	_ [^ P]
    construct NCompounds [number]
	_ [count each Compounds]  	[printf '"    compound statements    "] 

    construct ExtractEvenMoreFacts [program]
	P [extractevenmorefacts]
end function

function extractevenmorefacts
    match [program]
	P [program]

    construct Jumps [repeat jump_statement]
	_ [^ P]
    construct NJumps [number]
	_ [count each Jumps]      	[printf '"    jump statements        "] 

    construct Nulls [repeat null_statement]
	_ [^ P]
    construct NNulls [number]
	_ [count each Nulls]      	[printf '"    null statements        "] 
end function

function markup
    construct NFM [opt functionmark]
	% nada
    construct FM [opt functionmark]
	'MARK
    construct NDM [opt declarationmark]
	% nada
    construct DM [opt declarationmark]
	'MARK
    construct NSM [opt statementmark]
	% nada
    construct SM [opt statementmark]
	'MARK
    construct NCM [opt compoundmark]
	% nada
    construct CM [opt compoundmark]
	'MARK
    construct NEM [opt expressionmark]
	% nada
    construct EM [opt expressionmark]
	'MARK
    construct NSeM [opt selectionmark]
	% nada
    construct SeM [opt selectionmark]
	'MARK
    construct NIM [opt iterationmark]
	% nada
    construct IM [opt iterationmark]
	'MARK
    replace [program]
	P [program]
    by
	P [$ NFM FM]
	  [$ NDM DM]
	  [$ NSM SM]
	  [$ NCM CM]
	  [$ NEM EM]
	  [$ NSeM SeM]
	  [$ NIM IM]
end function
