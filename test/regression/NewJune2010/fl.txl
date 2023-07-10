define program
        [nlprogram] [flprogram]
end define

define nlprogram
    [repeat nlline]
end define

define flprogram
    [repeat flline]
end define

define nlline
    [line] [NL] [NL]
end define

define flline
    [line] [FL] [FL]
end define

define line
    [repeat notsemi] ;
end define

define notsemi
    [not ';] [token]
end define

function main
    replace [program]
        NLLines [repeat nlline]
    construct FLLines [repeat flline]
        _ [addLine each NLLines]
    by
        NLLines FLLines
end function

function addLine NLLine [nlline]
    deconstruct NLLine
        Line [line]
    replace * [repeat flline]
    by
        Line
end function
