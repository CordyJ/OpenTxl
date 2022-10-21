% Sum.Txl - demonstration of user % % % external rules

% Part I.  Syntax specification
define program
	[number]
end define


% Part 2.  Transformation rules
rule main
    replace [program]
	N [number]
    construct Command [id]
	_ [getid]
    where 
	Command [= 'double] [= 'triple]
    by
	N [docommand Command]
end rule

function docommand C [id] 
    replace [number]
	N [number]
    by
	N [dodouble C] [dotriple C]
end function

function dodouble C [id]
    deconstruct C
	double
    replace [number]
	N [number]
    by
	N [sum N N 0]
end function 

function dotriple C [id]
    deconstruct C
	triple
    replace [number]
	N [number]
    by
	N [sum N N N]
end function 

% % % external rule getid
% % % external rule sum N1 [number] N2 [number] N3 [number]
