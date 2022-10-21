% Example of use of new 'where all' clause
define program
    [thing*] 
end define

define thing
    [id] | [number] 
end define

function main
    replace [program]
	AllOfThem [thing*]
    construct Jim [thing]
	'Jim
    where all
	Jim [= each AllOfThem]
    by
	They were 'all Jims
end function
