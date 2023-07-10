#pragma -char

define program
        [repeat line]
end define

define line
        [repeat token_not_newline] [newline]
end define

define token_not_newline
        [not newline] [token]
end define

function main
        match [program]
                Lines [repeat line]
        construct AppendThem [repeat line]
                Lines [fopen "TheFile" "put"]
                      [fput "TheFile"]
                      [fclose "TheFile"]
        construct AppendThem2 [repeat line]
                Lines [fopen "TheFile" "append"]
                      [fput "TheFile"]
end function
