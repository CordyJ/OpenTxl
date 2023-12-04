#pragma -xml
#pragma -width 900 
#pragma -newline 


tokens 
    datachunk "{[\t \nABCDEFabcdef\d]+}" 
end tokens 

define program 
        [datachunk] [newline] 
end define 

function main 
  replace [program] 
    P [program] 
  by 
     P       
end function 

