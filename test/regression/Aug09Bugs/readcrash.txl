
define program 
    [repeat token] 
end define 

function main 
   replace [program] 
      P [program] 
   construct foo [repeat token] 
            _  [read ""] 
      [debug] 
      [read ""] % again 
      [debug] % but we are already dead 
   by foo 
end function

