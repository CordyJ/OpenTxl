% Bugs in built-ins in the presence of -case
% 10.5b 16.04.08
#pragma -case

define program
    [id]
end define

function main
    match [program]
        Id [id]
    construct Lower [id]
        Id [putp "[id]: %"]
	   [tolower] [putp "[tolower]: %"]
    construct Upper [id]
        Id [toupper] [putp "[toupper]: %"]
    construct LowerUpper [id]
        Lower [+ Upper] [putp "[lower+upper]: %"]
    construct UpperLower [id]
        Upper [+ Lower] [putp "[upper+lower]: %"]
    construct Lower_Upper [id]
        Lower [_ Upper] [putp "[lower_upper]: %"]
    construct Upper_Lower [id]
        Upper [_ Lower] [putp "[upper_lower]: %"]
    construct Lower23 [id]
        Lower [: 2 3] [putp "[lower:2:3]: %"]
    construct Upper23 [id]
        Upper [: 2 3] [putp "[upper:2:3]: %"]
end function
