% Calculator.Txl - simple numerical expression evaluator

% Part I.  Syntax specification
define program
        [expression]
end define

define expression
        [expression] + [term]
    |   [expression] - [term]
    |   [term]
end define

define term
        [term] * [primary]
    |   [term] / [primary]
    |   [primary]
end define

define primary 
        [number]
    |   ( [expression] )
end define


% Part 2.  Transformation rules
rule main
    replace [expression]
        E [expression]
    construct NewE [expression]
        E [resolveAddition]
          [resolveSubtraction]
          [resolveMultiplication]
          [resolveDivision]
          [resolveBracketedExpressions]
    where not
        NewE [= E]
    by
        NewE
end rule

rule resolveAddition
    replace [expression]
        N1 [number] + N2 [number]
    by
        N1 [+ N2]
end rule

rule resolveSubtraction
    replace [expression]
        N1 [number] - N2 [number]
    by
        N1 [- N2]
end rule 

rule resolveMultiplication
    replace [term]
        N1 [number] * N2 [number]
    by
        N1 [* N2]
end rule 

rule resolveDivision
    replace [term]
        N1 [number] / N2 [number]
    by
        N1 [/ N2]
end rule

rule resolveBracketedExpressions
    replace [primary]
        ( N [number] )
    by
        N
end rule

