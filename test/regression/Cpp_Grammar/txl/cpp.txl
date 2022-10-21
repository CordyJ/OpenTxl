% Parse and pretty print ANSI C++ programs

include "Cpp.grm"
include "CppCommentOverrides.Grm"

function main
    replace [program]
        P [program]
    by
        P    % Add your transformation rules here
end function

