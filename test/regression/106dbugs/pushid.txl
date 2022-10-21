% when compiled to ctxl, push/pop stop working

define program
	[push id] [notpopid*] [pop id]
end define

define notpopid
	[not popid] [token]
end define

define popid
	[pop id]
end define

function main
	match [program] _ [program]
end function
