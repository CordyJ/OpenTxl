% exhaustive test of repeat splicing using the [.]
% built-in rule

define program
        [repeat number] ; [repeat number+] ; [number]
    |   [repeat number]
end define

function main
    replace [program]
        L1 [repeat number] ; L2 [repeat number+] ; L3 [number]
    construct T1 [repeat number]
        L1 [. L1] [print]
    construct T2 [repeat number]
        L1 [. L2] [print]
    construct T3 [repeat number]
        L2 [. L2] [print]
    construct T4 [repeat number]
        L2 [. L1] [print]
    construct T5 [repeat number]
        L1 [. L3] [print]
    construct T6 [repeat number]
        L2 [. L3] [print]
    by
        L1 [. L2] [. L3]
end function

% external rule print
