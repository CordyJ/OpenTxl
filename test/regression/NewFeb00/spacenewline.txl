#pragma -char

tokens
        xspace "[       ]+"
end tokens

define program
        [repeat line]
end define

define line
        [opt xspace] [repeat token] [newline]
end define

rule main
        replace * [line]
                Space [xspace] Tokens [repeat token] NL [newline]
        by
                Space Tokens NL
end rule
