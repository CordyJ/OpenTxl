%token VAR
%token INT
%token CHAR
%token ','
%token ';'
%token ':'
%token '.'
%%

program 
        : decl_seq stmt_seq '.'
        | stmt_seq '.'

decl_seq
        : decl
        | decl_seq decl

expr
        : simple_expr
        | expr binaryop simple_expr

arg_list    
        : expr
        | arg_list ',' expr

var_decl
        : VAR idlist ':' type ';'

type 
     : INT  
     | CHAR
