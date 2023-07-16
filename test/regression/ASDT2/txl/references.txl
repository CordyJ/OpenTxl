% references.Txl
% rules for embedding symbol reference facts 

% fixed to handle function references correctly -- JRC 4.8.92
% fixed to handle var parameter arguments correctly -- JRC 10.8.92

% added module handling -- JRC 24.8.93
% merged globalRefs.Txl and moduleRefs.Txl -- JRC 24.8.93
% merged procedureRefs.Txl and functionRefs.Txl -- JRC 24.8.93

% merged *Refs.Txl -- JRC 25.8.93


include "Turing+.grm"

function main
    replace [program]
	P [repeat declarationOrStatement]
    construct AllFuncs [repeat functionDeclarator]
	_ [^ P]
    by
	P   % main program refs
	    % Order of these is important!
	    [embedProcCalls 'PROGRAM]
	    [embedFuncCalls 'PROGRAM AllFuncs]
	    [embedVarParmRefs 'PROGRAM]
	    [embedPutRefs 'PROGRAM]
	    [embedGetRefs 'PROGRAM]

	    % module refs
	    [getModuleRefs AllFuncs]

	    % subprogram refs
	    [getProcedureRefs AllFuncs]
	    [getFunctionRefs AllFuncs]
	    [cleanupMarks]
end function

rule getModuleRefs AllFuncs [repeat functionDeclarator]
	skipping [subprogramBody]
	replace [declaration]
		'module M [id] 
		    Scope [repeat declarationOrStatement]
		'end M
	construct EmbeddedModule [declaration]
		'MARK 'module M
		    Scope % Order of these is important!
			  [embedProcCalls M]
			  [embedFuncCalls M AllFuncs]
			  [embedVarParmRefs M]
			  [embedPutRefs M]
			  [embedGetRefs M]
		'end M
	by
		EmbeddedModule
end rule

rule getProcedureRefs AllFuncs [repeat functionDeclarator]
	skipping [subprogramBody]
	replace [declaration]
		'procedure P [id] ParmList [opt parameterListDeclaration] 
		    Scope [repeat declarationOrStatement]
		'end P
	construct EmbeddedProc [declaration]
		'MARK 'procedure P ParmList 
			Scope 
			    % Order of these is important!
			    [embedProcCalls P]
			    [embedFuncCalls P AllFuncs]
			    [embedVarParmRefs P]
			    [embedPutRefs P]
			    [embedGetRefs P]
		'end P
	by
		EmbeddedProc
end rule

rule getFunctionRefs AllFuncs [repeat functionDeclarator]
	skipping [subprogramBody]
	replace [declaration]
		'function F [id] ParmList [opt parameterListDeclaration] 
			: ResultType [typeSpec]
		    Scope [repeat declarationOrStatement]
		'end F
	construct EmbeddedFunc [declaration]
		'MARK 'function F ParmList : ResultType
			Scope 
			    % Order of these is important!
			    [embedProcCalls F]
			    [embedFuncCalls F AllFuncs]
			    [embedVarParmRefs F]
			    [embedPutRefs F]
			    [embedGetRefs F]
		'end F
	by
		EmbeddedFunc
end rule

rule embedProcCalls P [id]
	skipping [bigSubprogramDeclaration]
	replace [callStatement]
		REF [id] CS [repeat componentSelector]
	by
		'$ 'procCall ( P, REF ) '$ CS
end rule

function embedFuncCalls P [id] AllFunctions [repeat functionDeclarator]
    replace [repeat declarationOrStatement]
	ThisScope [repeat declarationOrStatement]
    by
	ThisScope [embedFuncCallsOf P each AllFunctions]
end function

rule embedFuncCallsOf P [id] FD [functionDeclarator]
    deconstruct FD 
	F [id]
    skipping [bigSubprogramDeclarationAndImportExportList]
    replace [subReference]
	F 
    by
	'$ 'procCall ( P, F ) '$
end rule

rule embedVarParmRefs P [id]
    skipping [bigSubprogramDeclaration]
    replace [argument]
	    REF [id] CS [repeat componentSelector] : 'var Formal [id]
    by
	    % These imply a binding to the formal, so make a special
	    % fact for it
	    '$ 'varActualRef ( P, REF, Formal ) '$ CS
end rule

rule embedPutRefs P [id]
    skipping [bigSubprogramDeclaration]
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
    skipping [bigSubprogramDeclarationAndImportExportList]
	replace [subReference]
		REF [id]
	by
		'$ 'getRef ( P, REF ) '$ 
end rule

function cleanupMarks
    construct AMark [opt 'MARK]
	'MARK
    construct NoMark [opt 'MARK]
	% nada
    replace [repeat declarationOrStatement]
	P [repeat declarationOrStatement]
    by
	P [$ AMark NoMark]
end function
