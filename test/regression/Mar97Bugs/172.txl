define program
	[repeat id]
end define

rule main
	replace $ [repeat id]
		X [id]
	by
		X X
end rule
