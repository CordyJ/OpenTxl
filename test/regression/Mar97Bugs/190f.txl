define entry
	[id] [value]
end define

define value
	{ [repeat id] }
end define

define program
	{ [repeat entry] } [repeat id]
end define

function main
	replace [program]
		{ Table [repeat entry] } Ids [repeat id]
	by
		{ Table } 
		Ids [lookup Table]
			[lookup Table]	%%
			[lookup Table]	%%
			[lookup Table]	%%
			[lookup Table]	%%
			[lookup Table]	%%
end function

%%rule lookup Table [repeat entry]
function lookup Table [repeat entry]
	%%replace [repeat id]
	replace * [repeat id]
		Id [id]
		MoreIds [repeat id]
	deconstruct * [entry] Table
		Id { Value [repeat id] }
	by
		Value [print]
			  [. MoreIds]
%%end rule
end function
