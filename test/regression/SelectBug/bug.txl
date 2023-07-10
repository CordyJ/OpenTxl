#pragma -Dfinal
define program 
        [repeat thingie] : [number] [number]
    |   [repeat thingie]
end define

define thingie
    [number] | [id]
end define

% external rule select L [number] U [number]

rule main
    replace [program]
        RT [repeat thingie] : Lower [number] Upper [number]
    by
        RT [select Lower Upper]
end rule

    
