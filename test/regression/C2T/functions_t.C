% TXL 7.7a4
% Andy Maloney, Queen's University, January 1995
%       [part of 499 project]


%% change a [repeat declaration] to a [repeat externaldefinition]
function makeExternalDef D [declaration]
        replace [repeat externaldefinition]
                SoFar [repeat externaldefinition]
                
        construct newExternalDef [externaldefinition]
                D
                
        by
                SoFar [. newExternalDef]
end function

rule changeCompound
        replace [compound_statement]
                '{
                        D [repeat declaration] 
                        S [repeat statement]
                '} OS [opt ';]

        construct RED [repeat externaldefinition]
                _ [makeExternalDef each D]

        construct TuringDecls [repeat externaldefinition]
                _ [changeExternalDef each RED]
                
        construct TuringStatements [repeat statement]
                _ [translateCStatements each S]
                
        by
                'begin
                        TuringDecls
                        TuringStatements 
                'end
end rule

%% change a C arg list to a Turing arg list
function translateArg AD [argument_declaration]
        deconstruct AD
                T [type_specifier] DI [decl_identifier] OAP [opt array_part] 
                        OI [opt initialisation]

        replace [list argument_declaration]
                SoFar [list argument_declaration]
        
        construct TuringArg [argument_declaration]
                DI ': T
        
        construct newTuringArg [argument_declaration]
                TuringArg
                                [changeOptArrayPart OAP]
                                [changeCharToString]
                                [changeLongToInt]
                                [changeFloatToReal]
                                [changeDoubleToReal]
        
        by
                SoFar [, newTuringArg]  
end function

%% change to array [if there is an 'opt array_part']
function changeOptArrayPart OAP [opt array_part]
        deconstruct OAP
                '[ N [number] ']
                
        replace [argument_declaration]
                DI [decl_identifier] ': T [type_specifier]
        
        construct newN [number]
                N [- 1]
        
        construct TuringArraySpec [type_specifier]
                'array 0 .. newN 'of T
        
        construct newTuringArraySpec [type_specifier]
                TuringArraySpec [changeToStrings]
                
        by
                DI ': newTuringArraySpec
end function


%% *****
%% functions
%%

define function_definition
%% C
        [opt decl_specifiers] [declarator] 
            [compound_statement]
  |
%% Turing
        'function [identifier] [opt t_paramDecl] ': [type_specifier]    [NL][IN]
                [repeat externaldefinition]     [NL]
                [repeat statement]                      [EX] 
        'end [identifier]                               [NL]
  |
        '%main_function                         [NL]            %%% this puts in a Turing comment
        [repeat externaldefinition]     [NL]
        [repeat statement]                      [NL] 
  |
        'procedure [identifier] [opt t_paramDecl]               [NL][IN]
        [repeat externaldefinition]     [NL]
                [repeat statement]                      [EX] 
        'end [identifier]                               [NL]
end define
        
define t_paramDecl
        '( [list argument_declaration] ')
end define

define argument_declaration
        [type_specifier] [decl_id_part]
  |
        [decl_identifier] ': [type_specifier]
end define


function translateCFunction
        replace [externaldefinition]
                F [function_definition]
                
        construct newTuringFunction [externaldefinition]
                F
                        [translateProcedure]            %% must be done before functions
                        [translateFunction]
                
        by
                newTuringFunction
end function


%% *****
%% functions
%%

function translateFunction
        replace [function_definition]
                TS [type_specifier] N [identifier] '( AD [list argument_declaration] ')
                CS [compound_statement]

        construct TuringArgs [list argument_declaration]
                _ [translateArg each AD]
        
        construct ArgPart [t_paramDecl]
                '( TuringArgs ')
        
        construct newFunc [function_definition]
                'function N ArgPart ': TS
                        CS [changeCompound]
                'end N
                
        by
                newFunc [removeBeginEndFromFunc] [removeEmptyArgsFromFunc]
end function

%% because the function 'translateFunctions' uses the more general 'changeCompound',
%% we must now remove the 'begin' and 'end from the function
function removeBeginEndFromFunc
        replace [function_definition]
                'function N [identifier] OA [opt t_paramDecl] ': TS [type_specifier]
                'begin
                        D [repeat externaldefinition]
                        S [repeat statement]
                'end
                'end N

        construct newType [type_specifier]
                TS
                                [changeCharToString]
                                [changeLongToInt]
                                [changeFloatToReal]
                                [changeDoubleToReal]

        by
                'function N OA ': newType
                        D
                        S
                'end N
end function

%% if the function has no arguments, remove the parens
function removeEmptyArgsFromFunc
        replace [function_definition]
                'function N [identifier] '( ') ': TS [type_specifier] 
                        D [repeat externaldefinition]
                        S [repeat statement]
                'end N
                
        by
                'function N ': TS
                        D
                        S
                'end N
end function


%% *****
%% procedures
%%

function translateProcedure
        replace [function_definition]
                'void N [identifier] '( AD [list argument_declaration] ')
                CS [compound_statement]
        
        construct TuringArgs [list argument_declaration]
                _ [translateArg each AD]
        
        construct ArgPart [t_paramDecl]
                '( TuringArgs ')
                
        construct newProc [function_definition]
                'procedure N ArgPart
                        CS [changeCompound]
                'end N
                
        by
                newProc [removeBeginEndFromProc] [removeEmptyArgsFromProc]
end function

%% because the function 'translateProcedures' uses the more general 'changeCompound',
%% we must now remove the 'begin' and 'end from the procedure
function removeBeginEndFromProc
        replace [function_definition]
                'procedure N [identifier] OA [opt t_paramDecl]
                'begin
                        D [repeat externaldefinition]
                        S [repeat statement]
                'end
                'end N
                
        by
                'procedure N OA
                        D
                        S
                'end N
end function

%% if the procedure has no arguments, remove the parens
function removeEmptyArgsFromProc
        replace [function_definition]
                'procedure N [identifier] '( ')
                        D [repeat externaldefinition]
                        S [repeat statement]
                'end N
                
        by
                'procedure N
                        D
                        S
                'end N
end function
