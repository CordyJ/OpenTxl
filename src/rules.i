% OpenTxl Version 11 rule table
% J.R. Cordy, July 2022

% Copyright 2022, James R. Cordy and others

% Permission is hereby granted, free of charge, to any person obtaining a copy of this software 
% and associated documentation files (the “Software”), to deal in the Software without restriction, 
% including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
% and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, 
% subject to the following conditions:

% The above copyright notice and this permission notice shall be included in all copies 
% or substantial portions of the Software.

% THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
% INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE 
% AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
% DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

% Abstract

% TXL rule table
% The TXL rule compiler stores the compiled rules and functions of the TXL program in this table,
% organized into separate stores for rule parts (constructors, deconstructors, etc.) and
% rule local variables in order to avoid artificial limits on any particular rule. 

% Modification Log

% v11.0 Initial revision, revised from FreeTXL 10.8b (c) 1988-2022 Queen's University at Kingston
%       Remodularized to aid maintenance and understanding.

% v11.1 Added new predefined function [faccess]
%       Updated [system] predefined function to return success code for use in where clauses

% v11.3 Added multiple skipping criteria for both patterns and deconstructors

% The TXL Rule Table

const * maxTotalParameters := maxRules * avgParameters
const * maxTotalLocals := maxTotalParameters + maxRules * avgLocalVars

type * localInfoT :
    record
        name : tokenT
        typename : tokenT
        basetypename : tokenT
        partof : nat2   % 0 .. maxLocalVars
        refs : nat2
        lastref : treePT
        global, changed : boolean
    end record

%% put : 0, "localInfoT: ", size (localInfoT)   %%

type localsBaseT : int  % 0 .. maxTotalLocals

type * localsListT :
    record
        localBase : localsBaseT
        nformals, nprelocals, nlocals : nat2    % 0 .. maxLocalVars
    end record

%% put : 0, "localsListT: ", size (localsListT)         %%

type * partKind : packed enum (construct, deconstruct, cond, import_, export_, assert_, none)

type * partDescriptor :
record
    kind : partKind
    name : tokenT
    nameRef : nat2      % 0 .. maxLocalVars
    globalRef : nat2    % 0 .. maxLocalVars
    target : tokenT
    skipName : tokenT
    skipName2 : tokenT
    skipName3 : tokenT
    replacementTP : treePT
    patternTP : treePT
    starred, negated, anded, skipRepeat : boolean
end record

%% put : 0, "partDescriptor: ", size (partDescriptor)   %%

type * partsBaseT : int % 0 .. maxTotalParts

type * partsListT : 
    record
        partsBase : partsBaseT
        nparts : nat2   % 0 .. maxParts
    end record

const * maxTotalParts := maxRules * avgParts

type * callsBaseT : int % 0 .. maxTotalCalls

type * callsListT : 
    record
        callBase : callsBaseT
        ncalls : nat2   % 0 .. maxRuleCalls
    end record

const * maxTotalCalls := maxTotalParts  % average one call per part

%% put : 0, "ruleCalls: ", size (nat2) * maxTotalCalls  %%

type * ruleKind : enum (normalRule, functionRule, onepassRule, predefinedFunction)

type * ruleT :
    record
        name : tokenT 
        localVars : localsListT
        calledRules : callsListT
        target : tokenT
        skipName : tokenT
        skipName2 : tokenT
        skipName3 : tokenT
        prePattern : partsListT
        patternTP : treePT
        postPattern : partsListT
        replacementTP : treePT
        defined, called, starred, isCondition, skipRepeat : boolean
        kind : ruleKind
    end record

%% put : 0, "ruleT: ", size (ruleT)     %%


% Predefined global vars

% Active
const * TXLargsG := 1
const * TXLprogramG := 2
const * TXLinputG := 3
const * TXLexitcodeG := 4

const * numGlobalVars := 4


% Predefined rules

const * addR := 1
const * subtractR := 2
const * multiplyR := 3
const * divideR := 4
const * substringR := 5
const * lengthR := 6
const * greaterR := 7
const * greaterEqualR := 8
const * lessR := 9
const * lessEqualR := 10
const * equalR := 11
const * notEqualR := 12
const * spliceR := 13
const * listSpliceR := 14
const * extractR := 15
const * shallowextractR := 16
const * substituteR := 17
const * newidR := 18
const * underscoreR := 19
const * messageR := 20
const * printR := 21
const * printattrR := 22
const * debugR := 23
const * breakpointR := 24
const * quoteR := 25
const * unparseR := 26
const * unquoteR := 27
const * parseR := 28
const * reparseR := 29
const * readR := 30
const * writeR := 31
const * getR := 32
const * getpR := 33
const * putR := 34
const * putpR := 35
const * indexR := 36
const * grepR := 37
const * repeatlengthR := 38
const * selectR := 39
const * tailR := 40
const * headR := 41
const * globalR := 42
const * quitR := 43
const * fgetR := 44
const * fputR := 45
const * fputpR := 46
const * fopenR := 47
const * fcloseR := 48
const * pragmaR := 49
const * divR := 50
const * remR := 51
const * systemR := 52
const * pipeR := 53
const * tolowerR := 54
const * toupperR := 55
const * typeofR := 56
const * istypeR := 57
const * roundR := 58
const * truncR := 59
const * getsR := 60
const * fgetsR := 61
const * putsR := 62
const * fputsR := 63
const * faccessR := 64
const * nPredefinedRules := 64

% The main rule of the transformation
var mainRule := 0


