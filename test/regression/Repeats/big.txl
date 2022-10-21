% Demonstration of working with sequences in TXL Pro
define program 
    	[repeat thingie]
end define

define thingie
    [number] | [id]
end define

rule main
    replace [program]
	Input [repeat thingie] 

    by
	Input [. Input]
end rule

    
