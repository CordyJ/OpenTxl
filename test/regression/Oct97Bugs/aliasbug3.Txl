% Andrew's alias bug, variant 1
define program
	[subprogram]
end define

define subprogram
	[repeat element] [repeat element]
end define

define element
	[subelement]
end define

define subelement
	[id] | [number]
end define

function main
	construct P [program]
		A B C D
	construct CauseBug [program]
		P [message "Next line should be: A_MODIFIED B C D A"] 
		  [alias] 
		  [print]
	replace [program]
		_ [program]
	by
		% nada
end function

function alias
	replace * [subprogram]
		RE [repeat element]
	deconstruct RE
		SE [element]
		RestRE [repeat element]
	by
		% RE is not copied since this is the last reference.
		RE [bugger]
		% SE is also not copied - this is the bug.
		% It must be copied since SE is an alias to RE.
		SE
end function

function bugger
	replace * [subelement]
		Id [id]
	by
		Id [_ 'MODIFIED]
end function