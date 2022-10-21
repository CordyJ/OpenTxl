% Backward static slicing of Tiny Imperative Language programs
% Jim Cordy, February 2007

% Given a TIL program with a single statement marked up using the
% XML markup <mark> </mark>, backward slices the program from that
% statement and its referenced variables.

% Works by inducing markup of unmarked statements from already marked-up
% statements beginning with the original marked statement until a fixed 
% point is reached, then removing all remaining unmarked statements.
% No dependency graph is required.

% Begin with the TIL base grammar
include "TIL.grm"

% Add allowance for XML markup of TIL statements
redefine statement
        ...
    |        [marked_statement]
end redefine

define marked_statement
            [xmltag] [statement] [xmlend]
end define

define xmltag
        < [SPOFF] [id] > [SPON]
end define

define xmlend
        < [SPOFF] / [id] > [SPON]
end define

% Conflate while and for statements into one form to optimize
% handling of both forms in one rule
redefine statement
        [loop_statement]
    |         ...
end redefine

define loop_statement
        [loop_head]                [NL][IN]
            [statement*]        [EX]
        'end                        [NL]
end define

define loop_head
        while [expression] do
    |         for [id] := [expression] to [expression] do
end define


% The main function gathers the steps of the transformation:
% induce markup to a fixed point, remove unmarked statements,
% remove declarations for variables not used in the slice,
% and strip the markups to yield the sliced program

function main
    replace [program]
        P [program]
    by
        P [propogateMarkupToFixedPoint]
          [removeUnmarkedStatements]
          [removeRedundantDeclarations]
          [stripMarkup]
end function

% Back propogate markup of statements beginning with the initially
% marked statement of interest.  Continue until a fixed point, 
% when no new markups are induced

rule propogateMarkupToFixedPoint
    replace [program]
        P [program]

    construct NP [program]
        P [backPropogateAssignments]
          [backPropogateReads]
          [whilePropogateControlVariables]
          [loopPropogateMarkup]
          [loopPropogateMarkupIn]
          [ifPropogateMarkupIn]
          [compoundPropogateMarkupOut]

    % We're at a fixed point when P = NP   :-)
    deconstruct not NP
        P
    by
        NP 
end rule

% Rule to back-propogate markup of assignments.
% A previous assignment is in the slice if its assigned 
% variable is used in a following marked statement

rule backPropogateAssignments
    skipping [marked_statement]
    replace [statement*]
        X [id] := E [expression] ; 
        More [statement*]
    where 
        More [hasMarkedUse X]
    by
        < mark > X := E; </ mark >
        More 
end rule

% Similar rule for back-propogating markup of read statements

rule backPropogateReads
    skipping [marked_statement]
    replace [statement*]
        read X [id] ; 
        More [statement*]
    where 
        More [hasMarkedUse X]
    by
        < mark > read X; </ mark >
        More 
end rule

function hasMarkedUse X [id]
    match * [marked_statement]
        M [marked_statement]
    deconstruct * [expression] M
        E [expression]
    deconstruct * [id] E
        X
end function

% Assignments to variables inside a while loop containing statements
% of a slice are also in the slice if the while condition uses them

rule whilePropogateControlVariables
    replace $ [statement]
        while E [expression] do
            S [statement*]
        'end
    deconstruct * [statement] S
        _ [marked_statement]
    by
        while E do
            S [markAssignmentsTo E]
              [markReadsOf E]
        'end
end rule

rule markAssignmentsTo Exp [expression]
    skipping [marked_statement]
    replace $ [statement]
        X [id] := E [expression] ;
    deconstruct * [id] Exp
        X
    by
        < mark > X := E; </ mark >
end rule

rule markReadsOf Exp [expression]
    skipping [marked_statement]
    replace $ [statement]
        read X [id] ;
    deconstruct * [id] Exp
        X
    by
        < mark > read X; </ mark >
end rule

% Rule for propagating dependencies around loops.
% An assignment inside a loop is in the slice if its assigned variable
% is used in a marked statement anywhere inside the loop

rule loopPropogateMarkup
    replace $ [statement]
        Head [loop_head]
            S [statement*]
        'end
    construct MarkedS [marked_statement*]
            _ [^ S]
    construct MarkedE [expression*]
            _ [^ MarkedS]
    by
        Head
            S [markAssignmentsTo each MarkedE]
              [markReadsOf each MarkedE]
        'end
end rule

% Rule for propagating dependencies into loops.
% An assignment inside the loop is in the slice if its assigned variable 
% is used in a marked statement anywhere following the loop

rule loopPropogateMarkupIn
    replace $ [statement*]
        Head [loop_head]
            S [statement*]
        'end
        MoreS [statement*]
    construct MarkedMoreS [marked_statement*]
            _ [^ MoreS]
    construct MarkedMoreE [expression*]
            _ [^ MarkedMoreS]
    by
        Head
            S [markAssignmentsTo each MarkedMoreE]
              [markReadsOf each MarkedMoreE]
        'end
        MoreS
end rule

% Rule for propagating dependencies into if statements.
% An assignment inside the then or else part of the if is in the slice 
% if its assigned variable is used in a marked statement anywhere 
% following the if

rule ifPropogateMarkupIn
    replace $ [statement*]
        if E [expression] then
            ST [statement*]
        ElseSE [opt else_statement]
        'end
        MoreS [statement*]
    construct MarkedMoreS [marked_statement*]
            _ [^ MoreS]
    construct MarkedMoreE [expression*]
            _ [^ MarkedMoreS]
    by
        if E then
            ST [markAssignmentsTo each MarkedMoreE]
        ElseSE [markAssignmentsTo each MarkedMoreE]
        'end
        MoreS
end rule

% Rule for propagating dependencies out.
% A compound statement of any kind is in the loop if it contains
% a marked statement

rule compoundPropogateMarkupOut
    replace $ [statement*]
        CS [statement]
        More [statement*]
    deconstruct not CS
        _ [marked_statement]
    deconstruct * [statement] CS
        _ [marked_statement]
    by
        <mark> CS </mark>
        More
end rule

% Rule to remove all unmarked statements after the fixed point
% is reached, yielding only the slice

rule removeUnmarkedStatements
    replace [statement*]
        S [statement]
        More [statement*]
    deconstruct not S
        _ [marked_statement]
    deconstruct not S
        _ [declaration]
    by
        More
end rule

% Rule to remove declarations not needed in the slice

rule removeRedundantDeclarations
    replace [statement*]
        var X [id] ;
        More [statement*]
    deconstruct not * [id] More
        X
    by
        More
end rule

% Rule to strip all markup when we're done

rule stripMarkup
    replace [statement]
        < _ [id] > S [statement] </ _ [id] >
    by
        S
end rule

