tokens
	id 	... | "hello"
end tokens

define program
	[id]
end define

function main
	match [program] _ [program]
end function
