define stuff
    [id]
end define

% this redefine kills TXL
redefine stuff
    ...
end redefine

define program
    [repeat stuff]
end define

function main
    match [program] _ [program]
end function