module rule

    import
        var ident, typeKind, error

    export
        rules, nRules, ruleParts, ruleLocals, ruleCalls, 
        rulePartCount, ruleFormalCount, ruleLocalCount, ruleCallCount

        #if not NOCOMPILE then
            , incLocalCount, incFormalCount, incPartCount, 

            cloneRule, setCalled, setDefined, setIsCondition, setKind, setPattern, setReplacement, setSkipRepeat, setStarred, setTarget,
            setLocalBase, setNFormals, setNPreLocals, setNLocals, setCallBase, setNCalls, setPrePatternPartsBase, setPrePatternNParts,
            setPostPatternPartsBase, setPostPatternNParts, setSkipName,

            cloneLocal, incLocalRefs, setLocalChanged, setLocalGlobal, setLocalLastRef, setLocalName, setLocalPartOf, setLocalRefs, setLocalType,

            setPartKind, setPartName, setPartNameRef, setPartTarget, setPartPattern, setPartReplacement, setPartNegated, setPartAnded, setPartStarred,
            setPartSkipName, setPartSkipRepeat, setPartGlobalRef,

            enterRule, enterRuleCall, enterLocalVar, unenterLocalVar, lookupLocalVar, findLocalVar,
            checkPredefinedFunctionScopeAndParameters
        #end if

    % The rule table 
    var rules : array 1 .. maxRules of ruleT
    var nRules := 0

    %% put : 0, "rules: ", size (ruleT) * maxRules      %%

    % Rule local variables, rule parts (constructors, deconstructors, etc.), and rule calls
    % are all stored indirectly as frames in a large single array containing all of them for all rules.
    % This avoids artificial limits on the size of rules by allowing for rules with hundreds of locals, parts or calls.

    % The rule local variables table

    % The local variables for all rules are stored as contiguous frames in this single array, 
    % defined for each rule by a zero-origin base element index (rule.localVars.localsBase), 
    % the number of rule formal parameters (rule.localVars.nformals),
    % the number of pre-pattern local variables (rule.localVars.nprelocals), 
    % the number of total local variables (rule.localVars.nlocals), including the above.

    % Because rules may be used before being defined, the table is organized into 
    % a temporary inferred formals space, used to hold the inferred parameter type frames 
    % of rules that have been used but not yet defined, and the actual locals space, 
    % used for the complete locals frames of rules when they are defined.

    % When a used rule is defined, its formal types are compared to the inferred types
    % in its temporary inferred formals frame to check for consistency.

    var ruleLocals : array 1 .. maxTotalLocals of localInfoT
    var ruleFormalCount := 0                    
    var ruleLocalCount := maxTotalParameters    % leave space reserved for temporary formals info

    %% put : 0, "locals: ", size (localInfoT) * maxTotalLocals  %%

    % The rule parts table

    % The rule parts (constructors, deconstructors, where clauses, etc.)
    % for all rules are stored as sequential contiguous frames in this single array,
    % defined for each rule by a zero-origin index for each of the pre-pattern (rule.prePattern.partsBase) 
    % and post-pattern (rule.postPattern.partsBase) and their respective counts (rule.prePattern.nparts, rule.postPattern.nparts). 

    var ruleParts : array 1 .. maxTotalParts of partDescriptor
    var rulePartCount := 0 

    %% put : 0, "ruleParts: ", size (partDescriptor) * maxTotalParts    %%

    % The rule calls table
    % Used only by the rule compiler, to optimize tree sharing and avoid copying of trees

    % The set of called rules for all rules are stored as contiguous frames in this single array,
    % defined for each rule by a zero-origin index (rule.calledRules.callBase) and a count (rule.calledRules.ncalls).

    var ruleCalls : array 1 .. maxTotalCalls of nat2 % 1 .. maxRules
    var ruleCallCount := 0


