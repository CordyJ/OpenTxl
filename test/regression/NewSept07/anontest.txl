% Test of anonymous improvements and multiline comments in TXL 10.5
define program 
    [repeat item]
end define

define item
    [id] | [number] | [jimbo]
end define

tokens
    jimbo "\#\a+"
end tokens
    
function main
    replace * [repeat item]
        Items [repeat item]
    construct NewId [id]
        _ [+ "theid"]
    construct NewItem [item]
	NewId
    construct NewJimbo [jimbo]
       _ [+ "#jimbo"]
    construct NewJimboItem [item]
	NewJimbo
    by
        _ [. each Items] [. NewItem] [. NewJimboItem]
end function
