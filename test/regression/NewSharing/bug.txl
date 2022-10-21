% Example of one manifestation of a new bug in sharing.
% In this bug, the match rule changes a shared pattern variable,
% which is consequently used again in the calling scope.
% Since we don't ever copy vars that we apply conditions to,
% we have to be more careful about the side effects
% of these "post constructs" in match rules.

% JRC 26.10.94

% Suitable input to this program is:
%	Jim Jim Jim
% The output should be unchanged.

define program
    [repeat thing]
end define

define thing
    [id] | [number] | [stringlit]
end define

function main
    replace [program]
	Things [repeat thing]
    where
	Things [willChange]
    by
	Things
end function

rule willChange
    match [repeat thing]
	'Jim
	MoreThings [repeat thing]
    construct Result [repeat thing]
	MoreThings [$ 'Jim 'OH_NOOOO]
end rule
