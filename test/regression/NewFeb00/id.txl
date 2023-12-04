define id
	...
    |	'{ [id] '}
end define

define program
	[repeat id]
end define

function main
	replace [program]
		P [program]
	by
		P [hotspot 'Jim]
end function

rule hotspot Id [id]
	replace $ [id]
		Id
	by
		'{ Id '}
end rule
