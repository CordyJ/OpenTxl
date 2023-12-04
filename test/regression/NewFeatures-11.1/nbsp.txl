define program
    [tokenNL*]
end define

define tokenNL
    [token] [NL]
end define

function main
    match [program] 
	_ [program]
end function
