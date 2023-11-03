% rules should not search inside attributes
#pragma -attr
define program
    [word*]
end define

define word
    [id] [attr Attribute] [NL]
end define

define Attribute
    [not token] [id]
end define

function main
    replace [program]
        P [program]
    by
        P [attribute 'id2]
          [replaceallids]
end function

rule attribute Id [id]
    replace $ [word]
        Id
    by
        Id Id
end rule

rule replaceallids
    skipping [Attribute]
    replace $ [id]
        _ [id]
    by
        'replaced
end rule
