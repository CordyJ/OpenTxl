define program
    [empty]
end define

function main
    match [program] _ [program]
    construct NumberInString [stringlit] 
	"27" 
    % This fails due to newline in parse string
    construct Number [number] 
        _ [parse NumberInString]
end function
