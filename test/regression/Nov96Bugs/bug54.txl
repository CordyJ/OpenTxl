	tokens
		number		"\d*(.\d+)?([eE][+-]?\d+)?"
	end tokens

define program
[repeat number]
end define

function main
match [program]
P [program]
end function
