% With input "tigger item pooh" 
% This program yields "tigger item item pooh" instead of "tigger item pooh"
define item 
    tigger | pooh | [id] 
end define 

define program 
    [repeat item] 
end define 

function main 
    replace [program] 
	    P [program] 
    construct Q [repeat item] 
	_ [^ P] 
    by 
	Q 
end function
