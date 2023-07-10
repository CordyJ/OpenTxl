% Parser and pretty-printer for Oberon
% J.R. Cordy, October 2010

% Use Oberon grammar with formatting cues
include "oberon.grm"

% Optionally preserve comments - to enable, use -comment on command line
include "oberon-comments.grm"

% Null transformation
function main
    match [program] 
        _ [program]
end function

