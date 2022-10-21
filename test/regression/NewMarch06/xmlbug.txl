% Input to this program should be:
% < > & "< & >"
% which outputs invalid XML since the < > and & are not all encoded
#pragma -xml 

define program 
    [repeat token] 
end define 

function main 
match [program] _ [program] 
end function
