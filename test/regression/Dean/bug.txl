
%% simple left recursion.  Not even a loop between exp4 and exp3.

% external function message M [any]

define program
    [exp3]
end define

define exp3
       [exp4]
     | [exp3] [exp4] [attr 'c ]	%% simple left recursion for left assoc
end define

define exp4
    [id]
end define

function main
   replace [program]
       P [program]
    by
       P [checkFunCall] [message '"done"]
end function

rule checkFunCall
    replace [exp3]
       F [exp3] A [exp4] 
    by
       F [message '"found func application"] A 'c
end rule
