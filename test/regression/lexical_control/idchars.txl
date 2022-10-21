% This demonstrates a safer way to allow other
% characters in identifiers, using the -idchars option.
% It also demonstrates treating characters as white space.
% In this case ';'.

#pragma -idchars '-+#$%' -spchars ';'

tokens
    hexnumber	"[\dabcdefABCDEF]+H"
    octalnumber	"0[01234567]*"
end tokens

define program
    [thing*] 
end define

define thing
    [id] | [number] | [hexnumber] | [octalnumber]
end define

rule main
    replace [thing*]
	H [hexnumber]
	Rest [thing*]
    by
	0777
	Rest
end rule
