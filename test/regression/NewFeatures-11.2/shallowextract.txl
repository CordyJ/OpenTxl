include "Turing.grm"

function main
    replace [program]
        P [program]
    construct AllProcs [procedure_declaration*]
        _ [^ P]
    construct NAllProcs [number]
        _ [length AllProcs] [putp "allprocs (should be 7): "]
    construct ShallowProcs [procedure_declaration*]
        _ [^/ P]
    construct NShallowProcs [number]
        _ [length ShallowProcs] [putp "shallowprocs (should be 1): "]
    deconstruct * [subprogram_body] P
        PBody [subprogram_body]
    construct SecondLevelProcs [procedure_declaration*]
        _ [^ PBody]
    construct NSecondLevelProcs [number]
        _ [length SecondLevelProcs] [putp "secondlevelprocs (should be 6): "]
    construct ShallowSecondLevelProcs [procedure_declaration*]
        _ [^/ PBody]
    construct NShallowSecondLevelProcs [number]
        _ [length ShallowSecondLevelProcs] [putp "shallowsecondlevelprocs (should be 2): "]
    by
        'put NAllProcs, NShallowProcs, NSecondLevelProcs, NShallowSecondLevelProcs 
end function
