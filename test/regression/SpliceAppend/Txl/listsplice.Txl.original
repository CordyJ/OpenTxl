% exhaustive test of list splicing using the [,]
% built-in rule

define program
        [list number] ; [list number+] ; [number]
    |   [list number]
end define

function main
    replace [program]
        L1 [list number] ; L2 [list number+] ; L3 [number]
    construct T1 [list number]
        L1 [, L1] [print]
    construct T2 [list number]
        L1 [, L2] [print]
    construct T3 [list number]
        L2 [, L2] [print]
    construct T4 [list number]
        L2 [, L1] [print]
    construct T5 [list number]
        L1 [, L3] [print]
    construct T6 [list number]
        L2 [, L3] [print]
    by
        L1 [, L2] [, L3]
end function

% external rule print
