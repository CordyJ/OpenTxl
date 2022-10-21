%%
%%	CPS Translator
%%
%%	T.C. Nicholas Graham
%%	GMD Karlsruhe
%%	August 24, 1992
%%
%%	Maps a GTML program into continuation passing style.
%%

include "gtmlcps.grm"

% include "addContinuationParameter.i"
include "introduceCpsRequests.i"
include "optimize.i"

function main
    replace [program]
	P [program]
    by
	P [introduceCpsRequests]
	  [optimize]
end function
