%%
%%	introduceCpsRequests
%%
%%      T.C. Nicholas Graham
%%      GMD Karlsruhe
%%      August 24, 1992
%%

%% Various optimizations for time and space JRC 13.5.93
%%
%% Notably, converted several recursions to 'each',
%%	    introduced special cases for lists of constants,
%%	    removed intermediate 'cntn forms, which are optimized out anyway,
%%	    and beta-reduced lists (which are the only important case) on the fly.

function introduceCpsRequests
    replace * [repeat definition]
	D [definition] 
	Ds [repeat definition]
    by
	D [cpsEqn] [cpsEval] 
	Ds [introduceCpsRequests]
end function

function cpsEqn
    replace [definition]
	'fun F [functionName] -> E [expression] .
    construct CCName [variable]
	^ 'cc
    construct C [simpleExpression]
	CCName
    by
	'fun F ->
	    'callcc (('fn CCName => E [cpsExpression C])) .
end function

% Main function for cps'ing expressions.  The parameter is the current
% continuation context.
function cpsExpression C [simpleExpression]
    replace [expression]
	E [expression]
    by
	E 
	  %% Note that order of these subfunctions is critical, lest one
	  %% create a pattern that a following one may erroneously add
	  %% the same continuation to again! -- JRC

	  [cpsApplication C] 
	  [cpsPredefinedApplication C]
	  [cpsFunctionName C] 
	  [cpsPredefinedFunction C]
	  [cpsVariable C]
	  [cpsConstant C] 
	  [cpsNullList C]
	  [cpsListConstant C]
	  [cpsListLiteral1 C]
	  [cpsListLiteral2 C]
	  [cpsListLiteral3 C]
	  [cpsConstructor1 C]
	  [cpsConstructor2 C]
	  [cpsConstructor3 C]
	  [cpsConstructor4 C]
	  [cpsConstructor5 C]
	  [cpsConstructor6 C]
	  [cpsIfExpression1 C]
	  [cpsIfExpression2 C]
	  [cpsCaseExpression C]
	  [cpsLetExpression1 C]
	  [cpsLetExpression2 C]
	  [cpsLambdaAbstraction C] 
	  [cpsBinaryOpExpression C]
	  [cpsUnaryOpExpression C]
	  [cpsGroup C]
	  [cpsTuple C]

	  %% Note that beta reducing here will not work since
	  %% at this point we may be half way through the transform 
	  %% of a list or such -- JRC

end function

function cpsConstant C [simpleExpression]
    replace [expression]
	K [constant]
    by
	%% 'cntn (K, C)
	C K
end function

function cpsConstructor1 C [simpleExpression]
    replace [expression]
	$ K [id]
    by
	%% 'cntn ($K, C)
	C $K
end function

function cpsConstructor2 C [simpleExpression]
    replace [expression]
	$ K [id] '!
    by
	'updt ($K, C)
end function

function cpsConstructor3 C [simpleExpression]
    replace [expression]
	$ K [id] '?
    by
	'rqst ($K, C)
end function


function addVarToList E [expression]
    replace [list expression]
	L [list expression]
    construct I [id]
	'cArg
    construct A [expression]
	^ I [!]
    by
	L [, A]
end function

function cpsConstructor4 C [simpleExpression]
    replace [expression]
	$ K [id] ( L [list expression] )
    construct ArgList [list expression]
	_ [addVarToList each L]
    construct CK [expression]
	%% 'cntn (($K (ArgList)), C)
	C ($K (ArgList))
    by
	CK [addLambda each L ArgList]
end function

function cpsConstructor5 C [simpleExpression]
    replace [expression]
	$ K [id] ? ( L [list expression] )
    construct ArgList [list expression]
	_ [addVarToList each L]
    construct CK [expression]
	'rqst (($K (ArgList)), C)
    by
	CK [addLambda each L ArgList]
end function

function cpsConstructor6 C [simpleExpression]
    replace [expression]
	$ K [id] ! ( L [list expression] )
    construct ArgList [list expression]
	_ [addVarToList each L]
    construct CK [expression]
	'updt (($K (ArgList)), C)
    by
	CK [addLambda each L ArgList]
end function

function addLambda L [expression] A [expression]
    replace [expression]
	E [expression]
    deconstruct A
	A1 [variable]
    construct C [simpleExpression]
	('fn A1 => E)
    by
	L [cpsExpression C] 
end function

function cpsFunctionName C [simpleExpression]
    replace [expression]
	K [functionName]
    by
	'setcc (C, K)
	% 'cntn (C, K)
end function

function cpsVariable C [simpleExpression]
    replace [expression]
	K [variable]
    by
	%% 'cntn (K, C)
	C K
end function

function cpsNullList C [simpleExpression]
    replace [expression]
	'[ ']
    by
	%% 'cntn ('[ '], C)
	C '[ ']
