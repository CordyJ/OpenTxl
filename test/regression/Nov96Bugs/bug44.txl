	define program
		[repeat id+]
	end define
	
	function main
		replace [program]
			R [program]
		by
			R [bug]
	end function
	
	rule bug
		replace [repeat id]
			X [id]
			More [repeat id]
		by
			More
	end rule
