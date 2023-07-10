define program
    [repeat number]
end define

function main
    replace [program]
        RN [repeat number]
    by
        RN [trybutfail each RN] 
end function

function trybutfail N [number]
    replace [repeat number]
        RN [repeat number]
    construct Result [repeat number]
        RN [trashit N] 
    construct one [number] 1
    where not
        one [= one]
    by
        Result
end function

% external rule print

rule trashit N [number]
    replace [repeat number]
        N 
        RN [repeat number]
    by
        RN
end rule

