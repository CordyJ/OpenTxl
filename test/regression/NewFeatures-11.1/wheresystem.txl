define program
    [token*]
end define

function main
    replace [program]
	P [program]
    where
	_ [system "echo 'ok'"]
    where 
	_ [system "test 'x' == 'x'"]
    where not
	_ [system "test 'x' == 'y'"]
    by
	'ok
end function
