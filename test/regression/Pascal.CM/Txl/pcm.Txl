% Code motion - lift independent assignments outside of loops
% (Pascal version)
% J.R. Cordy   20.5.93

% This TXL program will move all assignments not dependent on 
% computation inside a repeat, while or for loop to the outside.  

% Based on the Pascal basis grammar
include "Pascal.Grammar"


% Redefine the parsing of statements to make the transform easier ...
define statements
    [repeat statementOptSemicolon]
end define

define statementOptSemicolon
    	[new_var_marker]
    |	[statement] [opt ';]	[NL]
end define

define new_var_marker
	'NEW_VAR ( [id], [id] );	[NL]
end define


% Main rule: lift assignments outside loops until no more can be lifted
function main
    replace [program]
	P [program]
    by
	P [renameAndLift]
	  [removeImplicitReferences]
end function

% This rule must retry after each pass since assignments lifted from inner loops 
% to outer ones may be condidates for further lifting.
rule renameAndLift
    replace [program]
	P [program]
    construct NewP [program]
	P [renameMaskingAssignments]
	  [liftLoopAssignments]
	  [declareNewVariables]
    where not
	NewP [= P]
    by
	NewP
end rule


% Ruleset 1: Rename any masking assignments (i.e., re-assignments to the same variable)
function renameMaskingAssignments
    replace [program]
	P [program]
    by
	P [renameMaskingAssignmentsRepeat]
	  [renameMaskingAssignmentsWhile]
	  [renameMaskingAssignmentsFor]
end function

rule renameMaskingAssignmentsRepeat
    % Find every repeat loop
    replace [repeat statementOptSemicolon]
	'repeat
	    Body [repeat statementOptSemicolon]
	until Cond [expression] Semi [opt ';]
	Rest [repeat statementOptSemicolon]

    % Add the until expression to the loop body to be converted (Pascal quirk)
    construct ConditionHolder [statementOptSemicolon]
	'IMPLICIT_REF (Cond);
    construct AugmentedBody [repeat statementOptSemicolon]
	Body [. ConditionHolder]

    % Keep renaming until there are no more to rename
    where
	AugmentedBody [?renameAssignment AugmentedBody]

    % Do the renaming
    construct NewAugmentedBody [repeat statementOptSemicolon]
	AugmentedBody [renameAssignment AugmentedBody]

    % Get back the converted condition in case vars in it were renamed
    deconstruct * NewAugmentedBody
	'IMPLICIT_REF ( NewCond [expression] );

    % Leave the body augmented until after lifting
    by
	'repeat
	    NewAugmentedBody
	until NewCond Semi
	Rest
end rule

rule renameMaskingAssignmentsWhile
    % Find every while loop
    replace [repeat statementOptSemicolon]
	while ( Cond [expression] ) do
	    begin
		Body [repeat statementOptSemicolon]
	    'end Semi [opt ';]
	Rest [repeat statementOptSemicolon]

    % Add the until expression to the loop body to be converted (Pascal quirk)
    construct AugmentedBody [repeat statementOptSemicolon]
	'IMPLICIT_REF (Cond);
	Body 

    % Keep renaming until there are no more to rename
    where
	AugmentedBody [?renameAssignment AugmentedBody]

    % Do the renaming
    construct NewAugmentedBody [repeat statementOptSemicolon]
	AugmentedBody [renameAssignment AugmentedBody]

    % Get back the converted condition in case it was renamed
    deconstruct NewAugmentedBody
	'IMPLICIT_REF ( NewCond [expression] );
	NewBody [repeat statementOptSemicolon]

    % Leave the body augmented until after lifting
    by
	while ( NewCond ) do
	    begin
		NewAugmentedBody 
	    'end Semi 
	Rest
end rule

rule renameMaskingAssignmentsFor
    % Find every for loop
    replace [repeat statementOptSemicolon]
	for X [id] := L [expression] to U [expression] do
	    begin
		Body [repeat statementOptSemicolon]
	    'end Semi [opt ';]
	Rest [repeat statementOptSemicolon]

    % Augment the loop body with the for assignment
    construct AugmentedBody [repeat statementOptSemicolon]
	'IMPLICIT_REF (X);	 % the iteration step both references and assigns X
	Body

    % Keep renaming until there are no more to rename
    where
	AugmentedBody [?renameAssignment AugmentedBody]

    % Do the renaming
    construct NewAugmentedBody [repeat statementOptSemicolon]
	AugmentedBody [renameAssignment AugmentedBody]

    % Leave the body augmented until after lifting
    by
	for X := L to U do
	    begin
		NewAugmentedBody 
	    'end Semi 
	Rest
