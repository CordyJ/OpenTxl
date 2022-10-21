#pragma -analyze

% need to detect repeats of possibly empty things
define program
    [x*]
end define

define x
    [y?] [x_y*]
end define

define y
    [id]
end define

define x_y
    [x] '_ [y]
end define

function main
    match [program] _ [program]
end function
