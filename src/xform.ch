% OpenTxl Version 11 transformer
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

% The TXL transformer
% Takes as input the input parse tree created by the parser and applies the transformation rules 
% in the rule table compiled by the rule compiler to create the transformed parse tree.

% Modification Log

% v11.0	Initial revision, revised from FreeTXL 10.8b (c) 1988-2022 Queen's University at Kingston
%	Modularized for easier maintenance and understanding 

parent "txl.t"

stub module transformer

    import 
	var rule, mainRule, var tree, var tree_ops, charset, var ident, var symbol, 
	var scanner, var parser, var unparser, var options, var exitcode,
	error, stackBase, predefinedParseError, externalType, kindType,
	var inputTokens, var lastTokenIndex, failTokenIndex

    export applyMainRule

    procedure applyMainRule (originalInputParseTreeTP : treePT, var transformedInputParseTreeTP : treePT)

end transformer


body module transformer

    % Called rule activation environments
    
    % In order to avoid an artificial limit on the number of parameters and local variables in a rule,
    % we store the value bindings for all of them as frames in a single array

    const maxTotalValues := maxCallDepth * avgLocalVars
    var valueTP : array 1 .. maxTotalValues of treePT
    var valueCount := 0

    type * ruleEnvironmentT :
	record
	    name : tokenT 			% name of the rule
	    scopeTP : treePT 			% scope of the rule
	    resultTP : treePT 			% partially resolved result of the rule
	    newscopeTP : treePT 		% partially resolved new scope of the rule
	    valuesBase : int			% bindings for parameters and locals
	    depth : int 			% dynamic depth of the rule
	    parentrefs : nat2 			% needed for predefined rule [.], [,] and [^] optimizations
	    hasExported : boolean 		% export flag
	    localsListAddr : addressint 	% the original rule table info about the formal parameters and locals
	end record

    var callEnvironment : array 0 .. maxCallDepth of ruleEnvironmentT
    var callDepth := 0

    % Search stack - same stack used for all searching
    const maxSearchDepth := maxParseDepth * 4
    var searchStack : array 1 .. maxSearchDepth of 
	record 
	    kidsKP, endKP : kidPT 
	end record
    var searchTop := 0

    % Match stack - used only in matchTreeToPattern
    const maxMatchDepth := maxParseDepth
    var matchStack : array 1 .. maxMatchDepth of 
	record 
	    patternKidsKP, patternEndKP : kidPT 
	    treeKidsKP : kidPT
	end record

    #if PROFILER then
        % Cycle counts for matches and searches
	var searchcycles : nat
	var matchcycles : nat
	
	% Rule stats 
	type ruleStatisticsT :
	    record
		calls : nat
		matches : nat
		searchcycles : nat
		matchcycles : nat
		time : nat
		trees : nat
		kids : nat
	    end record
	    
	var ruleStatistics : array 1 .. maxRules of ruleStatisticsT
    #end if
    
    % Kinds of debugger entries
    type * DBkind : 
	enum (startup, shutdown, ruleEntry, ruleExit, matchEntry, matchExit, 
	    deconstructExit, constructEntry, constructExit, conditionExit,
	    importExit, exportEntry, exportExit, historyCommand)

    #if DEBUGGER then
	% The TXL interactive debugger 
	include "xform-debug.i"
    #end if

    % Name of rule currently being applied (for error messages and such)
    var applyingRuleName := empty_T  % has to be something!
    var callingRuleName := empty_T   % used only by predefined rules, for error messages

    % Statistics on tree sharing
    var copies, noncopies := 0

    % Garbage recovery algorithm
    include "xform-garbage.i"

    % Garbage recovery stats
    var nGarbageRecoveries := 0
    var currentGCdepth := 0

    
#if EXECUTABLE_ASSERTS then
    procedure Assert (b : boolean, routine : string)
	if not b then
	    put : 0,  "Assertion failure in ", routine, " while processsing rule ", string@(ident.idents(applyingRuleName))
	    quit : 0
        end if
    end Assert
