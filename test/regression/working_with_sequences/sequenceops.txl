% Demonstration of working with sequences in TXL 8
% using the [length], [head], [tail] and [select] built-in 
% % external functions.

define program 
    	[repeat thingie]
end define

define thingie
    [number] | [id]
end define

% include "TxlExternals"

rule main
    replace $ [program]
	Input [repeat thingie] 

    construct Output [repeat thingie]
	Input [putp "The sequence we are working with is '%'"]

    % Built-in function to get length of a sequence
    construct InputLength [number]
	_ [length Input] [putp "The length of the sequence is %"]

    construct Bounds [repeat number]
	2 4 %% _ [getp "What subsequence would you like (first last)? "]

    % Paradigm for getting the first of a sequence
    deconstruct * [number] Bounds
	FirstBound [number]

    % And the last
    deconstruct * [repeat number] Bounds
	LastBound [number]
    construct message [number]
        FirstBound [putp "First is %"]
    construct message2 [number]
        LastBound [putp "Last is %"]
	
    % Built-in head function
    construct UpToFirstBound [repeat thingie]
	Input [head FirstBound] [putp "The subsequence up to your first is: %"]

    % Built-in tail function
    construct FromLastBound [repeat thingie]
	Input [tail LastBound] [putp "The subsequence from your last to end is: %"]

    % And general built-in select function
    by
	Input [select FirstBound LastBound] [message ""]
end rule

    
