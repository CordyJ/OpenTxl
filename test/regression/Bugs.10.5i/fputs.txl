% Missing [puts] and [fputs] functions in TXL 10.5i
define program
    [repeat token]
end define

function main
    match [program]
        _ [program]
    construct CopyFiles [id]
        _ [CopyLines "fputsinput.txt" "fputsoutput.txt"]
end function

rule CopyLines InputFile [stringlit] OutputFile [stringlit] 
    % we ignore our scope, so just pass it through 
    replace [any]
        Scope [any]
    % get the next line from our input file 
    construct NextInputLine [stringlit]
        _ [fgets InputFile]
    % if it's empty we're done 
    deconstruct not NextInputLine
        "" 
    % output it to our output file
    construct NextOutputLine [stringlit] 
        NextInputLine [fputs OutputFile]
                      [puts]  % show result for testing
    by 
        Scope
end rule
