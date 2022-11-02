define program
    [token*]
end define

function main
    match [program] _ [program]
    where _ [ok]
    construct _ [id]
	_ [message "ok"]
    where not _ [ok]
    construct _ [id]
	_ [message "not ok"]
end function

function ok
    match [any] _ [any]
end function
