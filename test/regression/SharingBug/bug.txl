% Demonstration that TXL's node sharing strategy is fundamentally flawed
% J.R. Cordy, 4 March 1993

% To demonstrate the problem, feed this program the input 1
% The output should be 6 1 1, but it will be 6 6 6 instead!

define program
        [repeat element]
end define

define element
        [number]
end define

function main
    replace [program]
        P [repeat element]
    by
        P [createAliases]
          [changeFirstAlias]
end function

function createAliases
    % create a DAG with E at the bottom
    replace [repeat element]
        E [element] R [repeat element]
    by
        E E E
end function

function changeFirstAlias
    % now try to change just the first E ...
    replace * [number]
        1
    by
        6
end function
