
#pragma -char -comment -esc '\\' -width 32767

% This shuld be accepted
tokens
        comment  "/\*#(\*/)*\*/"
end tokens

define program
    [repeat token]
end define

function main
        match [program]
                P [program]
end function
