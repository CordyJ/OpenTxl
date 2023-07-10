% Test new [ignore] feature
#pragma -Dtokens
tokens
        ignore  "%foobar%"
end tokens

define program
        [repeat token]
end define

function main
        match [program] _ [program]
end function
