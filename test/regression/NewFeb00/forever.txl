define program
	[repeat X]
	[repeat Y]
	[repeat X]
	[repeat Y]
	'end
end define

define X
	[Z] | [Z] [X]
end define

define Z
	[number] | [number] [Z]
end define

define Y
	[number] | [number] [Y]
end define

function main
	match [program]
		P [program]
end function