#if not NOCOMPILE then

    % Operations on the Rule Table

    function enterRule (ruleName : tokenT) : int

        for r : 1 .. nRules
            if rules (r).name = ruleName then
                result r
            end if
        end for

        if nRules = maxRules then
            error ("", "Too many rule/function definitions" + " (> " + intstr (maxRules, 1) + ")", LIMIT_FATAL, 531)
        end if

        nRules += 1
            
        bind var r to rules (nRules)
        r.name := ruleName
        r.localVars.nformals := 0
        r.localVars.nlocals := 0
        r.localVars.nprelocals := 0
        r.localVars.localBase := ruleLocalCount
        r.calledRules.ncalls := 0
        r.calledRules.callBase := ruleCallCount
        r.target := NOT_FOUND 
        r.skipName := NOT_FOUND 
        r.skipName2 := NOT_FOUND 
        r.skipName3 := NOT_FOUND 
        r.prePattern.nparts := 0
        r.prePattern.partsBase := rulePartCount
        r.postPattern.nparts := 0
        r.postPattern.partsBase := rulePartCount
        r.patternTP := nilTree
        r.replacementTP := nilTree
        r.kind := ruleKind.normalRule
        r.defined := false
        r.called := false
        r.starred := false
        r.isCondition := false
        r.skipRepeat := false

        result nRules
    end enterRule


    function lookupLocalVar (context : string, localVars : localsListT, varName : tokenT) : int
        for i : 1 .. localVars.nlocals 
            if ruleLocals (localVars.localBase + i).name = varName then
                result i
            end if
        end for

        result 0
    end lookupLocalVar


    function findLocalVar (context : string, localVars : localsListT, varName : tokenT) : int
        for i : 1 .. localVars.nlocals 
            if ruleLocals (localVars.localBase + i).name = varName then
                result i
            end if
        end for

        error (context, "Variable '" + string@(ident.idents (varName)) + "' has not been defined", FATAL, 532)
        result 0
    end findLocalVar


    function enterLocalVar (context : string, localVars : localsListT, varName : tokenT, varType : tokenT) : int
        for i : 1 .. localVars.nlocals
            if ruleLocals (localVars.localBase + i).name = varName then
                error (context, "Variable '" + string@(ident.idents (varName)) + 
                    "' has already been defined", FATAL, 533)
            end if
        end for

        if localVars.nlocals = maxLocalVars then
           error (context, "Rule/function is too complex - simplify using subrules", LIMIT_FATAL, 530)
        end if

        if ruleLocalCount = maxTotalLocals then
            error (context, "Too many total local variables in rules of TXL program" +
                "  (> " + intstr (maxTotalLocals, 1) + ")", LIMIT_FATAL, 534)
        end if

        ruleLocalCount += 1
        localsListT@(addr(localVars)).nlocals += 1      % not really a cheat, because localVars are actually in rules

        bind var localVar to ruleLocals (localVars.localBase + localVars.nlocals)
        localVar.name := varName
        localVar.typename := varType
        localVar.basetypename := varType

        bind varTypeName to string@(ident.idents (varType))

        if index (varTypeName, "repeat_1_") = 1 then
            % base type of [repeat_1_X] is [repeat_0_X]
            type char4095 : char (4095)
            var varBaseTypeName := varTypeName
            type (char4095, varBaseTypeName) (8) := '0'
            localVar.basetypename := ident.lookup (varBaseTypeName)
        elsif index (varTypeName, "list_1_") = 1 then
            % base type of [list_1_X] is [list_0_X]
            type char4095 : char (4095)
            var varBaseTypeName := varTypeName
            type (char4095, varBaseTypeName) (6) := '0'
            localVar.basetypename := ident.lookup (varBaseTypeName)
        end if

        localVar.refs := 0
        localVar.changed := false
        localVar.global := false
        localVar.partof := 0
        localVar.lastref := nilTree

        result localVars.nlocals
    end enterLocalVar

    procedure unenterLocalVar (context : string, localVars : localsListT, varName : tokenT)
        assert (ruleLocals (localVars.localBase + localVars.nlocals).name = varName)
        localsListT@(addr(localVars)).nlocals -= 1      % not really a cheat, because localVars are actually in rules
        ruleLocalCount -= 1
    end unenterLocalVar


    procedure enterRuleCall (context : string,  callingRuleIndex, calledRuleIndex : int)

        bind var calls to rules (callingRuleIndex).calledRules
        for c : 1 .. calls.ncalls
            if ruleCalls (calls.callBase + c) = calledRuleIndex then
                return
            end if
        end for
        
        if calls.ncalls = maxRuleCalls then
           error (context, "Rule/function is too complex - simplify using subrules", LIMIT_FATAL, 530)
        end if

        if ruleCallCount = maxTotalCalls then
            error (context, "Too many total rule calls in rules of TXL program" +
                "  (> " + intstr (maxTotalLocals, 1) + ")", LIMIT_FATAL, 535)
        end if

        ruleCallCount += 1
        calls.ncalls += 1
        ruleCalls (calls.callBase + calls.ncalls) := calledRuleIndex
    end enterRuleCall

    procedure cloneRule (newIndex : int, oldIndex : int)
        rules (newIndex) := rules (oldIndex)
    end cloneRule
   
    procedure setCalled (ruleIndex : int, setting : boolean)
        rules (ruleIndex).called := setting
    end setCalled
   
    procedure setDefined (ruleIndex : int, setting : boolean)
        rules (ruleIndex).defined := setting
    end setDefined
   
    procedure setIsCondition (ruleIndex : int, setting : boolean)
        rules (ruleIndex).isCondition := setting
    end setIsCondition
   
    procedure setKind (ruleIndex : int, kind : ruleKind)
        rules (ruleIndex).kind := kind
    end setKind
   
    procedure setPattern (ruleIndex : int, patternTP : treePT)
        rules (ruleIndex).patternTP := patternTP
    end setPattern
   
    procedure setReplacement (ruleIndex : int, replacementTP : treePT)
        rules (ruleIndex).replacementTP := replacementTP
    end setReplacement
   
    procedure setSkipRepeat (ruleIndex : int, setting : boolean)
        rules (ruleIndex).skipRepeat := setting
    end setSkipRepeat
   
    procedure setStarred (ruleIndex : int, setting : boolean)
        rules (ruleIndex).starred := setting
    end setStarred
   
    procedure setTarget (ruleIndex : int, typeName : tokenT)
        rules (ruleIndex).target := typeName
    end setTarget

    procedure setLocalBase (ruleIndex : int, localBase : int)
        rules (ruleIndex).localVars.localBase := localBase
    end setLocalBase

    procedure setNFormals (ruleIndex : int, nformals : int)
        rules (ruleIndex).localVars.nformals := nformals
    end setNFormals
   
    procedure setNPreLocals (ruleIndex : int, nprelocals : int)
        rules (ruleIndex).localVars.nprelocals := nprelocals
    end setNPreLocals
   
    procedure setNLocals (ruleIndex : int, nlocals : int)
        rules (ruleIndex).localVars.nlocals := nlocals
    end setNLocals

    procedure setCallBase (ruleIndex : int, callBase : int)
        rules (ruleIndex).calledRules.callBase := callBase
    end setCallBase

    procedure setNCalls (ruleIndex : int, ncalls : int)
        rules (ruleIndex).calledRules.ncalls := ncalls
    end setNCalls

    procedure setPrePatternPartsBase (ruleIndex : int, partsBase : int)
        rules (ruleIndex).prePattern.partsBase := partsBase
    end setPrePatternPartsBase 
   
    procedure setPrePatternNParts (ruleIndex : int, nparts : int)
        rules (ruleIndex).prePattern.nparts := nparts
    end setPrePatternNParts
   
    procedure setPostPatternPartsBase (ruleIndex : int, partsBase : int)
        rules (ruleIndex).postPattern.partsBase := partsBase
    end setPostPatternPartsBase
   
    procedure setPostPatternNParts (ruleIndex : int, nparts : int)
        rules (ruleIndex).postPattern.nparts := nparts
    end setPostPatternNParts

    procedure setSkipName (ruleIndex : int, name : tokenT)
        if rules (ruleIndex).skipName = NOT_FOUND then
            rules (ruleIndex).skipName := name
        elsif rules (ruleIndex).skipName2 = NOT_FOUND then
            rules (ruleIndex).skipName2 := name
        else
            rules (ruleIndex).skipName3 := name
        end if
    end setSkipName

    procedure incLocalCount (increment : int) 
        ruleLocalCount += increment
    end incLocalCount
   
    procedure incFormalCount (increment : int) 
        ruleFormalCount += increment
    end incFormalCount

    procedure incPartCount (increment : int) 
        rulePartCount += increment
    end incPartCount
   
    procedure cloneLocal (newLocalIndex : int, oldLocalIndex : int) 
        ruleLocals (newLocalIndex) := ruleLocals (oldLocalIndex)
    end cloneLocal

    procedure incLocalRefs (localIndex : int, increment : int)
        ruleLocals (localIndex).refs += increment
    end incLocalRefs
   
    procedure setLocalChanged (localIndex : int, setting : boolean)
        ruleLocals (localIndex).changed := setting
    end setLocalChanged

    procedure setLocalGlobal (localIndex : int, setting : boolean)
        ruleLocals (localIndex).global := setting
    end setLocalGlobal

    procedure setLocalLastRef (localIndex : int, lastref : treePT)
        ruleLocals (localIndex).lastref := lastref
    end setLocalLastRef

    procedure setLocalName (localIndex : int, name : tokenT)
        ruleLocals (localIndex).name := name
    end setLocalName

    procedure setLocalPartOf (localIndex : int, nameRef : int)
        ruleLocals (localIndex).partof := nameRef
    end setLocalPartOf

    procedure setLocalRefs (localIndex : int, refs : int)
        ruleLocals (localIndex).refs := refs
    end setLocalRefs

    procedure setLocalType (localIndex : int, typeName : tokenT)
        ruleLocals (localIndex).typename := typeName
    end setLocalType

    procedure setPartKind (partIndex : partsBaseT, kind : partKind)
        ruleParts (partIndex).kind := kind
    end setPartKind

    procedure setPartName (partIndex : partsBaseT, name : tokenT)
        ruleParts (partIndex).name := name
    end setPartName

    procedure setPartNameRef (partIndex : partsBaseT, nameRef : int)
        ruleParts (partIndex).nameRef := nameRef
    end setPartNameRef

    procedure setPartTarget (partIndex : partsBaseT, typeName : tokenT)
        ruleParts (partIndex).target := typeName
    end setPartTarget

    procedure setPartPattern (partIndex : partsBaseT, patternTP : treePT)
        ruleParts (partIndex).patternTP := patternTP
    end setPartPattern

    procedure setPartReplacement (partIndex : partsBaseT, replacementTP : treePT)
        ruleParts (partIndex).replacementTP := replacementTP
    end setPartReplacement

    procedure setPartNegated (partIndex : partsBaseT, setting : boolean)
        ruleParts (partIndex).negated := setting
    end setPartNegated

    procedure setPartAnded (partIndex : partsBaseT, setting : boolean)
        ruleParts (partIndex).anded := setting
    end setPartAnded

    procedure setPartStarred (partIndex : partsBaseT, setting : boolean)
        ruleParts (partIndex).starred := setting
    end setPartStarred

    procedure setPartSkipName (partIndex : partsBaseT, name : tokenT)
        if ruleParts (partIndex).skipName = NOT_FOUND then
            ruleParts (partIndex).skipName := name
        elsif ruleParts (partIndex).skipName2 = NOT_FOUND then
            ruleParts (partIndex).skipName2 := name
        else
            ruleParts (partIndex).skipName3 := name
        end if
    end setPartSkipName

    procedure setPartSkipRepeat (partIndex : partsBaseT, setting : boolean)
        ruleParts (partIndex).skipRepeat := setting
    end setPartSkipRepeat

    procedure setPartGlobalRef (partIndex : partsBaseT, ref : treePT)
        ruleParts (partIndex).globalRef := ref
    end setPartGlobalRef

    % Predefined functions of TXL

    procedure checkPredefinedFunctionScopeAndParameters (context : string,
            ruleIndex : int, scopetype, p1type, p2type : tokenT)

        pre rules (ruleIndex).kind = ruleKind.predefinedFunction

        case ruleIndex of
            label spliceR : 
                % Generic repeat splice or append 
                % Repeat1 [. Repeat2]  or  Repeat1 [. Element2] 

                var sname := string@(ident.idents (scopetype))

                % can only splice to a repeat 
                if index (sname, "repeat_") not= 1 then
                    error (context, "Scope of [.] predefined function is not a repeat", FATAL, 536)
                end if 

                % get the element type of the repeat 
                var X := sname (10..*) 
                const Xindex : tokenT := ident.lookup (X)
                const repeatIndex : tokenT := ident.lookup ("repeat_0_" + X) 
                const repeatFirstIndex : tokenT := ident.lookup ("repeat_1_" + X) 

                % can only splice elements or repeats onto repeats 
                if p1type not= Xindex and p1type not= repeatIndex and
                        p1type not= repeatFirstIndex then
                    error (context, "Parameter of [.] predefined function does not match scope type", FATAL, 537)
                end if 
                
            label listSpliceR : 
                % Generic list splice or append 
                % List1 [, List2]  or  List1 [, Element2] 

                var sname := string@(ident.idents (scopetype)) 

                % can only list splice to a list 
                if index (sname, "list_") not= 1 then
                    error (context, "Scope of [,] predefined function is not a list", FATAL, 538)
                end if 

                % get the element type of the list 
                var X := sname (8..*) 
                const Xindex : tokenT := ident.lookup (X)
                const listIndex : tokenT := ident.lookup ("list_0_" + X) 
                const listFirstIndex : tokenT := ident.lookup ("list_1_" + X) 

                % can only splice elements or lists onto lists 
                if p1type not= Xindex and p1type not= listIndex and
                        p1type not= listFirstIndex then
                    error (context, "Parameter of [,] predefined function does not match scope type", FATAL, 539)
                end if 
                
            label addR, subtractR, multiplyR, divideR, divR, remR :
                % N1 [+ N2]     N1 := N1 + N2
                % N1 [- N2]     N1 := N1 - N2
                % N1 [* N2]     N1 := N1 * N2
                % N1 [/ N2]     N1 := N1 / N2
                % N1 [div N2]   N1 := N1 div N2
                % N1 [rem N2]   N1 := N1 rem N2

                var resulttype := number_T

                if scopetype = number_T or scopetype = floatnumber_T or 
                        scopetype = decimalnumber_T or scopetype = integernumber_T then
                    resulttype := number_T
                elsif scopetype = stringlit_T then
                    resulttype := stringlit_T
                elsif scopetype = charlit_T then
                    resulttype := charlit_T
                elsif scopetype = id_T or scopetype = upperid_T or scopetype = lowerid_T or
                        scopetype = upperlowerid_T or scopetype = lowerupperid_T then
                    resulttype := id_T  % equivalence class
                elsif typeKind (scopetype) > firstLeafKind and typeKind (scopetype) <= lastLeafKind then
                    resulttype := scopetype
                else
                    error (context, "Scope of [+], [-], [*], [/], [div] or [rem] is not a number, string or token", FATAL, 540)
                end if

                var ok := true

                if p1type = number_T or p1type = floatnumber_T or 
                        p1type = decimalnumber_T or p1type = integernumber_T then
                    if resulttype not= number_T and ruleIndex not= addR then
                        ok := false
                    end if
                elsif typeKind (p1type) > firstLeafKind and typeKind (p1type) <= lastLeafKind then
                    if resulttype = number_T or ruleIndex not= addR then
                        ok := false
                    end if
                else
                    ok := false
                end if

                if not ok then
                    error (context, "Parameter of [+], [-], [*], [/], [div] or [rem] predefined function does not match scope type", FATAL, 541)
                end if

            label substringR :
                if typeKind (scopetype) <= firstLeafKind or typeKind (scopetype) > lastLeafKind then
                    error (context, "Scope of [:] predefined function is not a string, identifier or token", FATAL, 542)
                end if

                var ok := true

                if p1type not= number_T and p1type not= floatnumber_T and 
                        p1type not= decimalnumber_T and p1type not= integernumber_T then
                    ok := false
                end if

                if p2type not= number_T and p2type not= floatnumber_T and 
                        p2type not= decimalnumber_T and p2type not= integernumber_T then
                    ok := false
                end if

                if not ok then
                    error (context, "Parameters of [:] predefined function are not numbers", FATAL, 543)
                end if


            label lengthR :
                if scopetype not= number_T and scopetype not= floatnumber_T and 
                        scopetype not= decimalnumber_T and scopetype not= integernumber_T then
                    error (context, "Scope of [#] predefined function is not a number", FATAL, 544)
                end if

                if typeKind (p1type) <= firstLeafKind or typeKind (p1type) > lastLeafKind then
                    error (context, "Parameter of [#] predefined function is not a string, identifier or token", FATAL, 545)
                end if

            label equalR, notEqualR :
                % N1 [= N2]     N1 = N2
                % N1 [~= N2]    N1 ~= N2
                % (defined as equality on numbers and identity on all other types)

                var ok := true

                if scopetype = number_T or scopetype = floatnumber_T or 
                        scopetype = decimalnumber_T or scopetype = integernumber_T then
                    if p1type not= number_T and p1type not= floatnumber_T and 
                            p1type not= decimalnumber_T and p1type not= integernumber_T then
                        ok := false
                    end if
                elsif typeKind (scopetype) > firstLeafKind and typeKind (scopetype) <= lastLeafKind then
                    if typeKind (p1type) <= firstLeafKind and typeKind (p1type) > lastLeafKind then
                        ok := false
                    end if
                else
                    if p1type not= scopetype then
                        ok := false
                    end if
                end if

                if not ok then
                    error (context, "Parameter of [=] or [~=] predefined function does not match scope type", FATAL, 546)
                end if

            label lessR, lessEqualR, greaterR, greaterEqualR :
                % N1 [> N2]     N1 > N2
                % N1 [< N2]     N1 < N2
                % N1 [<= N2]    N1 <= N2
                % N1 [>= N2]    N1 >= N2
                % (all of above also defined on strings and ids)

                var ok := true

                if scopetype = number_T or scopetype = floatnumber_T or 
                        scopetype = decimalnumber_T or scopetype = integernumber_T then
                    if p1type not= number_T and p1type not= floatnumber_T and 
                            p1type not= decimalnumber_T and p1type not= integernumber_T then
                        ok := false
                    end if
                elsif typeKind (scopetype) > firstLeafKind and typeKind (scopetype) <= lastLeafKind then
                    if typeKind (p1type) <= firstLeafKind and typeKind (p1type) > lastLeafKind then
                        ok := false
                    end if
                else
                    error (context, "Scope of [>], [<], [>=] or [<=] predefined function is not a number, string or identifier", FATAL, 547)
                end if

                if not ok then
                    error (context, "Parameter of [>], [<], [>=] or [<=] predefined function does not match scope type", FATAL, 548)
                end if

            label extractR, shallowextractR :
                % Repeat_X [^ Y] or Repeat_X [^/ Y]
                % generic extract from any scope 
                % The scope should be something of type [repeat X] for some X.
                % Replaces the scope with a sequence of all of the occurences of
                % something of type [X] in the parameter.

                const sname := string@(ident.idents (scopetype))

                if index (sname, "repeat_0_") not= 1 then
                    error (context, "Scope of [^] or [^/] predefined function is not a repeat", FATAL, 549)
                end if

            label substituteR :
                % Scope [$ Old New]
                % generic substitute any type in any scope 

                if p1type not= p2type then
                    error (context, "Parameters of [$] predefined function are of different types", FATAL, 550)
                end if

            label newidR :
                % Id [!]
                % make any identifier unique
                if scopetype not= id_T and scopetype not= upperlowerid_T and 
                        scopetype not= upperid_T and scopetype not= lowerupperid_T and 
                        scopetype not= lowerid_T then
                    error (context, "Scope of [!] predefined function is not an identifier", FATAL, 551)
                end if

            label underscoreR :
                % Id [_ Id2]
                % concat ids with _ between
                if scopetype not= id_T and scopetype not= upperlowerid_T and 
                        scopetype not= upperid_T and scopetype not= lowerupperid_T and 
                        scopetype not= lowerid_T then
                    error (context, "Scope of [_] predefined function is not an identifier", FATAL, 552)
                end if

                if p1type not= id_T and p1type not= upperlowerid_T and 
                        p1type not= upperid_T and p1type not= lowerupperid_T and 
                        p1type not= lowerid_T then
                    error (context, "Parameter of [_] predefined function is not an identifier", FATAL, 553)
                end if

            label messageR, printR, printattrR, debugR, breakpointR :
                % X [message X]
                % X [print]
                % X [printattr]
                % X [debug]
                % X [breakpoint]

                % (any scope will do)

            label quoteR, unparseR :
                % S [quote X]
                % S [unparse X]

                if typeKind (scopetype) <= firstLeafKind or typeKind (scopetype) > lastLeafKind then
                    error (context, "Scope of [quote] or [unparse] predefined function is not a string, identifier or token", FATAL, 554)
                end if

            label unquoteR :
                % I [unquote S]
                % replaces original id or comment with the unquoted text of a string or char literal
                if typeKind (scopetype) <= firstLeafKind or typeKind (scopetype) > lastLeafKind 
                            or scopetype = stringlit_T or scopetype = charlit_T then
                    error (context, "Scope of [unquote] predefined function is not an identifier or token", FATAL, 555)
                end if

                if p1type not= stringlit_T and p1type not= charlit_T then
                    error (context, "Parameter of [unquote] predefined function is not a string", FATAL, 556)
                end if

            label parseR :
                % X [parse S]
                if typeKind (p1type) <= firstLeafKind or typeKind (p1type) > lastLeafKind then
                    error (context, "Parameter of [parse] predefined function is not a string, identifier or token", FATAL, 557)
                end if

            label reparseR :
                % X1 [reparse X2]
                % (any scope and parameter will do)

            label readR, writeR :
                % X [read S]
                if p1type not= stringlit_T and p1type not= charlit_T 
                        and p1type not= id_T and p1type not= upperlowerid_T 
                        and p1type not= upperid_T and p1type not= lowerupperid_T 
                        and p1type not= lowerid_T then
                    error (context, "Parameter of [read] or [write] predefined function is not a string or identifier", FATAL, 558)
                end if

            label getR :
                % X [get]
                % (any scope will do)

            label getpR :
                % X [getp S]
                % (any scope will do)

                if p1type not= stringlit_T and p1type not= charlit_T then
                    error (context, "Parameter of [getp] predefined function is not a string", FATAL, 559)
                end if

            label putR :
                % X [put]
                % (any scope will do)

            label putpR :
                % X [putp S]
                % (any scope will do)

                if p1type not= stringlit_T and p1type not= charlit_T then
                    error (context, "Parameter of [putp] predefined function is not a string", FATAL, 560)
                end if

            label indexR :
                % N [index S1 S2]
                if scopetype not= number_T and scopetype not= floatnumber_T and 
                        scopetype not= decimalnumber_T and scopetype not= integernumber_T then
                    error (context, "Scope of [index] predefined function is not a number", FATAL, 561)
                end if

                if typeKind (p1type) <= firstLeafKind or typeKind (p1type) > lastLeafKind 
                        or typeKind (p2type) <= firstLeafKind or typeKind (p2type) > lastLeafKind then
                    error (context, "Parameters of [index] predefined function are not strings, identifiers or tokens", FATAL, 562)
                end if

            label grepR :
                % S1 [grep S2]
                if typeKind (scopetype) <= firstLeafKind or typeKind (scopetype) > lastLeafKind then
                    error (context, "Scope of [grep] predefined function is not a string, identifier or token", FATAL, 563)
                end if

                if typeKind (p1type) <= firstLeafKind or typeKind (p1type) > lastLeafKind then
                    error (context, "Parameter of [grep] predefined function is not a string, identifier or token", FATAL, 564)
                end if

            label repeatlengthR :
                % N [length RX]
                if scopetype not= number_T and scopetype not= floatnumber_T and 
                        scopetype not= decimalnumber_T and scopetype not= integernumber_T then
                    error (context, "Scope of [length] predefined function is not a number", FATAL, 565)
                end if

                if index (string@(ident.idents (p1type)), "repeat_") not= 1 
                        and index (string@(ident.idents (p1type)), "list_") not= 1 then
                    error (context, "Parameter of [length] predefined function is not a [repeat] or [list]", FATAL, 566)
                end if

            label selectR :
                % RX [select N1 N2]
                if index (string@(ident.idents (scopetype)), "repeat_") not= 1 
                        and index (string@(ident.idents (scopetype)), "list_") not= 1 then
                    error (context, "Scope of [select] predefined function is not a [repeat] or [list]", FATAL, 567)
                end if

                if p1type not= number_T and p1type not= floatnumber_T and 
                        p1type not= decimalnumber_T and p1type not= integernumber_T 
                    or p2type not= number_T and p2type not= floatnumber_T and 
                        p2type not= decimalnumber_T and p2type not= integernumber_T then
                    error (context, "Parameters of [select] predefined function are not numbers", FATAL, 568)
                end if

            label headR, tailR :
                % RX [head N]
                % RX [tail N]
                if index (string@(ident.idents (scopetype)), "repeat_") not= 1 
                        and index (string@(ident.idents (scopetype)), "list_") not= 1 then
                    error (context, "Scope of [head] or [tail] predefined function is not a [repeat] or [list]", FATAL, 569)
                end if

                if p1type not= number_T and p1type not= floatnumber_T and 
                        p1type not= decimalnumber_T and p1type not= integernumber_T then
                    error (context, "Parameter of [head] or [tail] predefined function is not a number", FATAL, 570)
                end if

            label globalR :
                % Fake rule to hold info on global vars - never called!
                assert false
                
            label quitR :
                % X [quit N]
                if p1type not= number_T and p1type not= floatnumber_T and 
                        p1type not= decimalnumber_T and p1type not= integernumber_T then
                    error (context, "Parameter of [quit] predefined function is not a number", FATAL, 571)
                end if

            label fgetR :
                % X [fget F]
                % (any scope will do)
                if p1type not= stringlit_T and p1type not= charlit_T then
                    error (context, "Parameter of [fget] predefined function is not a string filename", FATAL, 572)
                end if

            label fputR :
                % X [fput F]
                % (any scope will do)
                if p1type not= stringlit_T and p1type not= charlit_T then
                    error (context, "Parameter of [fput] predefined function is not a string filename", FATAL, 573)
                end if

            label fputpR :
                % X [fputp F S]
                % (any scope will do)

                if p1type not= stringlit_T and p1type not= charlit_T then
                    error (context, "First parameter of [fputp] predefined function is not a string filename", FATAL, 574)
                end if
                
                if p2type not= stringlit_T and p2type not= charlit_T then
                    error (context, "Second parameter of [fputp] predefined function is not a string", FATAL, 575)
                end if

            label fopenR :
                % X [fopen F M]
                % (any scope will do)

                if p1type not= stringlit_T and p1type not= charlit_T then
                    error (context, "First parameter of [fopen] predefined function is not a string filename", FATAL, 578)
                end if
                
                if p2type not= stringlit_T and p2type not= charlit_T then
                    error (context, "Second parameter of [fopen] predefined function is not a string file mode", FATAL, 579)
                end if
                
            label fcloseR :
                % X [fclose F]
                % (any scope will do)

                if p1type not= stringlit_T and p1type not= charlit_T then
                    error (context, "Parameter of [fclose] predefined function is not a string filename", FATAL, 576)
                end if

            label pragmaR :
                % X [pragma S]
                % (any scope will do)

                if p1type not= stringlit_T and p1type not= charlit_T then
                    error (context, "Parameter of [pragma] predefined function is not an options string", FATAL, 577)
                end if

            label systemR :
                % X [system S]
                % (any scope will do)

                if p1type not= stringlit_T and p1type not= charlit_T then
                    error (context, "Parameter of [system] predefined function is not a command string", FATAL, 581)
                end if

            label pipeR :
                % S1 [pipe S2]

                if scopetype not= stringlit_T and scopetype not= charlit_T then
                    error (context, "Scope of [pipe] predefined function is not a string", FATAL, 582)
                end if

                if p1type not= stringlit_T and p1type not= charlit_T then
                    error (context, "Parameter of [pipe] predefined function is not a command string", FATAL, 583)
                end if

            label tolowerR, toupperR :
                % I [tolower]
                if typeKind (scopetype) <= firstLeafKind or typeKind (scopetype) > lastLeafKind then
                    error (context, "Scope of [tolower] or [toupper] predefined function is not an identifier, string or token", FATAL, 586)
                end if

            label typeofR :
                % I [typeof X]

                if scopetype not= id_T then
                    error (context, "Scope of [typeof] predefined function is not of type [id]", FATAL, 584)
                end if

            label istypeR :
                % X [istype I]

                if p1type not= id_T then
                    error (context, "Parameter of [istype] predefined function is not of type [id]", FATAL, 585)
                end if

            label roundR, truncR :
                % N [round]
                % N [trunc]
                if not (scopetype = number_T or scopetype = floatnumber_T or 
                        scopetype = decimalnumber_T or scopetype = integernumber_T) then
                    error (context, "Scope of [round] or [trunc] predefined function is not a number", FATAL, 587)
                end if
                
            label getsR :
                % S [gets]
                if scopetype not= stringlit_T and scopetype not= charlit_T then
                    error (context, "Scope of [gets] predefined function is not a string", FATAL, 588)
                end if
                
            label fgetsR :
                % S [fgets F]
                if scopetype not= stringlit_T and scopetype not= charlit_T then
                    error (context, "Scope of [fgets] predefined function is not a string", FATAL, 589)
                end if
                if p1type not= stringlit_T and p1type not= charlit_T then
                    error (context, "Parameter of [fgets] predefined function is not a string filename", FATAL, 590)
                end if

            label putsR :
                % S [puts]
                if scopetype not= stringlit_T and scopetype not= charlit_T then
                    error (context, "Scope of [puts] predefined function is not a string", FATAL, 591)
                end if

            label fputsR :
                % S [fputs F]
                if scopetype not= stringlit_T and scopetype not= charlit_T then
                    error (context, "Scope of [fputs] predefined function is not a string", FATAL, 592)
                end if
                if p1type not= stringlit_T and p1type not= charlit_T then
                    error (context, "Parameter of [fputs] predefined function is not a string filename", FATAL, 593)
                end if

            label faccessR :
                % X [faccess F M]
                % (any scope will do)
                if p1type not= stringlit_T and p1type not= charlit_T then
                    error (context, "First parameter of [faccess] predefined function is not a string filename", FATAL, 594)
                end if
                if p2type not= stringlit_T and p2type not= charlit_T then
                    error (context, "Second parameter of [faccess] predefined function is not a string file mode", FATAL, 595)
                end if
        end case

    end checkPredefinedFunctionScopeAndParameters


    % Initialize the rule table with the predefined functions

    type predefinedDescription :
        record
            name : string (25)
            ruleNumber : int
            nformals : int
            isCondition : boolean
        end record

    const predefinedRules :
        array 1 .. nPredefinedRules of predefinedDescription :=
            init (
                init ("+", addR, 1, false),
                init ("-", subtractR, 1, false),
                init ("*", multiplyR, 1, false),
                init ("/", divideR, 1, false),
                init (":", substringR, 2, false),
                init ("#", lengthR, 1, false),
                init (">", greaterR, 1, true),
                init (">=", greaterEqualR, 1, true),
                init ("<", lessR, 1, true),
                init ("<=", lessEqualR, 1, true),
                init ("=", equalR, 1, true),
                init ("~=", notEqualR, 1, true),
                init (".", spliceR, 1, false),
                init (",", listSpliceR, 1, false),
                init ("\^", extractR, 1, false),
                init ("\^/", shallowextractR, 1, false),
                init ("$", substituteR, 2, false),
                init ("!", newidR, 0, false),
                init ("_", underscoreR, 1, false),
                init ("message", messageR, 1, false),
                init ("print", printR, 0, false),
                init ("printattr", printattrR, 0, false),
                init ("debug", debugR, 0, false),
                init ("breakpoint", breakpointR, 0, false),
                init ("quote", quoteR, 1, false),
                init ("unparse", unparseR, 1, false),
                init ("unquote", unquoteR, 1, false),
                init ("parse", parseR, 1, false),
                init ("reparse", reparseR, 1, false),
                init ("read", readR, 1, false),
                init ("write", writeR, 1, false),
                init ("get", getR, 0, false),
                init ("getp", getpR, 1, false),
                init ("put", putR, 0, false),
                init ("putp", putpR, 1, false),
                init ("index", indexR, 2, false),
                init ("grep", grepR, 1, true),
                init ("length", repeatlengthR, 1, false),
                init ("select", selectR, 2, false),
                init ("tail", tailR, 1, false),
                init ("head", headR, 1, false),
                init ("_globals_", globalR, 0, false),
                init ("quit", quitR, 1, false),
                init ("fget", fgetR, 1, false),
                init ("fput", fputR, 1, false),
                init ("fputp", fputpR, 2, false),
                init ("fopen", fopenR, 2, false),
                init ("fclose", fcloseR, 1, false),
                init ("pragma", pragmaR, 1, false),
                init ("div", divR, 1, false),
                init ("rem", remR, 1, false),
                init ("system", systemR, 1, true),
                init ("pipe", pipeR, 1, false),
                init ("tolower", tolowerR, 0, false),
                init ("toupper", toupperR, 0, false),
                init ("typeof", typeofR, 1, false),
                init ("istype", istypeR, 1, true),
                init ("round", roundR, 0, false),
                init ("trunc", truncR, 0, false),
                init ("gets", getsR, 0, false),
                init ("fgets", fgetsR, 1, false),
                init ("puts", putsR, 0, false),
                init ("fputs", fputsR, 1, false),
                init ("faccess", faccessR, 2, true)
            )

    for p : 1 .. nPredefinedRules
        bind px to predefinedRules (p)
        var pname := ident.install (px.name, kindT.id)
        var prule := enterRule (pname)
        assert prule = px.ruleNumber 
        begin
            bind var pr to rules (prule)
            pr.localVars.nformals := 0
            pr.localVars.nprelocals := 0
            pr.localVars.nlocals := 0
            pr.localVars.localBase := ruleLocalCount
            pr.target := NOT_FOUND
            pr.skipName := NOT_FOUND
            pr.skipName2 := NOT_FOUND
            pr.skipName3 := NOT_FOUND
            pr.prePattern.nparts := 0
            pr.patternTP := nilTree
            pr.postPattern.nparts := 0
            pr.replacementTP := nilTree
            pr.kind := ruleKind.predefinedFunction
            pr.isCondition := px.isCondition
            pr.defined := true
            pr.called := false
            for f : 1 .. px.nformals
                const dummyFormal := ident.install ("_TXL_Dummy_Formal_" + intstr (f,1), kindT.id)
                const dummyIndex := enterLocalVar ("*** In TXL initialization! ***, ", pr.localVars, dummyFormal, any_T)
            end for
            pr.localVars.nformals := pr.localVars.nlocals
            assert pr.localVars.nformals = px.nformals
        end
    end for

    assert nRules = nPredefinedRules

#end if

end rule
