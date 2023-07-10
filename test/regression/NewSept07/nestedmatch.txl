% Test of new [push X], [pop X] defines

% We're interested in the parse
# pragma -xml

define program
    [nestedmatch]
end define

define nestedmatch
    [push id] [repeat nestedmatch] [pop id]
end define

function main
    match * [nestedmatch]
        Bra [id]
            _ [repeat nestedmatch]
        Ket [id]
    deconstruct not Bra
        Ket
    construct Error [id]
        _ [message "*** ERROR, mismatch in push/pop parse"]
end function
