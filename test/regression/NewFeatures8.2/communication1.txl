% Test of global variable paradigm 4: communication between parent and subrules

define program
	[repeat id]
end define

define yesno
	'yes | 'no
end define

function main
    replace * [repeat id]
    	Ids [repeat id]
    by
    	Ids [ParentRule]
end function

rule ParentRule
	replace [repeat id]
		Ids [repeat id]
	construct NewIds [repeat id]
		Ids [Subrule]
	import OK [yesno]
	deconstruct OK
		'yes
	by
		NewIds
end rule

rule Subrule
	export OK [yesno]
		'no
	replace [repeat id]
		Ids [repeat id]
	deconstruct * [id] Ids
		'Jim
	deconstruct not * [id] Ids
		'WithJim
	
	export OK
		'yes
	
	by
		Ids [. 'WithJim]
end rule

