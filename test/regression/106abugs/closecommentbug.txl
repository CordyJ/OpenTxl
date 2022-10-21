define program
    [token*]
end define

function main
    match [program] _ [program]
%( long comment buggers up
   end of function )% end function
