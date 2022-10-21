%%
%%	Adds a continuation parameter to all lambda abstractions.
%%
%%
%%

function addContinuationParameter
    replace [program]
	P [program]
    by
	P [addCParameter] [cfnToFn]
end function

rule addCParameter
    replace [lambdaAbstraction]
	( 'fn X [variable] => E [expression] )
    construct DummyId [lowerupperid]
	'd
    construct D [variable]
	^ DummyId [!]
    construct ContParm [lowerupperid]
	'c
    construct C [variable]
	^ ContParm [!]
    by
	( 'cfn D =>
	    ( 'let (C, X) = D 'in
		E
	    )
	)
end rule

rule cfnToFn
    replace [lambdaAbstraction]
	( 'cfn X [variable] => E [expression] )
    by
	( 'fn X => E )
end rule
