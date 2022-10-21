% Lift independent assignments outside of TIL while loops
% J.R. Cordy, November 2005

% This TXL program will optimize a TIL program by moving all assignments 
% not dependent on computation inside while loops to the outside.  
% For loops can be done similarly, but are not handled by this program.

% Based on the TIL grammar
include "TIL.grm"

% Lift all independent assignments out of loops
rule main
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
    % The [?loopLift] form tests whether the pattern of the [loopLift] rule can be matched -
    % "each AllAssignments" tests This condition is tested for each of the top-level internal assignments
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
