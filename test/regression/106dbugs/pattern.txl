#pragma --multiline

% error message for problems in the pattern is hard to understand
% since it just says "Syntax error"

define program
    [thing] [thang] [thong] 
end define

define thing
    [id]
end define

define thang
    [number]
end define

define thong
    [stringlit]
end define

function main
    replace [program] 
	missing "foo"
    by
	missing 7 "bar"
end function
