% Objective Turing dialect
% Eric Promislow & Jim Cordy
% Queen's University, August 1987  
% Revised May 1989

include "Turing.Grammar"

% Dialect syntactic forms

define typeSpec
	[standardType]
    |	[arrayType]
    |	[recordType]
    |	[enumeratedType]
    |	[setType]
    |	[unionType]
    |	[pointerType]
    |	[collectionType]
    |	[objectType]
    |	[subrangeType]
    |	[namedType]
end define

define objectType 
				[IN][NL]
	object			[NL][IN]
	    [moduleBody]	[EX]
	'end [id]		[EX][NL]
end define


% Modified syntax of declarations to allow easy sorting

define declaration
	[constantTypeOrModuleDeclaration]
    |	[variableOrSubprogramDeclaration]
end define

define variableOrSubprogramDeclaration
	[variableDeclaration]
    |	[variableBinding]
    |	[subprogramDeclaration]
end define

define constantTypeOrModuleDeclaration
	[constantDeclaration]
    |	[typeDeclaration]
    |	[moduleDeclaration]
end define


% Modified syntax of export lists to allow splicing

define exportList 
 	'export ( [list optOpaqueId] [repeat commaListOptOpaqueId] )	[NL]
end define

define commaListOptOpaqueId
       , [list optOpaqueId]
end define


% Semantic transforms

function main
    replace [program]
	P [repeat declarationOrStatement]
    by
	P [fixObjects] 
end function

rule fixObjects
    replace [repeat declarationOrStatement]
	type ObName [id] : 
	    object
		ObImp [opt importList]
		ObExp [opt exportList]
		ObBody [repeat declarationOrStatement]
	    'end ObName
	RestOfScope [repeat declarationOrStatement]

    construct ObModule [id]
	ObName [!]

    construct ObRecordTmp [id]
	'Record
    construct ObRecord [id]
	ObName [_ ObRecordTmp] [!]

    construct ObParamTmp [id]
	'Param
    construct ObParam [id]
	ObParamTmp [!]

    construct ObInitTmp [id]
	'Init
    construct ObInit [id]
	ObInitTmp [!]

    by
	% Generate object-related identifiers
	% We delete them because we don't want them to appear in the
	% final source

	% Sort the contents of the object's body in order of
	% typeDecs, varDecs, procedureDecs, statements
	module ObModule
	    ObImp
	    ObExp [addObjectAndInitializerExport ObRecord ObInit]
	    ObBody
		% First handle embedded objects
		[fixObjects]
		% Split initialized vars : var v: t := e --> var v: t; v := e
		[splitInitVars]
		% Sort declarations and statements to make transform easier:
		% constants+types+modules, variables, subprograms, statements
		[sort]
		% Make empty object record type, put just before variables
		[makeObjectRecord ObRecord]
		% Now fill it in with the variables
		[enterObjectRecordFields ObRecord ObParam]
		% Make object initializer procedure, put just before statements
		[makeInitializerProcAndEnterStatements ObInit ObParam ObRecord]
		% Add object record parameter to each entry subprogram
		[addObjectParameterToSubprogs ObRecord ObParam ObInit]
		% Don't bother searching inside, we already did embedded objects first
	'end ObModule

	% Now transform references to the object
	RestOfScope [transformObjects ObName ObRecord ObModule ObInit]
		[transformArrayObjects ObName ObRecord ObModule ObInit]
end rule

function addObjectAndInitializerExport ObRecord [id] ObInit [id]
    replace [opt exportList]
	E [opt exportList]
    by
	E [yesExportList ObRecord ObInit] 
	  [noExportList ObRecord ObInit]
end function

function noExportList ObRecord [id] ObInit [id]
    replace [opt exportList]
    by
	'export ( ObRecord , ObInit )
end function

function yesExportList ObRecord [id] ObInit [id]
    replace [opt exportList]
	'export ( OldExports [list optOpaqueId] )
    by
	'export ( ObRecord , ObInit , OldExports )
end function


% We don't want to worry about compound var dec'ns.
% Note that TXL can't really determine the type of an
% arbitrary expression, and Turing has no operator such
% as TYPE(expn).  Otherwise we could do:

% replace   var Id [expn] := E [expn]
% by        var Id : TYPE (E)
%               Id := E

rule splitInitVars
    replace [repeat declarationOrStatement]
	var IdName [id] : T [typeSpec] := E [expn]
	Rest [repeat declarationOrStatement]
    by
	var IdName : T
	IdName := E
	Rest 
end rule

% Make an empty object record to enter variables in, insert it just
% before the variable declarations.

function makeObjectRecord ObRecord [id]
    replace * [repeat declarationOrStatement]
	V [variableDeclaration]
	Rest [repeat declarationOrStatement]
    by
	type pervasive ObRecord : 
	    record
	    'end record		% Empty record def to begin
	V
	Rest 
end function

