% Test of TXL Pro standard external reparse

% Standard externals headers
% include "TxlExternals"

define program
	[repeat thing]
    |	[repeat thang]
end define

define thing
    [id] | [stringlit] | [number] | ( [repeat thing] )	% note nested brackets
end define

define thang
    [id] | [stringlit] | [number] | ( | )		% note unstructured brackets
end define

function main
    replace [program]
	Things [repeat thing]

    % Turn nested parse of input into unnested form
    construct Thangs [repeat thang]
	_ [reparse Things]

    % Now fiddle with it
    construct NewThangs [repeat thang]
	( Thangs 

    construct Ket [thang]
	)

    construct NewNewThangs [repeat thang]
	NewThangs [. Ket] 

    % And reparse the result into nested form
    construct NewThings [repeat thing]
	_ [reparse NewNewThangs] 

    by
	NewThings
end function
