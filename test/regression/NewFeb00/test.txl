#pragma -char

% include "TxlExternals"
% include "System"

tokens
	char "\c"
end tokens

define program
	[repeat char]
end define

function main
	replace [program]
		P [program]
	by
		P
end function
