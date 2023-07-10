% Trivial demonstration of using complex attributes with computed values.

% We demonstrate with the example of attributing every token in
% the input with a number giving its ordinal position in the input sequence.

define program
        [repeat attributedtoken]
end define

% [attr ordinal] indicates that [ordinal] is an optional attribute.
% Attributes are not output unless the -attr command option is given.

define attributedtoken
        [unattributedtoken] [attr ordinal]
end define

define unattributedtoken
        [token]
end define

define ordinal
        ( [number] )    
end define

function main
    replace [program]
        Input [repeat attributedtoken]
    by
        % We can see the attributions in the output 
        % only if the -attr run option is set.
        Input [attributetokens] 
              [enumerateattributions 1]
end function

rule attributetokens
    replace [attributedtoken]
        T [unattributedtoken]
    by
        T ( 0 )
end rule

rule enumerateattributions N [number]
    replace [repeat attributedtoken]
        AT [repeat attributedtoken]
    deconstruct * [attributedtoken] AT
        T [unattributedtoken] ( 0 )
    construct NP1 [number]
        N [+ 1]
    by
        AT [enumerateattribution N] [enumerateattributions NP1]
end rule 

function enumerateattribution N [number]
    replace * [attributedtoken]
        T [unattributedtoken] ( 0 )
    by
        T ( N )
end function

