tokens 
    number    ... | "[+-]\d+" 
end tokens 

define program 
    [integernumber] + [integernumber]
|   [integernumber]
end define

function main
    replace [program] 
        I [integernumber] + J [integernumber]
    by
        I [+ J]
end function
