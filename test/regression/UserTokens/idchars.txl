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
	Rest
end rule