% Move the variable declarations into the object record.

rule enterObjectRecordFields ObRecord [id] ObParam [id]
    replace [repeat declarationOrStatement]
	type pervasive ObRecord : 
	    record
		R [repeat recordField]
	    'end record
	var V [id] : T [typeSpec]
	RestOfScope [repeat declarationOrStatement]

    construct NewV [id]
	V [!]

    by
	type pervasive ObRecord : 
	    record
		% Remember to drop the "var" inside the record.
		NewV : T
		R
	    'end record
	RestOfScope [substIdRef1 V ObParam NewV] 
end rule

rule substIdRef1 OldVar [id] ObRecord [id] NewVar [id]
    replace [reference]
	OldVar Rest [repeat componentSelector]
    by
	ObRecord . NewVar Rest
end rule

% Make the object initializer procedure, fill it with 
% the initialization statements of the object.

rule makeInitializerProcAndEnterStatements ObInit [id]
					   ObParam [id]
					   ObRecord [id]
    replace [repeat declarationOrStatement]
	P [subprogramDeclaration]
	S [statement]
	Rest [repeat declarationOrStatement]
    by
	P
	procedure ObInit (var ObParam : ObRecord)
	S
	Rest 
	'end ObInit
end rule

% Finally, change all the object's procedure headers.

rule addObjectParameterToSubprogs
	 ObRecord [id] ObParam [id] ObInit [id]
    replace [repeat declarationOrStatement]
	ObBody [repeat declarationOrStatement]
    construct NewBody [repeat declarationOrStatement]
	ObBody 
	    [addObjectParameterToProcsWithArgs ObRecord ObParam ObInit]
	    [addObjectParameterToProcsWithoutArgs ObRecord ObParam ObInit]
	    [addObjectParameterToFunctionsWithArgs ObRecord ObParam ObInit]
	    [addObjectParameterToFunctionsWithoutArgs ObRecord ObParam ObInit]
    where not
	NewBody [= ObBody]
    by
	NewBody
end rule

% These four similar rules do two things: put all the procedures and
% functions in the module and add the first argument to the parameter list.
% Read one to understand all four.

rule addObjectParameterToProcsWithArgs
	ObRecord [id] ObParam [id] ObInit [id]
    replace [repeat declarationOrStatement]
	procedure PName [id] ( Arg1 [parameterDeclaration]
		RestOfArgs [repeat commaParameterDecl] )
	    OIL [opt importList]
	    PBody [subprogramBody]
	procedure ObInit InitPList [opt parameterList]
	    IBody [subprogramBody]
	RestOfScope [repeat declarationOrStatement]
    by
	procedure ObInit InitPList
	    IBody
	procedure PName ( var ObParam : ObRecord , Arg1 RestOfArgs )
	    OIL PBody
	RestOfScope 
end rule

rule addObjectParameterToProcsWithoutArgs
	ObRecord [id] ObParam [id] ObInit [id]
    replace [repeat declarationOrStatement]
	procedure PName [id]
	    OIL [opt importList]
	    PBody [subprogramBody]
	procedure ObInit InitPList [opt parameterList]
	    IBody [subprogramBody]
	RestOfScope [repeat declarationOrStatement]
    by
	procedure ObInit InitPList
	    IBody
	procedure PName ( var ObParam : ObRecord )
	    OIL PBody
	RestOfScope 
end rule 

rule addObjectParameterToFunctionsWithArgs
	ObRecord [id] ObParam [id] ObInit [id]
    replace [repeat declarationOrStatement]
	'function FName [id] ( Arg1 [parameterDeclaration]
	    RestOfArgs [repeat commaParameterDecl] )
	    FRes [opt id] : ResultType [typeSpec]
	    OIL [opt importList]
	    FBody [subprogramBody]
	procedure ObInit InitPList [opt parameterList]
	    IBody [subprogramBody]
	RestOfScope [repeat declarationOrStatement]
    by
	procedure ObInit InitPList
	    IBody 
	'function FName ( ObParam : ObRecord , Arg1 RestOfArgs )
	    FRes : ResultType
	    OIL FBody
	RestOfScope 
end rule

rule addObjectParameterToFunctionsWithoutArgs
	ObRecord [id] ObParam [id] ObInit [id]
    replace [repeat declarationOrStatement]
	'function FName [id] FRes [opt id] : ResultType [typeSpec]
	    OIL [opt importList]
	    FBody [subprogramBody]
	procedure ObInit InitPList [opt parameterList]
	    IBody [subprogramBody]
	RestOfScope [repeat declarationOrStatement]
    by
	procedure ObInit InitPList
	    IBody 
	'function FName ( ObParam : ObRecord ) FRes : ResultType
	    OIL FBody
	RestOfScope 
end rule

% This is the rule that does most of the work, just changing calls
% of the form
% 	X.P(Args) to  Module.P(X,Args)
%
% The Turing syntax is set up so that procedure and function calls
% must be handled separately.

