define program
    #ifdef BUG 
	[repeat token]
    #endif
end BUG		% this syntax error is erroneously reported on line 2

function main
    match [program]
	_ [program]
end function
