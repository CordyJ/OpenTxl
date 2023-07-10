tokens
        newline "\n"
        space "[        ]+"
end tokens

define program
        [repeat token]
end define

function main
        match [program] _ [program]
end function
