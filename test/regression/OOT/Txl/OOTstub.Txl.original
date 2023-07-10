% OOT unit interface extractor
% J.R. Cordy, 1.5.92
% This TXL spec extracts the interface from an OOT unit file
% commented in the David Penny style.

include "OOT.Grammar"

% allow marking of declarations
define declarationOrStatement
        [NL] [opt 'MARKED] [declaration] [opt ';] [NL] 
    |   [variableBinding] [opt ';] [NL] 
    |   [statement] [opt ';] [NL] 
    |   [commentlines]          
end define


% build the stub
function main
    replace [program]
        C [compilation]
    by
        C [normalizeExportLists] 
          [removeExportComments] 
          [extractModuleUnitStub]
          [extractMonitorUnitStub]
          [extractClassUnitStub]
end function

rule normalizeExportLists
    replace [exportList]
        'export ExportItems [list exportItem+]
    by
        'export ( ExportItems )
end rule

rule removeExportComments
    replace [exportList]
        ExpList [exportList]
    where
        ExpList [?removeComments]
    by
        ExpList [removeComments]
end rule

rule removeComments
    replace [opt commentlines]
        C [commentlines]
    by
        % doodly
end rule

function extractMonitorUnitStub
    replace [compilation]
        Comments [opt commentlines]
        unit monitor M [id] ColonExpn [opt colonExpn] 
            Implement [opt implementClause]
            ImplementBy [opt implementByClause]
            Imports [opt importList]
            'export ( Exports [list exportItem+] )
            Pre [opt preClause]
            Body [repeat declarationOrStatement]
            Post [opt postClause] 
        'end M

    by
        Comments
        unit monitor M ColonExpn
            'export ( Exports )
            Body [removeStatements] 
                 [markDeclaration each Exports]
                 [deleteUnmarkedDeclarations]
                 [removeMarks]
                 [sortBy each Exports]
        'end M
end function

function extractModuleUnitStub
    replace [compilation]
        Comments [opt commentlines]
        unit module M [id] 
            Implement [opt implementClause]
            ImplementBy [opt implementByClause]
            Imports [opt importList]
            'export ( Exports [list exportItem+] )
            Pre [opt preClause]
            Body [repeat declarationOrStatement]
            Post [opt postClause] 
        'end M

    by
        Comments
        unit module M 
            'export ( Exports )
            Body [removeStatements] 
                 [markDeclaration each Exports]
                 [deleteUnmarkedDeclarations]
                 [removeMarks]
                 [sortBy each Exports]
        'end M
end function

function extractClassUnitStub
    replace [compilation]
        Comments [opt commentlines]
        unit Monitor [opt 'monitor] class M [id] 
            Expand [opt expandClause]
            Implement [opt implementClause]
            ImplementBy [opt implementByClause]
            Imports [opt importList]
            'export ( Exports [list exportItem+] )
            Pre [opt preClause]
            Body [repeat declarationOrStatement]
            Post [opt postClause] 
        'end M

    by
        Comments
        unit Monitor class M 
            'export ( Exports )
            Body [removeStatements] 
                 [markDeclaration each Exports]
                 [deleteUnmarkedDeclarations]
                 [removeMarks]
                 [sortBy each Exports]
        'end M
end function

% % external rule message N [number]
% % external rule print

rule removeStatements
    replace [repeat declarationOrStatement]
        DeclarationOrStatement [declarationOrStatement]
        Rest [repeat declarationOrStatement]
    where not
        DeclarationOrStatement [isDeclaration] 
    by
        Rest
end rule

function isDeclaration
    match [declarationOrStatement]
        Marked [opt 'MARKED] Declaration [declaration] Semi [opt ';] 
end function

rule markDeclaration Export [exportItem]
    deconstruct Export
        Comment [opt commentlines]  
        ExportMethods [repeat exportMethod] 
        ExportId [id]
    replace [declarationOrStatement]
        Declaration [declaration]
    where 
        Declaration [declares ExportId]
    where not
        Declaration [isModule] [isMonitor] [isClass] 
    by
        'MARKED Declaration [trimProcDeclaration] 
                            [trimFunctionDeclaration]
                            [trimOtherDeclarations]
end rule

function isModule
    match [declaration]
        Module [moduleDeclaration]
end function

function isMonitor
    match [declaration]
        Monitor [monitorDeclaration]
end function

function isClass
    match [declaration]
        Class [classDeclaration]
end function

rule deleteUnmarkedDeclarations 
    replace [repeat declarationOrStatement]
        Declaration [declaration] Semi [opt ';]
        Rest [repeat declarationOrStatement]
    by
        Rest
end rule

rule removeMarks
    replace [opt 'MARKED]
        'MARKED
    by
        % nada
end rule

rule declares Id [id]
    match [declaredId]
        Id
end rule

function trimProcDeclaration 
    replace [declaration]
        Comments [opt commentlines]
        Proc [procSpec] Id [id] Parms [opt parameterListDeclaration]
        Imports [opt importList]
        Body [subprogramBody]
    by
        Comments 
        'deferred Proc Id Parms 
end function

function trimFunctionDeclaration 
    replace [declaration]
        Comments [opt commentlines]
        Fcn [fcnSpec] Id [id] Parms [opt parameterListDeclaration]
            ResultId [opt id] : ResultType [typeSpec] 
        Imports [opt importList]
        Body [subprogramBody]
    by
        Comments 
        'deferred Fcn Id Parms ResultId : ResultType
end function

function trimOtherDeclarations
    replace [declaration]
        Declaration [declaration]
    where not
        Declaration [isSubprogram] 
    by
        Declaration [removeComments]
end function

function isSubprogram
    match [declaration]
        Declaration [subprogramDeclaration]
end function

rule sortBy Export [exportItem]
    deconstruct Export
        Comment [opt commentlines]  
        ExportMethods [repeat exportMethod] 
        ExportId [id]
    replace [repeat declarationOrStatement]
        Declaration [declarationOrStatement]
        OtherDeclaration [declarationOrStatement]
        Rest [repeat declarationOrStatement]
    where
        Declaration [declares ExportId]
    construct OtherAndRest [repeat declarationOrStatement]
        OtherDeclaration
        Rest
    by
        OtherAndRest [removeDuplicates ExportId] 
                     [. Declaration]
end rule

rule removeDuplicates DeclaredId [id]
    replace [repeat declarationOrStatement]
        DuplicateDeclaration [declarationOrStatement]
        Rest [repeat declarationOrStatement]
    where
        DuplicateDeclaration [declares DeclaredId]
    by
        Rest
end rule
