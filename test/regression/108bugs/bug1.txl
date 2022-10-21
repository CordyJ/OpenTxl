#pragma -Dtokens

tokens
    % unfortunately this override does not work, due to priority of [id] built-in token
    stringlit "L?\"#\"*\""
end tokens

define program
    [repeat token]
end define

function main
    match [program] _ [program]
end function
