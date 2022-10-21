% Simplify Mates logic formulas
include "Mates.Grammar"

function main
    replace [program] 
	P [formula]
    by
	P [normalize]
	  [simplify]
	  [denormalize]
end function

include "Mates.Normalize"
include "Mates.Simplify"
include "Mates.Denormalize"
