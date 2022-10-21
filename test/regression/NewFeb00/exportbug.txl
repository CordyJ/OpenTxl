% Example of a subtle bug in TXL 2.4d8's optimization
% of recursive exports.  Output should be "GOOD".

define program
	[repeat anid]
end define

define anid
	[id]
end define

function main
	replace [program]
		P [program]
	export X [anid]
		'GOOD
	construct NewP [program]
		P [r1]
	import X
	by
		NewP
end function

function r1
	import X [anid]
	construct NotX [id]
		_ [r2]
	replace [program] P [program]
	by X
end function

rule r2
	import X [anid]
	construct NotX [id]
		'BAD
	replace [id] '_
	export X
		X [replaceby NotX]
	by 'BOZO
end rule

function replaceby Y [id]
	replace * [id]	
		_ [id]
	by
		Y
end function

