% is this really a bug?

define percent 
    '% 
end define

define program
    [percent]
end define

function main
    match [program] _ [program]
end function
