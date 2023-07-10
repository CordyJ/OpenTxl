% Transformations from limited imperative to pure functional form.
% T.C.N. Graham, GMD Karlsruhe, January 1990.

% This specfication extends the grammar of the pure functional
% subset of T'Nial to include limited forms of several imperative 
% programming features, including sequential statements, variables
% and assignment, procedures, out and inout parameters, 
% and global variables (through existential parameters).

% The ruleset prototypes the general transformations of these features
% to pure functional form described in the paper "Clean Introduction of
% Limited Imperative Features into a Functional Programming Language"
% by T.C.N Graham.

include "TN.Grammar"

compounds
    '->  ':=
end compounds

keys
    var procedure exists inout out
end keys

define expression
    [declarationAndExpression]
  | [value]
  | [nullValue]
end define

define nullValue
    [empty]
end define

define declaration
    [functionDeclaration]
  | [assigningDeclaration]
  | [variableDeclaration]
  | [assignment]
  | [multiAssignment]
  | [tameAssignment]
  | [ifValue]
  | [procedureDeclaration]
  | [procedureCall]
  | [block]
end define

define assigningDeclaration
    var [id] := [value]
end define

define variableDeclaration
    var [id] [repeat followingId]
end define

define followingId
    , [id]
end define

define assignment
    [variableReference] := [value]
end define

define multiAssignment
    [variableReferenceList] := [value]
end define

define variableReferenceList
    '[ [variableReference] [followingVariableReferences] ']
end define

define followingVariableReferences
    [repeat followingVariableReference]
end define

define followingVariableReference
    , [variableReference]
end define

define tameAssignment
    [variableReference] -> [value]
end define

% Extend to allow 'exist' parameters
define singleParm
    [existsParm]
  | [outParm]   % out and inout parms permitted only in proc's
  | [inoutParm]
  | [id]
end define

define existsParm
    exists [id]
end define

define outParm
    out [id]
end define

define inoutParm
    inout [id]
end define

define functionApplication
    [id] [actualTuple]
end define

define value
    [number]
  | [phrase]
  | [stringlit]
  | [constructedList]
  | [ifValue]
  | [functionApplication]
  | [variableReference]
end define

define procedureDeclaration
    procedure [id] [parameterList]
        [expression]
    'end [id]
end define

define procedureCall
    [id] [actualTuple]
end define

define block
    { [expression] }
end define


