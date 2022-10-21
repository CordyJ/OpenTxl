define program
	[repeat item]
end define

define item
	[id]
end define

redefine item 
	... |
	[number]
    |	'Jim
end redefine

function main
	match [program] _ [program]
end function
