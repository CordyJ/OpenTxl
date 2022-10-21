%  Reduced Function Block Syntax Checker
% Author: Mitch Webster 
% Date:  18 - 3 - 93 
% this set of rules is intended to detect boolean conditions and 
% replace then with a BOOL array variable for timing harness manipulation

include "FB.grm"

% Transformation rules

function main
    replace [program]
	Proc [proc]
    by
	Proc [FindRunPhase]
end function


% Find the run phase of the program and modify it to have all decisions
% controlled by a branch control array

function FindRunPhase
    construct DefaultName [id]
	FunctionTest

    replace [proc]
	U [repeat usedeclarations] 
	PROC name [id] (F [list formal], BOOL initialise) @ N [number]
	    Spec [repeat specification]
	    IF @  N1 [number]
		initialise @ N2 [number]
		    SU [setupphase]
		TRUE @ N3 [number]
		    R [runphase]
	    : @ N4 [number]
    by
	U 
	PROC DefaultName (F, BOOL initialise, '[']'BranchTests) @ N
	    Spec
	    IF @ N1
		initialise @ N2
		    SU
		TRUE @ N3
		    R [ReplaceChoicesWithArrayRefs] [EnumerateArrayRefs '1]
	    : @ N4
end function 


% Replace every decision expression with a branch control array reference
% - we begin with every index 0, and then enumerate them later

rule ReplaceChoicesWithArrayRefs
    construct B [boolean]
	'BranchTest '[ 0 ']
    replace [choice]
	Bool [boolean] @ N [number] 
	P [process]
    where not
	Bool [= B]
    by
	B @ N
	P
end rule


% Assign a unique branch control array index to each decision

function EnumerateArrayRefs N [number]
    replace [runphase]
	R [runphase]
    where
	R [?NumberArrayRef N]
    construct NP1 [number]
	N [+1]
    by
	R [NumberArrayRef N] [EnumerateArrayRefs NP1]
end function

function NumberArrayRef N [number]
    replace * [boolean]
	'BranchTest '[ 0 ']
    by
	'BranchTest '[ N ']
end function