end function

function cpsListConstant C [simpleExpression]
    replace [expression]
       LC [listConstant]
    by
	C LC
	%% 'cntn (LC, C)
end function

function cpsListLiteral1 C [simpleExpression]
    replace [expression]
	'[ L1 [expression] ']
    construct I [id]
	'le
    construct Elt [variable]
	^ I [!]
    construct C1 [simpleExpression]
	%% ( fn Elt => 'cntn ('[ Elt '], C) )
	( fn Elt => C '[ Elt '] )
    by
	L1 [cpsExpression C1] 
	   [betaReduce] %% We can reduce here since the whole list is now done -- JRC
end function

function cpsListLiteral2 C [simpleExpression]
    replace [expression]
	'[ L1 [expression], L2 [list expression+] La [opt appendListLiteral] ']
    construct I [id]
	'ls
    construct Elt1 [variable]
	^ I [!]
    construct Elt2 [variable]
	^ I [!]
    construct NLs [expression]
	'[ L2 La ']
    construct C2 [simpleExpression]
	%% ('fn Elt2 => 'cntn ('[ Elt1 '| Elt2 '], C) )
	('fn Elt2 => C '[ Elt1 '| Elt2 '] )
    construct C1 [simpleExpression]
	('fn Elt1 => NLs [cpsExpression C2])
    by
	L1 [cpsExpression C1]
	   [betaReduce] %% We can reduce here since the whole list is now done -- JRC
end function

function cpsListLiteral3 C [simpleExpression]
    replace [expression]
	'[ L1 [expression] '| L2 [expression] ']
    construct I [id]
	'le
    construct Elt1 [variable]
	^ I [!]
    construct Elt2 [variable]
	^ I [!]
    construct C2 [simpleExpression]
	%% ('fn Elt2 => 'cntn ('[ Elt1 '| Elt2 '], C) )
	('fn Elt2 => C '[ Elt1 '| Elt2 '] )
    construct C1 [simpleExpression]
	('fn Elt1 => L2 [cpsExpression C2])
    by
	L1 [cpsExpression C1] 
	   [betaReduce] %% We can reduce here since the whole list is now done -- JRC
end function

function cpsIfExpression1 C [simpleExpression]
    replace [expression]
	( 'if E1 [expression] 'then
	    E2 [expression]
	'else
	    E3 [expression]
	)
    construct I [id]
	'ifExp
    construct IfVar [variable]
	^ I [!]
    construct CE2 [expression]
	E2 [cpsExpression C]
    construct CE3 [expression]
	E3 [cpsExpression C]
    construct C1 [simpleExpression]
	('fn IfVar => ('if IfVar 'then CE2 'else CE3))
    by
	E1 [cpsExpression C1] 
end function

function cpsIfExpression2 C [simpleExpression]
    replace [expression]
	( 'if P [pattern] = E1 [expression] 'then
	    E2 [expression]
	'else
	    E3 [expression]
	)
    construct I [id]
	'ifExp
    construct IfVar [variable]
	^ I [!]
    construct CE2 [expression]
	E2 [cpsExpression C]
    construct CE3 [expression]
	E3 [cpsExpression C]
    construct C1 [simpleExpression]
	('fn IfVar => ('if P = IfVar 'then CE2 'else CE3))
    by
	E1 [cpsExpression C1]
end function

function cpsCaseExpression C [simpleExpression]
    replace [expression]
	( 'case E1 [expression] 'of          
	    A [alternative]
	    As [repeat alternatives]         
	)
    construct I [id]
	'caseExp
    construct CaseVar [variable]
	^ I [!]
    construct CA [alternative]
	A [cpsAlternative C]
    construct CAs [repeat alternatives]
	As [cpsAlternatives C]
    construct C1 [simpleExpression]
	('fn CaseVar =>
	    ('case CaseVar 'of
		CA
		CAs
	    )
	)
    by
	E1 [cpsExpression C1] 
end function

function cpsAlternative C [simpleExpression]
    replace [alternative]
	P [pattern] -> E [expression]
    by
	P -> E [cpsExpression C] 
end function

function cpsAlternatives C [simpleExpression]
    replace [repeat alternatives]
	'| A [alternative]
	As [repeat alternatives]
    by
	'| A [cpsAlternative C]
	As [cpsAlternatives C]
end function

function cpsLetExpression1 C [simpleExpression]
    replace [expression]
	( 'let P [pattern] = Eb [expression] 'in          
	    E [expression]
	)
    construct I [id]
	'bindExp
    construct BindVar [variable]
	^ I [!]
    construct C1 [simpleExpression]
	('fn BindVar =>
	    ('let P = BindVar 'in
		E [cpsExpression C]
	    )
	)
    by
	Eb [cpsExpression C1]
end function

%	Buggy -- does not correctly handle mutually recursive
%	definitions.
function cpsLetExpression2 C [simpleExpression]
    replace [expression]
	( 'let B [binding],
	       Bs [list binding+] 'in          
	    E [expression]
	)
    construct FollowLet [expression]
	('let B 'in ('let Bs 'in E) )
    by
	FollowLet [cpsExpression C]
end function

function cpsLambdaAbstraction C [simpleExpression]
    replace [expression]
	('fn D [variable] => E [expression] )
    construct I [id]
	'cc
    construct CVar [variable]
	^ I [!]
    construct CC [simpleExpression]
	CVar
    construct NewFn [simpleExpression]
	( 'fn D => 'callcc ( ('fn CVar => E [cpsExpression CC] ) ) )
    by
	%% 'cntn ( NewFn , C )
	C NewFn
end function

function cpsGroup C [simpleExpression]
    replace [expression]
	( E [expression] )
    by
	E [cpsExpression C]
end function

function cpsTuple C [simpleExpression]
    replace [expression]
	( L [list expression] )
    construct ArgList [list expression]
	_ [addVarToList each L]
    construct CK [expression]
	%% 'cntn ((ArgList), C)
	C (ArgList)
    by
	CK [addLambda each L ArgList]
end function

function cpsBinaryOpExpression C [simpleExpression]
    replace [expression]
	E1 [binarySubExpression] Op [binaryOp] E2 [binarySubExpression]
    construct I [id]
	'bArg
    construct V1 [variable]
	^ I [!]
    construct V2 [variable]
	^ I [!]
    construct C2 [simpleExpression]
	%% ('fn V2 => 'cntn ((V1 Op V2), C))
	('fn V2 => C (V1 Op V2) )
    construct E1e [expression]
	E1
    construct E2e [expression]
	E2
    construct CE2 [expression]
	E2e [cpsExpression C2]
    construct C1 [simpleExpression]
	('fn V1 => CE2)
    by
	E1e [cpsExpression C1]
end function

function cpsUnaryOpExpression C [simpleExpression]
    replace [expression]
	Uop [unaryOp] E [simpleExpression]
    construct I [id]
	'uArg
    construct V [variable]
	^ I [!]
    construct C1 [simpleExpression]
	%% ('fn V => 'cntn ((Uop V), C))
	('fn V => C (Uop V) )
    construct Ee [expression]
	E
    by
	Ee [cpsExpression C1]
end function

function cpsApplication C [simpleExpression]
    replace [expression]
	Fn [simpleExpression] Arg [simpleExpression]
    construct I [id]
	'applArg
    construct LA [variable]
	^ I [!]
    construct A [variable]
	^ I [!]
    construct CA [simpleExpression]
	('fn A => 'setcc (C, (LA A)) )
    construct EArg [expression]
	Arg
    construct CFn [simpleExpression]
	('fn LA => EArg [cpsExpression CA])
    construct EFn [expression]
	Fn
    by
	EFn [cpsExpression CFn]
end function


function cpsEval
    replace [definition]
	'eval E [expression] .
    construct X [id]
	'x
    construct Xx [variable]
	^ X [!]
    construct NullC [simpleExpression]
	( 'fn Xx => Xx )
    by
	'eval E [cpsExpression NullC] .
end function


%%
%%	Predefined applications -- make into a constructor symbol, and
%%	let them be transformed that way.
%%
%%	BUG:  doesn't properly handle fnal parameters, since the predefined
%%	doesn't expect them to be in cps.
%%

function cpsPredefinedApplication C [simpleExpression]
    replace [expression]
	~ F [id] ( Ps [list expression+] )
    construct ApplAsCS [expression]
	$ F ( Ps )
    by
	ApplAsCS [cpsExpression C]
end function


function cpsPredefinedFunction C [simpleExpression]
    replace [expression]
	~ F [id]
    construct CTerm [expression]
	$ F
    by
	CTerm [cpsExpression C]
end function
