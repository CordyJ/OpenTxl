#pragma -Dtokens
define program
	[stringlit]
    |	[repeat token]
end define

function main
    replace [program]
	S [stringlit]
    construct ParsedS [repeat token]
	_ [parse S]
    by
	ParsedS
end function
