% Trivial test of deconstruct not

define program
	[repeat id]
end define

rule main
    replace [program]
    	P [program]
    construct NewP [program]
    	P [doit]
    deconstruct not NewP
    	P
    by
    	NewP
end rule

rule doit
    replace [repeat id+]
    	Rid [repeat id+]
    deconstruct not * [id] Rid
    	'Jim
    by
    	'Jim
end rule
