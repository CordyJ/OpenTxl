define program
	[id*]
end define

function main
	match [program]
	    P [program]
	export Ntokens [number]
	    0
	construct Counter [program]
	    P [countTokens] 
   	import Ntokens
    	construct _ [number]
	    Ntokens [putp "% ids were processed"]
end function

rule countTokens
	match $ [id]
	    _ [id]
	import Ntokens [number]
	export Ntokens 
	    Ntokens [+ 1] [put]
end rule
