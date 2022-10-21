% Test of TXL Pro standard externals getp, putp, parse, unparse, index

% Standard externals headers

% include "TxlExternals"

define program
    [repeat thing]
end define

define thing
    [id] | [stringlit] | [number] | ( [repeat thing] )
end define

function main
    match [program]
	Things [repeat thing]

    % Testing put, getp, putp

    construct Doodly [repeat thing]
	Things [message "Here are the things from which to choose:"] [put]

    construct EmptyT [thing]
	'nada

    construct T [thing]
	"five" %% EmptyT [getp "From which of these things would you like me to output? "]

    construct Ans [thing]
	T [putp "From %, then"] %% [getp "Is that right (y/n)? "]

    %% deconstruct Ans
	%% 'y

    % Testing unparse

    construct TString [stringlit]
	_ [unparse T] 

    construct ThingsString [stringlit]
	_ [unparse Things] 

    % Testing index

    construct Position [number]
	_ [index ThingsString TString] 

    construct NewThingsString [stringlit]
	ThingsString [: Position 999] 

    % Testing parse

    construct NewThings [repeat thing]
	_ [parse NewThingsString]

    construct Output [repeat thing]
	NewThings [putp "So here they are then: '%', and there they went!"]
end function
