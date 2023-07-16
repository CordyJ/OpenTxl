define program
	[repeat item]
end define

define item
	[opt id]
end define

function main
	replace [program]
		P [program]
	construct Try [program]
		P [try]
	import Item [item]
	by
		Try [message "Next two lines should read: EXPORT RESULT"]
		    [message Item]
end function

function try
	replace [program]
		Item [item]
		RestItems [repeat item]
	export Item [item]
		'EXPORT
	by
		Item [bugger]
end function

function bugger
	replace * [id]
		Id [id]
	by
		'RESULT
end function