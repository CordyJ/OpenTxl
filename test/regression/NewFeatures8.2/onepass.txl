% Trivial test of new one-pass rules

define program
	[repeat id]
end define

rule main
    replace $ [id]
    	AnyId [id]
    by
    	'Jim
end rule
