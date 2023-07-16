% Prototype extension of the Concurrent beahviours language Abacus
% Oscar Neierstrasz, Centre d'Informatique, U. Genève

% This dialect is intended to support cascaded behaviour expressions of the form :
%	P = A guard B guard C guard D guard ...
% by transforming them into  
%	P = A guard P'
% where
% 	P' = B guard C guard D guard ...
% and so on, recursively.

include "Abacus.grm"

% Modify the choice grammar to allow cascaded behaviour expressions ( [repeat guardId+] )
% The + in the TXL grammatical form [repeat X+] means 1 or more repetitions rather than zero.
define choice
	[id]  [repeat guardId+]
end define

define guardId
	[guard] [id]
end define


% Transform as described above.
% The transform is done in two steps, since the Abacus grammar for the first choice
% of a sequence is different from that of the other choices.  I don't understand why
% the Abacus grammar is written that way, but ours is not to reason why ...

function main
    replace [program]
        Program [repeat statement]
    by
        Program	[fixFirstChoices] 
		[fixAlternateChoices] 
end function


% These rules are tricky but not complex.  Basically, they capture each statement sequence
% (the main pattern) that is headed by a process definition (the first deconstruct pattern), 
% and then check the process definition for the presence of a cascaded behaviour (the second
% two deconstruct patterns).  If we find a match to all these, then a cascaded behaviour
% is present.  In this case each of the rules consructs a the name for the auxiliary process
% to implement the cascade (the first constructor), the modified new process definition 
% that refers to it (the second constructor) and the auxiliary process definition to 
% implement the cascade (the third constructor).  They then replace the original process
% definition with the constructed pair.

rule fixFirstChoices
    replace [repeat statement]
    	Statements [repeat statement]
    deconstruct Statements
	ProcDef [processDefinition]
	FollowingStatements [repeat statement]
    deconstruct ProcDef
    	P [id] = C [choices]
    deconstruct C
        A [id] G [guard] B [id] G2 [guard] D [id] RG [repeat guardId] RA [repeat altChoice]
    construct X [id]
        P [!]
    construct NewProcDef [statement]
	P = A G X RA
    construct AuxiliaryProcDef [processDefinition]
	X = B G2 D RG
    by
	NewProcDef
	AuxiliaryProcDef
	FollowingStatements 
end rule

rule fixAlternateChoices
    replace [repeat statement]
    	Statements [repeat statement]
    deconstruct Statements
	ProcDef [processDefinition]
	FollowingStatements [repeat statement]
    deconstruct ProcDef
    	P [id] = C1 [choice] AC2 [altChoice] RAC [repeat altChoice]
    deconstruct AC2
        + A [id] G [guard] B [id] G2 [guard] D [id] RG [repeat guardId] 
    construct X [id]
        P [!]
    construct AC1 [altChoice]
	+ C1
    construct NewProcDef [statement]
	P = A G X RAC [. AC1]
    construct AuxiliaryProcDef [processDefinition]
	X = B G2 D RG
    by
	NewProcDef
	AuxiliaryProcDef
	FollowingStatements 
end rule

