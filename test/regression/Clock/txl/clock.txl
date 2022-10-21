include "clock.grm"
include "gtml.grm"

include "doImports.i"
include "unravelFunDefs.i"
include "coalesceEquations.i"
include "depattern.i"
include "fixupExpressions.i"
include "toGtml.i"

function simplify
    replace [program]
	P [program]
    by
	P [doImports] [unravelFunDefs] [coalesceEquations] [depattern]
	    [fixupExpressions] [toGtml]
end function

function main
    replace [program]
	P [program]
    by
	P [simplify]
end function
