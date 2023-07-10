% rename.Txl - Rename all objects to reflect their context of declaration

% merged name.Txl and name2.Txl into rename.Txl -- JRC 13.8.93


% name.Txl
% uniquely name functions, procedures, formal parameters and modules
% embed is-composed-of (ICO) prolog facts
% assumes a simplified TuringPlus source (no stubs, few lists, ...)

% Several bugs fixed by Jim Cordy 12.6.92
% Several additional bugs fixed by KAS July 16, 1992

% fixed to handle externals -- JRC 4.8.92
% tuned for better speed -- JRC 7.8.92
% fixed to handle exported calls correctly -- JRC 8.8.92

include "Turing+.grm"


% Do it once for the whole program
function main
    replace [program]
        C [compilation]
    by
        C 
           % rules from name.Txl
          [message '"[nameModules 'PROGRAM]"]
          [nameModules 'PROGRAM]
          [message '"[nameForwardProcedures 'PROGRAM]"]
          [nameForwardProcedures 'PROGRAM]
          [message '"[nameProcedures 'PROGRAM]"]
          [nameProcedures 'PROGRAM]
          [message '"[nameForwardFunctions 'PROGRAM]"]
          [nameForwardFunctions 'PROGRAM]
          [message '"[nameFunctions 'PROGRAM]"]
          [nameFunctions 'PROGRAM]
          [message '"[nameExternalFunctionsWithParameters 'LIBRARY]"]
          [nameExternalFunctionsWithParameters 'LIBRARY]
          [message '"[nameExternalFunctions 'LIBRARY]"]
          [nameExternalFunctions 'LIBRARY]
          [message '"[nameExternalProceduresWithParameters 'LIBRARY]"]
          [nameExternalProceduresWithParameters 'LIBRARY]
          [message '"[nameExternalProcedures 'LIBRARY]"]
          [nameExternalProcedures 'LIBRARY]
          [message '"[nameExportedCalls]"]
          [nameExportedCalls]
          [message '"[cleanupExportMarks]"]
          [cleanupExportMarks]
          [message '"[cleanupMarks]"]
          [cleanupMarks]
          
           % rules from name2.Txl
          [message '"[nameModuleVars]"]
          [nameModuleVars]
          [message '"[nameProcedureVars]"]
          [nameProcedureVars]
          [message '"[nameFunctionVars]"]
          [nameFunctionVars]
          [message '"[nameExternalVariables 'LIBRARY]"]
          [nameExternalVariables 'LIBRARY]
          [message '"[nameExternalConstants 'LIBRARY]"]
          [nameExternalConstants 'LIBRARY]
          [message '"[nameVariables 'PROGRAM]"]
          [nameVariables 'PROGRAM]
          [message '"[nameConstants 'PROGRAM]"]
          [nameConstants 'PROGRAM]
          [message '"[nameForConstants 'PROGRAM]"]
          [nameForConstants 'PROGRAM]
          [message '"[nameHandlerConstants 'PROGRAM]"]
          [nameHandlerConstants 'PROGRAM]
          [message '"[cleanupMarks]"]
          [cleanupMarks]
end function

% external rule message S [stringlit]


% Find each module declaration
rule nameModules G [id]
    skipping [bigSubprogramDeclaration]
    replace [repeat declarationOrStatement]
        module M [id] 
            Scope [repeat declarationOrStatement] 
        'end M 
        RestOfScope [repeat declarationOrStatement]
    construct Mprime [id]
        G [+ 'X_X] [+ M] [+ 'X_X] [!]
    construct ICO [prologFact]  
        '$ ico ( G , Mprime ) '$
    construct NewModule [declaration]
        'MARK M module Mprime 
            ICO
            Scope [nameModules Mprime]
                [nameForwardProcedures Mprime]
                [nameProcedures Mprime]
                [nameForwardFunctions Mprime]
                [nameFunctions Mprime]
                [nameExportedCalls]
        'end Mprime
    by
        NewModule
        RestOfScope [substituteModuleId M Mprime]
end rule


rule nameForwardFunctions M [id] 
    skipping [subprogramBody]
    replace [repeat declarationOrStatement]
        'forward 'function P [id] ParmList [opt parameterListDeclaration]
            : ResultType [typeSpec]
        RestOfScope [repeat declarationOrStatement]
    construct Pprime [id]
        M [+ 'X_X] [+ P] [+ 'X_X] [!]
    construct ICO [prologFact]  
        '$ ico ( M , Pprime ) '$
    construct Result [repeat declarationOrStatement]
        ICO
        RestOfScope [nameAndMarkFunctionBody M P Pprime]
                    [$ P Pprime]
                    [markExport P Pprime]
    by
        Result
end rule

rule nameAndMarkFunctionBody M [id]  P [id] Pprime [id]
    skipping [subprogramBody]
    replace [declaration]
        'function P ParmList [opt parameterListDeclaration] 
                : ResultType [typeSpec]
            FuncScope [repeat declarationOrStatement]
        'end P
    construct NewBody [declaration]
        'MARK 'function Pprime ParmList : ResultType
            FuncScope 
        'end Pprime
    construct Result [declaration]
        NewBody [nameParameters Pprime ParmList]
    by
        Result
end rule

function nameParameters M [id] OptParmList [opt parameterListDeclaration]
    deconstruct OptParmList
        ( ParmList [list parameterDeclaration+] ) 
    replace [declaration]
        SubProgDecl [subprogramDeclaration]
    by
        SubProgDecl [nameParameter M each ParmList]
end function

rule nameFunctions M [id] 
    skipping [subprogramBody]
    replace [repeat declarationOrStatement]
        'function P [id]  ParmList [opt parameterListDeclaration]
                : ResultType [typeSpec]
            FuncScope [repeat declarationOrStatement]
        'end P
        RestOfScope [repeat declarationOrStatement]
    construct Pprime [id]
        M [+ 'X_X] [+ P] [+ 'X_X] [!]
    construct ICO [prologFact]  
        '$ ico ( M , Pprime ) '$
    construct NewFunc [declaration]
        'MARK 'function Pprime ParmList : ResultType
            ICO
            FuncScope 
                  [$ P Pprime]
        'end Pprime
    construct Result [repeat declarationOrStatement]
        NewFunc [nameParameters Pprime ParmList]
        RestOfScope [$ P Pprime]
                    [markExport P Pprime]
    by
        Result
end rule

rule nameForwardProcedures M [id] 
    skipping [subprogramBody]
    replace [repeat declarationOrStatement]
        'forward 'procedure P [id] ParmList [opt parameterListDeclaration]
        RestOfScope [repeat declarationOrStatement]
    construct Pprime [id]
        M [+ 'X_X] [+ P] [+ 'X_X] [!]
    construct ICO [prologFact]  
        '$ ico ( M , Pprime ) '$
    construct Result [repeat declarationOrStatement]
        ICO
        RestOfScope [nameAndMarkProcedureBody M P Pprime]
                    [$ P Pprime]
                    [markExport P Pprime]
    by
        Result
end rule

rule nameAndMarkProcedureBody M [id]  P [id] Pprime [id]
    skipping [subprogramBody]
    replace [declaration]
        'procedure P ParmList [opt parameterListDeclaration]
            ProcScope [repeat declarationOrStatement]
        'end P
    construct NewBody [declaration]
        'MARK 'procedure Pprime ParmList
            ProcScope 
        'end Pprime
    construct Result [declaration]
        NewBody [nameParameters Pprime ParmList]
    by
        Result
end rule

rule nameProcedures M [id] 
    skipping [subprogramBody]
    replace [repeat declarationOrStatement]
        'procedure P [id]  ParmList [opt parameterListDeclaration]
            ProcScope [repeat declarationOrStatement]
        'end P
        RestOfScope [repeat declarationOrStatement]
    construct Pprime [id]
        M [+ 'X_X] [+ P] [+ 'X_X] [!]
    construct ICO [prologFact]  
        '$ ico ( M , Pprime ) '$
    construct NewProc [declaration]
        'MARK 'procedure Pprime ParmList
            ICO
            ProcScope [$ P Pprime]
        'end Pprime
    construct Result [repeat declarationOrStatement]
        NewProc [nameParameters Pprime ParmList]
        RestOfScope  [$ P Pprime]
                     [markExport P Pprime]
    by
        Result
end rule


rule nameExportedCalls
    skipping [bigSubprogramDeclaration]
    replace [repeat declarationOrStatement]
        'MARK M [id] module Mprime [id] 
            Scope [repeat declarationOrStatement] 
        'end Mprime 
        RestOfScope [repeat declarationOrStatement]
    construct Exports [repeat exportItem]
        _ [^ Scope]
    construct Result [repeat declarationOrStatement]
        module Mprime
            Scope 
        'end Mprime
        RestOfScope [nameIndirectRefs M each Exports]
    by
        Result
end rule


rule markExport P [id] Pprime [id]
    replace [exportItem]
        OP [opt 'opaque] Pprime
    by
        OP P Pprime
end rule

rule cleanupExportMarks
    replace [exportItem]
        OP [opt 'opaque] P [id] Pprime [id]
    by
        OP Pprime
end rule

rule nameIndirectRefs M [id] Export [exportItem]
    deconstruct Export
        OP [opt 'opaque] P [id] Pprime [id]
    replace [reference]
        M . P CS [repeat componentSelector]
    by
        Pprime CS
end rule


rule nameExternalProceduresWithParameters M [id]
        skipping [subprogramBody]
        replace [repeat declarationOrStatement]
                'external STRLIT [opt stringlit]
                    'procedure P [id] ( ParmList [list parameterDeclaration+] )
                Scope [repeat declarationOrStatement]
        construct Pprime [id]
                M [+ 'X_X] [+ P] [+ 'X_X] [!]
        construct ICO [prologFact]      
            '$ ico ( M , Pprime ) '$
        construct ParmListPrime [parameterDeclarationList]
                ParmList [nameParameter Pprime each ParmList]
        construct ExternalProcedure [externalDeclaration]
                'MARK 'external STRLIT 'procedure Pprime ( ParmListPrime ) 
        construct Result [repeat declarationOrStatement]
                ExternalProcedure
                ICO
                Scope   [nameExternalProceduresWithParameters M]
                        [$ P Pprime]
        by
                Result
end rule


rule nameExternalProcedures M [id]
        skipping [subprogramBody]
        replace [repeat declarationOrStatement]
                'external STRLIT [opt stringlit] 'procedure P [id] 
                Scope [repeat declarationOrStatement]
        construct Pprime [id]
                M [+ 'X_X] [+ P] [+ 'X_X] [!]
        construct ICO [prologFact]      
            '$ ico ( M , Pprime ) '$
        construct ExternalProcedure [externalDeclaration]
                'MARK 'external STRLIT 'procedure Pprime 
        construct Result [repeat declarationOrStatement]
                ExternalProcedure
                ICO
                Scope   [nameExternalProcedures M]
                        [$ P Pprime]
        by
                Result
end rule


rule nameExternalFunctionsWithParameters M [id]
        skipping [subprogramBody]
        replace [repeat declarationOrStatement]
                'external STRLIT [opt stringlit] 
                    'function F [id] ( ParmList [list parameterDeclaration+] )
                        RID [opt id] : RTYPE [typeSpec] 
                Scope [repeat declarationOrStatement]
        construct Fprime [id]
                M [+ 'X_X] [+ F] [+ 'X_X] [!]
        construct ICO [prologFact]      
            '$ ico ( M , Fprime ) '$
        construct ParmListPrime [parameterDeclarationList]
                ParmList [nameParameter Fprime each ParmList]
        construct ExternalFunction [externalDeclaration]
                'MARK 'external STRLIT 'function Fprime ( ParmListPrime )
                    RID : RTYPE 
        construct Result [repeat declarationOrStatement]
                ExternalFunction
                ICO
                Scope  [$ F Fprime]
        by
                Result
end rule


rule nameExternalFunctions M [id]
        skipping [subprogramBody]
        replace [repeat declarationOrStatement]
                'external STRLIT [opt stringlit] 
                    'function F [id] RID [opt id] : RTYPE [typeSpec] 
                Scope [repeat declarationOrStatement]
        construct Fprime [id]
                M [+ 'X_X] [+ F] [+ 'X_X] [!]
        construct ICO [prologFact]      
            '$ ico ( M , Fprime ) '$
        construct ExternalFunction [externalDeclaration]
                'MARK 'external STRLIT 'function Fprime RID : RTYPE 
        construct Result [repeat declarationOrStatement]
                ExternalFunction
                ICO
                Scope  [$ F Fprime]
        by
                Result
end rule


rule nameParameter P [id] ParmDecl [parameterDeclaration]
    deconstruct ParmDecl
        OptVar [opt 'var] ParmId [id] : ParmType [parameterType]
    construct ParmIdPrime [id]
        P [+ 'X_X] [+ ParmId] [+ 'X_X] [!]
    replace [id]
        ParmId 
    by
        ParmIdPrime 
end rule


function substituteModuleId OldId [id] NewId [id]
     construct VarImport [importItem]
         'var OldId
     construct NewVarImport [importItem]
         'var NewId
     construct NonVarImport [importItem]
         OldId
     construct NewNonVarImport [importItem]
         NewId
     replace [repeat declarationOrStatement]
        Scope [repeat declarationOrStatement]
     by
        Scope [$ VarImport NewVarImport] 
              [$ NonVarImport NewNonVarImport]
end function

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


% name2.Txl
% uniquely name variables and constants
% embed is-composed-of (ICO) prolog facts
% assumes a simplified TuringPlus source (no stubs, no forwards, few lists, ...)

% Several bugs fixed by Jim Cordy 12.6.92
% Several additional bugs fixed by KAS July 16, 1992

% fixed to handle externals -- JRC 4.8.92
% fixed to handle for loop constants -- JRC 5.8.92
% fixed to handle exception handler constants -- JRC 5.8.92


% Find each module declaration
rule nameModuleVars 
    skipping [bigSubprogramDeclaration]
    replace [declaration]
        module M [id] 
            Scope [repeat declarationOrStatement] 
        'end M 
    construct Result [declaration]
        'MARK module M  
            Scope 
                   [nameModuleVars]
                   [nameProcedureVars]
                   [nameFunctionVars]
                   [nameVariables M]
                   [nameConstants M]
                   [nameForConstants M]
                   [nameHandlerConstants M]
        'end M
    by
        Result
end rule

rule nameFunctionVars 
    skipping [bigSubprogramDeclaration]
    replace [declaration]
        'function P [id]  ParmList [opt parameterListDeclaration]
                : ResultType [typeSpec]
            Scope [repeat declarationOrStatement]
        'end P
    construct Result [declaration]
        'MARK 'function P ParmList : ResultType
            Scope [nameVariables P] 
                  [nameConstants P] 
                  [nameForConstants P]
                  [nameHandlerConstants P]
        'end P
    by
        Result
end rule

rule nameProcedureVars 
    skipping [bigSubprogramDeclaration]
    replace [declaration]
        'procedure P [id]  ParmList [opt parameterListDeclaration]
            Scope [repeat declarationOrStatement]
        'end P
    construct Result [declaration]
        'MARK 'procedure P ParmList 
            Scope [nameVariables P] 
                  [nameConstants P] 
                  [nameForConstants P]
                  [nameHandlerConstants P]
        'end P
    by
        Result
end rule


% Unqiuely name the variables in it
rule nameVariables M [id] 
    skipping [bigSubprogramDeclaration]
    replace [repeat declarationOrStatement]
        var REG [opt 'register] V [id]
            REST [colonTypeSpec_or_colonEqualInitializingValue]
        Scope [repeat declarationOrStatement]
    construct Vprime [id] 
        M [+ 'X_X] [+ V] [+ 'X_X] [!]
    construct ICO [prologFact]
        '$ ico ( M , Vprime ) '$
    construct Result [repeat declarationOrStatement]
        'MARK var REG Vprime REST
        ICO
        Scope [$ V Vprime]
    by
        Result
end rule


rule nameConstants M [id] 
    skipping [bigSubprogramDeclaration]
    replace [repeat declarationOrStatement]
        const REG [opt 'register] PERVASIVE [opt pervasiveSpec] C [id] 
            CTS [opt colonTypeSpec] := CV [initializingValue]
        Scope [repeat declarationOrStatement]
    construct Cprime [id]
        M [+ 'X_X] [+ C] [+ 'X_X] [!]
    construct ICO [prologFact]  
        '$ ico ( M , Cprime ) '$
    construct Result [repeat declarationOrStatement]
        MARK const REG PERVASIVE Cprime CTS := CV
        ICO
        Scope [$ C Cprime]
    by
        Result
end rule


rule nameForConstants M [id] 
    replace [forStatement]
        for OD [opt 'decreasing] FC [id] : FR [forRange] 
            Body [repeat declarationOrStatement] 
        'end for
    construct FCprime [id]
        M [+ 'X_X] [+ FC] [+ 'X_X] [!]
    construct ICO [prologFact]  
        '$ ico ( M , FCprime ) '$
    construct Result [forStatement]
        MARK for OD FCprime : FR
            ICO
            Body [$ FC FCprime]
        'end for
    by
        Result
end rule


rule nameHandlerConstants M [id] 
    replace [exceptionHandler]
        handler ( HC [id] ) 
            Body [repeat declarationOrStatement] 
        'end handler 
    construct HCprime [id]
        M [+ 'X_X] [+ HC] [+ 'X_X] [!]
    construct ICO [prologFact]  
        '$ ico ( M , HCprime ) '$
    construct Result [exceptionHandler]
        'MARK handler ( HCprime ) 
            ICO
            Body [$ HC HCprime]
        'end handler 
    by
        Result
end rule


% Name external variables and constants
rule nameExternalVariables M [id] 
    replace [repeat declarationOrStatement]
        'external EXP [opt expn] var REG [opt 'register] V [id]
        REST [colonTypeSpec_or_colonEqualInitializingValue]
        Scope [repeat declarationOrStatement]
    construct Vprime [id] 
        M [+ 'X_X] [+ V] [+ 'X_X] [!]
    construct ICO [prologFact]
        '$ ico ( M , Vprime ) '$
    construct Result [repeat declarationOrStatement]
        'MARK 'external EXP var REG Vprime REST
        ICO
        Scope [$ V Vprime]
    by
        Result
end rule


rule nameExternalConstants M [id] 
    replace [repeat declarationOrStatement]
        'external EXP [opt expn] const REG [opt 'register] PERVASIVE [opt pervasiveSpec] 
            C [id] CTS [opt colonTypeSpec] := CV [initializingValue]
        Scope [repeat declarationOrStatement]
    construct Cprime [id]
        M [+ 'X_X] [+ C] [+ 'X_X] [!]
    construct ICO [prologFact]  
        '$ ico ( M , Cprime ) '$
    construct Result [repeat declarationOrStatement]
        'MARK 'external EXP const REG PERVASIVE Cprime CTS := CV
        ICO
        Scope [$ C Cprime]
    by
        Result
end rule
