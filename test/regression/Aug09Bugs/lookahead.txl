% Test of new lookahead token scanning feature
% Distinguish Fortran .op. from 3. numbers
tokens
        Dop     ".\a+."
        Rcon    "\d+.\:[\s\)\n]"
        Icon    "\d+"
end tokens

define program
        [repeat tokenSP]
end define

define tokenSP
        [token] [SP]
end define

function main
        match [program] _ [program]
end function

