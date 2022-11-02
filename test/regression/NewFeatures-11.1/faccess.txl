define program
    [token*]
end define

function main
    replace [program]
	P [program]
    where
	_ [faccess "eg.faccess" "get"]
    where not 
	_ [faccess "no file like this" "get"]
    where 
	_ [faccess "newfile.txt" "put"]
    by
	'ok
end function
