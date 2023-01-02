define program
    [token*]
end define

function main
    replace [program]
	P [program]

    construct ABC [id*]
	'a 'b 'c
    construct AAA [id*]
	'a 'a 'a
    construct XYZ [id*]
	'x 'y 'z
    construct Empty [id*]
	_

    % one
    where 
	_ [hasProperty each ABC AAA]
    % all
    where all 
	_ [hasProperty each ABC ABC]
    % not
    where not
	_ [hasProperty each ABC XYZ]
    % not all
    where not all
	_ [hasProperty each ABC AAA]
    % empty
    where 
	_ [hasProperty each Empty Empty]
    % mixed
    where not 
	_ [hasProperty each AAA Empty]

    by
	'ok
end function

function hasProperty Id1 [id] Id2 [id]
    deconstruct Id1
	Id2
end function
