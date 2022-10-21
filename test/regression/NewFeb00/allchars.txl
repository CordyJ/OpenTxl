tokens
	char "\c"
end tokens

define program
	[SPOFF] [repeat char] [SPON]
end define

function main
	match [program]
		Chars [repeat char]
	construct Msg [id]
		_ [show each Chars]
end function

function show Char [char]
	match [id]
		_ [id]
	construct Msg [char]
		Char [putp "char='%'"]
end function
