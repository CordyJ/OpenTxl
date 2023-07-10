% Trivial demonstration of a paradigm for applying
% a rule exactly once to each element of a scope of
% arbitrary type, even in cases where the result
% of the rule may match the pattern.

% We demonstrate with the example of annotating every identifer in
% a scope with "_ident", creating new identifiers as we go.
define program
        [repeat token]
end define

function main
    replace [program]
        Input [repeat token]
    by
        Input [annotateidents] 
end function

% The basic trick of the paradigm is to create a sequence of all
% of the identifiers in the scope and then apply the rule to each
% of them.

function annotateidents
    replace [repeat token]
        All [repeat token]
    construct AllIds [repeat id]
        _ [^ All]
    by
        All [annotateident each AllIds]
end function

% It is important that the rule be changed to a searching function.
% That way it will always find the *first* thing to change in the scope,
% i.e., the next one in the sequence of all of them.

function annotateident Id [id]
    replace * [id] 
        Id
    by
        Id [_ 'ident]
end function
