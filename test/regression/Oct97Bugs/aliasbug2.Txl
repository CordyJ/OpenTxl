% Andrew's alias bug, variant 2
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
		P [alias] 
		  [message "Next line should be: A B C D A_MODIFIED"] 
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
		% This RE is copied since it is not the last reference.
		RE 
		% SE is not copied - this is the bug.
		% It must be copied since SE is an alias to RE,
		% and RE is referenced by the message rule.
		SE [message "The next two lines should be the same"]
		   [message RE] 
		   [bugger] 
		   [message RE]
end function

function bugger
	replace * [subelement]
		Id [id]
	by
		Id [_ 'MODIFIED]
end function