include "filenameutils.rul"

define program
    [stringlit*]
end define

rule main
    match $ [stringlit]
        FilePath [stringlit]
    construct _ [stringlit]
        FilePath [putp "FilePath = "]
    construct _ [stringlit]
        FilePath [filename] [putp "filename = "] 
    construct _ [stringlit]
        FilePath [filedir] [putp "filedir = "] 
    construct _ [stringlit]
        FilePath [filerootname] [putp "filerootname = "] 
    construct _ [stringlit]
        FilePath [filetype] [putp "filetype = "] 
    construct _ [stringlit]
        FilePath [filereverse] [putp "filereverse = "]
end rule
