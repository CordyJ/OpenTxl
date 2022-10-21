% count the statements in a C++ program
% copyright 1993 J.R. Cordy

include "CppCount.grm"

% external function length RA [any]
% external function print
% external function unquote S [stringlit]

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

function main
    replace [program]
	P [program]

    construct PPs [repeat preprocessor]
	_ [^ P]
    construct NPPs [number]
	_ [length PPs]     [nl]	[printf '"Preprocessor directives  "] [nl]

    construct Decls [repeat declaration]
	_ [^ P]
    construct NDecls [number]
	_ [length Decls] 	[printf '"Declarations  "]

    construct Fcts [repeat fct_definition]
	_ [^ P]
    construct NFcts [number]
	_ [length Fcts] 	[printf '"    function declarations  "] [nl]

    construct Stmts [repeat statement]
	_ [^ P]
    construct NStmts [number]
	_ [length Stmts] 	[printf '"Statements    "]

    construct DeclStmts [repeat declaration_statement]
	_ [^ P] 
    construct NDeclStmts [number]
	_ [length DeclStmts] 	[printf '"    declaration statements "]

    construct ExpnStmts [repeat expression_statement]
	_ [^ P]
    construct NExpnStmts [number]
	_ [length ExpnStmts] 	[printf '"    expression statements  "] 

    construct ExtractMoreFacts [program]
	P [extractmorefacts]

    by
	% nada
end function

function extractmorefacts
    match [program]
	P [program]

    construct Selections [repeat selection_statement]
	_ [^ P]
    construct NSelections [number]
	_ [length Selections] 	[printf '"    selection statements   "] 

    construct Iterations [repeat iteration_statement]
	_ [^ P]
    construct NIterations [number]
	_ [length Iterations] 	[printf '"    iteration statements   "] 

    construct Compounds [repeat compound_statement]
	_ [^ P]
    construct NCompounds [number]
	_ [length Compounds]  	[printf '"    compound statements    "] 

    construct Jumps [repeat jump_statement]
	_ [^ P]
    construct NJumps [number]
	_ [length Jumps]      	[printf '"    jump statements        "] 

    construct Nulls [repeat null_statement]
	_ [^ P]
    construct NNulls [number]
	_ [length Nulls]      	[printf '"    null statements        "] 

%% Not really important, I guess - JRC
%%    construct Labels [repeat label]
%%	_ [^ P]
%%    construct NLabels [number]
%%	_ [length Labels] [printf '"Labeled statements  "] 
end function
