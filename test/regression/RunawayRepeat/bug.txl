define program 
    [identifier]
end define

define identifier
      [id] [repeat ref_mod] 
end define

define ref_mod
       [repeat of_in_id] [opt subscript]
end define

define of_in_id
      'OF [id]
    |   'IN [id]
end define

define subscript
        '( [identifier] ')
end define

function main
    match [program]
        Id [identifier]
end function
