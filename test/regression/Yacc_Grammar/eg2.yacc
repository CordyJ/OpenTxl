%{

/* sl.bnf   contains the yacc parser description for SL */

#include "parse.c"

/* explanation of how the the parsing works is given in parse.c */

%}

%token Identifier
%token Integer
%token Character
%token Binary_opsym
%token Amb_opsym
%token Unary_opsym
%token FUNCTION
%token ASSIGNSYM
%token IF	
%token THEN
%token ELSE
%token ENDIF
%token DO
%token WHILE
%token ENDWHILE
%token PUT
%token GET
%token VAR
%token INT
%token CHAR
%token '('
%token ')'
%token '['
%token ']'
%token ','
%token '{'
%token '}'
%token '-'
%token ';'
%token '+'
%token '<'
%token '>'
%token '='
%token '*'
%token '/'
%token ':'
%token '.'
%%

program 
 	: decl_seq stmt_seq '.'
		{ ($$).Ptree = ($2).Ptree; 
		  pushptptr(($$).Ptree); }
 	| stmt_seq '.'
		{ ($$).Ptree = ($1).Ptree; 
		  pushptptr(($$).Ptree); }

decl_seq
	: decl
		{($$).Ptree = ($1).Ptree;}
	| decl_seq decl
		{ ($$).Ptree = ($1).Ptree; }

decl
	: fn_defn 
		{($$).Ptree = ($1).Ptree;}
	| var_decl 
		{($$).Ptree = ($1).Ptree;}


stmt
	: assign_stmt ';'
		{($$).Ptree = ($1).Ptree;}
	| if_stmt ';'
		{($$).Ptree = ($1).Ptree;}
	| while_stmt ';'
		{($$).Ptree = ($1).Ptree;}
     | io_stmt ';'
		{($$).Ptree = ($1).Ptree;}

expr
	: simple_expr
		{($$).Ptree = ($1).Ptree;}
	| expr binaryop simple_expr
		{ ($$).Ptree = b_binaryopcall(($1).Ptree,($2).Ptree,($3).Ptree); }

binaryop
	: Binary_opsym
		{ ($$).Ptree = b_op(($1).Pstval); }
	| Amb_opsym
		{ ($$).Ptree = b_op(($1).Pstval); }

simple_expr
	: primary_expr
		{($$).Ptree = ($1).Ptree;}
	| unaryop simple_expr
		{ ($$).Ptree = b_unaryopcall(($1).Ptree,($2).Ptree); }
	| fctn_arg_hdr rest_fctn_arg
		{ ($$).Ptree = b_fncall(($1).Pintval,($2).Ptree); }

unaryop
	: Unary_opsym
		{ ($$).Ptree = b_op(($1).Pstval); }
	| Amb_opsym
		{ ($$).Ptree = b_op(($1).Pstval); }

fctn_arg_hdr
	: Identifier '(' 
		{ ($$).Pintval = check_fnname(($1).Pstval); argcnt = 0; }

rest_fctn_arg
	: arg_list ')'
		{ ($$).Ptree = b_arglist(argcnt); }

arg_list    
	: expr
		{ pushptptr(($1).Ptree); argcnt++;}
	| arg_list ',' expr
		{ pushptptr(($3).Ptree); argcnt++;}

primary_expr
	: constant
		{ ($$).Ptree = ($1).Ptree; }
	| Identifier
		{ ($$).Ptree = b_variableuse(($1).Pstval); }
	| '(' expr ')'
		{ ($$).Ptree = ($2).Ptree; }

constant
	: Integer
		{ ($$).Ptree = b_constant(inttype, ($1).Pstval); }
	| Character
		{ ($$).Ptree = b_constant(chartype, ($1).Pstval); }

stmt_seq  
	: stmt 
		{ ($$).Ptree = ($1).Ptree;}
	| stmt_seq stmt 
		{ ($$).Ptree = b_stmtseq(($1).Ptree,($2).Ptree); }

assign_stmt
	: Identifier ASSIGNSYM expr 
		{ ($$).Ptree = b_assignstmt(($1).Pstval,($3).Ptree); }

if_stmt
	: IF expr THEN stmt_seq ENDIF
		{ ($$).Ptree = b_ifstmt(($2).Ptree,($4).Ptree,pNulltree);}
	| IF expr THEN stmt_seq ELSE stmt_seq ENDIF
		{ ($$).Ptree = b_ifstmt(($2).Ptree,($4).Ptree,($6).Ptree);}

while_stmt
	: WHILE expr DO stmt_seq ENDWHILE
		{($$).Ptree = b_whilestmt(($2).Ptree,($4).Ptree);}

io_stmt
	: PUT expr 
		{($$).Ptree = b_putstmt(($2).Ptree);}
	| GET Identifier 
		{($$).Ptree = b_getstmt(($2).Pstval);}


fn_defn_name
	: type FUNCTION Identifier 
		{ ($$).Pintval = process_fnname(($1).Pintval,($3).Pstval); 
		  localcnt = 0; }

fn_defn_header
	: fn_defn_name '(' parameter_list ')'
		{ ($$).Pintval =  process_paramlist(($1).Pintval,($3).Ptree); }

parameter_list
	: parameter
		{ ($$).Ptree = b_list(pNulltree,($1).Ptree); }
	| parameter_list ',' parameter
		{ ($$).Ptree = b_list(($1).Ptree,($3).Ptree); }

parameter
	: Identifier ':' type
		{ ($$).Ptree = b_parameter(($1).Pstval,($3).Pintval); }

fn_defn
	: fn_defn_header body ';'
		{ process_fndefn(($1).Pintval,($2).Ptree,localcnt); 
		 ($$).Ptree = pNulltree; }

body_begin
	: '{'
		{ ($$).Ptree = pNulltree; }
	| '{' var_decl_seq
		{ ($$).Ptree = pNulltree; }
	
body
	:   body_begin stmt_seq expr '}'
		{ ($$).Ptree = b_fnbody(($2).Ptree,($3).Ptree); }

var_decl_seq 
	: var_decl      
		{ ($$).Ptree = pNulltree; }
	| var_decl_seq var_decl
		{ ($$).Ptree = pNulltree; }

var_decl
	: VAR idlist ':' type ';'
		{ process_var_decl(($2).Ptree,($4).Pintval); }

idlist    
	: Identifier
		{ ($$).Ptree = b_idlist(pNulltree,($1).Pstval); localcnt++; }
	| idlist ',' Identifier
		{ ($$).Ptree = b_idlist(($1).Ptree,($3).Pstval); localcnt++; }

type 
     : INT  
		{ ($$).Pintval = inttype; }
     | CHAR
		{ ($$).Pintval = chartype; }


