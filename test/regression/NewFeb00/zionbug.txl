
define program
	[repeat id]
end define

function isEmpty
	match [repeat id]
end function

function matchAandmore
	match [repeat id]
		'a moreAndMore [repeat id]
	where
		moreAndMore [isEmpty] [matchAandmore]
end function

function main
	replace [program]
		P [repeat id]
	where
		P [matchAandmore]
	by
		P
end function


