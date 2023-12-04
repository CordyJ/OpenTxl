% Test of global variable paradigm 1: global tables

define program
	[repeat id]
end define

define table_entry
	[id] -> [id]
end define

function main
    export TranslateTable [repeat table_entry]
    	'Jim -> 'Jane
	'Joe -> 'Josephine
	'James -> 'Janice
    replace [program]
    	P [program]
    by
    	P [translate]
end function

rule translate
    import TranslateTable [repeat table_entry]
    replace [id]
    	Him [id]
    deconstruct * [table_entry] TranslateTable
    	Him -> Her [id]
    by
    	Her
end rule
