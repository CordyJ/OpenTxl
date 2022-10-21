% Doubles <item> tag when verbose!
#pragma -xml -newline -v

define program 
        [repeat item] 
end define 

define item 
        'test [NL] 
    |   [newline] 
end define 

function main 
    match [program] 
        P [program] 
end function 
