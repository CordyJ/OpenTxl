% Normalize Mates formulas
include "Mates.Grammar"

function main
    replace [program]
	P [formula]
    by
	P [normalize]
end function

include "Mates.Normalize"
