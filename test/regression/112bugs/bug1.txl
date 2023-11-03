% intentionally empty tokens should simply disappear in output
#pragma -comment -newline
tokens
    comment "/\*#(\*/)*\*/"
end tokens

define program
    [word*]
end define

define word
    [id] | [NL] [comment] | [newline]
end define

rule main
    replace $ [comment]
        C [comment]
    by
        C [: 1 0]
end rule
