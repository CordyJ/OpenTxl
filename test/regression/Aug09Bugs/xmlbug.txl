define program
    [repeat listpair]
end define

define listpair
    [list pair]
end define

define pair
    'one [opt 'potato]
  | [id] [opt id]
end define

#pragma -xml

function main
    match [program] _ [program]
end function
