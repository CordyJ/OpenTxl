define program
	[repeat id]
end define

function main
	replace [program]
		P [program]
	by
		P [quit 33]
end function
