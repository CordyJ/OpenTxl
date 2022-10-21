
#pragma -in 2
 
include "delphi.grm"

include "delphi_comment_overr.grm"


define program
    [delphi_file]
end define

function main
    replace [program]
        P [delphi_file]
    by
        P
end function
