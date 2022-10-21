#pragma -case -xml

keys
    KEY
end keys

define program
    [id] [id]
|   'KEY [id]
end define

function main
    match [program] 
 	_ [program]
end function
