% Demonstrates a bug in the new [parse] built-in function.
% The representation of strings, as output, puts backslashes
% before quotes.  This renders them unparseable!

% external function unparse X[any]
% external function parse X[stringlit]
% external function print

define program
    [repeat num_char]
end define

define num_char   
    [number] [charlit]
end define

rule main   
    replace [program]
	cl [num_char] 
	rest [repeat num_char]
    construct X [stringlit] 
	_ [unparse cl] [print]
    construct ccc [num_char]
	0 '''
    construct numb [num_char] 
	ccc [parse X]
    by 
	rest
end rule
