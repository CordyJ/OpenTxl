define program
	[charlit] | [repeat id]
end define

function main
	replace [program]	
		C [charlit]
	construct Chars [repeat id]
		_ [LS_explode C]
	construct LChars [number]
		_ [length Chars] [print]
	by
		Chars
end function
