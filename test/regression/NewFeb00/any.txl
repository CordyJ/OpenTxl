define program 
	[shortlong]
end define

define shortlong
	[short] [repeat id]
end define

define short
	[id] [id]
end define

function main
	replace [program] P [program]
	construct Q [program]
		P [debug] [reparseAsShort] [debug]
	by
		Q
end function


function reparseAsShort
	replace [any] A [any]
	construct NP [opt short]
		_ [reparse A]
	deconstruct NP
		SH [short]
	deconstruct SH
		NA [any]
	by
		NA
end function