% Transformations to functional form.
%
%       Step 0:  Remove syntactic sugar in if's, var declarations
%       Step 1:  Remove inout/out parameters
%       Step 2:  Remove procedure declarations
%       Step 3:  Remove existential parameters
%       Step 4:  Remove explicit blocks
%       Step 5:  Remove local assignments
%
        %%% Advertisement %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % TEINACHER MINERAL WATER - The true refreshment %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function main
    replace [program]
        E [expression]
    by
        E  [message '"normalizing elses"]
            [addElse] [removeElseifDec] [removeElseif]
            [message '"removing assigning and multi declarations"]
            [removeAssigningDeclarations] [removeMultiDeclarations]
            [message '"removing inout and out parameters"]
            [removeInoutParameters] [removeOutParameters] 
            [message '"removing procedures"]
            [removeProcedures]
            [message '"removing existential parameters"]
            [removeExistentialParameters]
            [message '"removing explicit blocks"]
            [removeExplicitBlocks] 
            [message '"removing ifs"]
            [removeIfStatement]  
            [message '"removing var declarations"]
            [removeVarDeclarations] 
            [message '"unwinding multiple assignments"]
            [undoMultiAssignments] 
            [message '"alpha converting assignments"]
            [alphaConvAssign]
            [message '"removing converted assignments"]
            [removeAssignments]
end function

% % % external rule message M [stringlit]
% % % external rule print



%
%       All if statements are mapped to form 'if C then S1 else S2 endif'
%
rule addElse
    replace [ifValue]
        if V [value] then
            E [expression]
        endif
    by
        if V then
            E
        else
        endif
end rule

rule removeElseifDec
    replace [declaration]
        if V1 [value] then
            E1 [expression]
        elseif V2 [value] then
            E2 [expression]
        OtherElseifs [repeat elseifClause]
        ElseC [opt elseClause]
        endif
    by
        if V1 then
            E1
        else
            if V2 then
                E2
            OtherElseifs
            ElseC
            endif ;
        endif
end rule

rule removeElseif
    replace [ifValue]
        if V1 [value] then
            E1 [expression]
        elseif V2 [value] then
            E2 [expression]
        OtherElseifs [repeat elseifClause]
        ElseC [opt elseClause]
        endif
    by
        if V1 then
            E1
        else
            if V2 then
                E2
            OtherElseifs
            ElseC
            endif
        endif
end rule



%
%       Map declarations to normal form:
%               one declaration per line, no initializing assignments
%
rule removeAssigningDeclarations
    replace [expression]
        var X [id] := V [value] ; R [expression]
    by
        var X;
        X := V;
        R
end rule

rule removeMultiDeclarations
    replace [expression]
        var X [id] , Y [id] F [repeat followingId] ; R [expression]
    by
        var X ;
        var Y F ;
        R
end rule



%
%       Inout parameters:  change
%               procedure p (inout X, ...)
%                   ...
%                   X := E;
%                   ...
%               end p
%               ...
%               p (Y);
%       to
%               procedure p (exists NewX, ...)
%                   ...
%                   NewX := E;
%                   ...
%               end p
%               ...
%               {
%                   var NewX;
%                   NewX := Y;
%                   p ();
%                   Y := NewX;
%               };
%
%       For recursive calls in which the actual passed to the parameter is the formal
%       itself, we must be careful not to create the above block because of the name clash.
%       Instead, we simply remove the actual from the actuals tuple.
%

rule removeInoutParameters
    replace [expression]
        procedure P [id] ( inout X [id] OtherParms [repeat followingParm] )
            Body [expression]
        'end P ;
        RestOfScope [expression]
    construct NewX [id]
        X [!]
    construct NewP [id]
        P [!]
    by
        procedure NewP ( exists NewX  OtherParms )
            Body [$ X NewX] 
                    [removeRecursiveCallInoutParameter P NewP NewX]
        'end NewP ;
        RestOfScope [removeNonrecursiveCallInoutParameter P NewP NewX]
end rule

rule removeRecursiveCallInoutParameter P [id]  NewP [id]  NewX [id]
    replace [declaration]
        P A [actualTuple]
    construct PC [declaration]
        P A
    by
        PC [removeRecursiveCallSameParameter1 P NewP NewX]
             [removeRecursiveCallSameParameter2 P NewP NewX]
             [removeCallInoutParameter1 P NewP NewX]
             [removeCallInoutParameter2 P NewP NewX]
end rule

rule removeNonrecursiveCallInoutParameter P [id]  NewP [id]  NewX [id]
    replace [declaration]
        P A [actualTuple]
    construct PC [declaration]
        P A
    by
        PC [removeCallInoutParameter1 P NewP NewX]
             [removeCallInoutParameter2 P NewP NewX]
end rule

function removeRecursiveCallSameParameter1 P [id]  NewP [id]  NewX [id]
    replace [declaration]
        P ( NewX , B [singleActual]  OtherActuals [repeat followingActual] )
    by
        NewP ( B OtherActuals )
end function

function removeRecursiveCallSameParameter2 P [id]  NewP [id]  NewX [id]
    replace [declaration]
        P ( NewX )
    by
        NewP ( )
end function

function removeCallInoutParameter1 P [id] NewP [id]  NewX [id]
    replace [declaration]
        P ( Y [id] )
    by 
        {
            var NewX ;
            NewX := Y ;
            NewP ( ) ;
            Y := NewX ;
        }
end function

function removeCallInoutParameter2 P [id] NewP [id]  NewX [id]
    replace [declaration]
        P ( Y [id] , B [singleActual] OtherActuals [repeat followingActual] )
    by
        {
            var NewX ;
            NewX := Y ;
            NewP ( B OtherActuals ) ;
            Y := NewX ;
        }
end function

rule substituteParameter X [id] V [id]
    replace [id]
        X
    by
        V
end rule


%
%       The transformation of 'out' parameters is similar, except that we do a dummy 
%       assignment of `[]' to each parameter before the application.
%

rule removeOutParameters
    replace [expression]
        procedure P [id] ( out X [id] OtherParms [repeat followingParm] )
            Body [expression]
        'end P ;
        RestOfScope [expression]
    construct NewX [id]
        X [!]
    construct NewP [id]
        P [!]
    by
        procedure NewP ( exists NewX  OtherParms )
            Body [$ X NewX] 
                    [removeRecursiveCallOutParameter P NewP NewX]
        'end NewP ;
        RestOfScope [removeNonrecursiveCallOutParameter P NewP NewX]
end rule

rule removeRecursiveCallOutParameter P [id]  NewP [id]  NewX [id]
    replace [declaration]
        P A [actualTuple]
    construct PC [declaration]
        P A
    by
        PC [removeRecursiveCallSameParameter1 P NewP NewX]
             [removeRecursiveCallSameParameter2 P NewP NewX]
             [removeCallOutParameter1 P NewP NewX]
             [removeCallOutParameter2 P NewP NewX]
end rule

rule removeNonrecursiveCallOutParameter P [id]  NewP [id]  NewX [id]
    replace [declaration]
        P A [actualTuple]
    construct PC [declaration]
        P A
    by
        PC [removeCallOutParameter1 P NewP NewX]
             [removeCallOutParameter2 P NewP NewX]
end rule

function removeCallOutParameter1 P [id]  NewP [id]  NewX [id]
    replace [declaration]
        P ( Y [id] )
    by 
        {
            var NewX ;
            NewX := '[ '] ;
            NewP ( ) ;
            Y := NewX ;
        }
end function

function removeCallOutParameter2 P [id]  NewP [id]  NewX [id]
    replace [declaration]
        P ( Y [id] , B [singleActual] OtherActuals [repeat followingActual] )
    by
        {
            var NewX ;
            NewX := '[ '] ;
            NewP ( B OtherActuals ) ;
            Y := NewX ;
        }
end function



%
%       Remove procedures.  Map:
%               procedure p (exists X, exists Y)
%                   ...;
%               end p;
%               p()
%       to
%               function p (exists X, exists Y)
%                   ...;
%                   X
%               end p;
%               [ X, Y ] := p()
%

rule removeProcedures
    replace [expression]
        PD [procedureDeclaration] ;
        E [expression]
    deconstruct PD
        procedure P [id] ( exists X [id]  Others [repeat followingParm] )
            Body [expression]
        'end P 
    construct OneEPlist [variableReferenceList]
        '[ X '] 
    construct EPlist [variableReferenceList]
        OneEPlist [addExistentialParameterIds Others]
    construct FD [functionDeclaration]
        'function P (exists X  Others )
            Body [addProcedureResult EPlist] 
                    [removeProcedureCalls P EPlist]
        'end P
    by
        FD ; 
        E [removeProcedureCalls P EPlist]
end rule

rule removeProcedureCalls P [id] EPlist [variableReferenceList]
    replace [declaration]
        P A [actualTuple]
    construct RawResult [declaration]
        EPlist := P A
    construct ResultAssignment [declaration]
        RawResult [removeRedundantBrackets]
    by
        ResultAssignment
end rule

function removeRedundantBrackets
    replace [declaration]
        '[ A [id] '] := V [value]
    by
        A := V
end function

rule addProcedureResult EPlist [variableReferenceList]
    skipping [declaration]
    replace [expression]
        N [nullValue]
    deconstruct EPlist
        '[ X [id]  Others [repeat followingVariableReference] ']
    construct OneValueEPlist [expression]
        '[ X ']
    construct ValueEPlist [expression]
        OneValueEPlist [addOtherValueEPids Others]
    construct ResultValue [expression]
        ValueEPlist [removeRedundantValueBrackets]
    by
        ResultValue
end rule

function removeRedundantValueBrackets
    replace [expression]
        '[ X [id] ']
    by
        X
end function

function addOtherValueEPids MoreEPs [repeat followingVariableReference]
    replace [expression]
        '[ X [id]  Others [repeat followingListElement] ']
    deconstruct MoreEPs
        , Y [id]  EvenMoreEPs [repeat followingVariableReference]
    construct YfLE [followingListElement]
        , Y
    construct NewOthers [repeat followingListElement]
        Others [. YfLE]
    construct NewValueEPlist [expression]
        '[ X  NewOthers ']
    by
        NewValueEPlist [addOtherValueEPids EvenMoreEPs]
end function

function addExistentialParameterIds MoreEPs [repeat followingParm]
    replace [variableReferenceList]
        '[ X [id]  Others [repeat followingVariableReference] ']
    deconstruct MoreEPs
        , exists Y [id]  EvenMoreEPs [repeat followingParm]
    construct YfVR [followingVariableReference]
        , Y
    construct NewOthers [repeat followingVariableReference]
        Others [. YfVR]
    construct NewEPlist [variableReferenceList]
        '[ X NewOthers ']
    by
        NewEPlist [addExistentialParameterIds EvenMoreEPs]
end function


%
%
%
rule removeIfStatement
    replace [expression]
        E [expression]
    where
        E [containsIfStatement]
    by
        E [removeIfAssigningLocals] 
            [removeIfAssigningParameters]
            [removeIfStatements]
end rule

rule containsIfStatement
    match [expression]
        IF [ifValue]
        ;
        SE [expression]
end rule

rule removeIfAssigningLocals
    replace [expression]
        'function P [id] ( A [id] , B [id] C [repeat followingParm] )
            var X [id] ;
            Body [expression]
        'end P ;
        RestOfScope [expression]
    where
        Body [containsIfStatement]
    by
        'function P ( A , B  C ) 
            var X ;
            Body [removeIf3 A B X]
        'end P ;
        RestOfScope [removeIfAssigningLocals] 
end rule

rule removeIfAssigningParameters
    replace [expression]
        'function P [id] ( A [id] , B [id] C [repeat followingParm] )
            Body [expression]
        'end P ;
        RestOfScope [expression]
    where
        Body [containsIfStatement]
    by
        'function P ( A , B  C ) 
            Body [removeIf A B]
        'end P ;
        RestOfScope [removeIfAssigningParameters] 
end rule

rule removeIf A [id] B [id]
    replace [expression]
        if V [value] then
            E1 [expression]
        else
            E2 [expression]
        endif ;
        RestOfScope [expression]
    construct NewA [id]
        A [!]
    construct NewB [id]
        B [!]
    construct Result [expression]
        NewA  ->
            if V then
                E1 [replaceNullValueWithId A]
            else
                E2 [replaceNullValueWithId A]
            endif ;
        NewB  ->
            if V then
                E1 [replaceNullValueWithId B]
            else
                E2 [replaceNullValueWithId B] 
            endif ;
        RestOfScope [$ A NewA] [$ B NewB]
    by
        Result
end rule

rule removeIf3 A [id] B [id] C [id]
    replace [expression]
        if V [value] then
            E1 [expression]
        else
            E2 [expression]
        endif ;
        RestOfScope [expression]
    construct NewA [id]
        A [!]
    construct NewB [id]
        B [!]
    construct NewC [id]
        C [!]
    construct Result [expression]
        NewA  ->
            if V then
                E1 [replaceNullValueWithId A] 
            else
                E2 [replaceNullValueWithId A]
            endif ;
        NewB  ->
            if V then
                E1 [replaceNullValueWithId B]
            else
                E2 [replaceNullValueWithId B]
            endif ;
        NewC  ->
            if V then
                E1 [replaceNullValueWithId C] 
            else
                E2 [replaceNullValueWithId C] 
            endif ;
        RestOfScope [$ A NewA] [$ B NewB]
            [$ C NewC] [removeIf3 NewA NewB NewC] 
    by
        Result
end rule

rule removeIfStatements
    replace [expression]
        I [ifValue] ; R [expression]
    by
        R
end rule



%
%       Explicit blocks:  change
%               { [expression] }
%       to
%               [expression]
%
rule removeExplicitBlocks
    replace [expression]
        { B [expression] } ; R [expression]
    by
        B [appendExpression R]
end rule

function appendExpression R [expression]
    replace [expression]
        D [declaration] ;
        E [expression]
    by
        D ; E [appendExpression R] [replaceNullExpression R]
end function

function replaceNullExpression R [expression]
    replace [expression]
        N [nullValue]
    by
        R
end function

% % % external rule breakpoint

rule replaceNullValueWithId E [id]
    skipping [ifValue]
    replace [expression]
        N [nullValue]
    by
        E
end rule



%
%       Assignments:  remove variable declarations, multi-target assignents,
%               convert assignments to 'tame' assignments, remove tame assignments.
%

% Maps
%       [A, B, C, ...] := V
% to
%       A' -> first (V);
%       B' -> first (rest (V));
%       C' -> first (rest (rest (V)));
%       ...
% We map directly to the tame assignment form to give the assignment
% a simultaneous semantics -- e.g.
%       [X, Y] := [plus (X, 1), X]
% maps to
%       X' -> plus (X, 1);
%       Y' -> X   % the old X
rule undoMultiAssignments
    replace [expression]
        MA [multiAssignment] ;
        E [expression]
    construct RawE [expression]
        MA ; E
    construct NewE [expression]
        RawE [undoMA] [undoLastMA]
    by
        NewE
end rule

rule undoMA
    replace [expression]
        '[ A [id] , B [id]  R [repeat followingVariableReference] '] := V [value];
        RestOfScope [expression]
    construct NewA [id]
        A [!]
    by
        NewA  -> first ( V ) ;
            '[ B  R '] := rest ( V ) ;
        RestOfScope [$ A NewA]
end rule

rule undoLastMA
    replace [expression]
        '[ A [id]  '] := V [value] ;
        RestOfScope [expression]
    construct NewA [id]
        A [!]
    by
        NewA  -> V ;
        RestOfScope [$ A NewA]
end rule

rule removeVarDeclarations
    replace [expression]
        V [variableDeclaration] ; RestOfScope [expression]
    by
        RestOfScope
end rule

% Alpha-conversion for assignments:  sequences of the form
%       X := 3;
%       X := plus [X, 1];
%       X := times [X, 3]
% are converted to the form
%       X' -> 3;
%       X'' -> plus [X, 1];
%       X''' -> times [X', 3]
rule alphaConvAssign
    replace [expression]
        X [id] := V [value] ; 
        RestOfScope [expression]
    construct NewX [id]
        X [!]
    construct Result [expression]
        NewX  -> V ;
        RestOfScope [$ X NewX] 
    by
        Result
end rule

rule substituteVar V [id]  NewV [id]
    replace [variableReference]
        V
    by
        NewV
end rule

rule removeAssignments
    replace [expression]
        X [variableReference] -> V [value] ;
        RestOfScope [expression]
    construct XV [value]
        X
    construct NewScope [expression]
        RestOfScope [$ XV V]
    by
        NewScope 
end rule

rule substituteValue X [variableReference]  V [value]
    replace [value]
        X
    by
        V
end rule



%       EXISTENTIAL PARAMETERS

rule removeExistentialParameters
    replace [expression]
        F [functionDeclaration] ;
        E [expression]
    construct FE [expression]
        F ; 
        E
    construct NewFE [expression]
        FE [sortFollowingExistentialParameters]
             [sortFirstExistentialParameter]
             [removeOneExistentialParameter] 
    where not
        NewFE [= FE]
    by
        NewFE
end rule

rule removeOneExistentialParameter
    replace [expression]
        'function F [id] ( exists X [id] OtherParms [repeat followingParm] )
            Body [expression]
        'end F ;
        RestOfScope [expression]
    by
        'function F (X OtherParms)
            Body [insertParameter F X] 
        'end F;
        RestOfScope [insertParameter F X]
end rule

rule sortFirstExistentialParameter
    replace [multipleParm]
        ( P [id] , exists E [id]  OtherParms [repeat followingParm] )
    by
        ( exists E , P OtherParms )
end rule

rule sortFollowingExistentialParameters
    replace [repeat followingParm]
        , P [id] , exists E [id]  OtherParms [repeat followingParm]
    by
        , exists E , P OtherParms
end rule

rule insertParameter F [id] X [id]
    replace [functionApplication]
        F A [actualTuple]
    where not
        A [firstIs X] 
    by
        F A [insertMultipleParameter X] [insertSingleParameter X] 
end rule

function firstIs X [id]
    match [actualTuple]
        ( X  OtherParms [repeat followingActual] )
end function

function insertSingleParameter X [id]
    replace [actualTuple]
        ( )
    by 
        ( X )
end function

function insertMultipleParameter X [id]
    replace [actualTuple]
        ( FirstParm [singleActual]  OtherParms [repeat followingActual] ) 
    by
        ( X , FirstParm OtherParms )
end function
