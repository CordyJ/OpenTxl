define idlist 
	[opt number] [opt number] [list id] ; [NL]
end define

define program
	[repeat idlist]
end define

function main
	replace [program]
		List [list id] ;
		Indexes [repeat idlist]
	construct LengthList [number]
		_ [length List]
	by
		1 LengthList List ;
		Indexes [testSelect List]
end function

function testSelect List [list id]
	replace [repeat idlist]
		N1 [number] N2 [number] ;
		More [repeat idlist]
	by
		N1 N2 List [select N1 N2] ;
		More [testSelect List]
end function
