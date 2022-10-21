tokens
    notblank   "#[ \n]+"   % this causes bad line numbers
end tokens

define program
    [repeat word]
end define

define word
    [srclinenumber]      % this shows the bad line numbers
    [notblank]
    [NL]
end define

function main
    match [program]
   _ [program]
end function

