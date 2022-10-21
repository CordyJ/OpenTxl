% parFacts.Txl

include "Turing+.grm"


function main
    replace [program]
	C [compilation]
    by
	C 
	[varParameterFacts]
	[constParameterFacts]
end function


rule constParameterFacts
	skipping [subprogramBody]
	replace [parameterDeclaration]
	    ID [id] : PT [parameterType]
	by
	    '$ conidPar ( ID ) '$
end rule

rule varParameterFacts
	skipping [subprogramBody]
	replace [parameterDeclaration]
	    'var ID [id] : PT [parameterType]
	by
	    '$ varidPar ( ID ) '$
end rule

