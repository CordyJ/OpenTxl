define program
      [repeat token]
end define
    
% If the type to be [reparse]ed contains literal TXL keywords, such as "not":
define stuff 
    'not 'junk
end define

% The when [reparse]ing it as tokens, the parse can fail:
function main
    construct Stuff [stuff]
        'not 'junk
    construct TokensOfStuff [repeat token]
        _ [reparse Stuff]
    match [program] _ [program]
end function

function dummy
    replace [program] _ [program]
    construct X [id]
	'bar
    where not X [= 'foo]
    by
end function

