% Trivial demonstration of the easy paradigms for conversion
% between lists and sequences

% include "TxlExternals"

% We begin with either a list or a sequence, and output both

define program
	[repeat number]
    |	[list number]
    |	[list number] ; [repeat number]
end define

function main
    replace [program]
	Input [program]
    by
	Input [message ">> Input is:"] [print]
	      [convertLists] 
	      [convertSequences]
	      [message ">> Output is:"]
end function

function convertLists
    replace [program]
	L [list number]

    % The easy paradigm for converting a list to a sequence -
    % simply append each element of the list onto a new sequence.

    construct S [repeat number]
	_ [. each L]

    by
	L ; S
end function

function convertSequences
    replace [program]
	S [repeat number]

    % The easy paradigm for converting a sequence to a list -
    % simply append each element of the sequence onto a new list.

    construct L [list number]
	_ [, each S]

    by
	L ; S
end function
