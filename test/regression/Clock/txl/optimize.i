%%
%%	Optimize CPS Transforms
%%
%%	T.C. Nicholas Graham
%%	GMD Karlruhe, 26.8.92
%%
%%

%% Various optimizations for time and space JRC 13.5.93
%% Notably, removed the need for 'removeRequests' by never generating 'cntn,
%%	    and optimized 'pruneEqns'.

function optimize
    replace [program]
	P [program]
    by
	P %% [removeRedundantRequests] [betaReduce]
	  %% [removeRequests] [betaReduce]
	  [pruneEqns] [betaReduce]
end function

%% rule removeRedundantRequests
%%     replace [expression]
%% 	'cntn (E1 [simpleExpression], ('fn V [variable] => E2 [expression]))
%%     by
%% 	('fn V => E2) E1
%% end rule

rule betaReduce
    replace [expression]
	('fn V [variable] => Body [expression]) Arg [simpleExpression]
    construct VE [simpleExpression]
	V
    by
	Body [$ VE Arg]
end rule

%% rule removeRequests
%%     replace [expression]
%% 	'cntn (V [simpleExpression] , C [simpleExpression])
%%     by
%% 	C V
%% end rule

rule pruneEqns
    replace [program]
	P [program]
    deconstruct * [definition] P
	'fun F [functionName] ->
	    %% ('fn InitC [variable] => InitC [variable] E [simpleExpression]) .
	    ('fn InitC [variable] => InitC E [simpleExpression]) .
    by
	P [pruneEqn F] [pruneEqnAppls F]
end rule

function pruneEqn F [functionName]
    replace * [equation]
	'fun F ->
	    %% ('fn InitC [variable] => InitC [variable] E [simpleExpression]) .
	    ('fn InitC [variable] => InitC E [simpleExpression]) .
    by
	'fun F -> E .
end function

rule pruneEqnAppls F [functionName]
    replace [application]
	F E [simpleExpression]
    by
	E F
end rule
