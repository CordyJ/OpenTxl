% TXL 7.0 language pretty-printer
% J.R. Cordy, 24.3.92

% The vast majority of the work is done by the formatting
% cues in the Txl grammar file

% Fixed bugs in handling null comments and alternations of quoted literals -- JRC 25.8.93
% Updated to handle TXL 8.0 -- JRC 5.9.95

% Copyright 1995 Legasys Corp.

#pragma -txl -raw -comment

include "Txl.grm"

function main
    replace [program]
	P [program]
    by
	P [fixEmptyReplacements]
	  [fixQuotedPercents]
end function

rule fixEmptyReplacements
    replace [expsAndLits]
	% an empty one
    by
	'% '( 'empty ')
end rule

rule fixQuotedPercents
    replace [literal]
	'%
    by
	''
	'%
end rule
