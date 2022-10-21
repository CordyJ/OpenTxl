define program 
    [number]
end define

function main
    construct OKnumbers [repeat number]
    	1 2 3 4 5
    match [program]
    	Number [number]
    assert
    	Number [= each OKnumbers] 
end function
