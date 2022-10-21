% CRASHES TXL in checkRuleCallScopes 
% Should get syntax error - JRC
#pragma -char -esc "\\" 
define program 
        [stringlit] 
end define 

function main 
        construct Newline [newline] 
	    _ [parse ""]
        match [program] 
                S [stringlit] 
end function
