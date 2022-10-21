define program
    [repeat number]
end define

function main
    construct X [id]  
		% HUH?  Recursive def'n
		X [doanything]
    construct UseX [id]
		X 
	match [program]
		P [program]
end function

function doanything
    replace [id]
		'Jim
    by
		'Jane
end function
