% Ryman metaprogram for creating C function headers from GL library spec
% J.R. Cordy, 15.11.91

% hacked-up working grammars for prototyping purposes
include "Fspecs.grm"
include "Cfunctions.grm"

% silly main rule currently required by TXL to specify the database scope
function main
    replace [program] DB [repeat functionSpec_or_CfunctionHeader] 
    by 		      DB [createCfunctionDeclarations]
end function

% The real work happens here -
% this one is a TXL rule, which means it is automatically instantiated 
% for each pattern match in the database.
rule createCfunctionDeclarations

    % find all GL function specs in the database
    replace [functionSpec_or_CfunctionHeader]
	% pattern to match one complete function spec in the database
	FNS [functionNameSpec]
	RPS [repeat parameterSpec]
	ORS [opt returnsSpec]
	OFS [opt failsSpec]

    % get the function name from the spec
    deconstruct FNS
	'function ( F [id] ).

    % the mpro_ function name prefix
    construct MPRO [id]
	mpro_
    construct MPF [id]
	MPRO [_ F]

    % default C result type
    construct RT [typeSpec_or_void]
	void

    % empty C parameter list
    construct PL [list typeSpecParameterName]
	% empty

    % make the actual C function header
    construct CfunctionHeader [functionSpec_or_CfunctionHeader]
	%     replace RT with F's result type
	%          ---------^---------             
	%          |                 |       
	%          |                 |
	extern RT [setResultType F ORS] MPF 
		( /* PL [addParameter F each RPS] */ );
	%	         |                     |
	%        	 ----------v------------
	%	   add each parameter of F to the list
    by
	CfunctionHeader
end rule

function setResultType F [id] ORS [opt returnsSpec]
    % see if there is a result spec for F
    deconstruct ORS
	returns ( F , TS [typeSpec] , RN [returnsName] ).

    % if there is, replace void with the real C result type
    replace [typeSpec_or_void]
	void
    by
	TS
end function

function addParameter F [id] PS [parameterSpec]
    % get the parts of the parameter spec
    deconstruct PS
	parameter ( F , IO [inOut] , TS [typeSpec] , PN [parameterName] ).

    % make the C parameter declaration
    construct P [typeSpecParameterName]
	TS PN 

    % now append this parameter to the C parameter list
    replace [list typeSpecParameterName]
	PL [list typeSpecParameterName]
    by
	PL [, P]
end function
