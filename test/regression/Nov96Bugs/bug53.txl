	define program
		[list thing] ;
	end define
	
	define thing
		[opt id]
	end define
	
	function main
		match * [program] X [program]
	end function
