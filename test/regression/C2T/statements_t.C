% TXL 7.7a4
% Andy Maloney, Queen's University, January 1995
%       [part of 499 project]



%% *****
%% statements

function translateCStatements CStatement [statement]                    
        replace [repeat statement]
                SoFar [repeat statement]
        
        construct newTuringStatement [statement]
                CStatement
                        [changeCStatement]
                        
        by
                SoFar [. newTuringStatement]
end function

function changeCStatement
        replace [statement]
                S [statement]
        
        construct newS [statement]
                S
                        [changeExprStatement]
                        
                        [changeIfStatement]
                        
                %% Loop statements
                        [changeDoWhileStatement]
                        [changeWhileStatement]
                        [changeForStatement]
                        
                %% Jump statements
                        [changeReturnStatement]
                        [changeBreakStatement]
                
        where not
                newS [= S]
                
        by
                newS
end function                    

function removeBrackets
        replace [repeat statement]
                '{
                        RS [repeat statement]
                '}
        
        by
                RS
end function



%% *****
%% expression statements

define expression_statement
%% C
        [expression] ';                 [NL]
  |
%% Turing
        %% expression with semicolon removed
        [expression]                    [NL]
  |
        %% simple printf
        'put [stringlit] [opt '..]              [NL]
  |
        %% complex printf
        'put [list putArg] [opt '..]    [NL]
  |
        %% simple scanf
        'get [list assignment_expression]               [NL]
  |
        %% copy string
        [stringlit] ':= [stringlit]             [NL]
  |
        %% concat string [where second arg of strcat is a literal]
        [identifier] ':= [identifier] '+ [stringlit]            [NL]
  |
        %% concat string [where second arg of strcat is another identifier]
        [identifier] ':= [identifier] '+ [identifier]           [NL]
end define

define putArg
        [stringlit]
  |
        [assignment_expression]
end define

rule changeExprStatement
        replace [statement]
                ES [expression_statement] 
                
        construct newES [expression_statement]
                ES
                        [removeSemiColon]
                        [removeAmpersand]
                                                
                        [changeAssignment]
                        
                        [changeBasicPrintf]
                        [changeComplexPrintf]
                        [changeBasicScanf]
                        
                        [changeStrCopy]
                        [changeStrCat]
                        
                        [changePrePlusPlus]
                        [changePostPlusPlus]
                        [changePreMinusMinus]
                        [changePostMinusMinus]
                        
                        [changeArrayBrackets]           %% changeArrayBrackets defined in expr_t.C
        
        where not
                newES [= ES]
                
        by
                newES 
end rule

function removeSemiColon
        replace [expression_statement]
                E [expression] ';
                
        by
                E [changeExpression]
end function

function removeAmpersand
        replace * [cast_expression]
                '& CE [cast_expression]
                
        by
                CE
end function


%% *****
%% assignment statements

define assignment_expression
%% C
        [conditional_expression]
  |
        [unary_expression] [assignment_operator] [assignment_expression]
%% Turing
  |
        [cast_expression] ':= [expression]
end define


function changeAssignment
        replace [expression_statement]
                CE1 [cast_expression] '= CE2 [cast_expression] RBO [repeat binary_operation]


        by
                CE1 ':= CE2 RBO
end function



%% *****
%% printf statements

