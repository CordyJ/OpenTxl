% Example of use of new 'where all' clause

% This program accepts sequences of input tokens
% (identifiers and numbers) and recognizes only those
% that are *all* the identifier 'Jim'.

define program
    [thing*] 
end define

define thing
    [id] | [number] 
end define

function main
    replace [program]
	AllOfThem [thing*]

    construct Jim [thing]
	'Jim

    % Note the use of the 'where all' form to achieve the 'and' 
    % of the condition - without 'all', the condition would test if
    % *any* of the things were equal to Jim.
    where all
	Jim [= each AllOfThem]

    by
	They were 'all Jims
end function
