define program
	[upperid]
end define

function main
    match [program]
	Id [upperid]
    construct _ [upperid]
	Id [putp "Success! % is an [upperid]"]
end function
