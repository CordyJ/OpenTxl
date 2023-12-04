% Legasys 180: Grammar analysis incorrect for repeats
define alpha
    [repeat beta] ;
end define
define beta
    [id]
end define
define program
   [repeat alpha]
end define
rule main
   match [program] _ [program]
end rule
