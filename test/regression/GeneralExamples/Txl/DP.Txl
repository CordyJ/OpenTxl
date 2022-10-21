% Form the dot product of two vectors,
%	e.g., 	(1 2 3).(3 2 1)  =>  10

define program
	( [repeat number] ) . ( [repeat number] )
    |	[number]
end define

rule main
    replace [program]
	( V1 [repeat number] ) . ( V2 [repeat number] )
    construct Zero [number]
	0
    by
	Zero [addDotProduct V1 V2]
end rule

function addDotProduct V1 [repeat number] V2 [repeat number]
    deconstruct V1
	First1 [number] Rest1 [repeat number]
    deconstruct V2
	First2 [number] Rest2 [repeat number]
    construct ProductOfFirsts [number]
	First1 [* First2]
    replace [number]
	N [number]
    by
	N [+ ProductOfFirsts] [addDotProduct Rest1 Rest2] 
end function

