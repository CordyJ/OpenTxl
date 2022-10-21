% Lift independent assigned computations outside of TIL while loops
% J.R. Cordy, November 2005

% This more sophisitcated TXL program will optimize a TIL program by moving all 
% assigned computations not dependent on computation inside while loops to the outside.
% The process works in two steps: 
%   (1) Renaming of masking assignments (subsequent assignments to a variable), 
%       which exposes hidden opportunities for code motion, and 
%   (2) Lifting of independent assignments, exactly as in the simpler assignment
%       only case in TILcodemotion.Txl
% Finally, declarations are synthesized and inserted for any new variables introduced 
% by the renaming.

% Based on the TIL grammar
include "TIL.grm"

% Two main parts - the actual renaming and lifting, then the introduction of missing 
% declarations for any introduced renamed variables
function main
    replace [program]
        P [program]
    by
        P [renameAndLift]
          [declareNewVariables]
end function


% Main rule: Rename masking assignments and lift them outside loops until no more can be 
% renamed and no more can belifted
rule renameAndLift
    replace [program]
        P [program]

    % We continue as long as a match for either transform can be found - the form [?rule] 
    %   in TXL means test if a pattern match for the rule can be found
    % In TXL, the composition of two conditionals is "or", so this guard tests whether
    %   either rule can find a match
    where
        P [?renameMaskingAssignments]
          [?liftLoopAssignments]

    % If so, apply the rules and continue until the condition above fails 
    by
        P [renameMaskingAssignments]
          [liftLoopAssignments]
end rule


% Ruleset 1: Rename any masking assignments (i.e., re-assignments to the same variable)
% This exposes hidden opportunities to move assigned computations out of the loop
rule renameMaskingAssignments
    % Find every while loop
    replace [statement*]
        while Expn [expression] do
            Body [statement*]
        'end
        Rest [statement*]

    % Keep renaming until there are no more to rename
    where
        Body [?renameAssignment Body]
    by
        while Expn do
            Body [renameAssignment Body]
        'end 
        Rest
end rule

% Rename repeated assignments
rule renameAssignment Body [statement*]
    % Find an assignment
    replace [statement*]
        X [id] := E [expression];
        Rest [statement*]

    % Construct the context it appears in
    construct PreContext [statement*]
        Body [deleteAssignmentAndRest X]

    % Rename any subsequent assignment to X, if possible
    where
        Rest [?renameAssignmentsTo X PreContext]
    by
        X := E;
        Rest [renameAssignmentsTo X PreContext]
end rule

% Rename any subsequent assignment to X, if possible
rule renameAssignmentsTo X [id] PreContext [statement*]
    % Find a subsequent assignment to X
    replace [statement*]
        X := E [expression];
        Rest [statement*]

    % It only makes sense to rename it if its effect doesn't wrap around ...
    where not 
        PreContext [refers X]

    % ... and it is not an iteration 
    where not
        E [refers X]

    % ... and it is not assigned again
    where not
        Rest [assigns X]

    % If all that is ok, then rename it
    construct NewX [id]
        X [!]
    by  
        NewX := E;
        Rest [$ X NewX]      % [$ X NewX] means substitute NewX for X everywhere in Rest
end rule


% Ruleset 2: Lift all independent assignments out of loops
% This is exactly the same ruleset as in TILcodemotion.Txl - we could use a TXL "include"
% statement to reuse the original
rule liftLoopAssignments
    % Find every loop
    replace [statement*]
        while Expn [expression] do
            Body [statement*]
        'end 
        Rest [statement*]

    % Construct a list of all the top-level assignments in it
    construct AllAssignments [statement*]
        Body [deleteNonAssignments]

    % Construct a copy of the loop to work on
    construct LiftedLoop [statement*]
        while Expn do
            Body 
        'end 

    % Only proceed if there are assignments left that can be lifted out
    % The [?loopLift] form tests if the pattern of the [loopLift] rule can be matched -
    % "each AllAssignments" tests this for any of the top-level internal assignments
    where
        LiftedLoop [?loopLift Body each AllAssignments]

    % If the above guard succeeds, some can be moved out, so go ahead and move them,
    % replacing the original loop with the result
    by
        LiftedLoop [loopLift Body each AllAssignments]
        [. Rest]
end rule

% Attempt to lift a given assignment outside the loop
function loopLift Body [statement*] Assignment [statement]
    deconstruct Assignment
        X [id] := E [expression];

    % Extract a list of all the identifiers used in the expression
    construct IdsInExpression [id*]
        _ [^ E]

    % Replace the loop and its contents
    replace [statement*]
        Loop [statement*]

    % We can only lift the assignment out if all the identifiers in its
    % expression are not assigned in the loop ...
    where not
        Loop [assigns each IdsInExpression]

    % ... and X itself is assigned only once
    deconstruct * Body
        X := _ [expression];
        Rest [statement*]
    where not
        Rest [assigns X]

    % ... and the the effect of it does not wrap around the loop
    construct PreContext [statement*]
        Body [deleteAssignmentAndRest X]
    where not
        PreContext [refers X]

    % Now lift out the assignment
    by
        Assignment
        Loop [deleteAssignment Assignment]
end function


% Utility rules used above

% Delete a given assignment statement from a scope
function deleteAssignment Assignment [statement]
    replace * [statement*]
        Assignment
        Rest [statement*]
    by
        Rest
end function

% Delete all non-assignment statements in a scope -
% given a scope, yields the assignments only
rule deleteNonAssignments
    replace [statement*]
        S [statement]
        Rest [statement*]
    deconstruct not S
        _ [assignment_statement]
    by
        Rest
end rule

% Delete everything in a scope from the assignment to X on -
% given a scope and X, yields the context of the first assignment to X
function deleteAssignmentAndRest X [id]
    replace * [statement*]
        X := E [expression];
        Rest [statement*]
    by
        % nada
end function

% Condition - given a scope, does the scope assign to the identifier?
function assigns Id [id]
    match * [assignment_statement]
        Id := Expn [expression];
end function

% Condition - given a scope, does the scope refer to the identifier?
function refers Id [id]
    match * [id]
        Id
end function


% Ruleset 3: Declare any renaming variables we introduced
rule declareNewVariables
    replace [program]
        P [program]
    % Continue until we can't find any more
    where
        P [?declareNewVariable P]
    by
        P [declareNewVariable P]
end rule

function declareNewVariable P [program]
    replace * [statement*]
        X [id] := E [expression];
        MoreStatements [statement*]
    deconstruct not * [declaration] P
        'var X;
    by
        'var X;
        X := E;
        MoreStatements 
end function

