% Demonstration of a bug that indicates that quoting does not
% work properly in TXL.  The syntax error in the construct Jimbob
% below is bogus!

define program 
    [repeat predicate]
end define

define predicate
    [id] ( [list xx] )
end define

define xx
    [id]
end define

function main
    match [program]
        _ [repeat predicate]
    construct Jimbo [predicate]
        Jim ( Bo )
    construct Jimbob [predicate]
        Jim ( Nancy, 'Jimbo )
end function

