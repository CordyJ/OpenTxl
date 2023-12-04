% This demonstrates a bug in the combination of a left recursive
% and right recursive production.  For some reason we seem to
% lose some of the input altogether in this case.

% input file should be :  a (b)

compounds
    =>	
end compounds

define program
      [predicate]
end define

% This works fine if the alternatives are reversed,
% but this way round we lose the initial [expression]
% when backtracking out of the first case
define predicate
      [expression] '=>  [predicate]		%%R
    | [expression] 
end define

define expression
      [expression] [subexpression]
    | [subexpression]
end define

define subexpression
      [id] 
    | '( [expression] ')
end define

function main
    match [program]
	P [program]
end function
