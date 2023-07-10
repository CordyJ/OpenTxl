% simple.Txl
% Several bugs fixed by Jim Cordy 12.6.92

include "Tplus.Simple.grm"

define variableDeclaration
        [opt 'MARK]
        [opt externalSpec] var [opt 'register] [list id+]
        [colonTypeSpec_or_colonEqualInitializingValue]
end define


define constantDeclaration
        [opt externalSpec]
        [opt 'MARK] const [opt 'register] [opt pervasiveSpec] [opt 'VMARK]  [id] [opt colonTypeSpec ]
                := [initializingValue]
end define

define colonTypeSpec
        : [typeSpec]
end define


define parameterListDeclaration
        [opt 'MARK] ( [parameterDeclarationList] )
end define



% Do it once for the whole program
function main
    replace [program]
        C [compilation]
    by
        C 
          [uniquelyNameModuleLocals 'PROGRAM]
          [nameBodyModuleLocals 'PROGRAM]
          [nameVariables 'PROGRAM]
          [nameConstants 'PROGRAM]
          [replaceBinds 'PROGRAM] 
          [uniquelyNameProcedureCalls]
          [uniquelyNameBodyProcedureCalls]
          [uniquelyNameFunctionCalls]
          [uniquelyNameBodyFunctionCalls]
          [varParameterFacts]
          [constParameterFacts]
          [cleanupMarks]
          [cleanupVMarks]
        [getRefs]
        [cleanupRefMarks]
        %[printPrologFacts]
end function
rule getRefs
        skipping [subprogramDeclaration]
        replace [repeat declarationOrStatement]
                'procedure P [id] ParmList [opt parameterListDeclaration] 
                        Scope [repeat declarationOrStatement]
                'end P
                RestOfScope [repeat declarationOrStatement]
        construct EmbeddedProc [declaration]
                'MARK P 'procedure P ParmList
                        Scope [embedProcCalls P][embedPutRefs P][embedGetRefs P]
                'end P
        by
                EmbeddedProc
                RestOfScope
end rule
rule embedProcCalls P [id]
        replace [repeat declarationOrStatement]
                REF [id] CS [repeat componentSelector]
                RestOfScope [repeat declarationOrStatement]
        construct Result [repeat declarationOrStatement]
                '$ 'procCall ( P, REF ) '$ CS [subParRef P]
                RestOfScope 
        by
                Result
end rule
rule subParRef P [id]
        replace [reference]
                REF [id] CS [repeat componentSelector]
        by
                '$ 'parRef ( P, REF ) '$
end rule
rule embedPutRefs P [id]
        replace [assignmentStatement] 
                REF [id] CS [repeat componentSelector]
                ASSOP [assignmentOperator]  
                EXPN [expn]
        by
                '$ 'putRef ( P, REF ) '$ CS
                ASSOP 
                EXPN
end rule
rule embedGetRefs P [id]
        replace [reference]
                REF [id] CS [repeat componentSelector]
        by
                '$ 'getRef ( P, REF ) '$ CS
end rule
rule printPrologFacts
    match [repeat declarationOrStatement]
        P [repeat declarationOrStatement]
    construct listPrologFacts [repeat prologFact]
        _ [^ P][print]
end rule

% % % external rule print

rule printPrologFactsPar
    replace [prologFact]
        P [prologFact]
    by
        P [print]
end rule




rule transformBindList
    replace [repeat declarationOrStatement]
        'bind HEAD [bindClause] , TAIL [list bindClause+]
        Rest [repeat declarationOrStatement]
      construct Scope [repeat declarationOrStatement]
        'bind TAIL 
        Rest
    by
        'bind HEAD
        Scope
end rule


rule transformVarList
    replace [repeat declarationOrStatement]
        EXS [opt externalSpec] var REG [opt 'register]
        V1 [id] , IDLIST [list id+]
        REST [colonTypeSpec_or_colonEqualInitializingValue]
        RestOfScope [repeat declarationOrStatement]
    construct Scope [repeat declarationOrStatement]
            EXS var REG IDLIST REST
            RestOfScope
   by
        EXS var REG V1 REST
        Scope 
end rule

% Find each global declaration
rule uniquelyNameGlobals
    replace [program]
        Scope [repeat declarationOrStatement]
    by
        Scope [nameVariables 'PROGRAM] 
              [nameConstants 'PROGRAM] 
              [replaceBinds 'PROGRAM] 
end rule



rule sortSubprogramStubs
    replace [repeat stubDeclaration]
           StubFunc [stubFunctionHeader]
           StubProc [stubProcedureHeader]
           RestOfScope [repeat stubDeclaration]
    by
           StubProc
           StubFunc
           RestOfScope 
end rule


rule mergeForwardProcedureHeaderAndBody
    replace [repeat declarationOrStatement]
        FWDPROC [forwardProcedureHeader]
        ILIST [importList]
        RestOfScope [repeat declarationOrStatement]
    deconstruct FWDPROC
        'forward 'procedure P [id] ParmList [opt parameterListDeclaration] % ILIST [opt importList]
    by
        RestOfScope [replaceForwardProcBodyHeader P FWDPROC ILIST]
end rule

rule replaceForwardProcBodyHeader P [id] FWDPROC [forwardProcedureHeader] ILIST [importList]
        replace [repeat declarationOrStatement]
                'body 'procedure P
                        Scope [repeat declarationOrStatement]
                'end P
                RestOfScope [repeat declarationOrStatement]
        deconstruct FWDPROC
                'forward 'procedure X [id] ParmList [opt parameterListDeclaration]% ILIST [opt importList]
        by
                'procedure X ParmList 
                        ILIST
                        Scope
                'end P
                RestOfScope
end rule

rule mergeFunctionStubAndBody
    replace [repeat declarationOrStatement]
        stub module M [id] 
           StubFunc [stubFunctionHeader]
           StubScope [repeat stubDeclaration] 
        'end M 
        body module M
           BodyScope [repeat declarationOrStatement] 
        'end M 
        RestOfScope [repeat declarationOrStatement]
    deconstruct StubFunc
        'function F [id] ParmList [opt parameterListDeclaration] J1 [opt id] : J2 [typeSpec]
    by
        stub module M
           StubScope
        'end M
        body module M
            BodyScope [replaceFuncBodyHeader F StubFunc]
        'end M
        RestOfScope 
end rule

rule mergeProcedureStubAndBody
    replace [repeat declarationOrStatement]
        stub module M [id] 
           StubProc [stubProcedureHeader]
           StubScope [repeat stubDeclaration] 
        'end M 
        body module M
           BodyScope [repeat declarationOrStatement] 
        'end M 
        RestOfScope [repeat declarationOrStatement]
    deconstruct StubProc
        'procedure P [id] ParmList [opt parameterListDeclaration]
    by
        stub module M
           StubScope
        'end M
        body module M
            BodyScope [replaceProcBodyHeader P StubProc]
        'end M
        RestOfScope 
end rule

rule replaceFuncBodyHeader F [id] StubFunc [stubFunctionHeader]
        replace [repeat declarationOrStatement]
                'body 'function F
                        Scope [repeat declarationOrStatement]
                'end F
                RestOfScope [repeat declarationOrStatement]
        deconstruct StubFunc
                'function X [id] ParmList [opt parameterListDeclaration] OID [opt id] : TS [typeSpec]
        by
                'function X ParmList OID : TS
                        Scope
                'end X
                RestOfScope
end rule

rule replaceProcBodyHeader P [id] StubProc [stubProcedureHeader]
        replace [repeat declarationOrStatement]
                'body 'procedure P 
                        Scope [repeat declarationOrStatement]
                'end P
                RestOfScope [repeat declarationOrStatement]
        deconstruct StubProc
                'procedure X [id] ParmList [opt parameterListDeclaration]
        by
                'procedure X ParmList
                        Scope
                'end P
                RestOfScope
end rule

% Find each module declaration
rule mergeStubAndBody
    replace [repeat declarationOrStatement]
        stub module M [id] 
                IL [importList]
                EL [exportList]
           StubScope [repeat stubDeclaration] 
        'end M 
        body module M
           BodyScope [repeat declarationOrStatement] 
        'end M 
        RestOfScope [repeat declarationOrStatement]
    construct Y [repeat declarationOrStatement]
        IL
        EL
    construct X [repeat declarationOrStatement]
        BodyScope [. Y]
    by
        stub module M
           StubScope
        'end M
        body module M
            X
        'end M
        RestOfScope 
end rule
% external rule splice_declarationOrStatement S [repeat declarationOrStatement]
% external rule append_declarationOrStatement S [declarationOrStatement]
rule unparImports
        replace [importList]
                'import ( IL  [list importItem] )
        by
                'import IL 
end rule
rule unwindImports
        replace [repeat declarationOrStatement]
                'import  IITEM [importItem] , IL [list importItem+] 
                REST [repeat declarationOrStatement]
        by
                'import IITEM  
                'import IL 
                REST
end rule
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

rule unparExports
        replace [exportList]
                'export ( EL  [list exportItem+] )
        by
                'export EL 
end rule
rule unwindExports
        replace [repeat declarationOrStatement]
                'export  EITEM [exportItem] , EL [list exportItem+] 
                REST [repeat declarationOrStatement]
        by
                'export EITEM  
                'export EL 
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

        
                


% Find each module declaration
rule nameBodyModuleLocals G [id]
    replace [repeat declarationOrStatement]
        body module M [id] 
            Scope [repeat declarationOrStatement] 
        'end M 
        RestOfScope [repeat declarationOrStatement]
    construct Mprime [id]
        G [_ M] [!]
    construct RTYPE [prologFact]        
        '$ 'module ( Mprime ) '$
    by
        'MARK body module Mprime 
            RTYPE
            Scope [nameBodyModuleLocals Mprime]
                [nameProceduresWithParameters Mprime]
                [nameProcedures Mprime]
                [nameBodyProcedures Mprime]
                [nameFunctionsWithParameters Mprime]
                [nameFunctions Mprime]
                [nameBodyFunctions Mprime]
                  [nameVariables Mprime] 
                  [nameConstants Mprime] 
                  [replaceBinds Mprime] 
                  [constImports Mprime] 
                  [varImports Mprime] 
                  [opaqueExports Mprime] 
                  [clearExports Mprime] 
        'end Mprime
        RestOfScope [substituteModuleId M Mprime]
end rule


% Find each module declaration
rule uniquelyNameModuleLocals G [id]
    replace [repeat declarationOrStatement]
        module M [id] 
            Scope [repeat declarationOrStatement] 
        'end M 
        RestOfScope [repeat declarationOrStatement]
    construct Mprime [id]
        G [_ M] [!]
    construct RTYPE [prologFact]        
        '$ 'module ( M ) '$
    construct Result [repeat declarationOrStatement]
        'MARK module Mprime 
            RTYPE
            Scope [nameProcedures Mprime]
                  [nameBodyProcedures Mprime] 
                  [nameFunctions Mprime] 
                  [nameBodyFunctions Mprime] 
                  [nameVariables Mprime] 
                  [nameConstants Mprime] 
                  [replaceBinds Mprime] 
                  [constImports Mprime] 
                  [varImports Mprime] 
                  [opaqueExports Mprime] 
                  [clearExports Mprime] 
        'end Mprime
        RestOfScope [substituteModuleId M Mprime]
    by
        Result
end rule



rule uniquelyNameBodyFunctionCalls %M [id] 
    replace [repeat declarationOrStatement]
        'MARK P [id] 'body 'function Pprime [id]
            ProcScope [repeat declarationOrStatement]
        'end Pprime
        RestOfScope [repeat declarationOrStatement]
    construct Result [repeat declarationOrStatement]
        'body 'function
        Pprime
            ProcScope [substituteCallId P Pprime]
        'end Pprime
        RestOfScope  [substituteCallId P Pprime]
    by
        Result
end rule

rule uniquelyNameFunctionCalls %M [id] 
    replace [repeat declarationOrStatement]
        'MARK P [id] 'function Pprime [id] ParmList [opt parameterListDeclaration] OID [opt id] : TS [typeSpec] 
            ProcScope [repeat declarationOrStatement]
        'end Pprime
        RestOfScope [repeat declarationOrStatement]
    construct Result [repeat declarationOrStatement]
        'function
        Pprime
        ParmList OID : TS
            ProcScope [substituteCallId P Pprime]
        'end Pprime
        RestOfScope  [substituteCallId P Pprime]
    by
        Result
end rule


% Uniquely name the procedure calls
rule uniquelyNameBodyProcedureCalls %M [id] 
    replace [repeat declarationOrStatement]
        'MARK P [id] 'body 'procedure Pprime [id] 
            ProcScope [repeat declarationOrStatement]
        'end Pprime
        RestOfScope [repeat declarationOrStatement]
    construct Result [repeat declarationOrStatement]
        'body 'procedure
        Pprime
            ProcScope [substituteCallId P Pprime]
        'end Pprime
        RestOfScope  [substituteCallId P Pprime]
    by
        Result
end rule


% Uniquely name the procedure calls
rule uniquelyNameProcedureCalls %M [id] 
    replace [repeat declarationOrStatement]
        'MARK P [id] 'procedure Pprime [id] ParmList [opt parameterListDeclaration] %ILIST [opt importList]
            ProcScope [repeat declarationOrStatement]
        'end Pprime
        RestOfScope [repeat declarationOrStatement]
    construct Result [repeat declarationOrStatement]
        'procedure
        Pprime
        ParmList 
        %ILIST
            ProcScope [substituteCallId P Pprime]
        'end Pprime
        RestOfScope  [substituteCallId P Pprime]
    by
        Result
end rule



rule nameFunctionsWithParameters M [id] 
    replace [repeat declarationOrStatement]
        'function P [id] ( ParmList [list parameterDeclaration+] ) OID [opt id] : TS [typeSpec] 
            ProcScope [repeat declarationOrStatement]
        'end P
        RestOfScope [repeat declarationOrStatement]
    construct Pprime [id]
        M [_ P] [!]
    construct RTYPE [prologFact]        
        '$ 'function ( Pprime ) '$
    construct ICO [prologFact]  
        '$ 'ico ( M , Pprime ) '$
    construct Result [repeat declarationOrStatement]
        'MARK
        P
        'function
        Pprime
        ( ParmList ) OID : TS
        RTYPE
        ICO
            ProcScope [nameVariables Pprime] 
                  [nameConstants Pprime] 
                  [replaceBinds Pprime] 
                  [constImports Pprime] 
                  [varImports Pprime] 
        'end Pprime
    construct Result2 [repeat declarationOrStatement]
        Result [nameParameter Pprime each ParmList]
        [. RestOfScope]
    by
        Result2
end rule

% Uniquely name the functions in it
rule nameFunctions M [id] 
    replace [repeat declarationOrStatement]
        'function P [id] OID [opt id] : TS [typeSpec] 
            ProcScope [repeat declarationOrStatement]
        'end P
        RestOfScope [repeat declarationOrStatement]
    construct Pprime [id]
        M [_ P] [!]
    construct RTYPE [prologFact]        
        '$ 'function ( Pprime ) '$
    construct ICO [prologFact]  
        '$ 'ico ( M , Pprime ) '$
    construct Result [repeat declarationOrStatement]
        'MARK
        P
        'function
        Pprime
        OID : TS
        RTYPE
        ICO
            ProcScope [nameVariables Pprime] 
                  [nameConstants Pprime] 
                  [replaceBinds Pprime] 
                  [constImports Pprime] 
                  [varImports Pprime] 
        'end Pprime
        RestOfScope
    by
        Result
end rule

% Uniquely name the functions in it
rule nameBodyFunctions M [id] 
    replace [repeat declarationOrStatement]
        'body 'function P [id] %ParmList [opt parameterListDeclaration] OID [opt id] : TS [typeSpec]
            ProcScope [repeat declarationOrStatement]
        'end P
        RestOfScope [repeat declarationOrStatement]
    construct Pprime [id]
        M [_ P] [!]
    construct RTYPE [prologFact]        
        '$ 'function ( Pprime ) '$
    construct ICO [prologFact]  
        '$ 'ico ( M , Pprime ) '$
    construct Result [repeat declarationOrStatement]
        'MARK
        P
        'body
        'function
        Pprime
        RTYPE
        ICO
            ProcScope [nameVariables Pprime] 
                  [nameConstants Pprime] 
                  [replaceBinds Pprime] 
                  [constImports Pprime] 
                  [varImports Pprime] 
        'end Pprime
        RestOfScope  
    by
        Result
end rule

% Uniquely name the procedures in it
rule nameBodyProcedures M [id] 
    replace [repeat declarationOrStatement]
        'body 'procedure P [id]
            ProcScope [repeat declarationOrStatement]
        'end P
        RestOfScope [repeat declarationOrStatement]
    construct Pprime [id]
        M [_ P] [!]
    construct RTYPE [prologFact]        
        '$ 'procedure ( Pprime ) '$
    construct ICO [prologFact]  
        '$ 'ico ( M , Pprime ) '$
    construct Result [repeat declarationOrStatement]
        'MARK
        P
        'body 
        'procedure
        Pprime
        RTYPE
        ICO
            ProcScope [nameVariables Pprime] 
                  [nameConstants Pprime] 
                  [replaceBinds Pprime] 
                  [constImports Pprime] 
                  [varImports Pprime] 
        'end Pprime
        RestOfScope  
    by
        Result
end rule


% Uniquely name the procedures in it
rule nameProceduresWithParameters M [id] 
    replace [repeat declarationOrStatement]
        'procedure P [id] ( ParmList [list parameterDeclaration+] ) %ILIST[opt importList]
            ProcScope [repeat declarationOrStatement]
        'end P
        RestOfScope [repeat declarationOrStatement]
    construct Pprime [id]
        M [_ P] [!]
    construct RTYPE [prologFact]        
        '$ 'procedure ( Pprime ) '$
    construct ICO [prologFact]  
        '$ 'ico ( M , Pprime ) '$
    construct Result [repeat declarationOrStatement]
        'MARK
        P
        'procedure
        Pprime
        ( ParmList )
        %ILIST
        RTYPE
        ICO
            ProcScope [nameVariables Pprime] 
                  [nameConstants Pprime] 
                  [replaceBinds Pprime] 
                  [constImports Pprime] 
                  [varImports Pprime] 
        'end Pprime
    construct Result2 [repeat declarationOrStatement]
        Result [nameParameter Pprime each ParmList]
        [. RestOfScope]
    by
        Result2
end rule

rule nameProcedures M [id] 
    replace [repeat declarationOrStatement]
        'procedure P [id] 
            ProcScope [repeat declarationOrStatement]
        'end P
        RestOfScope [repeat declarationOrStatement]
    construct Pprime [id]
        M [_ P] [!]
    construct RTYPE [prologFact]        
        '$ 'procedure ( Pprime ) '$
    construct ICO [prologFact]  
        '$ 'ico ( M , Pprime ) '$
    construct Result [repeat declarationOrStatement]
        'MARK
        P
        'procedure
        Pprime
        RTYPE
        ICO
            ProcScope [nameVariables Pprime] 
                  [nameConstants Pprime] 
                  [replaceBinds Pprime] 
                  [constImports Pprime] 
                  [varImports Pprime] 
        'end Pprime
        RestOfScope  
    by
        Result
end rule


% Unqiuely name the variables in it
rule nameVariables M [id] 
    replace [repeat declarationOrStatement]
        EXTSPEC [opt externalSpec] var REG [opt 'register] V [id]
        REST [colonTypeSpec_or_colonEqualInitializingValue]
        Scope [repeat declarationOrStatement]
    construct Vprime [id] 
        M [_ V] [!]
    construct RTYPE [prologFact]
        '$ 'var ( Vprime ) '$
    construct ICO [prologFact]
        '$ 'ico ( M , Vprime ) '$
    construct Result [repeat declarationOrStatement]
        'MARK EXTSPEC var REG Vprime REST
        RTYPE
        ICO
        Scope [substituteRefId V Vprime]
    by
        Result
end rule


% replace binds with direct references to variableReferences
rule replaceBinds M [id] 
    replace [repeat declarationOrStatement]
        'bind V [opt 'var] R [opt 'register] BR [reference] to VR [reference]
        Scope [repeat declarationOrStatement]
    construct Result [repeat declarationOrStatement]
        Scope [substituteR BR VR]
    by
        Result
end rule

% and the constants in it
rule nameConstants M [id] 
    replace [repeat declarationOrStatement]
        EXTSPEC [opt externalSpec]
        const REG [opt 'register] PERVASIVE [opt pervasiveSpec] C [id] 
            CTS [opt colonTypeSpec] := CV [initializingValue]
        Scope [repeat declarationOrStatement]
    construct Cprime [id]
        M [_ C] [!]
    construct RTYPE [prologFact]        
        '$ 'const ( Cprime ) '$
    construct ICO [prologFact]  
        '$ 'ico ( M , Cprime ) '$
    construct Result [repeat declarationOrStatement]
        EXTSPEC
        MARK const REG PERVASIVE Cprime CTS := CV
        RTYPE
        ICO
        Scope [substituteRefId C Cprime]
    by
        Result
end rule


% Find each function declaration
rule uniquelyNameFunctionLocals
    replace [functionDeclaration]
        'function P [id] ParmList [opt parameterListDeclaration] OID [opt id] : TS [typeSpec]
            Scope [repeat declarationOrStatement] 
        'end P 
    by
        'function P ParmList OID : TS
            Scope [nameVariables P] 
                  [nameConstants P] 
                  [replaceBinds P] 
        'end P
end rule

% Find each procedure declaration
rule uniquelyNameProcedureLocals
    replace [repeat declarationOrStatement]
        'procedure P [id] ParmList [opt parameterListDeclaration] %ILIST [opt importList]
            Scope [repeat declarationOrStatement] 
        'end P 
        RestOfScope [repeat declarationOrStatement]
    by
        'procedure
        P ParmList %ILIST
            Scope [nameVariables P] 
                  [nameConstants P] 
                  [replaceBinds P] 
        'end P
        RestOfScope [uniquelyNameProcedureLocals]
end rule

rule constParameterFacts
        replace [parameterDeclaration]
            ID [id] : PT [parameterType]
        by
            '$ 'constPar ( ID ) '$
end rule

rule varParameterFacts
        replace [parameterDeclaration]
            'var ID [id] : PT [parameterType]
        by
            '$ 'varPar ( ID ) '$
end rule

% uniquely name parameters
rule nameParameter P [id] ParmDecl [parameterDeclaration]
    deconstruct ParmDecl
        _ [opt 'var] ParmId [id] : _ [parameterType]
    construct ParmIdPrime [id]
        P [_ ParmId] [!]
    replace [id]
        ParmId
    by
        ParmIdPrime
end rule

rule substituteCallId OldId [id] NewId [id]
    replace [reference]
        OldId CS [repeat componentSelector]
    by
        NewId CS
end rule

rule substituteRefId OldId [id] NewId [id]
    replace [reference]
        OldId CS [repeat componentSelector]
    by
        NewId CS
end rule

rule substituteModuleId OldId [id] NewId [id]
    replace [reference]
        OldId CS [repeat componentSelector]
    by
        NewId CS
end rule

rule substituteR OldVR [reference] NewVR [reference]
    replace [reference]
        OldVR
    by
        NewVR
end rule

rule substituteGrantId OldId [id] NewId [id]
    replace [grantId]
        OldId
    by
        NewId
end rule

rule cleanupMarks
    replace [opt 'MARK]
        MARK
    by
        % nothing
end rule


rule cleanupVMarks
    replace [opt 'VMARK]
        VMARK
    by
        % nothing
end rule

rule cleanupRefMarks
    replace [declaration]
            'MARK P [id] 'procedure P ParmList [opt parameterListDeclaration] 
                    Scope [repeat declarationOrStatement]
            'end P
    by
            'procedure P ParmList
                    Scope 
            'end P
end rule
