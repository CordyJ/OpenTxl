% Trivial test of gobal variable paradigm 2: multiple results from a rule

define program
	[repeat id]
end define

function main
    replace [program]
    	P [program]
    construct NewP [program]
    	P [subrule]
    import YesNo [id]
    construct message [id]
    	YesNo [putp "The second result was '%'"]
    by
    	NewP
end function

rule subrule
    export YesNo [id]
    	'No
    replace [id]
    	'Jim
    
    export YesNo
     	'Yes
    
    by
    	'Jane
end rule
