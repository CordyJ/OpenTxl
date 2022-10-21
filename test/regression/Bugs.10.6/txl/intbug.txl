define program
	[repeat number]
end define

function main
    replace [program]
	Nums [repeat number]
    construct _ [repeat number]
	Nums [message "Inputs"] [print]
    construct Sum [number]
	_ [+ each Nums]
    by
	Sum [message "Output"] [print]
end function
