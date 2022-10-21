% Trivial demonstration of counting items in TXL.
% This same recursive paradigm can be used, for example,
% to number testpoints in a test harness transform.

define program
        [repeat item]
end define

define item
	[opt number_colon] [id] [NL]
end define

define number_colon
	[number] :
end define

function main
    replace [program]
	P [program]
    by
	P [createLabels]
	  [enumerateLabels 1]
end function

rule createLabels
    replace [item]
	Item [id]
    by
	0 : Item
end rule

function enumerateLabels K [number]
    replace [program]
	P [program]

    % Make sure that there is one left to enumerate
    deconstruct * [number_colon] P
	0 :

    % Compute the number of the next one of the rest
    construct KP1 [number]
	K [+ 1]

    % OK, number this one and recursively number the rest
    by
	P [renumberLabel K] 
	  [enumerateLabels KP1]
end function

function renumberLabel K [number]
    replace * [number_colon]
	    0 :
    by
	    K :
end function
