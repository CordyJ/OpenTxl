%%
%%	Translates Clock programs to GTML.
%%
%%	T.C. Nicholas Graham
%%	GMD Karlsruhe
%%	21 Aug 1992
%%


function toGtml
    replace [program]
	D [program]
    by
	D [doVariable] 
	  [doFunctionName] 
	  [doPredefinedFunctionName]
	  [doConstructorSymbol1]
	  [doConstructorSymbol2] 
	  [doTypeName] 
	  [doTypeVariable]
	  [doTypeDefinition1] 
	  [doTypeDefinition2]
	  [doDataDefinition1] 
	  [doDataDefinition2]
	  [doTypeSpec1] 
	  [doTypeSpec2] 
	  [fixFunctionTypes]
	  [doDataType]
	  [doFunDefinition]
	  [doEquation]
	  [doPattern]
	  [doConstructorTerm] 
	  % [fixupConstructorTerm]
	  % [doLambdaAbstraction]
	  [unnestIfs] 
	  [doIfExpression]
	  [doCaseExpression] 
	  [doCaseAlternative]
	  % [doLetExpression]
	  [doPredefinedApplications]
	  [doNameCleanups]
end function

rule doVariable
    replace [variable]
	V [lowerupperid]
    by
	^ V
end rule

rule doFunctionName
    replace [functionName]
	F [lowerupperid]
    by
	@ F
end rule

rule doPredefinedFunctionName
    replace [predefinedFunctionName]
	F [lowerupperid]
    by
	~ F
end rule

rule doConstructorSymbol1
    replace [constructorSymbol]
	C [upperlowerid]
    by
	$ C
end rule

rule doConstructorSymbol2
    replace [constructorSymbol]
	C [upperlowerid] S [directiveSymbol]
    by
	$ C S
end rule

rule doTypeName
    replace [typeName]
	T [upperlowerid]
    by
	& T
end rule

rule doTypeVariable
    replace [typeVariable]
	T [lowerupperid]
    by
	^ T
end rule


%%
%%	Type Definitions
%%

rule doTypeDefinition1
    replace [typeDefinition]
	'type T [typeName] = TS [typeSpec] .
    by
	'type T == TS .
end rule


rule doTypeDefinition2
    replace [typeDefinition]
	'type T [typeName] TV [typeVariable] TVs [repeat typeVariable]
	    = TS [typeSpec] .
    construct TVl [list typeVariable+]
	TV
    by
	'type T ( TVl [, each TVs] ) == TS .
end rule



%%
%%	Data Definitions
%%

rule doDataDefinition1
    replace [dataDefinition]
	'data T [typeName] = DT [dataTypes] .
    by
	'type T ::= DT .
end rule

rule doDataDefinition2
    replace [dataDefinition]
	'data T [typeName] TV [typeVariable] TVs [repeat typeVariable]
	    = DT [dataTypes] .
    construct TVl [list typeVariable+]
	TV
    by
	'type T ( TVl [, each TVs] ) ::= DT .
end rule



%%
%%	Type Specs
%%

rule doTypeSpec1
    replace [typeSpec]
	S [simpleType] -> T [typeSpec]
    by
	S => T
end rule

rule doTypeSpec2
    replace [typeSpec]
	N [typeName] T [simpleType] Ts [repeat simpleType]
    construct Tl [list simpleType+]
	T
    by
	N ( Tl [, each Ts] )
end rule


%  Complications with type specs:  Clock fn's are implemented using
%  GTML's two kinds of functions, lambda abstractions and equations.
%  In general it _appears_ to be safe to use lambda abstractions,
%  since the generated equations have no parameters.  But the top-level
%  functions must nevertheless be declared with a void type in their
%  fun declarations.

rule fixFunctionTypes
    replace [functionTypeSpec]
	T [typeSpec]
    by
	'void -> T
end rule



%%
%%	Data Types
%%

% Case of no type parameter requires no change
rule doDataType
    replace [dataType]
	C [constructorSymbol] T [simpleType] Ts [repeat simpleType]
    construct Tl [list simpleType+]
	T
    by
	C ( Tl [, each Ts] )
end rule



%%
%%	Function Types
%%

rule doFunDefinition
    replace [funDefinition]
	F [functionName] :: T [functionTypeSpec] .
    by
	'type F :: T .
end rule



%%
%%	Equations -- only simple equations left at this point
%%

rule doEquation
    replace [equation]
	F [functionName] = E [expression] .
    by
	'fun F -> E .
end rule



%%
%%	Patterns
%%


rule doPattern
    replace [pattern]
	C [constructorSymbol] P [simplePattern] Ps [repeat simplePattern]
    construct Pl [list simplePattern+]
	P
    by
	C ( Pl [, each Ps] )
end rule



%%
%%	Constructor Terms
%%


rule doConstructorTerm
    replace [expression]
	C [constructorSymbol] E [simpleExpression] Es [repeat simpleExpression]
    construct El [list simpleExpression+]
	E
    by
	C ( El [, each Es] )
end rule

% Add paren's around constructor terms to make sure gtml binds them right
rule fixupConstructorTerm
    replace [expression]
	C [constructorTerm]
    by
	( C )
end rule



%%
%%	Lambda Abstractions
%%

rule doLambdaAbstraction
    replace [lambdaAbstraction]
	'fn V [variable] -> E [expression] 'end 'fn
    by
	( 'fn V =>  E )
end rule



%%
%%	If Expression
%%

rule unnestIfs
    replace [ifExpression]
	'if E1 [ifCondition] 'then
	    E2 [expression]
	'elsif E3 [ifCondition] 'then
	    E4 [expression]
	Elifs [repeat elsifClause]
	El [elseClause]
	'end 'if
    by
	( 'if E1 'then
		E2
	   'else
	       'if E3 'then
		   E4
		Elifs
		El
	       'end 'if
	 )
end rule

rule doIfExpression
    replace [ifExpression]
	'if E1 [ifCondition] 'then
	    E2 [expression]
	El [elseClause]
	'end 'if
    by
	( 'if E1 'then E2 El )
end rule



%%
%%	Case expression
%%

rule doCaseExpression
    replace [caseExpression]
	'case E [expression] 'of
	    A [alternative]
	    As [repeat alternatives]
	'end 'case
    by
	( 'case E 'of
	    A
	    As
	)
end rule

rule doCaseAlternative
    replace [alternative]
        P [pattern] : E [expression]
    by
	P -> E
end rule





%%
%%	Let expression
%%

rule doLetExpression
    replace [letExpression]
	'let B [list binding+] 'in
	    E [expression]
	'end 'let
    by
        ( 'let B 'in E )
end rule


%%
%%	Predefined applications
%%
%%

rule doPredefinedApplications
    replace [predefinedApplication]
	F [predefinedFunctionName] P [simpleExpression]
	    Parms [repeat simpleExpression]
    construct PL [list simpleExpression+]
	P
    construct ParmList [list simpleExpression+]
	PL [, each Parms]
    by
	F ( ParmList )
end rule


%%
%% 	Any odds and ends due to problems with naming in gtml.
%%

rule doNameCleanups
    replace [constructorSymbol]	
	$ At
    by
	$ Att
end rule
