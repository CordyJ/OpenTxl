%%
%%	Processes import lists.  The kind of the import must be
%%	specified by the import keyword chosen:  importType or importFun.
%%	Function imports are flagged as special prededined functions
%%	throughout the text of the program.
%%

function doImports
    replace [program]
	P [program]
    by
	P [doFunImports] [doTypeImports]
end function

rule doFunImports
    replace [repeat definition]
	'importFun F [functionName] 'from M [id] .
	Ds [repeat definition]
    by
	'from M 'import F .
	Ds [findPredefinedApplications1 F] [findPredefinedApplications2 F]
end rule

rule doTypeImports
    replace [repeat definition]
	'importType T [typeName] 'from M [id] .
	Ds [repeat definition]
    by
	'from M 'import T .
	Ds
end rule

rule findPredefinedApplications1 F [functionName]
    replace [expression]
	F Parms [repeat simpleExpression+]
    deconstruct F
	I [lowerupperid]
    construct PAppl [predefinedApplication]
	I Parms
    by
	PAppl
end rule

rule findPredefinedApplications2 F [functionName]
    replace [simpleExpression]
	F
    deconstruct F
	I [lowerupperid]
    construct PF [predefinedFunctionName]
	I
    by
	PF
end rule