rule transformObjects
	ObName [id] ObRecord [id] ObModule [id] ObInit [id]
    replace [repeat declarationOrStatement]
	var ObVar [id] : ObName
	RestOfScope [repeat declarationOrStatement]
    by
	var ObVar : ObModule.ObRecord
	ObModule.ObInit (ObVar)
	RestOfScope [changeProcsWithArgs ObVar ObModule]
	    [changeProcsWithoutArgs ObVar ObModule]
	    [changeFunsWithArgs ObVar ObModule]
	    [changeFunsWithoutArgs ObVar ObModule]
end rule

rule changeProcsWithArgs ObVar [id] ObModule [id]
    replace [procedureCall]
	ObVar . PName [id] ( Acts [expn] RestActs [repeat commaExpn] )
    by
	ObModule . PName (ObVar, Acts RestActs)
end rule

rule changeProcsWithoutArgs ObVar [id] ObModule [id]
    replace [procedureCall]
	ObVar . PName [id]
    by
	ObModule . PName (ObVar)
end rule

rule changeFunsWithArgs ObVar [id] ObModule [id]
    replace [reference]
	ObVar . PName [id] ( Acts [expn] RestActs [repeat commaExpn] )
	    RestSelectors [repeat componentSelector]
    by
	ObModule . PName (ObVar, Acts RestActs) RestSelectors
	% Watch out -- no comma should go between Acts and RestActs!
end rule

rule changeFunsWithoutArgs ObVar [id] ObModule [id]
    replace [reference]
	ObVar . PName [id]
    by
	ObModule . PName (ObVar)
end rule

rule transformArrayObjects
	ObName [id] ObRecord [id] ObModule [id] ObInit [id]
    replace [repeat declarationOrStatement]
	var ObVar [id] : array Lower [expn] .. Upper [expn] of ObName
	RestOfScope [repeat declarationOrStatement]

    construct IndexVarTmp [id]
	'i
    construct IndexVar [id]
	IndexVarTmp [!]

    by
	var ObVar : array Lower .. Upper of ObModule . ObRecord
	for IndexVar : Lower .. Upper
	    ObModule . ObInit (ObVar (IndexVar))
	'end for
	RestOfScope [changeArrayProcsWithArgs ObVar ObModule]
	    [changeArrayProcsWithoutArgs ObVar ObModule]
	    [changeArrayFunsWithArgs ObVar ObModule]
	    [changeArrayFunsWithoutArgs ObVar ObModule]
end rule

rule changeArrayProcsWithArgs ObVar [id] ObModule [id]
    replace [procedureCall]
	ObVar Sub [subscript] . PName [id] ( Acts [expn] RestActs [repeat commaExpn] )
    by
	ObModule . PName (ObVar Sub, Acts RestActs)
end rule

rule changeArrayProcsWithoutArgs ObVar [id] ObModule [id]
    replace [procedureCall]
	ObVar Sub [subscript] . PName [id]
    by
	ObModule . PName (ObVar Sub)
end rule

rule changeArrayFunsWithArgs ObVar [id] ObModule [id]
    replace [reference]
	ObVar Sub [subscript] . PName [id] ( Acts [expn] RestActs [repeat commaExpn] )
	    RestSelectors [repeat componentSelector]
    by
	ObModule . PName (ObVar Sub , Acts RestActs) RestSelectors
end rule

rule changeArrayFunsWithoutArgs ObVar [id] ObModule [id]
    replace [reference]
	ObVar Sub [subscript] . PName [id]
    by
	ObModule . PName (ObVar Sub)
end rule

% Sort to get statements grouped together (to form object initialize proc)
% and variables together (to form object record).
% Final form is:  consts+types, modules, vars, procs, stmts.
% These sort procedures are specialized bubble sorts (is it possible to do
% a faster sort with TXL?).

function sort
    replace [repeat declarationOrStatement]
	ObBody [repeat declarationOrStatement]
    by
	ObBody 
	    [sortDS]	% declarations before statements
	    [sortTV]	% constants, types and modules before variables 
			% and subprograms
	    [sortVP]	% then variables, then subprograms
end function

rule sortDS
    skipping [subScope] replace [repeat declarationOrStatement] 
	S [statement]
	D [declaration]
	R [repeat declarationOrStatement]
    by
	D
	S 
	R 
end rule

rule sortTV
    skipping [subScope] replace [repeat declarationOrStatement]
	V [variableOrSubprogramDeclaration]
	T [constantTypeOrModuleDeclaration]
	R [repeat declarationOrStatement]
    by
	T
	V
	R 
end rule

rule sortVP
     skipping [subScope] replace [repeat declarationOrStatement]
	P [subprogramDeclaration]
	V [variableDeclaration]
	R [repeat declarationOrStatement]
    by
	V 
	P
	R 
end rule
