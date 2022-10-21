include "Tplus.Grammar"

keys
    inline 
end keys

define fcnSpec
        [opt 'inline] [fcnOrFunction] 
end define

define fcnOrFunction
        fcn 
    |   'function 
end define

define parameterDeclarationList
        [list parameterDeclaration] [opt commaVaryingParameterDeclaration] 
    |   [id] :.. 
end define

define componentSelector
        ( [list expn] ) 
    |   . [id] 
end define

rule main
    replace [compilation]
        C [compilation]
    by
        C [transformTrivialInlineFunctions]
end rule

rule transformTrivialInlineFunctions
    replace [repeat declarationOrStatement]
        inline 
        Fcn [fcnOrFunction]
        Fname [id]
        ( 
        Fformals [list parameterDeclaration]
        ) 
        Fresultname [opt id]
        : 
        Ftype [typeSpec]
        Fimports [opt importList]
        result 
        Fresultexpn [expn]
        'end Fname 
        Fscope [repeat declarationOrStatement]

    construct Result1 [repeat declarationOrStatement]
        Fscope [fixTrivialCalls Fname Fformals Fresultexpn]
    by
        Result1 
end rule

rule fixTrivialCalls
            Fname [id]
            Fformals [list parameterDeclaration]
            Fresultexpn [expn]
    replace [subExpn]
        Fname ( 
        Factuals [list expn]
        ) 

    construct Result2 [subExpn]
        ( 
        Fresultexpn [replaceReferenceFormalWithActual each Fformals Factuals]
            [replaceValueFormalWithActual each Fformals Factuals]
        ) 
    by
        Result2 
end rule

rule replaceReferenceFormalWithActual
            Formal [parameterDeclaration]
            Actual [expn]

    deconstruct Actual
        Aref [reference]

    deconstruct Formal
        Fid [id]
        : 
        Ftype [parameterType]

    replace [reference]
        Fid 
    by
        Aref 
end rule

rule replaceValueFormalWithActual
            Formal [parameterDeclaration]
            Actual [expn]

    deconstruct Formal
        Fid [id]
        : 
        Ftype [parameterType]

    replace [subExpn]
        Fid 
    by
        ( Actual ) 
end rule


