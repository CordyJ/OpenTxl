% Test of long comments
define program %( this stuff is a comment 
    crap crap define crap rule crap
    more ignored define keys crap )% [repeat item] % but not that
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
