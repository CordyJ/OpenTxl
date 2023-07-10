define program
    [repeat item]
end define

define item
    [id] | [stringlit] | [charlit]
end define
    
function main
    replace [program]
        P [repeat item]
    %% construct S [stringlit]
        %% _ [gets]
    construct FS [stringlit]
        _ [fgets "fileeg.stringin"]
    by
        %% S
        FS
end function
