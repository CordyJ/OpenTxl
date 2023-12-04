define program
    [repeat number]
end define

rule main
    export Table [repeat number]
    	1 2
	3 4
	5 6 
	7 8
	9 10
    replace * [repeat number]
        Numbers [repeat number]
    construct NewNumbers [repeat number]
        Numbers [changeAccordingToTable]
    deconstruct not NewNumbers
    	Numbers
    by
    	NewNumbers
end rule

rule changeAccordingToTable
    import Table [repeat number]
    	First [number] Second [number] 
	Rest [repeat number]
    replace [number]
    	First
    export Table
    	Rest
    by
    	Second
end rule
