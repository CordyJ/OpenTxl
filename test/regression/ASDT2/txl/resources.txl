% resource.Txl

% fixed to handle externals -- JRC 4.8.92
% fixed to handle for loop constants -- JRC 5.8.92
% fixed to handle exception handler constants -- JRC 5.8.92
% fixed to handle pervasive constants -- JRC 5.8.92

include "Turing+.grm"


% Do it once for the whole program
function main
    replace [program]
        C [compilation]
    by
        C 
          [varResources]
          [conResources]
          [pconResources]
          [forconResources]
          [handlerconResources]
          [moduleResources]
          [procedureResources]
          [functionResources]
          [externalProcedureResources]
          [externalFunctionResources]
          [cleanupMarks]
end function


rule moduleResources
    skipping [subprogramBody]
    replace [moduleDeclaration]
        module M [id] 
            Scope [repeat declarationOrStatement] 
        'end M 
    construct RTYPE [prologFact]        
        '$ modid ( M ) '$
    by
        'MARK module M
            RTYPE
            Scope
        'end M
end rule


rule functionResources
    skipping [subprogramBody]
    replace [functionDeclaration]
        'function F [id] ParmList [opt parameterListDeclaration] : TS [typeSpec] 
            Scope [repeat declarationOrStatement]
        'end F
    construct RTYPE [prologFact]        
        '$ funcid ( F ) '$
    by
        'MARK 'function F ParmList : TS 
            RTYPE
            Scope
        'end F
end rule

rule procedureResources
    skipping [subprogramBody]
    replace [procedureDeclaration]
        'procedure P [id] ParmList [opt parameterListDeclaration] 
            Scope [repeat declarationOrStatement]
        'end P
    construct RTYPE [prologFact]        
        '$ procid ( P ) '$
    by
        'MARK 'procedure P ParmList 
            RTYPE
            Scope
        'end P
end rule


rule externalFunctionResources
    skipping [subprogramBody]
    replace [repeat declarationOrStatement]
        'external STRLIT [opt stringlit] 
        'function F [id] ParmList [opt parameterListDeclaration]
            : TS [typeSpec] 
        Rest [repeat declarationOrStatement]
    construct RTYPE [prologFact]        
        '$ funcid ( F ) '$
    by
        'MARK 'external STRLIT 'function F ParmList : TS 
        RTYPE
        Rest
end rule

rule externalProcedureResources
    skipping [subprogramBody]
    replace [repeat declarationOrStatement]
        'external STRLIT [opt stringlit] 
        'procedure P [id] ParmList [opt parameterListDeclaration] 
        Rest [repeat declarationOrStatement]
    construct RTYPE [prologFact]        
        '$ procid ( P ) '$
    by
        'MARK 'external STRLIT 'procedure P ParmList 
        RTYPE
        Rest
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

rule varResources
    replace [repeat declarationOrStatement]
        EXTSPEC [opt externalSpec] var REG [opt 'register] V [id]
            REST [colonTypeSpec_or_colonEqualInitializingValue]
        RestOfScope [repeat declarationOrStatement]
    construct RTYPE [prologFact]
        '$ varid ( V ) '$
    by
        'MARK EXTSPEC var REG V REST
        RTYPE
        RestOfScope
end rule


rule conResources
    replace [repeat declarationOrStatement]
        EXTSPEC [opt externalSpec]
        const REG [opt 'register] C [id] 
            CTS [opt colonTypeSpec] := CV [initializingValue]
        RestOfScope [repeat declarationOrStatement]
    construct RTYPE [prologFact]        
        '$ conid ( C ) '$
    by
        MARK EXTSPEC
        const REG C CTS := CV
        RTYPE
        RestOfScope
end rule

rule pconResources
    replace [repeat declarationOrStatement]
        EXTSPEC [opt externalSpec]
        const REG [opt 'register] PERVASIVE [pervasiveSpec] C [id] 
            CTS [opt colonTypeSpec] := CV [initializingValue]
        RestOfScope [repeat declarationOrStatement]
    construct RTYPE [prologFact]        
        '$ pconid ( C ) '$
    by
        MARK EXTSPEC
        const REG PERVASIVE C CTS := CV
        RTYPE
        RestOfScope 
end rule

rule forconResources 
    replace [forStatement]
        for OD [opt 'decreasing] FC [id] : FR [forRange] 
            Body [repeat declarationOrStatement] 
        'end for
    construct RTYPE [prologFact]
        '$ conid ( FC ) '$
    by
        MARK for OD FC : FR
            RTYPE
            Body 
        'end for
end rule


rule handlerconResources 
    replace [exceptionHandler]
        handler ( HC [id] ) 
            Body [repeat declarationOrStatement] 
        'end handler 
    construct RTYPE [prologFact]        
        '$ conid ( HC ) '$
    by
        MARK handler ( HC ) 
            RTYPE
            Body 
        'end handler 
end rule

