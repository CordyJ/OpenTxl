% TXL 7.7a4
% Andy Maloney, Queen's University, January 1995
%	[part of 499 project]


include "Pascal.grm"

% include "TxlExternals"

include "decls_t.P"
include "statements_t.P"
include "functions_t.P"
include "optimize_t.P"


define program
%% Pascal
	[empty]		%% to avoid the left-recursion 'feature'
	'program [id] '( [list id] ') ';	[NL][IN]
	[repeat p_declaration]				[NL]
	[repeat p_subprogramDeclaration]	[EX]
	'begin						[NL][IN]
		[repeat p_statement]		[EX]
	'end '.		
  |
%% Turing
	[repeat p_declaration]				[NL]
	[repeat p_subprogramDeclaration]	[NL]
	[repeat p_statement]				[NL]
end define

define p_declaration
%% Pascal
	[p_constDeclaration]	
  |
	[p_typeDeclaration]     	
  |
	[p_variableDeclaration]  	
  |
	[p_labelDeclaration]     	
%% Turing
  |
	[repeat t_constDecl]
  |
	[repeat t_typeDecl]     	
  |
	[repeat t_varDecl]   	
end define

define p_subprogramDeclaration
%% Pascal
	[p_procedureDeclaration]
  |
	[p_functionDeclaration]
%% Turing
  |
	[t_procedureDeclaration]	[NL]
  |
	[t_functionDeclaration]		[NL]
end define

define p_statement
%% Pascal
   	[opt p_statementLabel] [p_unlabeledStatement]	[NL]
%% Turing
  |
	'result [p_expression]	[NL]
end define

define p_beginEnd
	'begin						[NL][IN]
	    [repeat p_statement]	[EX][NL]
	'end          
end define 


function main
	replace [program]
		'program N[id] '( LID[list id] ') ';
		PascalDecls [repeat p_declaration]
		PascalFunctions[repeat p_subprogramDeclaration]
		'begin
			S [repeat p_statement]
		'end '.		

	construct TuringDeclBlock [repeat p_declaration]
		_ [translatePascalDeclarations each PascalDecls]

	construct TuringFunctionBlock [repeat p_subprogramDeclaration]
		_ [translatePascalFunctions each PascalFunctions]

	construct TuringStatements [repeat p_statement]
		_ [translatePascalStatements each S]

	construct newTuringProgram [program]
		TuringDeclBlock
		TuringFunctionBlock
		TuringStatements

	by
		newTuringProgram [optimizeTuring]
end function
