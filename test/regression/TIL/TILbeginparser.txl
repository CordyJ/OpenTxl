% TXL parser for begin-end language extenssion to Tiny Imperative Language
% Jim Cordy, October 2005

% Begin with the standard TIL grammar
include "TIL.grm"

% Add begin-end statements using grammar overrides
redefine statement
        ...                  % refers to all existing forms for [statement]
    |   [begin_statement]    % add alternative for our new form
end redefine

define begin_statement
    'begin                   [IN][NL]
        [statement*]         [EX]
    'end                     [NL]
end define

% No need to do anything except recognize the input, since the grammar
% includes the output formatting cues
function main
   match [program] 
      _ [program]
end function
