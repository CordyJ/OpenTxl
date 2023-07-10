% Example of another manifestation of the new bug in sharing.
% In this bug, the replace rule changes a shared pattern variable,
% which is consequently used again in the calling scope.
% Normally this is fine because we would have copied the variable
% in the calling scope in order to apply the rule.
% However, since we don't ever copy vars that we apply conditions to,
% and since the [?] metarule sneakily changes the rule to a match rule,
% we have to be more careful about the side effects
% of these "post constructs" in rules used as match rules via [?].

% JRC 26.10.94

% Suitable input to this program is:
%       Jim Jim Jim
% The output should be unchanged.

define program
    [repeat thing]
end define

define thing
    [id] 
end define

function main
    replace [program]
        Things [repeat thing]
    where
        Things [?willChange]
    by
        Things
end function

rule willChange
    replace [repeat thing]
        'Jim
        MoreThings [repeat thing]
    construct Result [repeat thing]
        MoreThings [$ 'Jim 'OH_NOOOO]
    by
        'Jim 
end rule
