% It appears that specifying -char or -newline should disable -multiline, since the two conflict. 
% As it is, you must explicitly specify -nomultiline when using -char or -newline, 
% otherwise newlines may be lost in multiline tokens.
#pragma -newline

define program
	[repeat line]
end define

define line
	[repeat token_not_newline] [newline]
end define

define token_not_newline
	[not newline] [token]
    | 	[number]
end define

function main
	replace [program]
		Lines [repeat line]
	by
		Lines [countThem 1]
end function

function countThem N [number]
	replace [repeat line]
		Tokens [repeat token_not_newline] Newline [newline]
		MoreLines [repeat line]
	construct NP1 [number]
		N [+1]
	by
		N Tokens Newline
		MoreLines [countThem NP1]
end function
