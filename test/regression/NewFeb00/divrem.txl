define program
	[repeat pair]
end define

define pair
	[number] [number]
end define

function main
	replace [program]
		Pairs [repeat pair]
	by
		Pairs [printResults]
end function

function printResults
	replace [repeat pair]
		Pair [pair]
		More [repeat pair]
	construct _ [pair]
		Pair [putp "==== %"]
	deconstruct Pair
		N1 [number] N2 [number]
	construct N1slashN2 [number]
		N1 [/ N2] [putp "/ %"]
	construct N1divN2 [number]
		N1 [div N2] [putp "div %"]
	construct N1remN2 [number]
		N1 [rem N2] [putp "rem %"]
	by
		N1 N2
		More [printResults]
end function
