#pragma -esc "'"

include "OOT.grm"

function main
	replace [program]
		P [program]
	construct OQ [charlit]
		_ [quote P] [print]
	construct Q [charlit]
		_ [LS_quote P] [print]
	construct LSexplode [repeat id]
		_ [LS_explode Q] [convertSpaces] [print]
	by
		const 'OldQuote := OQ
		const 'LS_Quote := Q
end function

rule convertSpaces
	construct SP [id]
		_ [unquote " "]
	construct UL [id]
		_ [unquote "_"]
	replace [id]
		SP
	by
		UL
end rule
