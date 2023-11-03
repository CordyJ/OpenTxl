
define program
    [unit*]
end define

define unit
    [statement]
|   [declaration]
end define

define statement
        [assignment]
    |   [expression] ; [NL]
    |   [block]
end define

define assignment
    [id] = [expression] ; [NL]
end define

define expression
        [number]
    |   [id]
end define

define block
    '{ [IN] [NL] [statement_or_declaration*] [EX] '} [NL]
end define

define statement_or_declaration
    [statement] | [declaration]
end define

define declaration
    'var [id] '; [NL]
end define

function main
    replace [program]
        Units [unit*]
    by
        Units [renameGlobalDeclarations]
              [firstExpression Units]
end function

rule renameGlobalDeclarations
    skipping [statement]
    skipping [expression]
    replace $ [id]
        Id [id]
    by
        'AllGlobalDeclarations
end rule

function firstExpression Units [unit*]
    skipping [block]
    skipping [assignment]
    deconstruct * [expression] Units 
        E [expression]
    replace * [expression]
        E
    by
        'OnlyFirstGlobalExpressionStatement
end function