#end if


    function matchTreeToPattern (argPatternTP : treePT, argTreeTP : treePT,
            var ruleEnvironment : ruleEnvironmentT) : boolean

	% Rationale for the order of the following logic is the typical frequency
	% profile of the cases in production use at Legasys.  Here is a sample:
	
	% choose	91040191	82.2%
	% firstTime	11178871	10.1%
	% subsequentUse	 3893958	 3.5%
	% repeat	 2386210	 2.2%
	% id		 2225540	 2.0%
	% order		   13748	 0.0%
	% empty		    1474	 0.0%
	% literal	     183	 0.0%

	var patternTP := argPatternTP
	var treeTP := argTreeTP
	var mt := 0
	
	loop
	    assert tree.trees (patternTP).kidsKP >= 0 and tree.trees (patternTP).kidsKP <= maxKids 
	    assert tree.trees (treeTP).kidsKP >= 0 and tree.trees (treeTP).kidsKP <= maxKids 

	    #if EXECUTABLE_ASSERTS then
	        Assert (tree.trees (patternTP).kidsKP >= 0 and tree.trees (patternTP).kidsKP <= maxKids, "matchTreeToPattern 1")
	        Assert (tree.trees (treeTP).kidsKP >= 0 and tree.trees (treeTP).kidsKP <= maxKids, "matchTreeToPattern 2")
	    #end if

	    #if PROFILER then
		matchcycles += 1
	    #end if
	    
	    if tree.trees (patternTP).kind = kindT.choose then
		% choose tree 
		if tree.trees (treeTP).name not= tree.trees (patternTP).name 
			or tree.trees (treeTP).kind not= kindT.choose then
		    result false
		end if
		    
		patternTP := tree.kids (tree.trees (patternTP).kidsKP)
		treeTP := tree.kids (tree.trees (treeTP).kidsKP)
		
	    elsif tree.trees (patternTP).kind = kindT.firstTime then
		% binding a TXL variable
		% the count field tells us the locals index!
		bind localVar to rule.ruleLocals (localsListT@(ruleEnvironment.localsListAddr).localBase + tree.trees (patternTP).count)

		if not ( 
		  % types match, in one of these ways ...
		    ( % types match exactly
			 tree.trees (treeTP).name = localVar.basetypename 
		      % and we don't mistake a literal id or other token for a type
			 and not (tree.trees (treeTP).kind >= firstLiteralKind and tree.trees (treeTP).kind <= lastLiteralKind)
		      % and we don't allow empty repeats/lists to match [repeat+]/[list+]
			 and not (localVar.basetypename not= localVar.typename and tree.trees (tree.kids (tree.trees (treeTP).kidsKP)).kind = kindT.empty)
		    ) 
		  or 
		    ( % type matches kind
		      kindType (ord (tree.trees (treeTP).kind)) = localVar.basetypename
		    )
		  or 
		    ( % type is [key] and tree is a keyword - JRC 21.5.99
		      localVar.basetypename = key_T and tree.trees (treeTP).kind = kindT.literal and scanner.keyP (tree.trees (treeTP).name)
		    )
		  or
		    ( % type is [token] and tree is a non-keyword - JRC 10.6.99
		      localVar.basetypename = token_T and tree.trees (treeTP).kind = kindT.literal and not scanner.keyP (tree.trees (treeTP).name)
		    )
		  or 
		    ( % type is [any] - JRC 29.3.99
		      localVar.basetypename = any_T
		    )
		)
		then
		    result false
		end if
		
		% bind the local variable to the tree
		valueTP (ruleEnvironment.valuesBase + tree.trees (patternTP).count) := treeTP
		if tree.trees (patternTP).count = 1 then
		    % only need this fact for the first parameter of a rule -- JRC 31.8.95
		    ruleEnvironment.parentrefs := 9 % any > 1
		end if
		
		% Pop any completed matches ...
		loop
		    if mt = 0 then
			result true
		    end if
		    exit when matchStack (mt).patternKidsKP < matchStack (mt).patternEndKP
		    mt -= 1
		end loop
		% ... and move on to the next subtree in the sequence
		assert mt > 0 and matchStack (mt).patternKidsKP < matchStack (mt).patternEndKP
		#if EXECUTABLE_ASSERTS then
		    Assert (mt > 0 and matchStack (mt).patternKidsKP < matchStack (mt).patternEndKP, "matchTreeToPattern 3")
	 	#end if
		matchStack (mt).patternKidsKP += 1
		patternTP := tree.kids (matchStack (mt).patternKidsKP)
		matchStack (mt).treeKidsKP += 1
		treeTP := tree.kids (matchStack (mt).treeKidsKP)

	    elsif tree.trees (patternTP).kind = kindT.subsequentUse then
		% matching a bound variable
		% the count field tells us the ruleLocals index!
		patternTP := valueTP (ruleEnvironment.valuesBase + tree.trees (patternTP).count)

	    elsif tree.trees (patternTP).kind <= lastStructureKind then
		assert tree.trees (patternTP).kind = kindT.order or tree.trees (patternTP).kind = kindT.repeat 
		    or tree.trees (patternTP).kind = kindT.list
		#if EXECUTABLE_ASSERTS then
		    Assert (tree.trees (patternTP).kind = kindT.order or tree.trees (patternTP).kind = kindT.repeat 
		        or tree.trees (patternTP).kind = kindT.list, "matchTreeToPattern 4")
		#end if
		% order tree
		if tree.trees (treeTP).name not= tree.trees (patternTP).name 
			or tree.trees (treeTP).kind not= tree.trees (patternTP).kind then
		    result false
		end if
    
		assert mt < maxMatchDepth	% we can easily prove this!
		#if EXECUTABLE_ASSERTS then
		    Assert (mt < maxMatchDepth, "matchTreeToPattern 5")
		#end if
		mt += 1
		matchStack (mt).patternKidsKP := tree.trees (patternTP).kidsKP
		matchStack (mt).patternEndKP := matchStack (mt).patternKidsKP + tree.trees (patternTP).count - 1
		patternTP := tree.kids (tree.trees (patternTP).kidsKP)
		matchStack (mt).treeKidsKP := tree.trees (treeTP).kidsKP
		treeTP := tree.kids (tree.trees (treeTP).kidsKP)

	    else
	    	assert tree.trees (patternTP).kind >= firstLeafKind
	    	#if EXECUTABLE_ASSERTS then
		    Assert (tree.trees (patternTP).kind >= firstLeafKind, "matchTreeToPattern 6")
		#end if
		% terminals and empty
		if tree.trees (patternTP).kind = kindT.empty then
		    if tree.trees (treeTP).kind not= kindT.empty then
		        result false
		    end if
		else
		    if tree.trees (treeTP).name not= tree.trees (patternTP).name then
			result false
		    end if
		    if tree.trees (treeTP).kind not= tree.trees (patternTP).kind then
			if tree.trees (patternTP).kind = kindT.literal then
			    if not (tree.trees (treeTP).kind = kindT.literal or tree.trees (treeTP).kind = kindT.id) then
				result false
			    end if
			else
			    result false
			end if
		    end if
		end if
		
		% Pop any completed matches ...
		loop
		    if mt = 0 then
			result true
		    end if
		    exit when matchStack (mt).patternKidsKP < matchStack (mt).patternEndKP
		    mt -= 1
		end loop
		% ... and move on to the next subtree in the sequence
		assert mt > 0 and matchStack (mt).patternKidsKP < matchStack (mt).patternEndKP
		#if EXECUTABLE_ASSERTS then
		    Assert (mt > 0 and matchStack (mt).patternKidsKP < matchStack (mt).patternEndKP, "matchTreeToPattern 7")
		#end if
		matchStack (mt).patternKidsKP += 1
		patternTP := tree.kids (matchStack (mt).patternKidsKP)
		matchStack (mt).treeKidsKP += 1
		treeTP := tree.kids (matchStack (mt).treeKidsKP)
	    end if
	end loop

    end matchTreeToPattern
    
    
    procedure searchdepth_error (ruleName : tokenT)
	error ("rule/function '" + string@(ident.idents (ruleName)) + "'",
	    "Maximum search depth (" + intstr (maxSearchDepth,1) + 
	    ") exceeded when searching for pattern match" +
	    " (a larger size is required for this transform)", FATAL, 501)
    end searchdepth_error


    function searchTreeForDeconstructPattern (argPatternTP : treePT, 
	    argTreeTP : treePT, var ruleEnvironment : ruleEnvironmentT) : boolean

	% Rationale for the order of the following logic is the typical frequency
	% profile of the cases in production use at Legasys.  Here is a sample:

	% kind of treeTP, per cycle :
	% literal	20292374	26.5%
	% repeat	15528787	20.3%
	% empty		13752757	17.9%
	% id		10819315	14.1%
	% choose	 6210380	 8.1%
	% order		 5789258	 7.6%
	% stringlit	 2207113	 2.8%
	% number	 2060547	 2.6%

	var treeTP := argTreeTP
	var patternTP := argPatternTP
	var st := searchTop
	const searchBase := searchTop
	
	if tree.trees (patternTP).kind = kindT.subsequentUse then
	    % use concrete pattern
	    patternTP := valueTP (ruleEnvironment.valuesBase + tree.trees (patternTP).count)
	end if
	    
	loop
	    assert tree.trees (patternTP).kidsKP >= 0 and tree.trees (patternTP).kidsKP <= maxKids 
	    assert tree.trees (treeTP).kidsKP >= 0 and tree.trees (treeTP).kidsKP <= maxKids 
	    
	    #if EXECUTABLE_ASSERTS then
		Assert (tree.trees (patternTP).kidsKP >= 0 and tree.trees (patternTP).kidsKP <= maxKids, "searchTreeForDeconstructPattern 1")
	        Assert (tree.trees (treeTP).kidsKP >= 0 and tree.trees (treeTP).kidsKP <= maxKids, "searchTreeForDeconstructPattern 2")
	    #end if

	    #if PROFILER then
		searchcycles += 1
	    #end if
	    
	    if (tree.trees (treeTP).kind = tree.trees (patternTP).kind or tree.trees (patternTP).kind = kindT.firstTime)
	    	    and matchTreeToPattern (patternTP, treeTP, ruleEnvironment) then
		searchTop := searchBase
		result true
	    end if
	
	    if tree.trees (treeTP).kind >= firstLeafKind then
	    	% A terminal -
		% Pop any completed sequences ...
		loop
		    if st = searchBase then
		        searchTop := searchBase
			result false
		    end if
		    exit when searchStack (st).kidsKP < searchStack (st).endKP
		    st -= 1
		end loop
		% ... and move on to the next subtree in the sequence
		assert st > searchBase and searchStack (st).kidsKP < searchStack (st).endKP
		#if EXECUTABLE_ASSERTS then
		    Assert (st > searchBase and searchStack (st).kidsKP < searchStack (st).endKP, "searchTreeForDeconstructPattern 3")
		#end if
		searchStack (st).kidsKP += 1
		treeTP := tree.kids (searchStack (st).kidsKP)

	    elsif tree.trees (treeTP).kind = kindT.choose then
		% One child - just go down to it (no need to come back)
		treeTP := tree.kids (tree.trees (treeTP).kidsKP)
    
	    else
		% Push a new sequence of subtrees to check
	    	assert tree.trees (treeTP).kind = kindT.order or tree.trees (treeTP).kind = kindT.repeat or tree.trees (treeTP).kind = kindT.list
	    	#if EXECUTABLE_ASSERTS then
		    Assert (tree.trees (treeTP).kind = kindT.order or tree.trees (treeTP).kind = kindT.repeat or tree.trees (treeTP).kind = kindT.list, "searchTreeForDeconstructPattern 4")
		#end if

		if st >= maxSearchDepth	then
		    searchdepth_error (applyingRuleName)
		end if
		    
		st += 1
		searchStack (st).kidsKP := tree.trees (treeTP).kidsKP
		searchStack (st).endKP := searchStack (st).kidsKP + tree.trees (treeTP).count - 1
		treeTP := tree.kids (tree.trees (treeTP).kidsKP)
	    end if
	end loop

    end searchTreeForDeconstructPattern


    function searchTreeForDeconstructPatternSkipping (argPatternTP : treePT, 
	    argTreeTP : treePT, var ruleEnvironment : ruleEnvironmentT,
	    skipName : tokenT) : boolean

	% Rationale for the order of the following logic is the typical frequency
	% profile of the cases in production use at Legasys.  Here is a sample:

	% kind of treeTP, per cycle :
	% literal	20292374	26.5%
	% repeat	15528787	20.3%
	% empty		13752757	17.9%
	% id		10819315	14.1%
	% choose	 6210380	 8.1%
	% order		 5789258	 7.6%
	% stringlit	 2207113	 2.8%
	% number	 2060547	 2.6%

	var treeTP := argTreeTP
	var patternTP := argPatternTP
	var st := searchTop
	const searchBase := searchTop
	
	if tree.trees (patternTP).kind = kindT.subsequentUse then
	    % use concrete pattern
	    patternTP := valueTP (ruleEnvironment.valuesBase + tree.trees (patternTP).count)
	end if
	    
	loop
	    assert tree.trees (patternTP).kidsKP >= 0 and tree.trees (patternTP).kidsKP <= maxKids 
	    assert tree.trees (treeTP).kidsKP >= 0 and tree.trees (treeTP).kidsKP <= maxKids 
	    
	    #if EXECUTABLE_ASSERTS then
		Assert (tree.trees (patternTP).kidsKP >= 0 and tree.trees (patternTP).kidsKP <= maxKids, "searchTreeForDeconstructPatternSkipping 1")
		Assert (tree.trees (treeTP).kidsKP >= 0 and tree.trees (treeTP).kidsKP <= maxKids, "searchTreeForDeconstructPatternSkipping 2")
	    #end if

	    #if PROFILER then
		searchcycles += 1
	    #end if
	    
	    if (tree.trees (treeTP).kind = tree.trees (patternTP).kind or tree.trees (patternTP).kind = kindT.firstTime)
	    	    and matchTreeToPattern (patternTP, treeTP, ruleEnvironment) then
		searchTop := searchBase
		result true
	    end if
	
	    if tree.trees (treeTP).kind >= firstLeafKind 
	    	    or tree.trees (treeTP).name = skipName then
	    	% A terminal -
		% Pop any completed sequences ...
		loop
		    if st = searchBase then
		        searchTop := searchBase
			result false
		    end if
		    exit when searchStack (st).kidsKP < searchStack (st).endKP
		    st -= 1
		end loop
		% ... and move on to the next subtree in the sequence
		assert st > searchBase and searchStack (st).kidsKP < searchStack (st).endKP
		#if EXECUTABLE_ASSERTS then
		    Assert (st > searchBase and searchStack (st).kidsKP < searchStack (st).endKP, "searchTreeForDeconstructPatternSkipping 3")
		#end if
		searchStack (st).kidsKP += 1
		treeTP := tree.kids (searchStack (st).kidsKP)

	    elsif tree.trees (treeTP).kind = kindT.choose then
		% One child - just go down to it (no need to come back)
		treeTP := tree.kids (tree.trees (treeTP).kidsKP)
    
	    else
		% Push a new sequence of subtrees to check
	    	assert tree.trees (treeTP).kind = kindT.order or tree.trees (treeTP).kind = kindT.repeat or tree.trees (treeTP).kind = kindT.list
	    	#if EXECUTABLE_ASSERTS then
		    Assert (tree.trees (treeTP).kind = kindT.order or tree.trees (treeTP).kind = kindT.repeat or tree.trees (treeTP).kind = kindT.list, "searchTreeForDeconstructPatternSkipping 4")
		#end if

		if st >= maxSearchDepth	then
		    searchdepth_error (applyingRuleName)
		end if
		    
		st += 1
		searchStack (st).kidsKP := tree.trees (treeTP).kidsKP
		searchStack (st).endKP := searchStack (st).kidsKP + tree.trees (treeTP).count - 1
		treeTP := tree.kids (tree.trees (treeTP).kidsKP)
	    end if
	end loop

    end searchTreeForDeconstructPatternSkipping


    function searchTreeForDeconstructPatternSkippingRepeat (argPatternTP : treePT, 
	    argTreeTP : treePT, var ruleEnvironment : ruleEnvironmentT) : boolean

	var treeTP := argTreeTP
	var patternTP := argPatternTP
	    
	if tree.trees (patternTP).kind = kindT.subsequentUse then
	    % use concrete pattern
	    patternTP := valueTP (ruleEnvironment.valuesBase + tree.trees (patternTP).count)
	end if

	% walk the repeat looking for the matching element
	loop 
	    exit when tree.trees (tree.kids (tree.trees (treeTP).kidsKP)).kind = kindT.empty 
	    
	    #if PROFILER then
		searchcycles += 1
	    #end if
	    
	    const elementTP := tree.kids (tree.trees (treeTP).kidsKP)
	    
	    if (tree.trees (elementTP).kind = tree.trees (patternTP).kind or tree.trees (patternTP).kind = kindT.firstTime)
	    	    and matchTreeToPattern (patternTP, elementTP, ruleEnvironment) then
		result true
	    end if
	    
	    treeTP := tree.kids (tree.trees (treeTP).kidsKP + 1) 
	end loop 
	
	result false
	
    end searchTreeForDeconstructPatternSkippingRepeat


    forward procedure applyRule (ruleIndex : int, 
	var ruleEnvironment : ruleEnvironmentT,
	originalTP : treePT, var resultTP : treePT, var matched : boolean)


    procedure calldepth_error (ruleName, calledRuleName : tokenT)
	error ("rule/function '" + string@(ident.idents (ruleName)) + "'",
	    "Maximum call depth (" + intstr (maxCallDepth,1) + 
	    ") exceeded when calling rule/function '" + string@(ident.idents (calledRuleName)) + 
	    "' (Probable cause: infinite recursion)", LIMIT_FATAL, 502)
    end calldepth_error


    procedure global_error (ruleName, partName : tokenT)
	error ("rule/function '" + string@(ident.idents (ruleName)) + "'",
	    "Imported global variable '" + string@(ident.idents (partName)) + "' has not been bound", FATAL, 503)
    end global_error


    procedure assert_error (ruleName, partName : tokenT)
	error ("rule/function '" + string@(ident.idents (ruleName)) + "'",
	    "Assertion on '" + string@(ident.idents (partName)) + "' failed", FATAL, 504)
    end assert_error


    procedure applyRules (ruleCallsKP : kidPT, var ruleEnvironment : ruleEnvironmentT,
	var resolvedTreeTP : treePT, var someMatched, allMatched : boolean)

	const thisRuleName := applyingRuleName

	someMatched := false
	allMatched := true

	assert ruleCallsKP not= nilKid
	#if EXECUTABLE_ASSERTS then
	    Assert (ruleCallsKP not= nilKid, "applyRules 1")
	#end if

	var localRuleCallsKP := ruleCallsKP
	
	loop
	    var subruleMatched : boolean

	    const ruleCallTP := tree.kids (localRuleCallsKP)

	    assert tree.trees (ruleCallTP).kind = kindT.ruleCall
	    #if EXECUTABLE_ASSERTS then
	        Assert (tree.trees (ruleCallTP).kind = kindT.ruleCall, "applyRules 2")
	    #end if

	    % rule index encoded in the name field of the call!
	    const ruleIndex := tree.trees (ruleCallTP).name

	    % allocate new environment for subrule call
	    if callDepth = maxCallDepth then
		calldepth_error (applyingRuleName, rule.rules (ruleIndex).name)
	    else
		callDepth += 1
	    end if

	    bind var subruleEnvironment to callEnvironment (callDepth)

	    % remember the call depth (for garbage collection)
	    subruleEnvironment.depth := callDepth

	    % remember rule name (for debugging)
	    subruleEnvironment.name := rule.rules (ruleIndex).name

	    % attach to the local symbol table for the rule
	    subruleEnvironment.localsListAddr := addr (rule.rules (ruleIndex).localVars)

	    % allocate value bindings for ruleLocals of the rule
	    subruleEnvironment.valuesBase := valueCount

	    if valueCount + rule.rules (ruleIndex).localVars.nlocals > maxTotalValues then
		calldepth_error (applyingRuleName, rule.rules (ruleIndex).name)
	    else
	        valueCount += rule.rules (ruleIndex).localVars.nlocals
	    end if

	    % remember the scope tree
	    subruleEnvironment.scopeTP := resolvedTreeTP
    
	    % and the partially resolved replacement
	    subruleEnvironment.resultTP := nilTree
	
	    % and the partially resolved new scope
	    subruleEnvironment.newscopeTP := nilTree

	    % bind values to the formal names
	    var litAndVarActualsLeftKP := tree.trees (ruleCallTP).kidsKP
	    var eachIndex := 0

	    for arg : 1 .. rule.rules (ruleIndex).localVars.nformals
		var litOrVarActualTP := tree.kids (litAndVarActualsLeftKP)

		if tree.trees (litOrVarActualTP).kind = kindT.subsequentUse then
		    % the count field tells us the ruleLocals index!
		    valueTP (subruleEnvironment.valuesBase + arg) := valueTP (ruleEnvironment.valuesBase + tree.trees (litOrVarActualTP).count)
		    if arg = 1 then
		        % only need this fact for the first parameter of a rule -- JRC 31.8.95
			subruleEnvironment.parentrefs :=
			    rule.ruleLocals (localsListT@(ruleEnvironment.localsListAddr).localBase + tree.trees (litOrVarActualTP).count).refs
		    end if
		    % and the kidsKP tells us if it is an 'each'ed parameter
		    if tree.trees (litOrVarActualTP).kidsKP not= nilKid then
			if eachIndex = 0 then
			    eachIndex := arg
			end if
		    end if
		else
		    valueTP (subruleEnvironment.valuesBase + arg) := litOrVarActualTP
		    if arg = 1 then
		        % only need this fact for the first parameter of a rule -- JRC 31.8.95
		        subruleEnvironment.parentrefs := 1
		    end if
		end if

		litAndVarActualsLeftKP += 1
	    end for

	    % nil out the unbound ruleLocals for garbage collection
	    for loc : rule.rules (ruleIndex).localVars.nformals + 1 ..  rule.rules (ruleIndex).localVars.nlocals
		valueTP (subruleEnvironment.valuesBase + loc) := nilTree
	    end for

	    if eachIndex = 0 then
		% simple arguments
		var resultTP : treePT

		applyRule (ruleIndex, subruleEnvironment, resolvedTreeTP, resultTP, subruleMatched)

		resolvedTreeTP := resultTP
		someMatched := someMatched or subruleMatched
		allMatched := allMatched and subruleMatched
		ruleEnvironment.hasExported := ruleEnvironment.hasExported or subruleEnvironment.hasExported
		
	    else
		% each specified; arguments each'ed must be lists or repeats
		% if only one arg, apply rule using each element of the list or repeat;
		% if two args, apply to corresponding pairs
		assert tree_ops.isListOrRepeat (valueTP (subruleEnvironment.valuesBase + eachIndex))
		#if EXECUTABLE_ASSERTS then
		    Assert (tree_ops.isListOrRepeat (valueTP (subruleEnvironment.valuesBase + eachIndex)), "applyRules 3")
	        #end if
		var each1KP := tree.trees (valueTP (subruleEnvironment.valuesBase + eachIndex)).kidsKP

		if eachIndex = rule.rules (ruleIndex).localVars.nformals then
		    % one eached parameter - special case for speed
		    % run through the lists - calls with empty lists do nothing!
		    loop
			exit when tree.trees (tree.kids (each1KP)).kind = kindT.empty
    
		    	% remember the scope tree for EACH invocation!
		    	subruleEnvironment.scopeTP := resolvedTreeTP

		    	% and the partially resolved replacement
		    	subruleEnvironment.resultTP := nilTree
    
			valueTP (subruleEnvironment.valuesBase + eachIndex) := tree.kids (each1KP)
    
			var resultTP : treePT
    
			applyRule (ruleIndex, subruleEnvironment, resolvedTreeTP, resultTP, subruleMatched)
    
			resolvedTreeTP := resultTP
			someMatched := someMatched or subruleMatched
			allMatched := allMatched and subruleMatched
			ruleEnvironment.hasExported := ruleEnvironment.hasExported or subruleEnvironment.hasExported
    			
			each1KP := tree.trees (tree.kids (each1KP + 1)).kidsKP
		    end loop
		    
		elsif eachIndex + 1 = rule.rules (ruleIndex).localVars.nformals then
		    % two eached parameters - special case for speed
		    assert tree_ops.isListOrRepeat (valueTP (subruleEnvironment.valuesBase + eachIndex + 1))
		    #if EXECUTABLE_ASSERTS then
		        Assert (tree_ops.isListOrRepeat (valueTP (subruleEnvironment.valuesBase + eachIndex + 1)), "applyRules 4")
		    #end if
		    var each2KP := tree.trees (valueTP (subruleEnvironment.valuesBase + eachIndex + 1)).kidsKP
		    
		    % Lengths no longer need be the same - JRC 26.5.96

		    % run through the lists - calls with empty lists do nothing!
		    loop
			exit when tree.trees (tree.kids (each1KP)).kind = kindT.empty
			    or tree.trees (tree.kids (each2KP)).kind = kindT.empty
    
		    	% remember the scope tree for EACH invocation!
		    	subruleEnvironment.scopeTP := resolvedTreeTP

		    	% and the partially resolved replacement
		    	subruleEnvironment.resultTP := nilTree
    
			valueTP (subruleEnvironment.valuesBase + eachIndex) := tree.kids (each1KP)
    			valueTP (subruleEnvironment.valuesBase + eachIndex + 1) := tree.kids (each2KP)
    
			var resultTP : treePT
    
			applyRule (ruleIndex, subruleEnvironment, resolvedTreeTP, resultTP, subruleMatched)
    
			resolvedTreeTP := resultTP
			someMatched := someMatched or subruleMatched
			allMatched := allMatched and subruleMatched
			ruleEnvironment.hasExported := ruleEnvironment.hasExported or subruleEnvironment.hasExported
    
			each1KP := tree.trees (tree.kids (each1KP + 1)).kidsKP
			each2KP := tree.trees (tree.kids (each2KP + 1)).kidsKP
		    end loop
		    
		else
		    % general case - not yet implemented
		    error ("", "'each' limited to at most two parameters", LIMIT_FATAL, 505)
		end if
	    end if  % eachIndex = 0
	
	    % deallocate value bindings for ruleLocals of the rule
	    valueCount := subruleEnvironment.valuesBase 

	    callDepth -= 1
	    
	    localRuleCallsKP += 1

	    exit when tree.kids (localRuleCallsKP) = nilTree
	end loop

	applyingRuleName := thisRuleName

    end applyRules


    procedure resolveReplacementExpressions (var resolvedReplacementTP : treePT, var ruleEnvironment : ruleEnvironmentT)

	assert tree.trees (resolvedReplacementTP).kidsKP >= 0 and tree.trees (resolvedReplacementTP).kidsKP <= maxKids 
	#if EXECUTABLE_ASSERTS then
	    Assert (tree.trees (resolvedReplacementTP).kidsKP >= 0 and tree.trees (resolvedReplacementTP).kidsKP <= maxKids , "resolveReplacementExpressions 1")
	#end if

	% Avoid multiple local vars
	var resolvedKidTP : treePT

	case tree.trees (resolvedReplacementTP).kind of

	    label kindT.order :
		var replacementKidsKP := tree.trees (resolvedReplacementTP).kidsKP
		const endKP := replacementKidsKP + tree.trees (resolvedReplacementTP).count
		assert replacementKidsKP not= nilKid
		#if EXECUTABLE_ASSERTS then
		    Assert (replacementKidsKP not= nilKid, "resolveReplacementExpressions 2")
		#end if
		loop
		    resolvedKidTP := tree.kids (replacementKidsKP)
		    resolveReplacementExpressions (resolvedKidTP, ruleEnvironment)
		    tree.setKidTree (replacementKidsKP, resolvedKidTP)
		    replacementKidsKP += 1
		    exit when replacementKidsKP >= endKP
		end loop

	    label kindT.repeat :
		var replacementKidsKP := tree.trees (resolvedReplacementTP).kidsKP
		assert replacementKidsKP not= nilKid
		#if EXECUTABLE_ASSERTS then
		    Assert (replacementKidsKP not= nilKid, "resolveReplacementExpressions 3")
		#end if
		loop
		    resolvedKidTP := tree.kids (replacementKidsKP)
		    resolveReplacementExpressions (resolvedKidTP, ruleEnvironment)
		    tree.setKidTree (replacementKidsKP, resolvedKidTP)
		    exit when tree.trees (tree.kids (replacementKidsKP + 1)).kind not= kindT.repeat
		    replacementKidsKP := tree.trees (tree.kids (replacementKidsKP + 1)).kidsKP
		end loop
		resolvedKidTP := tree.kids (replacementKidsKP + 1)
		resolveReplacementExpressions (resolvedKidTP, ruleEnvironment)
		tree.setKidTree (replacementKidsKP + 1, resolvedKidTP)

	    label kindT.list :
		var replacementKidsKP := tree.trees (resolvedReplacementTP).kidsKP
		assert replacementKidsKP not= nilKid
		#if EXECUTABLE_ASSERTS then
		    Assert (replacementKidsKP not= nilKid, "resolveReplacementExpressions 4")
		#end if
		loop
		    resolvedKidTP := tree.kids (replacementKidsKP)
		    resolveReplacementExpressions (resolvedKidTP, ruleEnvironment)
		    tree.setKidTree (replacementKidsKP, resolvedKidTP)
		    exit when tree.trees (tree.kids (replacementKidsKP + 1)).kind not= kindT.list
		    replacementKidsKP := tree.trees (tree.kids (replacementKidsKP + 1)).kidsKP
		end loop
		resolvedKidTP := tree.kids (replacementKidsKP + 1)
		resolveReplacementExpressions (resolvedKidTP, ruleEnvironment)
		tree.setKidTree (replacementKidsKP + 1, resolvedKidTP)

	    label kindT.choose :
		const replacementKidKP := tree.trees (resolvedReplacementTP).kidsKP
		assert replacementKidKP not= nilKid
		#if EXECUTABLE_ASSERTS then
		    Assert (replacementKidKP not= nilKid, "resolveReplacementExpressions 5")
		#end if

		resolvedKidTP := tree.kids (replacementKidKP)
		resolveReplacementExpressions (resolvedKidTP, ruleEnvironment)
		tree.setKidTree (replacementKidKP, resolvedKidTP)

	    label kindT.literal, kindT.stringlit, kindT.charlit, kindT.number, kindT.id,
		    kindT.comment, kindT.space, kindT.newline, kindT.srclinenumber, kindT.srcfilename,
		    kindT.usertoken1, kindT.usertoken2, kindT.usertoken3, kindT.usertoken4, kindT.usertoken5, 
		    kindT.usertoken6, kindT.usertoken7, kindT.usertoken8, kindT.usertoken9, kindT.usertoken10,
		    kindT.usertoken11, kindT.usertoken12, kindT.usertoken13, kindT.usertoken14, kindT.usertoken15, 
		    kindT.usertoken16, kindT.usertoken17, kindT.usertoken18, kindT.usertoken19, kindT.usertoken20,
		    kindT.usertoken21, kindT.usertoken22, kindT.usertoken23, kindT.usertoken24, kindT.usertoken25, 
		    kindT.usertoken26, kindT.usertoken27, kindT.usertoken28, kindT.usertoken29, kindT.usertoken30,
		    kindT.empty, kindT.token, kindT.key, kindT.upperlowerid, kindT.upperid,
		    kindT.lowerupperid, kindT.lowerid, kindT.floatnumber, 
		    kindT.decimalnumber, kindT.integernumber :
		return

	    label kindT.expression, kindT.lastExpression :
		% the count field tells us the ruleLocals index!
		const localIndex := tree.trees (resolvedReplacementTP).count
		const ruleCallsKP : kidPT := tree.trees (resolvedReplacementTP).kidsKP

		% We must copy every variable reference in order to
		% avoid creating DAGs - unless it is used exactly once, 
		% or is the very last reference.

		if (rule.ruleLocals (localsListT@(ruleEnvironment.localsListAddr).localBase + localIndex).refs = 1 
			or tree.trees (resolvedReplacementTP).kind = kindT.lastExpression)
			    and not options.option (apply_print_p) then  % Fix -Dapply tracing bug - JRC 21.8.07
		    #if DEBUGGER then
			if options.option (rule_print_p) and options.option (sharing_p) then
			    put:0, "Did not copy '", 
				string@(ident.idents (rule.ruleLocals (localsListT@(ruleEnvironment.localsListAddr).localBase + localIndex).name)), "'" ..
			    if tree.trees (resolvedReplacementTP).kind = kindT.lastExpression then
				put:0, " (last ref)"
			    else
				put:0, " (refs = 1)"
			    end if
			end if
		    #end if
		    resolvedReplacementTP := valueTP (ruleEnvironment.valuesBase + localIndex)
		    noncopies += 1

		else
		    const oldKidCount := tree.kidCount
		    const oldTreeCount := tree.treeCount
		    tree.copyTree (valueTP (ruleEnvironment.valuesBase + localIndex), resolvedReplacementTP)
		    #if DEBUGGER then
			if options.option (rule_print_p) and options.option (sharing_p) then
			    const refs : int := 
				rule.ruleLocals (localsListT@(ruleEnvironment.localsListAddr).localBase + localIndex).refs
			    put:0, "Forced to copy '", 
				string@(ident.idents (rule.ruleLocals (localsListT@(ruleEnvironment.localsListAddr).localBase + localIndex).name)), 
				"' (refs = ", refs, ")",
				" - cost ", tree.treeCount - oldTreeCount +1, 
				" trees and ", tree.kidCount - oldKidCount +1, " kids"
			end if
		    #end if
		    copies += 1
		end if

		if ruleCallsKP not= nilKid then 
		    % Now apply the subrules to it
		    var someRulesSucceeded, allRulesSucceeded : boolean
		    applyRules (ruleCallsKP, ruleEnvironment, resolvedReplacementTP, someRulesSucceeded, allRulesSucceeded)
		end if
		
	    label :
		error ("", "Fatal TXL error in resolveReplacementExpressions", INTERNAL_FATAL, 506)
	end case

    end resolveReplacementExpressions


    procedure makeReplacement (replacementTP : treePT, var subTreeTP : treePT,
	    var ruleEnvironment : ruleEnvironmentT)

	handler (code)
	    if code = outOfKids or code = outOfTrees then
		% re-establish the rule call context and synchronize the call stack
		callDepth := ruleEnvironment.depth
		valueCount := ruleEnvironment.valuesBase + localsListT@(ruleEnvironment.localsListAddr).nlocals
		applyingRuleName := ruleEnvironment.name		    

		if options.option (verbose_p) then
		    put : 0, "    applying rule/function '", string@(ident.idents (applyingRuleName)), "'"
		end if
		
		% attempt to recover
		if callDepth not= currentGCdepth then
		    if options.option (verbose_p) then
			put : 0, "  (invoking garbage recovery)"
		    end if
		    const prevGCdepth := currentGCdepth
		    currentGCdepth := callDepth
		    nGarbageRecoveries += 1
		    if options.option (verbose_p) then
			put : 0, "--- Recovering garbage ..." 
		    end if
		    garbageRecovery.recoverGarbage
		    % now try the rule again
		    if options.option (verbose_p) then
			put : 0, "--- Retrying replacement in '", string@(ident.idents (applyingRuleName)), "'" 
		    end if

		    makeReplacement (replacementTP, subTreeTP, ruleEnvironment)
		    
		    if options.option (verbose_p) then
			put : 0, "--- Completed retry of replacement in '", string@(ident.idents (applyingRuleName)), "'" 
		    end if
		    currentGCdepth := prevGCdepth
		    return
		else
		    error ("", "Repeated space failure in same replacement (a larger size is required for this transform)", FATAL, 507)
		end if
	    end if
	    quit > : code
	end handler

	assert callEnvironment (callDepth).name = applyingRuleName
	assert ruleEnvironment.name = applyingRuleName 

	#if EXECUTABLE_ASSERTS then
	    Assert (callEnvironment (callDepth).name = applyingRuleName, "makeReplacement 1")
	    Assert (ruleEnvironment.name = applyingRuleName, "makeReplacement 2") 
	#end if

	var oldTreeTP : treePT

	if options.option (apply_print_p) then
	    % will this work with garbage collecting? -- NO!
	    assert tree.allocationStrategy = simple

	    if subTreeTP = nilTree then
		oldTreeTP := nilTree
	    else
		tree.copyTree (subTreeTP, oldTreeTP)
	    end if
	end if

	assert replacementTP not= nilTree
	#if EXECUTABLE_ASSERTS then
	    Assert (replacementTP not= nilTree, "makeReplacement 3")
	#end if
		
	% The replacement is one thing we *must* copy every time,
	% since it will become part of the new parse tree.
	var resolvedReplacementTP : treePT
	tree.copyTree (replacementTP, resolvedReplacementTP)

	% Make sure the garbage collector knows we are working on this tree
	ruleEnvironment.resultTP := resolvedReplacementTP

	resolveReplacementExpressions (resolvedReplacementTP, ruleEnvironment)

	% Link in the resolved replacement for subTree by copying
	% the root tree of the replacement subtree into the root
	% tree of the original.

	if options.option (apply_print_p) then
	    if oldTreeTP not= nilTree and 
		    not tree.sameTrees (oldTreeTP, resolvedReplacementTP) then
		unparser.printLeaves (oldTreeTP, 0, false)
		put : 0, " ==> " ..
		unparser.printLeaves (resolvedReplacementTP, 0, false)
		put : 0, " [", string@(ident.idents (applyingRuleName)), "]"
	    end if
	end if

	% If sharing is done perfectly, it is not necessary to copy this!
	subTreeTP := resolvedReplacementTP

    end makeReplacement


    function testCondition (replacementTP : treePT, 
	    var ruleEnvironment : ruleEnvironmentT, wantAll : boolean) : boolean

	assert tree.trees (replacementTP).kind = kindT.expression 
	#if EXECUTABLE_ASSERTS then
	    Assert (tree.trees (replacementTP).kind = kindT.expression , "testCondition 1")
	#end if

	% the count field tells us the ruleLocals index!
	const localIndex := tree.trees (replacementTP).count
	var expressionTP := valueTP (ruleEnvironment.valuesBase + localIndex)

	const ruleCallsKP : kidPT := tree.trees (replacementTP).kidsKP
	assert ruleCallsKP not= nilKid 
	#if EXECUTABLE_ASSERTS then
	    Assert (ruleCallsKP not= nilKid , "testCondition 2")
	#end if

	var someSuccess, allSuccess := false
	applyRules (ruleCallsKP, ruleEnvironment, expressionTP, someSuccess, allSuccess)

	if wantAll then
	    result allSuccess
	else
	    result someSuccess
	end if

    end testCondition


    procedure processParts (ruleName : tokenT, prePostParts : partsListT, var ruleEnvironment : ruleEnvironmentT, var success : boolean)

	success := true

	for i : 1 .. prePostParts.nparts
	    bind part to rule.ruleParts (prePostParts.partsBase + i)

	    case part.kind of
		label partKind.construct :
		    #if DEBUGGER then
			if debugger.isbreakpoint (ruleName) then
			    debugger.breakpoint (DBkind.constructEntry, 
				ruleName, part.nameRef, nilTree, ruleEnvironment, false)
			end if
		    #end if

		    var resultTree := nilTree

		    makeReplacement (part.replacementTP, resultTree, ruleEnvironment)

		    valueTP (ruleEnvironment.valuesBase + part.nameRef) := resultTree

		    #if DEBUGGER then
			if debugger.isbreakpoint (ruleName) then
			    debugger.breakpoint (DBkind.constructExit, 
				ruleName, part.nameRef, resultTree, ruleEnvironment, true)
			end if
		    #end if

		label partKind.deconstruct :
		    const decValueTP := valueTP (ruleEnvironment.valuesBase + part.nameRef)

		    if part.starred then
			if part.skipName = NOT_FOUND then
			    success := searchTreeForDeconstructPattern (part.patternTP, decValueTP, ruleEnvironment)
			else
			    if part.skipRepeat then
			        success := searchTreeForDeconstructPatternSkippingRepeat (part.patternTP, decValueTP, ruleEnvironment)
			    else
			        success := searchTreeForDeconstructPatternSkipping (part.patternTP, decValueTP, ruleEnvironment, part.skipName)
			    end if
			end if
		    else
			success := matchTreeToPattern (part.patternTP, decValueTP, ruleEnvironment)
		    end if
		    
		    if part.negated then
		        success := not success
		    end if

		    #if DEBUGGER then
			if debugger.isbreakpoint (ruleName) then
			    debugger.breakpoint (DBkind.deconstructExit, 
				ruleName, part.nameRef, nilTree, ruleEnvironment, success)
			end if
		    #end if

		label partKind.cond :

		    success := testCondition (part.replacementTP, ruleEnvironment, part.anded)

		    if part.negated then
			success := not success
		    end if

		    #if DEBUGGER then
			if debugger.isbreakpoint (ruleName) then
			    debugger.breakpoint (DBkind.conditionExit, 
				ruleName, part.nameRef, nilTree, ruleEnvironment, success)
			end if
		    #end if

		label partKind.assert_ :

		    success := testCondition (part.replacementTP, ruleEnvironment, part.anded)

		    if part.negated then
			success := not success
		    end if

		    #if DEBUGGER then
			if debugger.isbreakpoint (ruleName) then
			    debugger.breakpoint (DBkind.conditionExit, 
				ruleName, part.nameRef, nilTree, ruleEnvironment, success)
			end if
		    #end if
		    
		    if not success then
		        assert_error (ruleName, part.name)
		    end if

		label partKind.import_ :
		    bind globalEnvironment to callEnvironment (0)
		    
		    const impValueTP := valueTP (globalEnvironment.valuesBase + part.globalRef)
		    valueTP (ruleEnvironment.valuesBase + part.nameRef) := impValueTP

		    if impValueTP = nilTree then
		        global_error (ruleName, part.name)
		    end if
		    
		    if part.patternTP not= nilTree then
		        success := matchTreeToPattern (part.patternTP, impValueTP, ruleEnvironment)
		    else
		        success := true
		    end if
		    
		    #if DEBUGGER then
			if debugger.isbreakpoint (ruleName) then
			    debugger.breakpoint (DBkind.importExit, 
				ruleName, part.nameRef, valueTP (ruleEnvironment.valuesBase + part.nameRef), 
				ruleEnvironment, success)
			end if
		    #end if

		label partKind.export_ :
		    #if DEBUGGER then
			if debugger.isbreakpoint (ruleName) then
			    debugger.breakpoint (DBkind.exportEntry, 
				ruleName, part.nameRef, nilTree, ruleEnvironment, false)
			end if
		    #end if

		    bind globalEnvironment to callEnvironment (0)

		    if part.replacementTP not= nilTree then
			var resultTree := nilTree
			makeReplacement (part.replacementTP, resultTree, ruleEnvironment)
			valueTP (ruleEnvironment.valuesBase + part.nameRef) := resultTree
		    end if

		    % we always share the value of a global with its corresponding local
		    % (note this means we must be careful to copy every reference to the corresponding local!)
		    valueTP (globalEnvironment.valuesBase + part.globalRef) := valueTP (ruleEnvironment.valuesBase + part.nameRef)

		    ruleEnvironment.hasExported := true
		    
		    #if DEBUGGER then
			if debugger.isbreakpoint (ruleName) then
			    debugger.breakpoint (DBkind.exportExit, 
				ruleName, part.nameRef, valueTP (ruleEnvironment.valuesBase + part.nameRef), ruleEnvironment, true)
			end if
		    #end if

		label :
		    error ("", "Fatal TXL error in processParts", INTERNAL_FATAL, 508)
	    end case

	    exit when not success
	end for
    end processParts


    function searchTreeForPattern (rule : ruleT, argTreeTP : treePT,
	    var parentKP : kidPT, var ruleEnvironment : ruleEnvironmentT) : boolean

	% Rationale for the order of the following logic is the typical frequency
	% profile of the cases in production use at Legasys.  Here is a sample:
	
	% kind of treeTP, per cycle :
	% empty		 4789226	28.0%
	% repeat	 3320065	19.4%
	% literal	 2687817	15.7%
	% choose	 2421533	14.2%
	% id		 2021533	11.8%
	% order		 1581074	 9.2%
	% stringlit	  250804	 1.5%
	% charlit	   15556	 0.1%
	% number	   15135	 0.1%

	var treeTP := argTreeTP
	var patternTP := rule.patternTP
	var st := searchTop
	const searchBase := searchTop

	if tree.trees (patternTP).kind = kindT.subsequentUse then
	    % use concrete pattern
	    patternTP := valueTP (ruleEnvironment.valuesBase + tree.trees (patternTP).count)
	end if
	    
	loop
	    assert tree.trees (patternTP).kidsKP >= 0 and tree.trees (patternTP).kidsKP <= maxKids 
	    assert tree.trees (treeTP).kidsKP >= 0 and tree.trees (treeTP).kidsKP <= maxKids 

	    #if EXECUTABLE_ASSERTS then
	        Assert (tree.trees (patternTP).kidsKP >= 0 and tree.trees (patternTP).kidsKP <= maxKids, "searchTreeForPattern 1")
	        Assert (tree.trees (treeTP).kidsKP >= 0 and tree.trees (treeTP).kidsKP <= maxKids, "searchTreeForPattern 2")
	    #end if

	    #if PROFILER then
		searchcycles += 1
	    #end if

	    if (tree.trees (treeTP).kind = tree.trees (patternTP).kind or tree.trees (patternTP).kind = kindT.firstTime)
	    	    and matchTreeToPattern (patternTP, treeTP, ruleEnvironment) then
		#if DEBUGGER then
		    if debugger.isbreakpoint (rule.name) then
			debugger.breakpoint (DBkind.matchEntry, rule.name, 0, treeTP, ruleEnvironment, false)
		    end if
		#end if

		if rule.postPattern.nparts > 0 then
		    const oldTreeCount := tree.treeCount
		    const oldKidCount := tree.kidCount
		    var yes : boolean
		    searchTop := st
		    processParts (rule.name, rule.postPattern, ruleEnvironment, yes)
		    if yes then
			searchTop := searchBase
			result true
		    else
		        if tree.allocationStrategy = simple and not ruleEnvironment.hasExported then
			    % recover any space we may have used in the post pattern
			    tree.setTreeCount (oldTreeCount)
			    tree.setKidCount (oldKidCount)
			end if
		    end if
		else
		    searchTop := searchBase
		    result true
		end if

		#if DEBUGGER then
		    const nprelocals := localsListT@(ruleEnvironment.localsListAddr).nprelocals
		    const nlocals := localsListT@(ruleEnvironment.localsListAddr).nlocals
		    for l : nprelocals + 1 .. nlocals
			valueTP (ruleEnvironment.valuesBase + l) := nilTree
		    end for
		#end if
	    end if
	
	    if tree.trees (treeTP).kind >= firstLeafKind then
	    	% A terminal -
		% Pop any completed sequences ...
		loop
		    if st = searchBase then
		        searchTop := searchBase
			result false
		    end if
		    exit when searchStack (st).kidsKP < searchStack (st).endKP
		    st -= 1
		end loop
		% ... and move on to the next subtree in the sequence
		assert st > searchBase and searchStack (st).kidsKP < searchStack (st).endKP
		#if EXECUTABLE_ASSERTS then
		    Assert (st > searchBase and searchStack (st).kidsKP < searchStack (st).endKP, "searchTreeForPattern 3")
		#end if
		searchStack (st).kidsKP += 1
	    	parentKP := searchStack (st).kidsKP
		treeTP := tree.kids (parentKP)

	    elsif tree.trees (treeTP).kind = kindT.choose then
		% One child - just go down to it (no need to come back)
		parentKP := tree.trees (treeTP).kidsKP
		treeTP := tree.kids (parentKP)
    
	    else
		% Push a new sequence of subtrees to check
	    	assert tree.trees (treeTP).kind = kindT.order or tree.trees (treeTP).kind = kindT.repeat or tree.trees (treeTP).kind = kindT.list
	    	#if EXECUTABLE_ASSERTS then
		    Assert (tree.trees (treeTP).kind = kindT.order or tree.trees (treeTP).kind = kindT.repeat or tree.trees (treeTP).kind = kindT.list, "searchTreeForPattern 4")
		#end if

		if st >= maxSearchDepth	then
		    searchdepth_error (applyingRuleName)
		end if

		st += 1
		searchStack (st).kidsKP := tree.trees (treeTP).kidsKP
		searchStack (st).endKP := searchStack (st).kidsKP + tree.trees (treeTP).count - 1
		parentKP := tree.trees (treeTP).kidsKP
		treeTP := tree.kids (parentKP)
	    end if
	end loop

    end searchTreeForPattern


    function searchTreeForPatternSkipping (rule : ruleT, argTreeTP : treePT,
	    var parentKP : kidPT, var ruleEnvironment : ruleEnvironmentT, 
	    skipName : tokenT) : boolean

	var treeTP := argTreeTP
	var patternTP := rule.patternTP
	var st := searchTop
	const searchBase := searchTop

	if tree.trees (patternTP).kind = kindT.subsequentUse then
	    % use concrete pattern
	    patternTP := valueTP (ruleEnvironment.valuesBase + tree.trees (patternTP).count)
	end if
	    
	loop
	    assert tree.trees (patternTP).kidsKP >= 0 and tree.trees (patternTP).kidsKP <= maxKids 
	    assert tree.trees (treeTP).kidsKP >= 0 and tree.trees (treeTP).kidsKP <= maxKids 
	    #if EXECUTABLE_ASSERTS then
	        Assert (tree.trees (patternTP).kidsKP >= 0 and tree.trees (patternTP).kidsKP <= maxKids , "searchTreeForPatternSkipping 1")
	        Assert (tree.trees (treeTP).kidsKP >= 0 and tree.trees (treeTP).kidsKP <= maxKids , "searchTreeForPatternSkipping 2")
	    #end if

	    #if PROFILER then
		searchcycles += 1
	    #end if
	    
	    if (tree.trees (treeTP).kind = tree.trees (patternTP).kind or tree.trees (patternTP).kind = kindT.firstTime)
	    	    and matchTreeToPattern (patternTP, treeTP, ruleEnvironment) then
		#if DEBUGGER then
		    if debugger.isbreakpoint (rule.name) then
			debugger.breakpoint (DBkind.matchEntry, rule.name, 0, treeTP, ruleEnvironment, false)
		    end if
		#end if

		if rule.postPattern.nparts > 0 then
		    const oldTreeCount := tree.treeCount
		    const oldKidCount := tree.kidCount
		    var yes : boolean
		    searchTop := st
		    processParts (rule.name, rule.postPattern, ruleEnvironment, yes)
		    if yes then
			searchTop := searchBase
			result true
		    else
			if tree.allocationStrategy = simple and not ruleEnvironment.hasExported then
			    % recover any space we may have used in the post pattern
			    tree.setTreeCount (oldTreeCount)
			    tree.setKidCount (oldKidCount)
			end if
		    end if
		else
		    searchTop := searchBase
		    result true
		end if

		#if DEBUGGER then
		    const nprelocals := localsListT@(ruleEnvironment.localsListAddr).nprelocals
		    const nlocals := localsListT@(ruleEnvironment.localsListAddr).nlocals
		    for l : nprelocals + 1 .. nlocals
			valueTP (ruleEnvironment.valuesBase + l) := nilTree
		    end for
		#end if
	    end if
	
	    if tree.trees (treeTP).kind >= firstLeafKind 
	    	    or tree.trees (treeTP).name = skipName then
	    	% A terminal -
		% Pop any completed sequences ...
		loop
		    if st = searchBase then
		        searchTop := searchBase
			result false
		    end if
		    exit when searchStack (st).kidsKP < searchStack (st).endKP
		    st -= 1
		end loop
		% ... and move on to the next subtree in the sequence
		assert st > searchBase and searchStack (st).kidsKP < searchStack (st).endKP
		#if EXECUTABLE_ASSERTS then
		    Assert (st > searchBase and searchStack (st).kidsKP < searchStack (st).endKP, "searchTreeForPatternSkipping 3")
		#end if
		searchStack (st).kidsKP += 1
	    	parentKP := searchStack (st).kidsKP
		treeTP := tree.kids (parentKP)

	    elsif tree.trees (treeTP).kind = kindT.choose then
		% One child - just go down to it (no need to come back)
		parentKP := tree.trees (treeTP).kidsKP
		treeTP := tree.kids (parentKP)
    
	    else
		% Push a new sequence of subtrees to check
		assert tree.trees (treeTP).kind = kindT.order or tree.trees (treeTP).kind = kindT.repeat or tree.trees (treeTP).kind = kindT.list
		#if EXECUTABLE_ASSERTS then
		    Assert (tree.trees (treeTP).kind = kindT.order or tree.trees (treeTP).kind = kindT.repeat or tree.trees (treeTP).kind = kindT.list, "searchTreeForPatternSkipping 4")
		#end if

		if st >= maxSearchDepth	then
		    searchdepth_error (applyingRuleName)
		end if

		st += 1
		searchStack (st).kidsKP := tree.trees (treeTP).kidsKP
		searchStack (st).endKP := searchStack (st).kidsKP + tree.trees (treeTP).count - 1
		parentKP := tree.trees (treeTP).kidsKP
		treeTP := tree.kids (parentKP)
	    end if
	end loop

    end searchTreeForPatternSkipping


    function searchTreeForPatternSkippingRepeat (rule : ruleT, argTreeTP : treePT,
	    var parentKP : kidPT, var ruleEnvironment : ruleEnvironmentT) : boolean

	var treeTP := argTreeTP
	var patternTP := rule.patternTP
	    
	if tree.trees (patternTP).kind = kindT.subsequentUse then
	    % use concrete pattern
	    patternTP := valueTP (ruleEnvironment.valuesBase + tree.trees (patternTP).count)
	end if

	% walk the repeat looking for the matching element
	loop 
	    exit when tree.trees (tree.kids (tree.trees (treeTP).kidsKP)).kind = kindT.empty 

	    #if PROFILER then
		searchcycles += 1
	    #end if
	    
	    parentKP := tree.trees (treeTP).kidsKP
	    const elementTP := tree.kids (parentKP)
	    
	    if (tree.trees (elementTP).kind = tree.trees (patternTP).kind or tree.trees (patternTP).kind = kindT.firstTime)
	    	    and matchTreeToPattern (patternTP, elementTP, ruleEnvironment) then
		#if DEBUGGER then
		    if debugger.isbreakpoint (rule.name) then
			debugger.breakpoint (DBkind.matchEntry, rule.name, 0, treeTP, ruleEnvironment, false)
		    end if
		#end if

		if rule.postPattern.nparts > 0 then
		    const oldTreeCount := tree.treeCount
		    const oldKidCount := tree.kidCount
		    var yes : boolean
		    processParts (rule.name, rule.postPattern, ruleEnvironment, yes)
		    if yes then
			result true
		    else
			if tree.allocationStrategy = simple and not ruleEnvironment.hasExported then
			    % recover any space we may have used in the post pattern
			    tree.setTreeCount (oldTreeCount)
			    tree.setKidCount (oldKidCount)
			end if
		    end if
		else
		    result true
		end if

		#if DEBUGGER then
		    const nprelocals := localsListT@(ruleEnvironment.localsListAddr).nprelocals
		    const nlocals := localsListT@(ruleEnvironment.localsListAddr).nlocals
		    for l : nprelocals + 1 .. nlocals
			valueTP (ruleEnvironment.valuesBase + l) := nilTree
		    end for
		#end if
	    end if
	    
	    treeTP := tree.kids (tree.trees (treeTP).kidsKP + 1) 
	end loop 
	
	result false
	
    end searchTreeForPatternSkippingRepeat


    procedure applyRuleWhileMatch 
	    (rule : ruleT, var ruleEnvironment : ruleEnvironmentT,
	     originalTP : treePT, var resultTP : treePT, var matchedAtLeastOnce : boolean)
	
	resultTP := originalTP

	const oldTreeCount := tree.treeCount
	const oldKidCount := tree.kidCount
	
	var matched : boolean
	matchedAtLeastOnce := false

	if rule.prePattern.nparts > 0 then
	    processParts (rule.name, rule.prePattern, ruleEnvironment, matched)

	    if not matched then
		if tree.allocationStrategy = simple and not ruleEnvironment.hasExported then
		    % recover any space we may have used in the post pattern
		    tree.setTreeCount (oldTreeCount)
		    tree.setKidCount (oldKidCount)
		end if
		return
	    end if
	end if

	var firstTime := true
	matched := false

	loop
	    var parentKP := nilKid

	    if rule.skipName = NOT_FOUND then
		matched := searchTreeForPattern (rule, resultTP, parentKP, ruleEnvironment)
	    else
		if rule.skipRepeat then
		    matched := searchTreeForPatternSkippingRepeat (rule, resultTP, parentKP, ruleEnvironment)
		else
		    matched := searchTreeForPatternSkipping (rule, resultTP, parentKP, ruleEnvironment, rule.skipName)
	        end if
	    end if

	    if not matched then
		if firstTime then
		    if tree.allocationStrategy = simple and not ruleEnvironment.hasExported then
			% recover any space we may have used in the post pattern
			tree.setTreeCount (oldTreeCount)
			tree.setKidCount (oldKidCount)
		    end if
		end if
		return
	    end if
	    
	    matchedAtLeastOnce := true

	    if rule.replacementTP = nilTree then
		% a match rule that succeeded
		assert matched
		if tree.allocationStrategy = simple and not ruleEnvironment.hasExported then
		    % recover any space we may have used in the post pattern
		    tree.setTreeCount (oldTreeCount)
		    tree.setKidCount (oldKidCount)
		end if
		return
	    end if

	    if parentKP = nilKid then
		makeReplacement (rule.replacementTP, resultTP, ruleEnvironment)
	    	% this will become the new scope when we are done -
		% so make sure that the garbage collector knows about it
		ruleEnvironment.newscopeTP := resultTP
	    else
		var replacedKidTP := tree.kids (parentKP)
		makeReplacement (rule.replacementTP, replacedKidTP, ruleEnvironment)
		tree.setKidTree (parentKP, replacedKidTP)
	    end if

	    #if DEBUGGER then
		if debugger.isbreakpoint (rule.name) then
		    var replacementResultTP := resultTP
		    if parentKP not= nilKid then
			replacementResultTP := tree.kids (parentKP)
		    end if
		    debugger.breakpoint (DBkind.matchExit, rule.name, 0, replacementResultTP, ruleEnvironment, true)
		end if
	    #end if
	    
	    firstTime := false
	end loop

    end applyRuleWhileMatch


    procedure applyRuleOnceOnly 
	    (rule : ruleT, var ruleEnvironment : ruleEnvironmentT,
	     originalTP : treePT, var resultTP : treePT, var matched : boolean)

	resultTP := originalTP 

	const oldTreeCount := tree.treeCount
	const oldKidCount := tree.kidCount

	if rule.prePattern.nparts > 0 then
	    processParts (rule.name, rule.prePattern, ruleEnvironment, matched)
	    
	    if not matched then
		if tree.allocationStrategy = simple and not ruleEnvironment.hasExported then
		    % recover any space we may have used in the post pattern
		    tree.setTreeCount (oldTreeCount)
		    tree.setKidCount (oldKidCount)
		end if
		return
	    end if
	end if

	var parentKP := nilKid

	if not rule.starred then

	    matched := matchTreeToPattern (rule.patternTP, resultTP, ruleEnvironment)

	    if not matched then
		if tree.allocationStrategy = simple and not ruleEnvironment.hasExported then
		    % recover any space we may have used in the post pattern
		    tree.setTreeCount (oldTreeCount)
		    tree.setKidCount (oldKidCount)
		end if
		return
	    end if

	    #if DEBUGGER then
		if debugger.isbreakpoint (rule.name) then
		    debugger.breakpoint (DBkind.matchEntry, 
			rule.name, 0, resultTP, ruleEnvironment, false)
		end if
	    #end if

	    if rule.postPattern.nparts > 0 then
		processParts (rule.name, rule.postPattern, ruleEnvironment, matched)
	    end if

	elsif rule.skipName = NOT_FOUND then
	    matched := searchTreeForPattern (rule, resultTP, parentKP, ruleEnvironment)
	else
	    if rule.skipRepeat then
		matched := searchTreeForPatternSkippingRepeat (rule, resultTP, parentKP, ruleEnvironment)
	    else
		matched := searchTreeForPatternSkipping (rule, resultTP, parentKP, ruleEnvironment, rule.skipName)
	    end if
	end if

	if not matched then
	    if tree.allocationStrategy = simple and not ruleEnvironment.hasExported then
		% recover any space we may have used in the post pattern
		tree.setTreeCount (oldTreeCount)
		tree.setKidCount (oldKidCount)
	    end if
	    return
	end if

	if rule.replacementTP = nilTree then
	    % a match function that succeeded
	    assert matched 
	    if tree.allocationStrategy = simple and not ruleEnvironment.hasExported then
		% recover any space we may have used in the post pattern
		tree.setTreeCount (oldTreeCount)
		tree.setKidCount (oldKidCount)
	    end if
	    return
	end if

	if parentKP = nilKid then
	    makeReplacement (rule.replacementTP, resultTP, ruleEnvironment)
	    % this will become the new scope when we are done -
	    % so make sure that the garbage collector knows about it
	    ruleEnvironment.newscopeTP := resultTP
	else
	    var resultKidTP := tree.kids (parentKP)
	    makeReplacement (rule.replacementTP, resultKidTP, ruleEnvironment)
	    tree.setKidTree (parentKP, resultKidTP)
	end if

	#if DEBUGGER then
	    if debugger.isbreakpoint (rule.name) then
		debugger.breakpoint (DBkind.matchExit, 
		    rule.name, 0, resultTP, ruleEnvironment, true)
	    end if
	#end if
    end applyRuleOnceOnly
    
    
    procedure termination_error (ruleName : tokenT)
        error ("rule/function '" + string@(ident.idents (ruleName)) + "'",
	    "One pass rule failed to terminate (probable cause: part of replacement matches pattern)", FATAL, 509)
    end termination_error


    procedure applyRuleOnePass 
	    (rule : ruleT, var ruleEnvironment : ruleEnvironmentT,
	     originalTP : treePT, var resultTP : treePT, var matchedAtLeastOnce : boolean)
	
	% 10.8 Added support for visit-only match $ rules - JRC 6.5.20
	resultTP := originalTP 
	
	var matched : boolean
	matchedAtLeastOnce := false

	if rule.prePattern.nparts > 0 then
	    const oldTreeCount := tree.treeCount
	    const oldKidCount := tree.kidCount

	    processParts (rule.name, rule.prePattern, ruleEnvironment, matched)
	    
	    if not matched then
		if tree.allocationStrategy = simple and not ruleEnvironment.hasExported then
		    % recover any space we may have used in the post pattern
		    tree.setTreeCount (oldTreeCount)
		    tree.setKidCount (oldKidCount)
		end if
		return
	    end if
	end if
	
	% Rationale for the order of the following logic is the typical frequency
	% profile of the cases in production use at Legasys.  Here is a sample:
	
	% kind of treeTP, per cycle :
	% empty		 2473860	29.4%
	% choose	 1522578	18.1%
	% repeat	 1512659	18.0%
	% order		 1017587	12.1%
	% literal	 1014848	12.1%
	% id		  762896	 9.1%
	% stringlit	   74698	 0.9%
	% number	   15054	 0.2%
	% charlit	   12667	 0.2%

	var treeTP := resultTP
	var patternTP := rule.patternTP
	var st := searchTop
	var parentKP := nilKid
	const searchBase := searchTop
		
	if tree.trees (patternTP).kind = kindT.subsequentUse then
	    % use concrete pattern
	    patternTP := valueTP (ruleEnvironment.valuesBase + tree.trees (patternTP).count)
	end if
	    
	
	loop
	    assert tree.trees (patternTP).kidsKP >= 0 and tree.trees (patternTP).kidsKP <= maxKids 
	    assert tree.trees (treeTP).kidsKP >= 0 and tree.trees (treeTP).kidsKP <= maxKids 

	    #if EXECUTABLE_ASSERTS then
	        Assert (tree.trees (patternTP).kidsKP >= 0 and tree.trees (patternTP).kidsKP <= maxKids , "applyRuleOnePass 2")
	        Assert (tree.trees (treeTP).kidsKP >= 0 and tree.trees (treeTP).kidsKP <= maxKids , "applyRuleOnePass 3")
	    #end if

	    #if PROFILER then
		searchcycles += 1
	    #end if
	    
	    matched := (tree.trees (treeTP).kind = tree.trees (patternTP).kind or tree.trees (patternTP).kind = kindT.firstTime)
	    	    and matchTreeToPattern (patternTP, treeTP, ruleEnvironment)
	    
	    if matched then
		#if DEBUGGER then
		    if debugger.isbreakpoint (rule.name) then
			debugger.breakpoint (DBkind.matchEntry, rule.name, 0, treeTP, ruleEnvironment, false)
		    end if
		#end if

		if rule.postPattern.nparts > 0 then
		    const oldTreeCount := tree.treeCount
		    const oldKidCount := tree.kidCount

		    searchTop := st
		    processParts (rule.name, rule.postPattern, ruleEnvironment, matched)

		    if not matched then
			#if DEBUGGER then
			    const nprelocals := localsListT@(ruleEnvironment.localsListAddr).nprelocals
			    const nlocals := localsListT@(ruleEnvironment.localsListAddr).nlocals
			    for l : nprelocals + 1 .. nlocals
				valueTP (ruleEnvironment.valuesBase + l) := nilTree
			    end for
			#end if
	
			if tree.allocationStrategy = simple and not ruleEnvironment.hasExported then
			    % recover any space we may have used in the post pattern
			    tree.setTreeCount (oldTreeCount)
			    tree.setKidCount (oldKidCount)
			end if
		    end if
		end if
	
		if matched then
		    matchedAtLeastOnce := true
		    
		    searchTop := st

		    % this might be a visitor-only match $ rule, so there may not be a replacement
		    if rule.replacementTP not= nilTree then

		        if parentKP = nilKid then
			    makeReplacement (rule.replacementTP, resultTP, ruleEnvironment)
			    treeTP := resultTP
			    % this will become the new scope when we are done -
			    % so make sure that the garbage collector knows about it
			    ruleEnvironment.newscopeTP := resultTP
		        else
			    var resultKidTP := tree.kids (parentKP)
			    makeReplacement (rule.replacementTP, resultKidTP, ruleEnvironment)
			    tree.setKidTree (parentKP, resultKidTP)
			    treeTP := resultKidTP
		        end if
		    end if
	    
		    #if DEBUGGER then
			if debugger.isbreakpoint (rule.name) then
			    debugger.breakpoint (DBkind.matchExit, rule.name, 0, treeTP, ruleEnvironment, true)
			end if
		    #end if
		end if
	    end if	    

	    if tree.trees (treeTP).kind >= firstLeafKind 
	    	    or tree.trees (treeTP).name = rule.skipName then
	    	% A terminal -
		% Pop any completed sequences ...
		loop
		    if st = searchBase then
		        searchTop := searchBase
			return
		    end if
		    exit when searchStack (st).kidsKP < searchStack (st).endKP
		    st -= 1
		end loop
		% ... and move on to the next subtree in the sequence
		assert st > searchBase and searchStack (st).kidsKP < searchStack (st).endKP
		#if EXECUTABLE_ASSERTS then
		    Assert (st > searchBase and searchStack (st).kidsKP < searchStack (st).endKP, "applyRuleOnePass 5")
		#end if
		searchStack (st).kidsKP += 1
		parentKP := searchStack (st).kidsKP
		treeTP := tree.kids (parentKP)

	    elsif tree.trees (treeTP).kind = kindT.choose then
		% One child - just go down to it (no need to come back)
		parentKP := tree.trees (treeTP).kidsKP
		treeTP := tree.kids (parentKP)
    
	    else
		% Push a new sequence of subtrees to check
		assert tree.trees (treeTP).kind = kindT.order or tree.trees (treeTP).kind = kindT.repeat or tree.trees (treeTP).kind = kindT.list
		#if EXECUTABLE_ASSERTS then
		    Assert (tree.trees (treeTP).kind = kindT.order or tree.trees (treeTP).kind = kindT.repeat or tree.trees (treeTP).kind = kindT.list, "applyRuleOnePass 6")
		#end if

		if st >= maxSearchDepth then
		    % this is impossible, so the replacement must match the pattern!
		    termination_error (applyingRuleName)
		end if

		st += 1
		searchStack (st).kidsKP := tree.trees (treeTP).kidsKP
		searchStack (st).endKP := searchStack (st).kidsKP + tree.trees (treeTP).count - 1
		parentKP := tree.trees (treeTP).kidsKP
		treeTP := tree.kids (parentKP)
	    end if
	    
	end loop

    end applyRuleOnePass


    include "xform-predef.i"


