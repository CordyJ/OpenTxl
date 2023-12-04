% Test of global variable paradigm 3: deep parameters

define program
	[repeat id]
end define

function main
    replace * [repeat id]
        First [id] Rest [repeat id]
    export First
    by
    	Rest [delete]
end function

function delete
    replace [repeat id]
        Ids [repeat id]
    by
    	Ids [deleteFirst]
end function

rule deleteFirst
    import First [id]
    replace [repeat id]
    	First Rest [repeat id]
    by
    	Rest
end rule
