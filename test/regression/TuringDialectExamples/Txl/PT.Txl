% Parameterized Type Turing dialect
% Jim Cordy
% Queen's University, October 1988

include "Turing.Grammar"


% Syntactic forms

define declaration
	[moduleDeclaration]
    |	[constantDeclaration]
    |	[typeDeclaration]
    |	[parameterizedTypeDeclaration]
    |	[variableDeclaration]
    |	[variableBinding]
    |	[subprogramDeclaration]
end define

define parameterizedTypeDeclaration
	'type [opt Pervasive] [id] ( [list id] ) : [typeSpec]
end define

define typeSpec
	[standardType]			
    |	[arrayType]			
    |	[recordType]
    |	[enumeratedType]
    |	[setType]
    |	[unionType]
    |	[collectionType]
    |	[pointerType]
    |	[subrangeType]
    |	[parameterizedTypeInstance]
    |	[namedType]
end define

define parameterizedTypeInstance
	[id] ( [list expnOrTypeSpec] )
end define

define expnOrTypeSpec
	[id]		% We'll separate the ambiguous case here.
    |	[typeSpec]
    |	[expn]	
end define



% Semantic transforms

rule main
    replace [repeat declarationOrStatement] 
	'type OP [opt Pervasive] PTname [id] ( Formals [list id] ) : 
	    PTBody [typeSpec]
	RestOfScope [repeat declarationOrStatement]
    by
	RestOfScope [fixInstances PTname Formals PTBody]
end rule

rule fixInstances PTname [id] Formals [list id] PTBody [typeSpec]
    replace [typeSpec]
	PTname ( Actuals [list expnOrTypeSpec] )
    by
	PTBody [subsId each Formals Actuals]
		[subsType each Formals Actuals] 
		[subsExpn each Formals Actuals]
end rule

rule subsId Old [id] New [expnOrTypeSpec]
    deconstruct New 
	NewName [id]
    replace [id] 
	Old 
    by
	NewName
end rule

rule subsType Old [id] New [expnOrTypeSpec]
    deconstruct New 
	NewType [typeSpec]
    replace [typeSpec] 
	Old 
    by
	NewType
end rule

rule subsExpn Old [id] New [expnOrTypeSpec]
    deconstruct New 
	NewExpn [expn]
    replace [primary] 
	Old 
    by
	( NewExpn )
end rule
