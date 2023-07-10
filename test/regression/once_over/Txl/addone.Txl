% Trivial demonstration of a paradigm for applying a rule exactly once 
% to each element of a scope of arbitrary type, even in cases where 
% the result of the rule may match the pattern.

% We demonstrate with the example of adding one to every [number] in the scope,
% using an attribute to mark each one as it is done so that we don't re-do
% any.

define program
        [repeat attributedtoken]
end define

define attributedtoken
        [number] [attr 'DONE]
    |   [id]
    |   [stringlit]
end define

% % external function message M [stringlit]
% % external function print

function main
    replace [program]
        Input [repeat attributedtoken]
    by
        Input [message "Original input:"] [print]
              [addonetonumbers] 
              [message "Final output:"]
end function

rule addonetonumbers
    % Note that the pattern does not allow an attribute, so we match
    % only items we have not yet done.
    % The replacement then adds the attribute so that we remember we
    % have done this one and don't match it again.
    replace [attributedtoken]
        N [number]
    by
        N [+ 1] DONE
end rule
