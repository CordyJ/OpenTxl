% Parse and pretty print Java code 

include "Java.grm"
include "JavaCommentOverrides.grm"

function main
	replace [program] 
        P [program]
    by
        P    % Add your transformation rules here
end function
