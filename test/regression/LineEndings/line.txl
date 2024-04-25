% Test handling and line numbering of standard line endings LF, CR, CR-LF
tokens
    line    "#[\n\r]#[\n\r]*\:[\n\r]"
end tokens

define program
    [lineSL*]
end define

define lineSL
    [srclinenumber] [line]
end define

rule main
    replace [lineSL*]
        _ [srclinenumber] Line [line]
        More [lineSL*]
    where not
        Line [grep "three"]
    by
        More
end rule
