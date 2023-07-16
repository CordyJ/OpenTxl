#pragma -xml

define program
	[repeat token]
end define

function main
	match [program] _ [program]
end function
