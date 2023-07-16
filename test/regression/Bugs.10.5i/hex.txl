% new handling of hex number computation on request
tokens
    number | "0[xX][0123456789abcdefABCDEF]+"
end tokens

define program
    [repeat number]
end define

rule main
    replace $ [number]
	N [number]
    by
	N [+ '0x1]
end rule
