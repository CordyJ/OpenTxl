% Parse and pretty print Modula-3 programs

include "Modula3.grm"

function main
    replace [program]
        P [program]
    by
        P    % Add your transformation rules here
end function
