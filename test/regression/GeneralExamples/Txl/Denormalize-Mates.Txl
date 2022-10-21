% Normalize Mates formulas
include "Mates.Grammar"

rule main
    replace [program]
	P [formula]
    by
	P [denormalize]
end rule

include "Mates.Denormalize"
