#pragma -Dtokens
tokens
	my_newline	"foo\n"	
	my_notnewline	"foo#\n"	
	my_WRONGnotnewline	"foo#n"	% this one shouldn't happen if the one above is intrpreted correctly
end tokens

define program
	[repeat token]
end define

function main
    match [program] _ [program]
end function
