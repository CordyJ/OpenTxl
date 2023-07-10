#pragma -char -Dtokens
tokens
    CR  "\r"
    TAB "\t"
    NOTCR  "#r"
end tokens

define program
    [repeat token]
end define

function main
    match [program]
        P [program]
end function
