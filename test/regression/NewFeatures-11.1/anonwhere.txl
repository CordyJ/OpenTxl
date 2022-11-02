define program
    [token*]
end define

function main
    replace [program] 
	_ [program]
    where _ [ok]
    where not _ [notok]
    by
	'ok
end function

function ok
    match [any] _ [any]
end function

function notok
    match [id] 'NOSUCHID
end function
