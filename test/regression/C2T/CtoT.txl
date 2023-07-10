% TXL 7.7a4
% Andy Maloney, Queen's University, January 1995
%       [part of 499 project]

include "C.grm"
include "myDeclarations.C"

% include "TxlExternals"
include "beforeAfter.ext"

include "decls_t.C"
include "statements_t.C"
include "functions_t.C"
include "expr_t.C"
include "optimize_t.C"


define program
%% C
%% Turing
        [repeat externaldefinition]     [NL]
end define

define externaldefinition
%% C
        [declaration]
  |
        [NL]
    [function_definition]       [NL]
%% Turing
  |
        [t_constDecl]
  |
        [t_typeDecl]
  |
        [t_varDecl]
end define

define compound_statement
        '{                                                      [IN][NL] 
                [repeat declaration] 
                [repeat statement]              [EX] 
        '} [opt ';]                                     [NL][KEEP]
  |
%% Turing
        'begin                                                  [IN][NL]
                [repeat externaldefinition]
                [repeat statement]                      [EX] 
        'end                                                    [NL]
end define


function main
        replace [program]
                RED [repeat externaldefinition]

        construct TuringProgram [repeat externaldefinition]
                _ [changeExternalDef each RED]
        
        construct newTuringProgram [repeat externaldefinition]
                TuringProgram [moveMain] [stripMainFunctionHeader]
        
        by
                newTuringProgram [optimizeTuring]
end function


function changeExternalDef ED [externaldefinition]
        replace [repeat externaldefinition]
                SoFar [repeat externaldefinition]
                
        construct newED [externaldefinition]
                ED
                        [translateCConst]
                        [translateCType]
                        [translateCVar]
                        [translateCFunction]
        
        by
                SoFar [. newED]
end function


%% move the 'main' function to the end of the function block
function moveMain
        replace * [repeat externaldefinition]
                'function 'main ': TS [type_specifier]
                        D [repeat externaldefinition]
                        S [repeat statement]
                'end 'main
                Rest [repeat externaldefinition]
        
        construct newMain [externaldefinition]
                'function 'main ': TS
                        D
                        S
                'end 'main

        by
                Rest [. newMain]
end function

%% remove the function header from the main function
function stripMainFunctionHeader
        replace * [externaldefinition]
                'function 'main ': TS [type_specifier]
                        D [repeat externaldefinition]
                        S [repeat statement]
                'end 'main
        
        by
                '%main_function
                        D
                        S
end function
