% Test of fence [!] backtrack limiter

define program
    	[opt longstuff] [TAB_10] [repeat shortstuff]
end define

define program2
    	[opt longstuff2] [repeat shortstuff]
end define

define longstuff
    	[repeat token] [!] [NL] '. [NL]
end define

define longstuff2
    	[repeat token] [NL] '. [NL]
end define

define shortstuff
	[token]
end define

function main
    replace [program] 
    	P [program]
    by 
    	P [message "NOFENCE"]
	  [andReparseP]
	  [message "FENCE"]
end function

function andReparseP
    match [program]
    	P [program]
    construct Preparse [opt program2]
    	_ [reparse P] [print]	
end function
