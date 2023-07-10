% Transform Pascal program to an auto-tracing version of itself.
% If this transform were to be completed, it would also indicate values 
% of assigned and passed variables and expressions in the trace.
% J.R. Cordy, 6.12.94

#pragma -esc '\\'

include "Pascal.Grammar"

keys
        DONE__
end keys

define statement
        [opt statementLabel] [unlabeledStatement] [attr 'DONE__]
end define

% external rule quote X [any]

function main
    replace [program]
        P [program]
    by
        P [addtracing1]
          [addtracing2]
end function

rule addtracing1
    % Handle statements in sequences
    replace [repeat statementSemicolon+]
        L  [opt statementLabel] US [unlabeledStatement] Semi [opt ';]
        Rest [repeat statementSemicolon]
    construct QuoteUS [charlit]
        _ [quote US]
    by
        writeln (''>>> ', QuoteUS) DONE__ ;     
        L US DONE__ Semi
        Rest
end rule

rule addtracing2
    % Handle lone statements that need to be turned into blocks
    replace [statement]
        L [opt statementLabel] US [unlabeledStatement] 
    construct QuoteUS [charlit]
        _ [quote US]
    by
        begin
            writeln (''>>> ', QuoteUS) DONE__ ;         
            L US DONE__ 
        'end DONE__
end rule
