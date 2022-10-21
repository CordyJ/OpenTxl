define program
	[repeat idorlits]
end define

define literals
	[repeat id] 
end define

define idorlits
    	[id]
    |	[literals]
end define

rule main
    replace [program]
	% an empty one
    by
	Jim
end rule

