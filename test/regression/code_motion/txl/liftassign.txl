% Lift independent assignments outside loops
% (Turing Plus version)
% J.R. Cordy   20.5.93

% This TXL program will move all assignments not dependent on 
% computation inside a loop to the outside.  
% For loops can be done similarly but for the moment I haven't bothered.

% Based on the Turing Plus basis grammar
include "Tplus.grm"


% Main rule: lift assignments outside loops until no more can be lifted
rule main
    replace [program]
	C [compilation]
    where
	C [?renameMaskingAssignments]
	  [?liftLoopAssignments]
    by
	C [renameMaskingAssignments]
	  [liftLoopAssignments]
end rule


% Ruleset 1: Rename any masking assignments (i.e., re-assignments to same var)
rule renameMaskingAssignments
    % Find every loop
    replace [repeat declarationOrStatement]
	loop
	    Body [repeat declarationOrStatement]
	'end loop
	Rest [repeat declarationOrStatement]
    % Keep renaming until there are no more to rename
    where
	Body [?renameAssignment Body]
    by
	loop
	    Body [renameAssignment Body]
	'end loop
	Rest
end rule

% Rename repeated assignments
rule renameAssignment Body [repeat declarationOrStatement]
    % Find an assignment
    replace [repeat declarationOrStatement]
	X [id] := E [expn]
	Rest [repeat declarationOrStatement]

    % Construct the context it appears in
    construct PreContext [repeat declarationOrStatement]
	Body [deleteAssignmentAndRest X]

    % Rename any subsequent assignment to X, if possible
    where
	Rest [?renameAssignmentsTo X PreContext]
    by
	X := E
	Rest [renameAssignmentsTo X PreContext]
end rule

% Rename any subsequent assignment to X, if possible
rule renameAssignmentsTo X [id] PreContext [repeat declarationOrStatement]
    % Find a subsequent assignment to X
    replace [repeat declarationOrStatement]
	X := E [expn]
	Rest [repeat declarationOrStatement]

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
	NewX := E
	Rest [$ X NewX]
end rule


% Ruleset 2: Lift all independent assignments out of loops
rule liftLoopAssignments
    % Find every loop
    replace [repeat declarationOrStatement]
	loop
	    Body [repeat declarationOrStatement]
	'end loop
	Rest [repeat declarationOrStatement]

    % Construct a list of all the assignments in it
    construct AllAssignments [repeat declarationOrStatement]
	Body [deleteNonAssignments]

    % Construct the result
    construct LiftedLoop [repeat declarationOrStatement]
	loop
	    Body 
	'end loop

    % Stop when there are no assignments that can be lifted out
    where
	LiftedLoop [?loopLift Body each AllAssignments]

    % Lift any that can be
    by
	LiftedLoop [loopLift Body each AllAssignments]
	[. Rest]
end rule

% Attempt to lift a given assignment outside the loop
function loopLift Body [repeat declarationOrStatement] Assignment [declarationOrStatement]
    deconstruct Assignment
	X [id] := E [expn]

    % Construct a list of the identifiers used in the expression
    construct IdsInExpression [repeat id]
	_ [^ E]

    % Replace the loop and its contents
    replace [repeat declarationOrStatement]
	Loop [repeat declarationOrStatement]

    % Can only lift the assignment if all the identifiers in its
    % expression are not assigned in the loop ...
    where not
	Loop [assigns each IdsInExpression]

    % ... and X is assigned only once
    deconstruct * Body
	X := E
	Rest [repeat declarationOrStatement]
    where not
	Rest [assigns X]

    % ... and the the effect of it does not wrap around the loop
    construct PreContext [repeat declarationOrStatement]
	Body [deleteAssignmentAndRest X]
    where not 
	PreContext [refers X]

    % Now lift the assignment
    by
	Assignment
	Loop [deleteAssignment Assignment]
end function


% Utility rules used above

% Delete a given assignment statement from a scope
function deleteAssignment Assignment [declarationOrStatement]
    replace * [repeat declarationOrStatement]
	Assignment
	Rest [repeat declarationOrStatement]
    by
	Rest
end function

% Delete all non-assignment statements in a scope - 
% given a scope, yields the assignments only
rule deleteNonAssignments
    replace [repeat declarationOrStatement]
	S [declarationOrStatement]
	Rest [repeat declarationOrStatement]
    where not
	S [isAssignment]
    by
	Rest
end rule

% Delete everything in a scope from the first assignment to X on -
% given a scope and X, yields the context of the first assignment to X
function deleteAssignmentAndRest X [id]
    replace * [repeat declarationOrStatement]
	X := E [expn]
	Rest [repeat declarationOrStatement]
    by
	% nada
end function

% Condition - is the given declarationOrStatement an assignment?
function isAssignment
    match [declarationOrStatement]
	AS [assignmentStatement]
end function

% Condition - given a scope, does the scope assign to the identifier?
function assigns Id [id]
    match * [assignmentStatement]
	Id FieldsOrSubscripts [repeat componentSelector] := Expn [expn]
end function

% Condition - given a scope, does the scope refer to the identifier?
function refers Id [id]
    match * [id]
	Id
end function
