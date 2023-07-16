% Null transform - format output according to grammar
include "C.grm"

% Comment out this line to disallow Gnu gcc extensions
include "CGnuOverrides.grm"

% Comment out this line to disallow parsing of comments
include "CCommentOverrides.grm"

function main
    match [program]
        _ [program]
end function