end rule

% Rename repeated assignments
rule renameAssignment Body [repeat statementOptSemicolon]
    % Find an assignment
    replace [repeat statementOptSemicolon]
	X [id] := E [expression] Semi [opt ';]
	Rest [repeat statementOptSemicolon]

    % Construct the context it appears in
    construct PreContext [repeat statementOptSemicolon]
	Body [deleteAssignmentAndRest X]

    % Rename any subsequent assignment to X, if possible
    where
	Rest [?renameAssignmentsTo X PreContext]
    by
	X := E Semi
	Rest [renameAssignmentsTo X PreContext]
end rule

% Rename any subsequent assignment to X, if possible
rule renameAssignmentsTo X [id] PreContext [repeat statementOptSemicolon]
    % Find a subsequent assignment to X
    replace [repeat statementOptSemicolon]
	X := E [expression] Semi [opt ';]
	Rest [repeat statementOptSemicolon]

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
	% remember to declare it later
	'NEW_VAR (NewX, X);
	NewX := E Semi
	Rest [$ X NewX]
end rule


% Ruleset 2: Lift all independent assignments out of loops
function liftLoopAssignments
    replace [program]
	P [program]
    by
	P [liftLoopAssignmentsRepeat]
	  [liftLoopAssignmentsWhile]
	  [liftLoopAssignmentsFor]
end function

rule liftLoopAssignmentsRepeat
    % Find every repeat loop
    replace [repeat statementOptSemicolon]
	'repeat
	    Body [repeat statementOptSemicolon]
	until Cond [expression] Semi [opt ';]
	Rest [repeat statementOptSemicolon]

    % Construct a list of all the assignments in it
    construct AllAssignments [repeat statementOptSemicolon]
	Body [deleteNonAssignments]

    % Construct the result
    construct LiftedLoop [repeat statementOptSemicolon]
	'repeat
	    Body 
	until Cond Semi

    % Stop when there are no assignments that can be lifted out
    where
	LiftedLoop [?loopLift Body each AllAssignments]

    % Lift any that can be
    by
	LiftedLoop [loopLift Body each AllAssignments] 
	[. Rest]
end rule

rule liftLoopAssignmentsWhile
    % Find every while loop
    replace [repeat statementOptSemicolon]
	while ( Cond [expression] ) do
	    begin
		Body [repeat statementOptSemicolon]
	    'end Semi [opt ';]
	Rest [repeat statementOptSemicolon]

    % Construct a list of all the assignments in it
    construct AllAssignments [repeat statementOptSemicolon]
	Body [deleteNonAssignments]

    % Construct the result
    construct LiftedLoop [repeat statementOptSemicolon]
	while ( Cond ) do
	    begin
		Body 
	    'end Semi 

    % Stop when there are no assignments that can be lifted out
    where
	LiftedLoop [?loopLift Body each AllAssignments]

    % Lift any that can be
    by
	LiftedLoop [loopLift Body each AllAssignments] 
	[. Rest]
end rule

rule liftLoopAssignmentsFor
    % Find every for loop
    replace [repeat statementOptSemicolon]
	for X [id] := L [expression] to U [expression] do
	    begin
		Body [repeat statementOptSemicolon]
	    'end Semi [opt ';]
	Rest [repeat statementOptSemicolon]

    % Construct a list of all the assignments in it
    construct AllAssignments [repeat statementOptSemicolon]
	Body [deleteNonAssignments]

    % Construct the result
    construct LiftedLoop [repeat statementOptSemicolon]
	for X := L to U do
	    begin
		Body 
	    'end Semi 

    % Stop when there are no assignments that can be lifted out
    where
	LiftedLoop [?loopLift Body each AllAssignments]

    % Lift any that can be
    by
	LiftedLoop [loopLift Body each AllAssignments] 
	[. Rest]
end rule

% Attempt to lift a given assignment outside the loop
function loopLift Body [repeat statementOptSemicolon] Assignment [statementOptSemicolon]
    deconstruct Assignment
	X [id] := E [expression] Semi [opt ';]

    % Construct a list of the identifiers used in the expression
    construct IdsInExpression [repeat id]
	_ [^ E]

    % Replace the loop and its contents
    replace [repeat statementOptSemicolon]
	Loop [repeat statementOptSemicolon]

    % Can only lift the assignment if all the identifiers in its
    % expression are not assigned in the loop ...
    where not
	Loop [assigns each IdsInExpression]

    % ... and X is assigned only once
    deconstruct * Body
	X := E Semi2 [opt ';]
	Rest [repeat statementOptSemicolon]
    where not
	Rest [assigns X]

    % ... and the the effect of it does not wrap around the loop
    construct PreContext [repeat statementOptSemicolon]
	Body [deleteAssignmentAndRest X]
    where not 
	PreContext [refers X]

    % Now lift the assignment
    by
	Assignment 
	Loop [deleteAssignment Assignment]
end function


% Ruleset 3.  Provide declarations for any new variables we created
function declareNewVariables
    replace [program]
	P [program]
    construct NewVars [repeat new_var_marker]
	_ [^ P]
    deconstruct * NewVars
	_ [new_var_marker]
    by
	P [addNewVarDeclaration each NewVars]
	  [deleteNewVarMarkers]
end function

function addNewVarDeclaration NewVarMarker [new_var_marker]
    deconstruct NewVarMarker
	NEW_VAR ( NewX [id], X [id] );
    replace * [idTypeSpec]
	Ids [list id+] : Type [typeSpec] ;
    deconstruct * [id] Ids
	X
    by
	Ids [, NewX] : Type ;
end function

rule deleteNewVarMarkers 
    replace * [repeat statementOptSemicolon]
	'NEW_VAR (X [id], Y [id]);
	Rest [repeat statementOptSemicolon]
    by
	Rest
end rule


% Ruleset 4.  Remove implicit reference markers
rule removeImplicitReferences
    replace [repeat statementOptSemicolon]
	'IMPLICIT_REF ( E [expression] );
	Rest [repeat statementOptSemicolon]
    by
	Rest
end rule


% Utility rules used above

% Delete a given assignment statement from a scope
function deleteAssignment Assignment [statementOptSemicolon]
    replace * [repeat statementOptSemicolon]
	Assignment 
	Rest [repeat statementOptSemicolon]
    by
	Rest
end function

% Delete all non-assignment statements in a scope - 
% given a scope, yields the assignments only
rule deleteNonAssignments
    replace [repeat statementOptSemicolon]
	S [statementOptSemicolon]
	Rest [repeat statementOptSemicolon]
    where not
	S [isAssignment]
    by
	Rest
end rule

% Delete everything in a scope from the first assignment to X on -
% given a scope and X, yields the context of the first assignment to X
function deleteAssignmentAndRest X [id]
    replace * [repeat statementOptSemicolon]
	X := E [expression] Semi [opt ';]
	Rest [repeat statementOptSemicolon]
    by
	% nada
end function

% Condition - is the given statementOptSemicolon an assignment?
function isAssignment
    match [statementOptSemicolon]
	AS [assignmentStatement] Semi [opt ';]
end function

% Condition - given a scope, does the scope assign to the identifier?
function assigns Id [id]
    match * [assignmentStatement]
	Id FieldsOrSubscripts [repeat componentSelector] := Expn [expression]
end function

% Condition - given a scope, does the scope refer to the identifier?
function refers Id [id]
    match * [id]
	Id
end function
