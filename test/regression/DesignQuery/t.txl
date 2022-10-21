% Design factbase analyzer
% J.R. Cordy, 21.12.94, Revised 9.1.95
% Copyright 1994,1995 by James R. Cordy - all rights reserved

#pragma -raw -w 120

define program
	[repeat fact]
end define

define fact
    	[predicate] ( [list entity] ) . [NL]
end define

define entity
	[id] [repeat id] [opt number]	
end define

define predicate
	[entitypredicate]
    |	[usepredicate] [opt 'indirect]
    |	contains
    |	exports
    |	[importpredicate]
    |	[argumentpredicate]
end define

define entitypredicate
	constant | pervasive_constant | [parameterpredicate]
    |	variable | 'function | procedure | module | 'program | library
end define

define parameterpredicate
	const_parameter | var_parameter
end define

define usepredicate
    	[readpredicate]
    |	[writepredicate]
end define

define readpredicate
	read_ref | calls
end define

define writepredicate
	write_ref | var_argument_ref 
end define

define importpredicate
	imports | imports_var
end define

define argumentpredicate
	const_argument | var_argument
end define

% include "TxlExternals"


function main
    match [program]
	FB [repeat fact]
end function
