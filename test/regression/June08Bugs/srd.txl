% Powerbuilder Transformer
% Steve O'Hara
% Trinity Millennium Group, Inc.
% June 3, 2008
%

include "pb-srd.grm"

function main
    replace [program]
        PGM [repeat srd_statement]
    by
        PGM
end function

