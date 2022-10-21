% Null transform to test parsing of ifdefed Linux 2.6 sources
include "CLinux.grm"

function main
    match [program]
        P [program]
end function
