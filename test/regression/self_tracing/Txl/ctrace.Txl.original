% Transform ANSI C program to an auto-tracing version of itself.
% If this transform were to be completed, it would also indicate values 
% of assigned and passed variables and expressions in the trace.
% J.R. Cordy, 6.12.94

#pragma -esc '\\'

include "ANSIC.Grammar"

keys
        DONE__
end keys

define real_statement
        [repeat label] [compound_statement]
    |   [repeat label] [expression_statement]
    |   [repeat label] [selection_statement]
    |   [repeat label] [iteration_statement]
    |   [repeat label] [jump_statement]
    |   [repeat label] [null_statement]
end define

define statement
        [real_statement] [attr 'DONE__]
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
    replace [repeat statement_or_preprocessor]
        RS [real_statement] 
        Rest [repeat statement_or_preprocessor]
    construct QuoteRS [stringlit]
        _ [quote RS]
    by
        fprintf (stderr, ">>> %s\n",  QuoteRS); DONE__ 
        RS DONE__
        Rest
end rule

rule addtracing2
    % Handle lone statements that need to be turned into blocks
    replace [statement]
        RS [real_statement]
    construct QuoteRS [stringlit]
        _ [quote RS]
    by
        {
            fprintf (stderr, ">>> %s\n",  QuoteRS); DONE__ 
            RS DONE__ 
        } DONE__
end rule
