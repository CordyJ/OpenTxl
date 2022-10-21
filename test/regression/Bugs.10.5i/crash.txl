% This program crashes TXL 10.5i and earlier due to the
% misinterpretation of -comments as -c
#pragma -comments 
define program [id*] end define 
function main replace [program] P [program] by P end function