#if TIMING then
    procedure put_time (start_time, end_time : int)
	const milliseconds := ((end_time - start_time) * 1000) div clocksPerSecond
	const seconds := milliseconds div 1000
	var thousandths : string := intstr (1000000000 + milliseconds, 10)
	thousandths := thousandths (8 .. *)
	put:0, ", ", seconds, ".", thousandths, " seconds"
    end put_time
#end if

#if PROFILER or TIMING then
    external function clock : nat
#end if

    body procedure applyRule 
	    % (ruleIndex : int,
	    % ruleEnvironment : ruleEnvironmentT,
	    % originalTP : treePT,
	    % var resultTP : treePT, 
	    % var matched : boolean)

	% Stack use limitation - to avoid crashes
	var dummy : int
	if stackBase - addr (dummy) > maxStackUse then 
	    quit : stackLimitReached
	end if
	
	bind rule to rule.rules (ruleIndex)

	callingRuleName := applyingRuleName
	applyingRuleName := rule.name
	
	assert ruleEnvironment.depth = callDepth
	#if EXECUTABLE_ASSERTS then
	    Assert (ruleEnvironment.depth = callDepth, "applyRule 1")
	#end if

	#if DEBUGGER then
	    bind ruleLocals to localsListT@(ruleEnvironment.localsListAddr)
	    for l : ruleLocals.nformals + 1 .. ruleLocals.nlocals
		valueTP (ruleEnvironment.valuesBase + l) := nilTree
	    end for

	    if debugger.isbreakpoint (rule.name) then
		debugger.breakpoint (DBkind.ruleEntry, 
		    rule.name, 0, originalTP, ruleEnvironment, false)
	    end if
	#end if

	const oldTreeCount := tree.treeCount
	const oldKidCount := tree.kidCount
	
	ruleEnvironment.hasExported := false
	
	% #if DEBUGGER then
	#if TIMING then
	    var start_time, end_time : nat := 0
	#end if

	if options.option (rule_print_p) then
	    put:0, "" : callDepth-1, "Entering rule ", string@(ident.idents (rule.name))
	    #if TIMING then
		start_time := clock
	    #end if
	end if
	% #end if

	#if PROFILER then
	    bind var ruleStats to ruleStatistics (ruleIndex)
	    var oldStats : ruleStatisticsT
	    oldStats.searchcycles := ruleStats.searchcycles 
	    oldStats.matchcycles := ruleStats.matchcycles 
	    oldStats.time := ruleStats.time
	    oldStats.trees := ruleStats.trees
	    oldStats.kids := ruleStats.kids
	    var startStats : ruleStatisticsT
	    startStats.searchcycles := searchcycles
	    startStats.matchcycles := matchcycles
	    startStats.time := clock
	    startStats.trees := tree.treeCount
	    startStats.kids := tree.kidCount
	#end if
	
	case rule.kind of
	    label ruleKind.normalRule :
		applyRuleWhileMatch (rule, ruleEnvironment, originalTP, resultTP, matched)
	    label ruleKind.functionRule : 
		applyRuleOnceOnly (rule, ruleEnvironment, originalTP, resultTP, matched)
	    label ruleKind.onepassRule : 
		applyRuleOnePass (rule, ruleEnvironment, originalTP, resultTP, matched)
	    label ruleKind.predefinedFunction :
		predefs.applyPredefinedFunction (ruleIndex, ruleEnvironment, originalTP, resultTP, matched)
	end case

	#if PROFILER then
	    ruleStats.calls += 1
	    if matched then
		ruleStats.matches += 1
	    end if
	    ruleStats.searchcycles := oldStats.searchcycles + (searchcycles - startStats.searchcycles)
	    ruleStats.matchcycles := oldStats.matchcycles + (matchcycles - startStats.matchcycles)
	    ruleStats.time := oldStats.time + (clock - startStats.time)
	    ruleStats.trees := oldStats.trees + (tree.treeCount - startStats.trees)
	    ruleStats.kids := oldStats.kids + (tree.kidCount - startStats.kids)
	#end if
	
	% #if DEBUGGER then
	if options.option (rule_print_p) then
	    put:0, "" : callDepth-1, "Exiting rule ", string@(ident.idents (rule.name)) ..
	    if matched then
		put:0, " (succeeded) " ..
	    else
		put:0, " (failed) " ..
	    end if
	    #if not DEBUGGER then
	        if options.option (verbose_p) then
	    #end if
	            put:0, "- ", tree.treeCount - oldTreeCount, " trees, ", 
		        tree.kidCount - oldKidCount, " kids" ..
	    #if not DEBUGGER then
	        end if
	    #end if
	    #if TIMING then
		end_time := clock
		put_time (start_time, end_time)
	    #else
		put:0, ""
	    #end if
	end if
	% #end if

	#if DEBUGGER then
	    if debugger.isbreakpoint (rule.name) then
		debugger.breakpoint (DBkind.ruleExit, 
		    rule.name, 0, resultTP, ruleEnvironment, matched)
	    end if
	#end if
	
	assert ruleEnvironment.depth = callDepth
	#if EXECUTABLE_ASSERTS then
	    Assert (ruleEnvironment.depth = callDepth, "applyRule 2")
	#end if

    end applyRule


    procedure recursion_error (ruleName : tokenT)
	error ("rule/function '" + string@(ident.idents (ruleName)) + "'",
	    "Transform recursion limit exceeded (Probable cause: infinite recursion, small size or stack limit)",
	     LIMIT_FATAL, 510)
    end recursion_error


    procedure interrupt_error (ruleName : tokenT)
	error ("rule/function '" + string@(ident.idents (ruleName)) + "'",
	    "Transform interrupted by user", FATAL, 511)
    end interrupt_error


    procedure fatal_error (ruleName : tokenT)
	error ("rule/function '" + string@(ident.idents (ruleName)) + "'",
	    "Fatal TXL error (signal)", DEFERRED, 512)
    end fatal_error


    procedure garbage_warning 
	error ("", intstr (nGarbageRecoveries, 0) + " garbage recoveries were required"
	    + " (larger size recommended for improved performance)", WARNING, 513)
    end garbage_warning 


    function install_as_string (id : string) : tokenT
	result ident.install ("\"" + id + "\"", kindT.stringlit)
    end install_as_string


    body procedure applyMainRule 
	% (originalInputParseTreeTP : treePT,
	% var transformedInputParseTreeTP : treePT)

	handler (code)
	    if code = outOfKids or code = outOfTrees then
		quit
	    elsif code = stackLimitReached then
		recursion_error (applyingRuleName)
	    elsif code = 2 then
		interrupt_error (applyingRuleName)
	    elsif code not= 1 and applyingRuleName not= quit_T then
		fatal_error (applyingRuleName)
	    end if
	    quit > : code
	end handler

        if not rule.rules (mainRule).defined then
	    % Parsing only - JRC 10.7
	    transformedInputParseTreeTP := originalInputParseTreeTP 
	    return
	end if

	% Remember treespace used by the compiled TXL program, for garbage collection
	lastCompileTree := tree.treeCount
	lastCompileKid := tree.kidCount
	
	#if PROFILER then
	    for r : 1 .. rule.nRules
		bind var ruleStats to ruleStatistics (r)
		ruleStats.calls := 0
		ruleStats.matches := 0
		ruleStats.searchcycles := 0
		ruleStats.matchcycles := 0
		ruleStats.time := 0
		ruleStats.trees := 0
		ruleStats.kids := 0
	    end for
	    searchcycles := 0
	    matchcycles := 0
	#end if

	% initialize the rule call stack
	bind var globalEnvironment to callEnvironment (0),
	     var mainEnvironment to callEnvironment (1)

	callDepth := 1

	% initialize the global environment 
	globalEnvironment.depth := 0

	% new value binding protocol
	globalEnvironment.valuesBase := valueCount
	valueCount += rule.rules (globalR).localVars.nlocals

	globalEnvironment.name := rule.rules (globalR).name
	globalEnvironment.localsListAddr := addr (rule.rules (globalR).localVars)
	globalEnvironment.scopeTP := nilTree
	globalEnvironment.resultTP := nilTree
	globalEnvironment.newscopeTP := nilTree
	
	% initialize the deprecated predefined global variables
	
	% initialize the (deprecated) global variable argv
	const repeat_0_stringlit_T := ident.install ("repeat_0_stringlit", kindT.id)
	const repeat_0_stringlit_index := symbol.lookupSymbol (repeat_0_stringlit_T)
	assert repeat_0_stringlit_index not= symbol.UNDEFINED

	% its tokens are the program arguments as strings
	lastTokenIndex := 0

	for pa : 1 .. options.nProgArgs
	    lastTokenIndex += 1
	    inputTokens (lastTokenIndex).token := ident.install (options.progArgs (pa), kindT.stringlit)
	    inputTokens (lastTokenIndex).rawtoken := inputTokens (lastTokenIndex).token
	    inputTokens (lastTokenIndex).kind := kindT.stringlit  
	end for

	lastTokenIndex += 1
	inputTokens (lastTokenIndex).token := empty_T  
	inputTokens (lastTokenIndex).rawtoken := empty_T  
	inputTokens (lastTokenIndex).kind := kindT.empty  

	% parse them as a sequence of stringlits
	var progArgsTP := nilTree
	parser.initializeParse ("command line arguments", false, false, false, 0, type (parser.parseVarOrExpProc, 0))
	parser.parse (symbol.symbols (repeat_0_stringlit_index), progArgsTP)

	% make sure we got a parse
	assert progArgsTP not= nilTree 

	% initialize the new (version 10) predefined global variables

	% initialize the global variable TXLargs
	var TXLargsTP : treePT
	tree.copyTree (progArgsTP, TXLargsTP)
	valueTP (globalEnvironment.valuesBase + TXLargsG) := TXLargsTP

	% initialize the global variable TXLprogram
	const TXLprogramT := install_as_string (options.txlSourceFileName)
	const TXLprogramTP := tree.newTreeInit (kindT.stringlit, TXLprogramT, TXLprogramT, 0, nilKid)
	valueTP (globalEnvironment.valuesBase + TXLprogramG) := TXLprogramTP

	% initialize the global variable TXLinput
	const TXLinputT := install_as_string (options.inputSourceFileName)
	const TXLinputTP := tree.newTreeInit (kindT.stringlit, TXLinputT, TXLinputT, 0, nilKid)
	valueTP (globalEnvironment.valuesBase + TXLinputG) := TXLinputTP

	% initialize the global variable TXLexitcode
	const TXLexitcodeT := ident.install ("0", kindT.number)
	const TXLexitcodeTP := tree.newTreeInit (kindT.number, TXLexitcodeT, TXLexitcodeT, 0, nilKid)
	valueTP (globalEnvironment.valuesBase + TXLexitcodeG) := TXLexitcodeTP

	% nil out the other global variables, if any
	for glob : numGlobalVars + 1 ..  rule.rules (globalR).localVars.nlocals
	    valueTP (globalEnvironment.valuesBase + glob) := nilTree
	end for


	mainEnvironment.depth := 1

	% new value binding protocol
	mainEnvironment.valuesBase := valueCount
	valueCount += rule.rules (mainRule).localVars.nlocals

	% remember name of the main rule (for debugging)
	mainEnvironment.name := rule.rules (mainRule).name
	
	% attach to the local symbol table for the mainRule
	mainEnvironment.localsListAddr := addr (rule.rules (mainRule).localVars)

	% remember the original scope tree
	mainEnvironment.scopeTP := originalInputParseTreeTP

	% and the partially resolved replacement
	mainEnvironment.resultTP := nilTree
		
	% and the partially resolved new scope
	mainEnvironment.newscopeTP := nilTree

	% nil out the unbound ruleLocals
	for loc : 1 ..  rule.rules (mainRule).localVars.nlocals
	    valueTP (mainEnvironment.valuesBase + loc) := nilTree
	end for

	var dontCareAboutSuccess : boolean

	#if DEBUGGER then
	    % new protocol - default to on!
	    debugger.breakpoint (DBkind.startup, 
		rule.rules (mainRule).name, 0, originalInputParseTreeTP, mainEnvironment, false)
	#end if

	applyRule (mainRule, mainEnvironment,
	    originalInputParseTreeTP, transformedInputParseTreeTP, dontCareAboutSuccess)
	    
	exitcode := round (strreal (string@(ident.idents (tree.trees (valueTP (globalEnvironment.valuesBase + TXLexitcodeG)).name))))
	
	#if DEBUGGER then
	    debugger.breakpoint (DBkind.shutdown, 
		rule.rules (mainRule).name, 0, transformedInputParseTreeTP, mainEnvironment, false)
	#end if

	if options.option (verbose_p) and copies + noncopies > 0 then
	    put : 0, "Forced to copy ", copies, " local vars (", (copies*100) div (copies + noncopies), "%)"
	end if
	
	if nGarbageRecoveries > 4 then
	    garbage_warning
	end if
	
	#if PROFILER then
	    var profout : int
	    open : profout, "txl.rprofout", put
	    if profout not= 0 then
		put : profout, "name calls matches searchcycles matchcycles time trees kids"
		for r : 1 .. rule.nRules
		    bind var ruleStats to ruleStatistics (r)
		    put : profout, string@(ident.idents (rule.rules (r).name)), " ",
			ruleStats.calls, " ", ruleStats.matches, " ", ruleStats.searchcycles, " ", 
			ruleStats.matchcycles, " ", ruleStats.time, " ", ruleStats.trees, " ", ruleStats.kids
		end for
		close : profout
	    else
		error ("", "Unable to create TXL profile file 'txl.rprofout'", FATAL, 514)
	    end if
	#end if

    end applyMainRule

end transformer
