define program
	[repeat item]
end define

define item
	[notend_item]
    |	[end_item]
end define

define notend_item
	[~ end_item] [token]
end define
 
define end_item
	[NL] 'END 'JIM [: '?] [NL]
end define

function main
    replace [program]
    	P [program]
    by
    	P 
end function
