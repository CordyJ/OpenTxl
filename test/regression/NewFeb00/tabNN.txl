define program
	[repeat idpair]
end define

define idpair
	[id] [TAB_10] [id] [NL]
end define

function main
	match [program] _ [program]
end function
