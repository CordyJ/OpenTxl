#pragma -esc '\'
define program
	[repeat line]
end define

define line
	[repeat id] [stringlit] [NL]
end define

function main
	replace [program] Ls [repeat line]
	construct Ss [repeat line]
		_ [doquote each Ls]
	by
		Ss
end function

function doquote L [line]
	replace * [repeat line]
	construct QL [stringlit]
		_ [quote L] [putp "'%'"]
	by
		QL
end function
