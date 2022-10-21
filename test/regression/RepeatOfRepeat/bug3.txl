keys
BEGIN
END 
end keys

define program
	BEGIN
	[repeat idorlits]
	END
end define

define literals
	[repeat id] 
end define

define idorlits
    	[id]
    |	[literals]
end define

rule main
    match [program]
	P [program]
end rule

