% Trivial demonstration of using attributes to mark items.

% We demonstrate with the example of attributing every token in
% the input with an attribute indicating if it is a representation
% of the number 1,  e.g., 1, one, "one", "1", and replacing
% every such item with the number 1.

define program
        [repeat attributedtoken]
end define

% [attr 'IS_ONE] has the same meaning as [opt 'IS_ONE] except that
% it never appears in output unless the -attr flag is given.

define attributedtoken
        [unattributedtoken] [attr 'IS_ONE]
end define

define unattributedtoken
        [id]
    |   [number]
    |   [stringlit]
end define

% external function message M [stringlit]
% external function printattr
% external function print

function main
    replace [program]
        Input [repeat attributedtoken]
    by
        % Show the original input ...
        Input [message '"Original input:"] [print]      
            % ... we can see the attribution with [printattr] ...
            [attributeOnes] [message '"Attributed input:"] [printattr] 
            % ... and convert all tokens attributed IS_ONE to 1
            [normalizeOnes] [message '"Normalized output:"] 
end function

rule attributeOnes
    replace [attributedtoken]
        AT [attributedtoken]
    where
        AT [?attributeids] [?attributestrings] [?attributenumbers]
    by
        AT [attributeids]
           [attributestrings]
           [attributenumbers]
end rule

function attributeids
    % We only attribute those ids that are equal to IS_ONE
    replace [attributedtoken]
        Id [id]
    where
        Id [= 'one] 
    by
        Id 'IS_ONE
end function

function attributestrings
    % We only attribute those strings that are equal to IS_ONE
    replace [attributedtoken]
        S [stringlit]
    where
        S [= '"1"] [= '"one"]
    by
        S 'IS_ONE
end function

function attributenumbers
    % We attribute those number that are equal to IS_ONE
    replace [attributedtoken]
        N [number]
    where
        N [= 1] 
    by
        N 'IS_ONE
end function

rule normalizeOnes
    % We turn everything attributed as IS_ONE into the literal number 1.
    replace [attributedtoken]
        T [unattributedtoken] 'IS_ONE
    by
        1
end rule
