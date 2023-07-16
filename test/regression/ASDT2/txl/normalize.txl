% normalize.Txl - Normalize Turing Plus source for easy handling

% merged source.Txl, source2.Txl and binds.Txl into normalize.Txl -- JRC 13.8.93


% source.Txl

% fixed to handle enumerated type constants -- JRC 4.8.92
% fixed to unwind parameter lists -- JRC 8.8.92
% fixed to remove forward subprogram import lists -- JRC 9.8.92

include "Turing+.grm"


% "unparX" means to remove the parenthesis around X
% for example, "unparExport" replaces "export (...)" with "export ..."
% "unwindXList" means to unwind an X list, for example
% "unwindExportList means to replace "export id1, id2, ..., idn" with
% "export id1" "export id2" ... "export idn"


% Do it once for the whole program
function main
    replace [program]
	C [compilation]
    by
	C 
	  % rules from source.Txl
	  [message '"[unwindVarList]"]
	  [unwindVarList]
	  [message '"[unwindBindList]"]
	  [unwindBindList]
	  [message '"[unwindParmList]"]
	  [unwindParmList]
	  [message '"[removeForwardProcedureImportLists]"]
	  [removeForwardProcedureImportLists]
	  [message '"[removeForwardFunctionImportLists]"]
	  [removeForwardFunctionImportLists]
	  [message '"[mergeModuleStubAndBody]"]
	  [mergeModuleStubAndBody]
	  [message '"[placeImportsAndExportsAtEndOfModule]"]
	  [placeImportsAndExportsAtEndOfModule]
	  [message '"[sortSubprogramStubs]"]
	  [sortSubprogramStubs]
	  [message '"[mergeProcedureStubAndBody]"]
	  [mergeProcedureStubAndBody]
	  [message '"[mergeFunctionStubAndBody]"]
	  [mergeFunctionStubAndBody]
	  [message '"[mergeForwardProcedureHeaderAndBody]"]
	  [mergeForwardProcedureHeaderAndBody]
	  [message '"[mergeForwardFunctionHeaderAndBody]"]
	  [mergeForwardFunctionHeaderAndBody]
	  [message '"[unparImportList]"]
	  [unparImportList]
	  [message '"[unwindImportList]"]
	  [unwindImportList]
	  [message '"[unparExportList]"]
	  [unparExportList]
	  [message '"[unwindExportList]	"]
	  [unwindExportList]	
	  [message '"[replaceModuleBodyHeader]"]
	  [replaceModuleBodyHeader]
	  [message '"[eliminateEnumeratedTypes]"]
	  [eliminateEnumeratedTypes]
	  [message '"[removeMarks]"]
	  [removeMarks]

	  % rules from source2.Txl
	  [message '"[fixBuiltinParameterNumbers]"]
	  [fixBuiltinParameterNumbers]
	  [message '"[fixSizeBuiltin]"]
	  [fixSizeBuiltin]
	  [message '"[removeNamedTypeImports]"]
	  [removeNamedTypeImports]
	  [message '"[removeNamedTypeReferences]"]
	  [removeNamedTypeReferences]
	  [message '"[removeGrantLists]"]
	  [removeGrantLists]
	  [message '"[removeMarks]"]
	  [removeMarks]
	  
	  % rules from binds.Txl
	  [message '"[replaceBinds]"]
	  [replaceBinds]
end function

% external rule message M [stringlit]


rule unwindBindList
    replace [repeat declarationOrStatement]
        'bind HEAD [bindClause] , TAIL [list bindClause+]
	RestOfScope [repeat declarationOrStatement]
    by
	'bind HEAD
	'bind TAIL 
	RestOfScope
end rule


rule unwindVarList
    replace [repeat declarationOrStatement]
        EXS [opt externalSpec] var REG [opt 'register]
        V1 [id] , IDLIST [list id+]
        REST [colonTypeSpec_or_colonEqualInitializingValue]
        RestOfScope [repeat declarationOrStatement]
   by
        EXS var REG V1 REST
	EXS var REG IDLIST REST
        RestOfScope
end rule


rule unwindParmList
    replace [list parameterDeclaration+]
	REG [opt 'register] VAR [opt 'var] ID1 [id] , IDLIST [list id+] : 
	    PT [parameterType] ,
	RestOfParms [list parameterDeclaration]
   by
       REG VAR ID1 : PT ,
       REG VAR IDLIST : PT ,
       RestOfParms
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
    skipping [subprogramBody]
    replace [repeat declarationOrStatement]
	'forward 'procedure P [id] ParmList [opt parameterListDeclaration] 
	RestOfScope [repeat declarationOrStatement]
    by
	'MARK 'forward 'procedure P ParmList 
	RestOfScope [replaceProcBodyHeader P ParmList]
end rule

rule mergeForwardFunctionHeaderAndBody
    skipping [subprogramBody]
    replace [repeat declarationOrStatement]
	'forward 'function P [id] ParmList [opt parameterListDeclaration] 
	    : ResultType [typeSpec]
	RestOfScope [repeat declarationOrStatement]
    by
	'MARK 'forward 'function P ParmList : ResultType
	RestOfScope [replaceFuncBodyHeader P ParmList ResultType]
end rule

rule mergeFunctionStubAndBody
    skipping [subprogramBody]
    replace [repeat declarationOrStatement]
	stub module M [id] 
	   'function F [id] ParmList [opt parameterListDeclaration] 
		: ResultType [typeSpec]
           StubScope [repeat stubDeclaration] 
        'end M 
	body module M
           BodyScope [repeat declarationOrStatement] 
        'end M 
	RestOfScope [repeat declarationOrStatement]
    by
	stub module M
	    StubScope
	'end M
	body module M
	    'MARK 'forward 'function F ParmList : ResultType
	    BodyScope [replaceFuncBodyHeader F ParmList ResultType]
	'end M
	RestOfScope 
end rule

rule mergeProcedureStubAndBody
    skipping [subprogramBody]
    replace [repeat declarationOrStatement]
	stub module M [id] 
	    'procedure P [id] ParmList [opt parameterListDeclaration]
           StubScope [repeat stubDeclaration] 
        'end M 
	body module M
           BodyScope [repeat declarationOrStatement] 
        'end M 
	RestOfScope [repeat declarationOrStatement]
    by
	stub module M
	   StubScope
	'end M
	body module M
	    'MARK 'forward 'procedure P ParmList
	    BodyScope [replaceProcBodyHeader P ParmList]
	'end M
	RestOfScope 
end rule

rule replaceFuncBodyHeader F [id] ParmList [opt parameterListDeclaration]
		ResultType [typeSpec]
	skipping [subprogramBody]
	replace [repeat declarationOrStatement]
	        'body 'function F %[id]
			Scope [repeat declarationOrStatement]
		'end F
		RestOfScope [repeat declarationOrStatement]
	by
		'function F ParmList : ResultType
			Scope
		'end F
		RestOfScope
end rule

rule replaceProcBodyHeader P [id] ParmList [opt parameterListDeclaration]
	skipping [subprogramBody]
	replace [repeat declarationOrStatement]
	        'body 'procedure P %[id]
			Scope [repeat declarationOrStatement]
		'end P
		RestOfScope [repeat declarationOrStatement]
	by
		'procedure P ParmList
			Scope
		'end P
		RestOfScope
end rule

% Find each module declaration
rule mergeModuleStubAndBody
    skipping [subprogramBody]
    replace [repeat declarationOrStatement]
	stub module M [id] 
		IL [importList]
		EX [exportList]
           StubScope [repeat stubDeclaration] 
        'end M 
	body module M
           BodyScope [repeat declarationOrStatement] 
        'end M 
	RestOfScope [repeat declarationOrStatement]
    construct Y [repeat declarationOrStatement]
	IL
	EX
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

rule placeImportsAndExportsAtEndOfModule
    skipping [subprogramBody]
    replace [repeat declarationOrStatement]
	module M [id] 
		IL [importList]
		EX [exportList]
           Scope [repeat declarationOrStatement] 
        'end M 
	RestOfScope [repeat declarationOrStatement]
    construct Y [repeat declarationOrStatement]
	IL
	EX
    construct X [repeat declarationOrStatement]
	Scope [. Y]
    by
	module M
	    X
	'end M
	RestOfScope 
end rule

rule replaceModuleBodyHeader
    skipping [subprogramBody]
    replace [repeat declarationOrStatement]
	stub module M [id] 
           StubScope [repeat stubDeclaration] 
        'end M 
	body module M
           BodyScope [repeat declarationOrStatement] 
        'end M 
	RestOfScope [repeat declarationOrStatement]
    by
	module M
	   %StubScope % it is known in the txl source that there will be no StubScope
	   BodyScope
	'end M
	RestOfScope 
end rule

rule removeForwardProcedureImportLists
    replace [forwardProcedureHeader]
    	'forward 'procedure P [id] ParmList [opt parameterListDeclaration]
	    Imports [importList]
    by
    	'forward 'procedure P ParmList
end rule

rule removeForwardFunctionImportLists
    replace [forwardFunctionHeader]
    	'forward 'function P [id] ParmList [opt parameterListDeclaration]
	    : ResultType [typeSpec]
	    Imports [importList]
    by
    	'forward 'function P ParmList : ResultType
end rule

rule unparImportList
	skipping [subprogramBody]
	replace [importList]
		'import ( IL  [list importItem] )
	by
		'import IL 
end rule

rule unwindImportList
	skipping [subprogramBody]
	replace [repeat declarationOrStatement]
		'import  IITEM [importItem] , IL [list importItem+] 
		REST [repeat declarationOrStatement]
	by
		'import IITEM  
		'import IL 
		REST
end rule

rule unparExportList
	skipping [subprogramBody]
	replace [exportList]
		'export ( EL  [list exportItem+] )
	by
		'export EL 
end rule

rule unwindExportList
	skipping [subprogramBody]
	replace [repeat declarationOrStatement]
		'export  EITEM [exportItem] , EL [list exportItem+] 
		REST [repeat declarationOrStatement]
	by
		'export EITEM  
		'export EL 
		REST
end rule

rule eliminateEnumeratedTypes
	replace [repeat declarationOrStatement]
	    type PS [opt pervasiveSpec] T [id] : OP [opt 'packed]
		enum ( EClist [list id+] )
	    RestOfScope [repeat declarationOrStatement]
	construct Result [repeat declarationOrStatement]
	    type PS T : OP int
	    RestOfScope [makeConstDeclaration T PS each EClist]
	by
	    Result
end rule

function makeConstDeclaration T [id] OP [opt pervasiveSpec] EC [id]
	construct ECprime [id]
	    T [_ EC]
	construct ECdecl [declarationOrStatement]
	    const OP ECprime := 0
	replace [repeat declarationOrStatement]
	    Scope [repeat declarationOrStatement]
	construct OldRef [reference]
	    T . EC
	construct NewRef [reference]
	    ECprime
	by
	    ECdecl
	    Scope [$ OldRef NewRef]
end function

function removeMarks
    construct AMark [opt 'MARK]
	MARK
    construct NoMark [opt 'MARK]
	% nada
    replace [compilation]
	C [compilation]
    by
	C [$ AMark NoMark]
end function


% source2.Txl

% ensure consistent numbers of parameters -- JRC 5.8.92
% remove grant lists and imports of types -- JRC 8.8.92

rule fixBuiltinParameterNumbers
    replace [reference]
	intstr ( E [expn] )
    by
	intstr ( E , 1 )
end rule

rule fixSizeBuiltin
    replace [reference]
	size ( X [id] )
    by
	size ( 1 )
end rule

rule removeNamedTypeImports
    skipping [subprogramBody]
    replace [repeat declarationOrStatement]
	type PERV [opt pervasiveSpec] T [id] : TS [typeSpec]
	RestOfScope [repeat declarationOrStatement]
    construct Result [repeat declarationOrStatement]
	'MARK type PERV T : TS
	RestOfScope [removeImports T]
    by
	Result
end rule

function removeNamedTypeReferences
    replace [compilation]
	C [compilation]
    by
	C [removeNamedTypeSpecs]
	  [removeNamedIndexTypes]
end function

rule removeNamedTypeSpecs
    replace [typeSpec]
	T [id]
    by
	int
end rule

rule removeNamedIndexTypes
    replace [indexType]
	T [id]
    by
	1..1
end rule

rule removeImports T [id]
    skipping [subprogramBody]
    replace [repeat declarationOrStatement]
	'import T
	RestOfScope [repeat declarationOrStatement]
    by
	RestOfScope
end rule

rule removeGrantLists
    skipping [subprogramBody]
    replace [repeat declarationOrStatement]
	G [grantList]
	RestOfScope [repeat declarationOrStatement]
    by
	RestOfScope
end rule


% binds.Txl

% Fixed to handle type cast binds correctly  --  JRC 8.8.92
% Tuned to do all kinds of binds at once  --  JRC 8.8.92

rule replaceBinds
    replace [repeat declarationOrStatement]
	'bind V [opt 'var] R [opt 'register] 
	    BindId [id] to BindedRef [reference]
	Scope [repeat declarationOrStatement]
    construct RealBindedRef [reference]
	BindedRef [removeTypeCasting]
    construct Result [repeat declarationOrStatement]
	Scope [substituteBindIdRef BindId RealBindedRef]
    by
	Result
end rule

function removeTypeCasting
    replace [reference]
	type ( Cheat [typeCheatSpec] , RealRef [reference] )
    by
	RealRef 
end function

rule substituteBindIdRef BindId [id] BindedRef [reference]
    replace [reference]
 	BindId CS [repeat componentSelector]
    deconstruct BindedRef
	BindedId [id] BindedCS [repeat componentSelector]
    construct Result [reference]
	BindedId BindedCS [.CS]
    by
	Result
end rule

function null
    match [id]
	NOT_ANY_ID_I_KNOW
end function

