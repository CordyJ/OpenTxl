#pragma -analyze
define program
	[repeat X]
	[repeat Y]
	'end
end define

define X
	[repeat Z+]
end define

define Z
	[number]
end define

define Y
	[repeat number+]
end define

function main
	match [program]
		P [program]
end function
