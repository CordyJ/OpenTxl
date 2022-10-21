define program
        [number]
end define

function main
    replace [program]
        N [number]
    construct N1000 [number]
	N [* 1000] [print]
    by         
        N [trunc]
end function
