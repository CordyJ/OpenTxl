define program
    [token*]
end define

function main
    replace [program]
	P [program]
    where
	_ [nomatch P]
    construct NewP [program]
	P [noreplace 'test]
    by
	'ok
end function

rule nomatch P [program]
    deconstruct P
	_ [token*]
end rule

rule noreplace Id [id]
    where
	Id [= 'test]
end rule
