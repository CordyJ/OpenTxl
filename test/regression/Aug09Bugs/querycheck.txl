
include "Turing.grm" 

function main 
    replace [program] 
        Statements [repeat declaration_or_statement] 
    deconstruct * [statement] Statements 
        Id [id] := Expn [expn] 
    % This where clause calls transformAssignments without the first argument, 
    % but TXL does not notice 
    where 
        Statements [?transformAssignments each Statements] 
    by 
        Statements [transformAssignments Id each Statements] 
end function 

function transformAssignments X [id] Statement [declaration_or_statement] 
    construct _ [id]
 	X [putp "X is '%'"]
    deconstruct Statement 
        X := _ [expn] 
    replace * [declaration_or_statement] 
        Statement 
    by 
        'AssignmentTo (X) 
end function
