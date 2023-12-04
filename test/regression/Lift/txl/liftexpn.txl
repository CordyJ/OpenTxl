% Lift independent expressions outside loops
% (Turing Plus version)
% J.R. Cordy   20.5.93

% This TXL program will move all expressions containing at least one 
% binary operator which are not dependent on computation inside a loop 
% to the outside.
% Since the rule is automatically applied recursively, the net effect 
% of this transform is to tune an entire program to lift expression 
% computations to the outermost scope on which they are dependent.

% Based on the Turing Plus basis grammar
include "Tplus.Grammar"


% Main rule: lift expressions outside loops until no more can be lifted
rule main
    replace [program]
	C [compilation]
    where
	C [?liftLoopExpressions]
	  [?liftForExpressions]
    by
	C [liftLoopExpressions]
	  [liftForExpressions]
end rule


% Rule set 1: Lift expressions out of 'loop .. end loop' constructs
rule liftLoopExpressions
    % Find every loop
    replace [repeat declarationOrStatement]
	loop
	    Body [repeat declarationOrStatement]
	'end loop
	Rest [repeat declarationOrStatement]

    % Construct a list of all the expressions used in it
    construct AllAssignments [repeat declarationOrStatement]
	Body [deleteNonAssignments]
    construct AllExpressions [repeat expn]
	_ [^ AllAssignments]

    % Construct the result
    construct LiftedLoop [repeat declarationOrStatement]
	loop
	    Body 
	'end loop

    % Stop when there are no expressions that can be lifted out
    where
	LiftedLoop [?loopLift each AllExpressions]

    % Lift any that can be
    by
	LiftedLoop [loopLift each AllExpressions]
	[. Rest]
end rule

% Attempt to lift a given expression outside the loop
function loopLift Expression [expn]
    % Is it worth doing?  Only if there are operators in it
    deconstruct * [binaryOperator] Expression
	_ [binaryOperator]

    % Construct a list of the identifiers used in the expression
    construct IdsInExpression [repeat id]
	_ [^ Expression]

    % Replace the loop and its contents
    replace [repeat declarationOrStatement]
	Loop [repeat declarationOrStatement]

    % Can only lift the expression if all the identifiers in it 
    % are not assigned in the loop 
    % (Note: this check is easily extended to handle passing them 
    %	     to var parameters as well)
    where not
	Loop [assigns each IdsInExpression]

    % Create a new name for the lifted expression
    construct LE [id]
	'E
    construct LiftedExpnId [id]
	LE [!]
    construct LiftedExpn [expn]
	LiftedExpnId

    % Now lift it and substitute all occurences 
    by
	LiftedExpnId := Expression
	Loop [$ Expression LiftedExpn]
end function


% Rule set 2: Lift expressions out of 'for .. end for' constructs
rule liftForExpressions
    % Find every for loop
    replace [repeat declarationOrStatement]
	for Iterator [id] : Range [forRange]
	    Body [repeat declarationOrStatement]
	'end for
	Rest [repeat declarationOrStatement]

    % Construct a list of all the expressions used in it
    construct AllAssignments [repeat declarationOrStatement]
	Body [deleteNonAssignments]
    construct AllExpressions [repeat expn]
	_ [^ AllAssignments]

    % Construct the result
    construct LiftedFor [repeat declarationOrStatement]
	for Iterator : Range
	    Body 
	'end for

    % Stop when there are no expressions that can be lifted out
    where
	LiftedFor [?forLift Iterator each AllExpressions]

    % Lift any that can be
    by
	LiftedFor [forLift Iterator each AllExpressions]
	[. Rest]
end rule

% Attempt to lift a given expression outside the for loop
function forLift Iterator [id] Expression [expn]
    % Is it worth doing?  Only if there are operators in it
    deconstruct * [binaryOperator] Expression
	_ [binaryOperator]
    construct IdsInExpression [repeat id]
	_ [^ Expression]

    % Replace the for loop and its contents
    replace [repeat declarationOrStatement]
	ForLoop [repeat declarationOrStatement]

    % Can only lift the expression if none of the identifiers used in it
    % are assigned in the loop ...
    where not
	ForLoop [assigns each IdsInExpression]

    % ... and none of them are the for index 
    where not
	Iterator [= each IdsInExpression]

    % Create a new name for the lifted expression
    construct LE [id]
	'E
    construct LiftedExpnId [id]
	LE [!]
    construct LiftedExpn [expn]
	LiftedExpnId

    % Now lift it and all occurences
    by
	LiftedExpnId := Expression
	ForLoop [$ Expression LiftedExpn]
end function


% Utility rules used above

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
