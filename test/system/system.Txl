% Trivial demonstration of use of the [pipe] and [system]
% external functions on Unix systems.

include "System"

define program
        [repeat thing]
end define

define thing
        [stringlit]     [NL]
    |   [id]            [NL]
    |   [number]        [NL]
end define

function main
    replace [program]
        Stuff [repeat thing]
    by
        Stuff   [message "before:"] [print] 
                [join] 
                [usort]
                [message "after:"] 
end function

rule join
    replace [repeat thing]
        N1 [number] N2 [number] Rest [repeat thing]
    construct NewNS [stringlit]
        _ [quote N1] [+ " + "] [quote N2] [pipe "sed 's/ + //'"] 
    construct NewN [number]
        _ [parse NewNS]
    by
        NewN Rest
end rule

function usort 
    replace [repeat thing]
        Things [repeat thing]
    by
        Things  [write "Jimbo"] 
                [system "sort -u < Jimbo > Jambo"] 
                [read "Jambo"]
                [system "rm Jimbo Jambo"]
end function

