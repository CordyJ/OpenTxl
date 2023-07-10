% Another example of a bug in sharing.
% In this bug, the second rule changes a shared pattern variable,
% but then fails.  The variable is consequently used again in the 
% calling scope but has been changed.

% JRC 12.4.96

% Suitable input to this program is:
%       Jim Jim Jim
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
    by
        Things [willChange]
end function

function willChange
    replace [repeat thing]
        'Jim
        MoreThings [repeat thing]
    construct ChangedThings [repeat thing]
        MoreThings [$ 'Jim 'OH_NOOOO]
    construct One [number]
        1
    where not
        One [= One]
    by 
        % unreachable
end function
