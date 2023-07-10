% Ryman metaprogram for creating C glue routines from GL library spec
% J.R. Cordy, 23.11.91

% hacked-up working grammars for prototyping purposes
include "Fspecs.grm"
include "CglueRoutines.grm"

% silly main rule currently required by TXL to specify the database scope
function main
    replace [program] DB [repeat functionSpec_or_CglueRoutine] 
    by                DB [createCglueRoutines]
end function

% The real work happens here -
% this one is a TXL rule, which means it is automatically instantiated 
% for each pattern match in the database.
rule createCglueRoutines

    % find all GL function specs in the database
    replace [functionSpec_or_CglueRoutine]
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

    % empty C pointer field list
    construct PFL [repeat typeSpecIndirectParameterNameSemi]
        % empty

    % empty C parameter declarations
    construct PDL [repeat typeSpecParameterNameSemi]
        % empty

    % empty C input parameter bindings
    construct IPL [repeat inParameterBindingSemi]
        % empty

    % empty C output parameter bindings
    construct OPL [repeat outParameterBindingSemi]
        % empty

    % default C function call
    construct FC [functionCallSemi]
        F ();

    % default return code
    construct RC [returnCode]
        return (0);

    by
        int MPF (p)
                struct
                {
                        PFL [addParameterPointerField F each RPS] 
                            [addResultPointerField F ORS]
                            [addDummyFieldIfNecessary]
                } *p;
        { 
                PDL [addParameterDeclaration F each RPS]
                    [addResultDeclaration F ORS]
                IPL [addInputParameterBinding F each RPS]
                FC [addResultAssign F ORS] 
                   [addInputParameter F each RPS]
                OPL [addOutputParameterBinding F each RPS]
                RC [addFailCondition F OFS] 
        }
end rule

function addParameterPointerField F [id] PS [parameterSpec]
    % get the parts of the parameter spec
    deconstruct PS
        parameter ( F , IO [inOut] , TS [typeSpec] , PN [parameterName] ).

    % make the C parameter pointer field declaration
    construct P [typeSpecIndirectParameterNameSemi]
        TS * PN ;

    % now append this parameter field
    replace [repeat typeSpecIndirectParameterNameSemi]
        PL [repeat typeSpecIndirectParameterNameSemi]
    by
        PL [. P]
end function

function addResultPointerField F [id] ORS [opt returnsSpec]
    % for each returns spec
    deconstruct ORS
        returns ( F , TS [typeSpec] , PN [id] ).

    % make the C parameter pointer field declaration
    construct P [typeSpecIndirectParameterNameSemi]
        TS * PN ;

    % now append this parameter field
    replace [repeat typeSpecIndirectParameterNameSemi]
        PL [repeat typeSpecIndirectParameterNameSemi]
    by
        PL [. P]
end function

function addDummyFieldIfNecessary
    replace [repeat typeSpecIndirectParameterNameSemi]
        % nothing
    by
        int * dummy;
end function

function addParameterDeclaration F [id] PS [parameterSpec]
    % get the parts of the parameter spec
    deconstruct PS
        parameter ( F , IO [inOut] , TS [typeSpec] , PN [parameterName] ).

    % make the C parameter declaration
    construct P [typeSpecParameterNameSemi]
        TS PN ;

    % now append this parameter declaration
    replace [repeat typeSpecParameterNameSemi]
        PL [repeat typeSpecParameterNameSemi]
    by
        PL [. P]
end function

function addResultDeclaration F [id] ORS [opt returnsSpec]
    % for each returns spec
    deconstruct ORS
        returns ( F , TS [typeSpec] , PN [id] ).

    % make the C local declaration
    construct P [typeSpecParameterNameSemi]
        TS PN ;

    % now append this parameter declaration
    replace [repeat typeSpecParameterNameSemi]
        PL [repeat typeSpecParameterNameSemi]
    by
        PL [. P]
end function

function addInputParameterBinding F [id] PS [parameterSpec]
    % for each 'in' parameter spec
    deconstruct PS
        parameter ( F , in , TS [typeSpec] , PN [parameterName] ).

    % make the C binding
    construct IPB [inParameterBindingSemi]
        PN = ( TS ) * p -> PN ;

    % now append this parameter binding
    replace [repeat inParameterBindingSemi]
        PBL [repeat inParameterBindingSemi]
    by
        PBL [. IPB]
end function

function addOutputParameterBinding F [id] PS [parameterSpec]
    % for each 'out' parameter spec
    deconstruct PS
        parameter ( F , out , TS [typeSpec] , PN [parameterName] ).

    % make the C binding
    construct OPB [outParameterBindingSemi]
        * p -> PN = ( TS) PN ;

    % now append this parameter binding
    replace [repeat outParameterBindingSemi]
        PBL [repeat outParameterBindingSemi]
    by
        PBL [. OPB]
end function

function addFailCondition F [id] OFS [opt failsSpec]
    % check for a fail condition
    deconstruct OFS
        'fails ( F , C [stringlit] ) .
    construct FC [id]
        'NONE
    replace [returnCode]
        'return (0);
    by
        'return ( FC [unquote C] );
end function

function addResultAssign F [id] ORS [opt returnsSpec]
    % for each returns spec
    deconstruct ORS
        returns ( F , TS [typeSpec] , PN [id] ).
    replace [functionCallSemi]
        F ( PL [list parameterName] );
    by
        PN = F ( PL );
end function

function addInputParameter F [id] PS [parameterSpec]
    % for each 'in' parameter spec
    deconstruct PS
        parameter ( F , in , TS [typeSpec] , PN [parameterName] ).
    replace [functionCallSemi]
        OPNE [opt outParameterNameEquals] F ( PL [list parameterName] );
    by
        F ( PL [, PN] );
end function

% external function unquote S [stringlit]
