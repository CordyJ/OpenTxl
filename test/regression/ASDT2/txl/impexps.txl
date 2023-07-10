% impexp.Txl

include "Turing+.grm"


% Do it once for the whole program
function main
    replace [program]
        C [compilation]
    by
        C 
          [importsAndExportsInModules]
          [importsInProcedures]
          [importsInFunctions]
          [cleanupMarks]
end function


rule importsAndExportsInModules 
    replace [moduleDeclaration]
        module M [id] 
            Scope [repeat declarationOrStatement] 
        'end M 
    construct Result [moduleDeclaration]
        'MARK module M
            Scope [importsAndExportsInModules]
                  [importsInProcedures]
                  [importsInFunctions]
                  [constImports M] 
                  [varImports M] 
                  [opaqueExports M] 
                  [clearExports M] 
        'end M
    by
        Result
end rule


rule importsInFunctions
    replace [functionDeclaration]
        'function F [id] ParmList [opt parameterListDeclaration]
        RID [opt id] : TS [typeSpec] 
            Scope [repeat declarationOrStatement]
        'end F
    construct Result [functionDeclaration]
        'MARK 'function F ParmList RID : TS 
            Scope 
                  [constImports F] 
                  [varImports F] 
        'end F
    by
        Result
end rule

rule importsInProcedures
    replace [procedureDeclaration]
        'procedure P [id] ParmList [opt parameterListDeclaration] 
            Scope [repeat declarationOrStatement]
        'end P
    construct Result [procedureDeclaration]
        'MARK 'procedure P ParmList 
            Scope 
                  [constImports P] 
                  [varImports P] 
        'end P
    by
        Result
end rule


function cleanupMarks
    construct AMark [opt 'MARK]
        MARK
    construct NoMark [opt 'MARK]
        % nada
    replace [compilation]
        C [compilation]
    by
        C [$ AMark NoMark]
end function


rule constImports M [id]
        replace [repeat declarationOrStatement]
                'import  OF [opt 'forward] ID [id]
                REST [repeat declarationOrStatement]
        by
                'import ( OF ID )
                '$ 'importConst ( M , ID ) '$
                REST
end rule

rule varImports M [id]
        replace [repeat declarationOrStatement]
                'import  OF [opt 'forward] 'var ID [id]
                REST [repeat declarationOrStatement]
        by
                'import ( OF 'var ID )
                '$ 'importVar ( M , ID ) '$
                REST
end rule

rule opaqueExports M [id]
        replace [repeat declarationOrStatement]
                'export  'opaque ID [id]
                REST [repeat declarationOrStatement]
        by
                'export ( opaque ID )
                '$ 'exportOpaque ( M , ID ) '$
                REST
end rule

rule clearExports M [id]
        replace [repeat declarationOrStatement]
                'export ID [id]
                REST [repeat declarationOrStatement]
        by
                'export ( ID )
                '$ 'exportClear ( M , ID ) '$
                REST
end rule

        
