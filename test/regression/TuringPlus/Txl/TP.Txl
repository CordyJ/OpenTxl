% Test of extract 

include "Tplus.Grammar"

rule main
    match [compilation]
	C [compilation]
    construct NullProcCalls [repeat callStatement]
	% none yet
    construct ProcCalls [repeat callStatement]
	NullProcCalls [extract C] [print]
end rule

% % external rule extract Scope [compilation]
% % external rule print
