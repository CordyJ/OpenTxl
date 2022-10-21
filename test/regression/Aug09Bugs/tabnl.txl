#pragma -newline 

define program
	[repeat line]
end define

define line
	[TAB_1] [TAB_1] [repeat token_not_newline] [newline]
end define

define token_not_newline
	[not newline] [token]
end define

function main
	match [program] _ [program]
end function
