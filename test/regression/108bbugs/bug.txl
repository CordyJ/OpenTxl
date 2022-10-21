define program
	[pat]
end define

define formal
   	( [list pat] )
   |	[id]
   |	[number]
end define

define pat 
	[formal]
   | 	[pat] + [number]
end define

function main
    match [program]
	P [program]
end function