function changeBasicPrintf
        replace [expression_statement]
                'printf '( SL[stringlit] ')
                
        by
                'put SL '..
end function

function changeComplexPrintf
        replace [expression_statement]
                'printf '( LE [list assignment_expression+] ')
        
        construct repeatExpr [repeat assignment_expression]
                _ [. each LE]
                
        deconstruct repeatExpr
                SL [stringlit] Rest [repeat assignment_expression]

        construct newArgList [list putArg]
                _ [translatePutArgs SL Rest]                    
        
        construct putStatement [expression_statement]
                'put newArgList [removeEmptyArg] '..
                
        by
                putStatement [removeOptDotDot]
end function

function translatePutArgs SL [stringlit] RAE [repeat assignment_expression]                     
        replace [list putArg]
                SoFar [list putArg]
                
        construct beforePercent [stringlit]             % get everything before the next percent
                SL [before "%"] [replaceEmpty SL RAE]
                
        construct newSL [putArg]
                beforePercent

        where not                                                               % terminating condition
                beforePercent [?replaceEmpty SL RAE]
                
        construct afterPercent [stringlit]              % get everything after the percent sign
                SL [after "%"]

        construct strLength [number]                    % calculate length of string after percent sign
                _ [# afterPercent]

        construct restSL [stringlit]                    % skip the next character
                afterPercent [: 2 strLength]            % this implies we have no :x:y etc.
        
        construct RestAE [repeat assignment_expression]
                _ [getRest RAE]
                
        construct recurse [list putArg]
                _ [translatePutArgs restSL RestAE]
                                
        by
                SoFar [, newSL] [addAE RAE] [, recurse]
end function

%% we only want to replace the "" if there are no assignment expr left
function replaceEmpty restSL [stringlit] RAE [repeat assignment_expression]
        replace [stringlit]
                SL [stringlit]
        
        where not
                RAE [?notEmpty]

        where
                SL [= ""]
                
        by
                restSL
end function

function notEmpty
        replace [repeat assignment_expression]
                RAE [repeat assignment_expression]
        
        deconstruct RAE
                AE [assignment_expression] RestAE [repeat assignment_expression]

        by
                RAE
end function
                
function addAE RAE [repeat assignment_expression]
        deconstruct RAE
                AE [assignment_expression] RestAE [repeat assignment_expression]

        replace [list putArg]
                LPA [list putArg]
                
        construct newPA [putArg]
                AE
                
        by
                LPA [, newPA]
end function

function getRest RAE [repeat assignment_expression]
        replace [repeat assignment_expression]
                Rest [repeat assignment_expression]
        
        deconstruct RAE
                AE [assignment_expression] RestAE [repeat assignment_expression]
                                        
        by
                RestAE
end function

function removeEmptyArg
        replace * [list_1_putArg]
                "" ', Tail [list_1_putArg]
                                                
        by
                Tail 
end function

function removeOptDotDot
        replace [expression_statement]
                'put LPA [list putArg] '..
                                
        construct newLPA [list putArg]
                LPA [removeNewline]

        where not
                newLPA [= LPA]
                
        by
                'put newLPA
end function

function removeNewline
        replace * [list putArg]
                "\n"
                
        by
                %nothing
end function


%% *****
%% scanf statements

function changeBasicScanf
        replace [expression_statement]
                'scanf '( LE [list assignment_expression+] ')
        
        construct repeatExpr [repeat assignment_expression]
                _ [. each LE]
                
        deconstruct repeatExpr
                SL [stringlit] Rest [repeat assignment_expression]
                
        construct listExpr [list assignment_expression]
                _ [, each Rest]

        by
                'get listExpr
end function


%% *****
%% str statements

function changeStrCopy
        replace [expression_statement]
                ES [expression_statement]
                
        by
                ES
                        [changeCopyWithLiteral]
                        [changeCopyWithIdentifier]
end function

function changeCopyWithLiteral
        replace [expression_statement]
                'strcpy '( N [identifier] ', SL [stringlit] ')
                
        by
                N ':= SL
end function

function changeCopyWithIdentifier
        replace [expression_statement]
                'strcpy '( N [identifier] ', N2 [identifier] ')
                
        by
                N ':= N2
end function

function changeStrCat
        replace [expression_statement]
                ES [expression_statement]
                
        by
                ES
                        [changeCatWithLiteral]
                        [changeCatWithIdentifier]
end function

function changeCatWithLiteral
        replace [expression_statement]
                'strcat '( N [identifier] ', SL [stringlit] ')
                
        by
                N ':= N '+ SL
end function

function changeCatWithIdentifier
        replace [expression_statement]
                'strcat '( N [identifier] ', N2 [identifier] ')
                
        by
                N ':= N '+ N2
end function


%% *****
%% increment/decrement statements

function changePrePlusPlus
        replace [expression_statement]
                '++ ID [identifier]
                
        by
                ID ':= ID '+ 1
end function

function changePostPlusPlus
        replace [expression_statement]
                ID [identifier] '++ 
                
        by
                ID ':= ID '+ 1
end function

function changePreMinusMinus
        replace [expression_statement]
                '-- ID [identifier]
                
        by
                ID ':= ID '- 1
end function

function changePostMinusMinus
        replace [expression_statement]
                ID [identifier] '-- 
                
        by
                ID ':= ID '- 1
end function



%% *****
%% loop statements

define iteration_statement
%% C
        'while '( [expression] ')       [NL]
                [statement]
  |
        'do
                [statement] 
        'while '( [expression] ') '; [NL]
  |
        'for '( [expression] '; [expression] '; [expression] ')         [NL]
                [statement]
%% Turing
  |
        [opt init_statement]
        'loop                                           [NL][IN]
                [repeat statement]              [EX]
        'end 'loop                                      [NL]
  |
        'for [opt 'decreasing] [opt identifier] : [expression] '.. [expression] [NL][IN]
                [repeat statement]              [EX]
        'end 'for
end define


define init_statement
        '% due to an error, this comment is required for the program to compile         [NL]
        [repeat statement]      
end define


function changeDoWhileStatement
        replace [statement]
                'do
                        S [statement] 
                'while '( E [expression] ') ';
        
        construct exitCondition [statement]     
                'exit 'when 'not '( E [changeExpression] ')
        
        construct newS [repeat statement]
                S 
                
        construct newS2 [repeat statement]
                newS [removeBrackets]
                
        construct newBody [repeat statement]
                _ [translateCStatements each newS2]
                        
        by
                'loop
                        newBody [. exitCondition]
                'end 'loop
end function

function changeWhileStatement
        replace [statement]
                'while '( E [expression] ') 
                        S [statement]
                        
        construct exitCondition [statement]     
                'exit 'when 'not '( E [changeExpression] ')
        
        construct newS [repeat statement]
                S 
                
        construct newS2 [repeat statement]
                newS [removeBrackets]
                
        construct newBody [repeat statement]
                _ [translateCStatements each newS2]

        by
                'loop
                        exitCondition 
                        newBody
                'end 'loop
end function

function changeForStatement
        replace [statement]
          'for '( I [expression] '; C [expression] '; S1 [expression] ') 
                        S2 [statement]
                                
        construct InitStatement [repeat statement]
                I

        construct newInitStatement [repeat statement]
                _ [translateCStatements each InitStatement]

        construct exitCondition [statement]     
                'exit 'when 'not '( C [changeExpression] ')
                
        construct newFinalStatement [repeat statement]
                S1

        construct newS [repeat statement]
                S2 
                
        construct newS2 [repeat statement]
                newS [removeBrackets] [. newFinalStatement]
                
        construct newBody [repeat statement]
                _ [translateCStatements each newS2]
                
        by
                '% due to an error, this comment is required for the program to compile
                newInitStatement
                'loop
                        exitCondition
                        newBody
                'end 'loop
end function



%% *****
%% if statements

define if_statement
%% C
        'if '( [expression] ') 
            [statement] 
        [opt ELSEstatement]
  |
%% Turing
        'if [expression] 'then  [NL][IN]
            [repeat statement]          [EX]
        [opt ELSEstatement]
        'end 'if                                [NL]
end define

define ELSEstatement
%% C
%% Turing
        else                            [IN][NL]
            [statement]         [EX]
  |
%% Turing
        'elsif [expression] 'then       [IN][NL]
            [repeat statement]          [EX]
         [opt ELSEstatement]
end define


function changeIfStatement
        replace [statement]
                'if '( E [expression] ')
                        S [statement]
                OE [opt ELSEstatement]
                
        construct newS [repeat statement]
                S
                
        construct newS2 [repeat statement]
                newS [removeBrackets]
                
        construct newBody [repeat statement]
                _ [translateCStatements each newS2]

        by
                'if E [changeExpression] 'then
                        newBody
                OE [changeElse]
                'end 'if
end function

% change 'else if' statments to 'elsif' statments
rule changeElse
        replace [ELSEstatement]
                'else 'if '( E [expression] ')
                        S [statement]
                OE [opt ELSEstatement]
                
        construct newS [repeat statement]
                S
                
        construct newS2 [repeat statement]
                newS [removeBrackets]
                
        construct newBody [repeat statement]
                _ [translateCStatements each newS2]

        by
                'elsif E [changeExpression] 'then
                        newBody
                OE [changeElse]
end rule


%% *****
%% jump statements

define jump_statement
%% C
        'goto [identifier] ';           [NL]
    |   'continue ';                    [NL]
    |   'break ';                       [NL]
    |   'return [opt expression] ';     [NL]
    |   'return '( [opt expression] ') ';       [NL]
%% Turing
        |       'result [expression]    [NL]
        |       'exit [opt whenPart]    [NL]
end define

define whenPart
        'when [opt 'not] '( [expression] ')
end define

function changeReturnStatement
        replace [statement]
                'return E [expression] ';
                
        by
                'result E [changeExpression]
end function

function changeBreakStatement
        replace [statement]
                'break ';
                
        by
                'exit
end function

