define program
    [repeat number]
end define

% should not change input!
function main
    replace [program]
        RN [repeat number]
    by
        RN [trybutfail] 
end function

function trybutfail 
    replace [repeat number]
        RN [repeat number]
    construct Result [repeat number]
        RN [trashit]
    construct one [number] 1
    where not
        one [= one]
    by
        Result
end function

% external rule print

rule trashit 
    replace [repeat number]
        2
        RN [repeat number]
    by
        RN
end rule

