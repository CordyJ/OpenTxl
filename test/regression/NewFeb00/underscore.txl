define program
    [repeat item]
end define

define item
    [id] | [stringlit] | [number] | [empty]
end define

function main
	match [program] P [program]
	construct _ [program]
		P [print]
	construct _ [program]
		P [print]
	deconstruct P
		_ [program]
	construct R [program]
		_ [print]
end function
