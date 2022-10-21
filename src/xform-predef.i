% OpenTxl Version 11 predefined built-in functions
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

% TXL predefined built-in functions

% Modification Log

% v11.0	Initial revision, revised from FreeTXL 10.8b (c) 1988-2022 Queen's University at Kingston

module predefs
    import 
	var tree, var tree_ops,
	charset, var ident, var scanner, var symbol, var parser, var options, var unparser,
	kindType,
	failTokenIndex,
	callingRuleName, applyingRuleName,
	valueTP,
	error, predefinedParseError, externalType

    export 
	applyPredefinedFunction


    % Line-oriented Fget/Fput file to stream mappings
    const maxFgetputFiles := 10
    var fgetputFiles : array 1 .. maxFgetputFiles of
	record
	    name : tokenT
	    stream : int
	end record
    for f : 1 .. maxFgetputFiles
	fgetputFiles (f).name := NOT_FOUND
	fgetputFiles (f).stream := 0
    end for


    % Garbage collection utilities
    const nineTenthsMaxTrees := 9 * (maxTrees div 10)
    const nineTenthsMaxKids := 9 * (maxKids div 10)
    
    procedure checkSufficientParseSpace
	% We cannot recover from running out of space in a scan or parse,
	% so we try to be conservative by predicting the need for
	% a garbage collection in advance.
	if tree.treeCount > nineTenthsMaxTrees or tree.kidCount > nineTenthsMaxKids then
	    % Force a garbage recovery
	    if options.option (verbose_p) then
		if tree.treeCount > nineTenthsMaxTrees then
		    error ("", outOfTreesMessage, DEFERRED, 521)
		else
		    error ("", outOfKidsMessage, DEFERRED, 522)
		end if
	    end if
	    quit : outOfTrees
	end if
    end checkSufficientParseSpace


    % Long string operations - length must match sourceText in scan.ch
    type longstring : char (maxLineLength + maxTuringStringLength + 1)
    var LS1, LS2, LS3 : longstring

    procedure lconcat (var ls1 : string, ls2 : string)
	const length1 := length (ls1)
	if length1 + length (ls2) > maxLineLength then
	    var j := length1
	    for i : 1 .. maxLineLength - length1
		type (longstring, ls1) (j) := type (longstring, ls2) (i)
		j += 1
	    end for
	else
	    type (string, type (longstring, ls1) (length1 + 1)) := ls2
	end if
    end lconcat

    procedure lsubstr (var ls1 : string, ls2 : string, n1, n2 : int)
	pre n1 >= 1 and n1 <= length (ls2) + 1
	    and n2 >= 0 and n2 <= length (ls2)
	    and n2 >= n1 - 1
	ls1 := type (string, type (longstring, ls2) (n1))
	type (longstring, ls1) (n2 - n1 + 2) := '\0'
    end lsubstr

    procedure ltruncate (var ls : string, n : int)
	pre n <= maxLineLength
	type (longstring, ls) (n+1) := '\0'
    end ltruncate

    procedure ltolower (var ls : string)
	for i : 1 .. length (ls)
	    type (longstring, ls) (i) := charset.lowercase (type (longstring, ls) (i))
	end for
    end ltolower

    procedure ltoupper (var ls : string)
	for i : 1 .. length (ls)
	    type (longstring, ls) (i) := charset.uppercase (type (longstring, ls) (i))
	end for
    end ltoupper


    % Routines to evaluate and de-evaluate token text

    procedure evaluateString (tokentext : string, kind : kindT, var text : string)
	pre kind > firstLeafKind and kind <= lastLeafKind
	
	% Always long enough when called, even if tokentext is a longstring
	text := tokentext
	
	if kind = kindT.stringlit or kind = kindT.charlit then
	    % Strip off quotes
	    assert length (tokentext) >= 2
	    lsubstr (text, tokentext, 2, length (tokentext) - 1)
	    
	    % Unescape embedded escaped quotes if necessary
	    if charset.stringlitEscapeChar not= ' ' then
		var escapeChar, quoteChar : char
		if kind = kindT.stringlit then
		    escapeChar := charset.stringlitEscapeChar
		    quoteChar := '"'
		else
		    escapeChar := charset.charlitEscapeChar
		    quoteChar := '\''
		end if
		
		var ix := 1
		var len := length (text)
		loop
		    exit when ix > len
		    if type (longstring, text) (ix) = escapeChar and ix < len and type (longstring, text) (ix+1) = quoteChar then
			for i : ix + 1 .. len + 1	% (sic!)
			    type (longstring, text) (i-1) := type (longstring, text) (i)
			end for
			len -= 1
		    end if
		    ix += 1
		end loop
	    end if
	end if
    end evaluateString


    procedure unevaluateString (kind : kindT, var text : string)
	if kind = kindT.stringlit or kind = kindT.charlit then
	    assert length (text) <= maxLineLength - 2
	
	    var escapeChar, quoteChar : char
	    if kind = kindT.stringlit then
		escapeChar := charset.stringlitEscapeChar
		quoteChar := '"'
	    else
		escapeChar := charset.charlitEscapeChar
		quoteChar := '\''
	    end if

	    % Escape embedded quotes if necessary
	    if charset.stringlitEscapeChar not= ' ' then
		var ix := 1
		var len := length (text)
		loop
		    exit when len = maxLineLength - 2
		    exit when ix > len
		    if type (longstring, text) (ix) = quoteChar then
			for decreasing i : len + 1 .. ix	% (sic!)
			    type (longstring, text) (i+1) := type (longstring, text) (i)
			end for
			type (longstring, text) (ix) := escapeChar
			len += 1
			ix += 1
		    end if
		    ix += 1
		end loop
	    end if
		    
	    % Add surrounding quotes
	    const len := length (text)
	    for decreasing i : len + 1 .. 1	% (sic!)
		type (longstring, text) (i+1) := type (longstring, text) (i)
	    end for
	    type (longstring, text) (1) := quoteChar
	    type (longstring, text) (len+2) := quoteChar
	    type (longstring, text) (len+3) := '\0'
	end if
    end unevaluateString


    % Predefined function error procedure 

    procedure predefinedError (message : string, rulename, callername : tokenT)
	error ("predefined function [" + string@(ident.idents(rulename)) + "], called from ["
	    + string@(ident.idents(callername)) + "]", message, FATAL, 592) 
    end predefinedError


    % Utility routines to optimize stack use

    procedure convertHexToString (hex : real, var s : string)
	s := intstr (round (hex), 0, 16)
    end convertHexToString

    procedure convertRealToString (r : real, var s : string)
	s := realstr (r, 0)
    end convertRealToString


    procedure applyPredefinedFunction
	    (ruleIndex : int, var ruleEnvironment : ruleEnvironmentT,
	     originalTP : treePT, var resultTP : treePT, var matched : boolean)

	resultTP := originalTP

	case ruleIndex of

	    label spliceR : 
		% Generic repeat splice or append 
		% Repeat1 [. Repeat2]  or  Repeat1 [. Element2] 

		% can't fail since types are ok
		matched := true 

		var scopeTP := resultTP 
		var paramTP := valueTP (ruleEnvironment.valuesBase + 1) 

		% get the element type of the repeat 
		assert string@(ident.idents (tree.trees (scopeTP).name)) (1..9) = "repeat_0_" 
		bind X to string@(ident.idents (tree.trees (scopeTP).name) + 9)	% substr (10..*) 
		const XT : tokenT := ident.lookup (X)
		const repeatXT : tokenT := tree.trees (scopeTP).name 

		% build the tail of the spliced repeat 
		if tree.trees (paramTP).name = repeatXT then
		    % repeat_0_X
		    if tree.trees (tree.kid1TP (paramTP)).kind = kindT.empty then 
			% splicing on an empty repeat - nothing to do!   
			return 
		    end if
		    
		    % a nonempty repeat - get the repeat_1_X node 
		    % must copy since this ruleEnvironment.valueTP becomes part of the result
		    % unless the calling rule has only one reference to it, 
		    % in which case there is no problem 
		    if ruleEnvironment.parentrefs not= 1 then
			var paramCopyTP : treePT
			tree.copyTree (paramTP, paramCopyTP)
			paramTP := paramCopyTP
		    end if

		else
		    % X - need to make into a repeat_0_X
		    assert tree.trees (paramTP).name = XT or kindType (ord (tree.trees (paramTP).kind)) = XT 
		    
		    % must copy since this ruleEnvironment.valueTP becomes part of the result
		    % unless the calling rule has only one reference to it, in which
		    % case there is no problem 
		    var paramCopyTP := paramTP
		    if ruleEnvironment.parentrefs > 1 then
			tree.copyTree (paramTP, paramCopyTP)
		    end if

		    % paramTP must be a new repeat_0_X
		    paramTP := tree.newTreeInit (kindT.repeat, repeatXT, repeatXT, 0, nilKid) 
		    
		    % every repeat is ended with a doubly empty repeat
		    var endTP := tree.newTreeInit (kindT.repeat, repeatXT, repeatXT, 0, nilKid) 
		    tree.makeTwoKids (endTP, emptyTP, emptyTP)
		    
		    % now construct the whole thing
		    tree.makeTwoKids (paramTP, paramCopyTP, endTP) 
		end if 

		% hopefully it is a repeat_0_X tree we are attaching 
		assert tree.trees (paramTP).name = repeatXT 

		% now attach the tail to the scope repeat 
		assert tree.trees (scopeTP).name = repeatXT 

		% attaching to a repeat_0_X - it may be empty! 
		if tree.trees (tree.kid1TP (scopeTP)).kind = kindT.empty then
		    % empty repeat - replace it with the nonempty tail 
		    tree.setKids (scopeTP, tree.trees (paramTP).kidsKP)
		    return 
		end if 

		% we are now attaching to a nonempty repeat 
		assert tree.trees (scopeTP).name = repeatXT
		
		% find last "repeat_0_" tree 
		loop 
		    exit when tree.trees (tree.kid2TP (scopeTP)).kind = kindT.empty 
		    % go on to next "repeat_0_" tree 
		    scopeTP := tree.kid2TP (scopeTP) 
		end loop

		% now we have an empty repeat_0_X to attach to 
		assert tree.trees (scopeTP).name = repeatXT

		% and attach the tail to it 
		tree.setKids (scopeTP, tree.trees (paramTP).kidsKP)

	    label listSpliceR : 
		% Generic list splice or append 
		% List1 [. List2]  or  List1 [. Element2] 

		% can't fail since types are ok
		matched := true 

		var scopeTP := resultTP 
		var paramTP := valueTP (ruleEnvironment.valuesBase + 1) 

		% get the element type of the list 
		assert string@(ident.idents (tree.trees (scopeTP).name)) (1..7) = "list_0_" 
		bind X to string@(ident.idents (tree.trees (scopeTP).name) + 7)	% substr (8..*) 
		const XT : tokenT := ident.lookup (X)
		const listXT : tokenT := tree.trees (scopeTP).name

		% build the tail of the spliced list 
		if tree.trees (paramTP).name = listXT then
		    % list_0_X
		    if tree.trees (tree.kid1TP (paramTP)).kind = kindT.empty then 
			% splicing on an empty list - nothing to do!                 
			return 
		    end if
		    
		    % a nonempty list - get the list_1_X node 
		    % must copy since this ruleEnvironment.valueTP becomes part of the result
		    % unless the calling rule has only one reference to it, 
		    % in which case there is no problem 
		    if ruleEnvironment.parentrefs not= 1 then
			var paramCopyTP : treePT
			tree.copyTree (paramTP, paramCopyTP)
			paramTP := paramCopyTP
		    end if

		else
		    % X - need to make into a list_0_X
		    assert tree.trees (paramTP).name = XT or kindType (ord (tree.trees (paramTP).kind)) = XT 
		    
		    % must copy since this ruleEnvironment.valueTP becomes part of the result
		    % unless the calling rule has only one reference to it, in which
		    % case there is no problem 
		    var paramCopyTP := paramTP
		    if ruleEnvironment.parentrefs > 1 then
			tree.copyTree (paramTP, paramCopyTP)
		    end if

		    % paramTP must be a new list_0_X
		    paramTP := tree.newTreeInit (kindT.list, listXT, listXT, 0, nilKid) 
		    
		    % every list is ended with a doubly empty list
		    var endTP := tree.newTreeInit (kindT.list, listXT, listXT, 0, nilKid)
		    tree.makeTwoKids (endTP, emptyTP, emptyTP)
		    
		    % now construct the whole thing
		    tree.makeTwoKids (paramTP, paramCopyTP, endTP) 
		end if 

		% hopefully it is a list_0_X tree we are attaching 
		assert tree.trees (paramTP).name = listXT 

		% now attach the tail to the scope list 
		assert tree.trees (scopeTP).name = listXT 

		% attaching to a list_0_X - it may be empty! 
		if tree.trees (tree.kid1TP (scopeTP)).kind = kindT.empty then
		    % empty list - replace it with the nonempty tail 
		    tree.setKids (scopeTP, tree.trees (paramTP).kidsKP)
		    return 
		end if 

		% we are now attaching to a nonempty list 
		assert tree.trees (scopeTP).name = listXT
		
		% find last "list_0_" tree 
		loop 
		    exit when tree.trees (tree.kid2TP (scopeTP)).kind = kindT.empty 
		    % go on to next "list_0_" tree 
		    scopeTP := tree.kid2TP (scopeTP) 
		end loop

		% now we have an empty list_0_X to attach to 
		assert tree.trees (scopeTP).name = listXT

		% and attach the tail to it 
		tree.setKids (scopeTP, tree.trees (paramTP).kidsKP)

	    label addR, subtractR, multiplyR, divideR, divR, remR :
		% N1 [+ N2] 	N1 := N1 + N2
		% N1 [- N2] 	N1 := N1 - N2
		% N1 [* N2] 	N1 := N1 * N2
		% N1 [/ N2] 	N1 := N1 / N2
		% N1 [div N2] 	N1 := N1 div N2
		% N1 [rem N2] 	N1 := N1 rem N2

		% can't fail since types are ok
		matched := true

		var kind := kindT.undefined

		case tree.trees (resultTP).kind of
		    label kindT.number, kindT.floatnumber, kindT.decimalnumber, 
			    kindT.integernumber:
			kind := kindT.number
		    label kindT.stringlit :
			kind := kindT.stringlit
		    label kindT.charlit:
			kind := kindT.charlit
		    label kindT.id, kindT.upperlowerid, kindT.upperid, 
			    kindT.lowerupperid, kindT.lowerid :
			kind := kindT.id
		    label kindT.comment :
			kind := kindT.comment
		    label:
			kind := tree.trees (resultTP).kind
		end case

		const oldresultTP := resultTP
		resultTP := tree.newTreeClone (oldresultTP)

		if kind = kindT.number then
		    var N1 := strreal (string@(ident.idents (tree.trees (resultTP).name)))
		    const N2 := strreal (string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name)))

		    case ruleIndex of
			label addR :
			    N1 += N2
			label subtractR :
			    N1 -= N2
			label multiplyR :
			    N1 *= N2
			label divideR :
			    if N2 not= 0 then
				N1 /= N2
			    else
				predefinedError ("Division by zero", applyingRuleName, callingRuleName)
			    end if
			label divR :
			    var I1 : int := round (N1)
			    const I2 : int := round (N2)
			    if I2 not= 0 then
				I1 := I1 div I2
			    else
				predefinedError ("Division by zero", applyingRuleName, callingRuleName)
			    end if
			    N1 := I1
			label remR :
			    var I1 : int := round (N1)
			    const I2 : int := round (N2)
			    if I2 not= 0 then
				I1 := I1 mod I2
			    else
				predefinedError ("Division by zero", applyingRuleName, callingRuleName)
			    end if
			    N1 := I1
		    end case

		    bind var resultValue to type (string, LS1)

		    bind ns to longstring@(ident.idents (tree.trees (resultTP).rawname))
		    if ns (1) = '0' and (ns (2) = 'x' or ns (2) = 'X') then
			resultValue := type (string, ns) (1..2) 
			bind var resultValue3 to type (string, LS1 (3))
			convertHexToString (N1, type (string, resultValue3))
		    else
			convertRealToString (N1, resultValue)
		    end if

		    var resultT := ident.install (resultValue, kindT.number) 
		    tree.setName (resultTP, resultT) 
		    tree.setRawName (resultTP, resultT) 

		else
		    assert kind > firstLeafKind and kind <= lastLeafKind
		    
		    % Concatenate the raw names in case they are different
		    bind var S1 to type (string, LS1), var S2 to type (string, LS2)
		    evaluateString (string@(ident.idents (tree.trees (resultTP).rawname)), tree.trees (resultTP).kind, S1)
		    evaluateString (string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).rawname)), 
			tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind, S2)
		    
		    assert ruleIndex = addR 
		    lconcat (S1, S2)
		    
		    unevaluateString (kind, S1)
		    
		    var resultT := ident.install (S1, kind)
		    tree.setRawName (resultTP, resultT)

		    % If -case is on, normalize the internal name, otherwise it is the same
		    if options.option (case_p) and kind not= kindT.stringlit and kind not= kindT.charlit then
			ltolower (S1)
		        resultT := ident.install (S1, kind)
		        tree.setName (resultTP, resultT)
		    else
			tree.setName (resultTP, resultT)
		    end if
		end if

	    label substringR :
		% can't fail since types are right
		matched := true

		% Substring the raw name in case it is different
		bind var S1 to type (string, LS1), var S2 to type (string, LS2)
		evaluateString (string@(ident.idents (tree.trees (resultTP).rawname)), tree.trees (resultTP).kind, S1)

		var N1 := round (strreal (string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name))))
		if N1 > length (S1) + 1 then
		    N1 := length (S1) + 1
		elsif N1 < 1 then
		    N1 := 1
		end if

		var N2 := round (strreal (string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 2)).name))))
		if N2 > length (S1) then
		    N2 := length (S1)
		elsif N2 < N1 - 1 then
		    N2 := N1 - 1
		end if

		const oldresultTP := resultTP
		resultTP := tree.newTreeClone (oldresultTP)
		
		lsubstr (S2, S1, N1, N2)
		
		unevaluateString (tree.trees (resultTP).kind, S2)
		
		var resultT := ident.install (S2, tree.trees (resultTP).kind)
		tree.setRawName (resultTP, resultT)

		% If -case is on, normalize the internal name, otherwise it is the same
		if options.option (case_p) and tree.trees (resultTP).kind not= kindT.stringlit 
			and tree.trees (resultTP).kind not= kindT.charlit then
		    ltolower (S2)
		    resultT := ident.install (S2, tree.trees (resultTP).kind)
		    tree.setName (resultTP, resultT)
		else
		    tree.setName (resultTP, resultT)
		end if

	    label lengthR :
		% can't fail since types are right
		matched := true

		const oldresultTP := resultTP
		resultTP := tree.newTreeClone (oldresultTP)

		bind var S1 to type (string, LS1)
		evaluateString (string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name)), tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind, S1)
		
		var L := length (S1)
		S1 := intstr (L, 0)
		
		var resultT := ident.install (S1, kindT.number)
		tree.setName (resultTP, resultT)
		tree.setRawName (resultTP, resultT)

	    label equalR, notEqualR :
		% N1 [= N2] 	N1 = N2
		% N1 [~= N2] 	N1 ~= N2
		% (defined as equality on numbers and text tokens, and identity on all other types)

		case tree.trees (resultTP).kind of
		    label kindT.number, kindT.floatnumber, kindT.decimalnumber, 
			    kindT.integernumber:
			const N1 := strreal (string@(ident.idents (tree.trees (resultTP).name)))
			const N2 := strreal (string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name)))
			matched := N1 = N2
		    label:
			if tree.trees (resultTP).kind > firstLeafKind and tree.trees (resultTP).kind <= lastLeafKind then
			    bind var S1 to type (string, LS1), var S2 to type (string, LS2)
			    evaluateString (string@(ident.idents (tree.trees (resultTP).name)), tree.trees (resultTP).kind, S1)
			    evaluateString (string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name)), 
				tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind, S2)
			    matched := S1 = S2
			else
			    matched := tree.sameTrees (resultTP, valueTP (ruleEnvironment.valuesBase + 1))
			end if
		end case

		if ruleIndex = notEqualR then
		    matched := not matched
		end if

	    label lessR, lessEqualR, greaterR, greaterEqualR :
		% N1 [> N2] 	N1 > N2
		% N1 [< N2] 	N1 < N2
		% N1 [<= N2] 	N1 <= N2
		% N1 [>= N2] 	N1 >= N2
		% (all of above also defined on strings and ids)

		var kind := tree.trees (resultTP).kind

		case tree.trees (resultTP).kind of
		    label kindT.number, kindT.floatnumber, kindT.decimalnumber, kindT.integernumber:
			kind := kindT.number
		    label:
			if tree.trees (resultTP).kind > firstLeafKind and tree.trees (resultTP).kind <= lastLeafKind then
			    kind := kindT.id	% anything not number
			else
			    assert false
			end if
		end case

		if kind = kindT.number then
		    const N1 := strreal (string@(ident.idents (tree.trees (resultTP).name)))
		    const N2 := strreal (string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name)))

		    case ruleIndex of
			label greaterR :
			    matched := N1 > N2
			label greaterEqualR :
			    matched := N1 >= N2
			label lessR :
			    matched := N1 < N2
			label lessEqualR :
			    matched := N1 <= N2
		    end case

		else
		    assert kind > firstLeafKind and kind <= lastLeafKind
		    bind var S1 to type (string, LS1), var S2 to type (string, LS2)
		    evaluateString (string@(ident.idents (tree.trees (resultTP).name)), tree.trees (resultTP).kind, S1)
		    evaluateString (string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name)), 
			tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind, S2)

		    case ruleIndex of
			label greaterR :
			    matched := S1 > S2
			label greaterEqualR :
			    matched := S1 >= S2
			label lessR :
			    matched := S1 < S2
			label lessEqualR :
			    matched := S1 <= S2
		    end case
		end if

	    label extractR :
		% Repeat_X [^ Y]
		% generic extract from any scope 
		% The scope should be something of type [repeat X] for some X.
		% Extracts a sequence of all of the occurences of
		% something of type [X] in the ruleEnvironment.valueTP,
		% and appends it to the scope.

		% can't fail since types are right
		matched := true

		const repeatXT : tokenT := tree.trees (resultTP).name 
		assert string@(ident.idents (repeatXT)) (1..9) = "repeat_0_" 
		bind X to string@(ident.idents (repeatXT) + 9)	% substr (10..*) 
	 	const XT := ident.lookup (X)

		var extractTP : treePT 
		tree.extract (XT, repeatXT, valueTP (ruleEnvironment.valuesBase + 1), 
		    ruleEnvironment.parentrefs not= 1, extractTP)

		% hopefully it is a repeat_0_X tree we are attaching 
		assert tree.trees (extractTP).name = repeatXT 

		% now attach the tail to the scope repeat 
		var scopeTP := resultTP 
		assert tree.trees (scopeTP).name = repeatXT 

		% attaching to a repeat_0_X - it may be empty! 
		if tree.trees (tree.kid1TP (scopeTP)).kind = kindT.empty then
		    % empty repeat - replace it with the nonempty tail 
		    tree.setKids (scopeTP, tree.trees (extractTP).kidsKP)
		    return 
		end if 

		% we are now attaching to a nonempty repeat 
		assert tree.trees (scopeTP).name = repeatXT
		
		% find last "repeat_0_" tree 
		loop 
		    exit when tree.trees (tree.kid2TP (scopeTP)).kind = kindT.empty 
		    % go on to next "repeat_0_" tree 
		    scopeTP := tree.kid2TP (scopeTP) 
		end loop

		% now we have an empty repeat_0_X to attach to 
		assert tree.trees (scopeTP).name = repeatXT

		% and attach the tail to it 
		tree.setKids (scopeTP, tree.trees (extractTP).kidsKP)

	    label substituteR :
		% Scope [$ Old New]
		% generic substitute any type in any scope 

		% can't fail since types are right
		matched := true

		if tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind >= firstLiteralKind then
		    tree.substituteLiteral (valueTP (ruleEnvironment.valuesBase + 1), valueTP (ruleEnvironment.valuesBase + 2), resultTP)
		else
		    tree.substitute (valueTP (ruleEnvironment.valuesBase + 1), valueTP (ruleEnvironment.valuesBase + 2), resultTP)
		end if

	    label newidR :
		% Id [!]
		% make any identifier unique

		% can't fail since types are right
		matched := true

		const oldresultTP := resultTP
		resultTP := tree.newTreeClone (oldresultTP)
		
		bind var symbol to type (longstring, LS1)
		evaluateString (string@(ident.idents (tree.trees (resultTP).name)), kindT.id, type (string, symbol))
		
		assert symbol (1) < '0' or symbol (1) > '9'
		var last := length (type (string, symbol))
		loop
		    exit when symbol (last) < '0' or symbol (last) > '9'
		    last -= 1
		end loop
		ltruncate (type (string, symbol), last)
		
		if last + 6 > maxLineLength then
		    last := maxLineLength - 6
		    ltruncate (type (string, symbol), last)
		end if
		
		for i : 1 .. 999999	% tries up to 999999
		    type (string, symbol (last + 1)) := intstr (i)	% (hup!)
		    exit when ident.lookup (type (string, symbol)) = NOT_FOUND
		end for
		
		var resultT := ident.install (type (string, symbol), kindT.id)
		tree.setName (resultTP, resultT)
		tree.setRawName (resultTP, resultT)

	    label underscoreR :
		% Id [_ Id2]
		% concat ids with _ between

		% can't fail since types are right
		matched := true

		const oldresultTP := resultTP
		resultTP := tree.newTreeClone (oldresultTP)
		
		% Concatenate the raw names in case they are different
		bind oldId to string@(ident.idents (tree.trees (resultTP).rawname)),
		     parmId to string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).rawname))
		bind var newId to type (string, LS1)
		newId := oldId
		
		lconcat (newId, "_")
		lconcat (newId, parmId)
		
		var resultT := ident.install (newId, kindT.id)
		tree.setRawName (resultTP, resultT)

		% If -case is on, normalize the internal name, otherwise it is the same
		if options.option (case_p) then
		    ltolower (newId)
		    resultT := ident.install (newId, kindT.id)
		    tree.setName (resultTP, resultT)
		else
		    tree.setName (resultTP, resultT)
		end if

	    label messageR :
		% Print a message
		% Any1 [message Any2]
		if tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind = kindT.stringlit 
			or tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind = kindT.charlit then
		    bind var param1text to type (string, LS1)
		    evaluateString (string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name)), 
			tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind, param1text)
		    put : 0, param1text
		else
		    unparser.printLeaves (valueTP (ruleEnvironment.valuesBase + 1), 0, true)
		end if

		matched := false
		
	    label printR :
		% Print the leaves of the scope tree
		% Any [print]
		if tree.trees (resultTP).kind = kindT.stringlit or tree.trees (resultTP).kind = kindT.charlit then
		    bind var resultext to type (string, LS1)
		    evaluateString (string@(ident.idents (tree.trees (resultTP).name)), tree.trees (resultTP).kind, resultext)
		    put : 0, resultext
		else
		    unparser.printLeaves (resultTP, 0, true)
		end if
		matched := false

	    label printattrR :
		% Print the leaves of the scope tree with attributes
		% Any [printattr]
		if tree.trees (resultTP).kind = kindT.stringlit or tree.trees (resultTP).kind = kindT.charlit then
		    bind var resultext to type (string, LS1)
		    evaluateString (string@(ident.idents (tree.trees (resultTP).name)), tree.trees (resultTP).kind, resultext)
		    put : 0, resultext
		else
		    const saveattr := options.option (attr_p)
		    options.setOption (attr_p, true)
		    unparser.printLeaves (resultTP, 0, true)
		    options.setOption (attr_p, saveattr)
		end if
		matched := false

	    label debugR :
		% Print the scope tree as a tree
		% Any [debug]
		put : 0, ""
		put : 0, "--- DEBUG ", string@(ident.idents (tree.trees (resultTP).name)), " ---"
		unparser.printParse (resultTP, 0, 0)
		put : 0, ""
		matched := false

	    label breakpointR :
		% Breakpoint - stop and wait to continue
		% ANY [breakpoint]
		put : 0, ""
		put : 0, "--- BREAKPOINT [Hit return to continue] " ..
		bind var dummy to type (string, LS1)
		get dummy : *
		matched := false

	    label quoteR, unparseR :
		% Concatenate the output text of the parameter to the scope string
		% String [quote Any]
		bind var leavestext to type (string, LS1)
		unparser.quoteLeaves (valueTP (ruleEnvironment.valuesBase + 1), leavestext)
		resultTP := tree.newTreeClone (originalTP)

		bind var resultext to type (string, LS2)
		evaluateString (string@(ident.idents (tree.trees (resultTP).name)), tree.trees (resultTP).kind, resultext)
		lconcat (resultext, leavestext)
		unevaluateString (tree.trees (resultTP).kind, resultext)

		var resultT := ident.install (resultext, tree.trees (resultTP).kind)
		tree.setName (resultTP, resultT)
		tree.setRawName (resultTP, resultT)
		matched := true

	    label unquoteR :
		% Replace id or comment with unquoted text of string or char literal
		% Id [unquote String]
		resultTP := tree.newTreeClone (originalTP)
		
		bind var parameterText to type (string, LS1)
		evaluateString (string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name)), 
		    tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind, parameterText)
		
		var resultT := ident.install (parameterText, kindT.id)
		tree.setName (resultTP, resultT)
		tree.setRawName (resultTP, resultT)
		matched := true

	    label parseR :
		% Replace scope of type [X] with a parse of the text of string S as an [X]
		% Any [parse String]

		% Make sure we have room to scan and parse
		checkSufficientParseSpace
		
		% Get the text to parse from the parameter
		bind var parameterText to type (string, LS1)
		evaluateString (string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name)), 
		    tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind, parameterText)

		% Set up the tokens to parse by scanning the input
		scanner.tokenize (parameterText, false, false)

		% Find the grammar type of the scope
		var typename := tree.trees (resultTP).name

		if tree.trees (resultTP).kind >= firstLiteralKind then
		    if tree.trees (resultTP).kind = kindT.literal then
			predefinedError ("Scope of [parse] function is literal (probable cause: scope is [token], use [repeat token] instead)", applyingRuleName, callingRuleName)
		    end if
		    typename := tree_ops.literalTypeName (tree.trees (resultTP).kind)
		end if

		var typeIndex := symbol.lookupSymbol (typename)
		assert typeIndex not= symbol.UNDEFINED

		% Now attempt to parse them as the scope type
		var parseTreeTP := nilTree
		parser.initializeParse ("[parse]", false, false, false, 0, type (parser.parseVarOrExpProc, 0))
		parser.parse (symbol.symbols (typeIndex), parseTreeTP)

		% Make sure we got a parse
		if parseTreeTP = nilTree then
		    predefinedParseError (failTokenIndex, applyingRuleName, callingRuleName, typename, 
			string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name)))
		end if

		% Got one!
		resultTP := parseTreeTP
		matched := true

	    label reparseR :
		% Replace scope of type [X] with a parse of the tokens (leaves) of the parameter tree as an [X]
		% Any1 [reparse Any2]
		
		% Make sure we have room to parse
		checkSufficientParseSpace
		
		% Set up the tokens to parse from the leaves of the parameter
		unparser.extractLeaves (valueTP (ruleEnvironment.valuesBase + 1))

		% Find the grammar type of the scope
		var typename := tree.trees (resultTP).name

		if tree.trees (resultTP).kind >= firstLiteralKind then
		    typename := tree_ops.literalTypeName (tree.trees (resultTP).kind)
		end if

		var typeIndex := symbol.lookupSymbol (typename)
		assert typeIndex not= symbol.UNDEFINED

		% Now attempt to parse them as the scope type
		var parseTreeTP := nilTree
		parser.initializeParse ("[reparse]", false, false, false, 0, type (parser.parseVarOrExpProc, 0))
		parser.parse (symbol.symbols (typeIndex), parseTreeTP)

		% Make sure we got a parse
		if parseTreeTP = nilTree then
		    predefinedParseError (failTokenIndex, applyingRuleName, callingRuleName, typename, "parameter")
		end if

		% Got one!
		resultTP := parseTreeTP
		matched := true

	    label readR :
		% Replace scope of type [X] with a parse of parameter file as an [X].
		% Any [read Stringlit]

		% Make sure we have room to scan and parse
		checkSufficientParseSpace
		
		% Set up the tokens to parse by scanning the file
		bind var fileName to type (string, LS1)
		evaluateString (string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name)), 
		    tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind, fileName)
		ltruncate (fileName, maxTuringStringLength)

		scanner.tokenize (fileName, true, false)

		% Find the grammar type of the scope
		var typename := tree.trees (resultTP).name

		if tree.trees (resultTP).kind >= firstLiteralKind then
		    typename := tree_ops.literalTypeName (tree.trees (resultTP).kind)
		end if

		var typeIndex := symbol.lookupSymbol (typename)
		assert typeIndex not= symbol.UNDEFINED

		% Now attempt to parse them as the scope type
		var parseTreeTP := nilTree
		parser.initializeParse ("[read] of file '" + fileName + "'", 
		    false, false, false, 0, type (parser.parseVarOrExpProc, 0))
		parser.parse (symbol.symbols (typeIndex), parseTreeTP)

		% Make sure we got a parse
		if parseTreeTP = nilTree then
		    predefinedParseError (failTokenIndex, applyingRuleName, callingRuleName, typename, 
			"file '" + fileName + "'")
		end if

		% Got one!
		resultTP := parseTreeTP
		matched := true

	    label writeR :
		% Output the leaves of the scope tree to a file
		% Any [write Stringlit]

		% Try to open the file
		bind var fileName to type (string, LS1)
		evaluateString (string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name)), 
		    tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind, fileName)
		ltruncate (fileName, maxTuringStringLength)

		var outstream := 0
		open : outstream, fileName, put

		if outstream = 0 then
		    predefinedError ("Unable to open output file '" + fileName + "'", applyingRuleName, callingRuleName)
		end if

		unparser.printLeaves (resultTP, outstream, true)
		matched := true
		
		close : outstream

	    label getR, getpR :
		% Replace scope of type [X] with a parse of one line of terminal input as an [X]
		% (The parameter to [getp] is the prompt)
		% Any [get]
		% Any [getp Stringlit]

		% Make sure we have room to scan and parse
		checkSufficientParseSpace
		
		if ruleIndex = getpR then
		    % Issue the prompt
		    if tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind = kindT.stringlit 
			    or tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind = kindT.charlit then 
			bind var promptext to type (string, LS1)
			evaluateString (string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name)),
			    tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind, promptext)
			put : 0, promptext ..
		    else
			put : 0, string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name)) ..
		    end if
		end if

		var parseTreeTP := nilTree
		loop
		    % Get the input line
		    bind var input to type (string, LS1)
		    get input : *

		    % Set up the tokens to parse by scanning the input
		    scanner.tokenize (input, false, false)

		    % Find the grammar type of the scope
		    var typename := tree.trees (resultTP).name
		    
		    if tree.trees (resultTP).kind >= firstLiteralKind then
			typename := tree_ops.literalTypeName (tree.trees (resultTP).kind)
		    end if

		    var typeIndex := symbol.lookupSymbol (typename)
		    assert typeIndex not= symbol.UNDEFINED

		    % Now attempt to parse them as the scope type
		    parser.initializeParse ("", false, false, false, 0, type (parser.parseVarOrExpProc, 0))
		    parser.parse (symbol.symbols (typeIndex), parseTreeTP)

		    % Make sure we got a parse
		    exit when parseTreeTP not= nilTree

		    put : 0, "[", externalType (string@(ident.idents (typename))), 
			"] input expected - try again (y/n)? " ..
		    get input : *

		    if input not= "y" then
			predefinedParseError (failTokenIndex, applyingRuleName, callingRuleName, typename, "input")
		    end if
		end loop

		% Got one!
		resultTP := parseTreeTP
		matched := true

	    label putR, putsR :
		% Output the leaves of the scope tree to the terminal
		% Any [put]
		% S1 [puts]

		if tree.trees (resultTP).kind = kindT.stringlit or tree.trees (resultTP).kind = kindT.charlit then
		    bind var resultext to type (string, LS1)
		    evaluateString (string@(ident.idents (tree.trees (resultTP).name)), tree.trees (resultTP).kind, resultext)
		    put : 0, resultext
		else
		    unparser.printLeaves (resultTP, 0, true)
		end if
		matched := false

	    label putpR :
		% The parameter is a pattern of the form "here it is % there it went"
		% where the "%" marks the point at which put the output
		% Any [putp Stringlit]

		% Output the first part of the pattern
		bind var promptext to type (string, LS1)
		evaluateString (string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name)),
		    tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind, promptext)

		const pcindex := index (promptext, "%") 
		if pcindex not= 0 then
		    bind var pthead to type (string, LS3)
		    lsubstr (pthead, promptext, 1, pcindex - 1)
		    put : 0, pthead ..
		else
		    put : 0, promptext ..
		end if

		% Output the scope
		if tree.trees (resultTP).kind = kindT.stringlit or tree.trees (resultTP).kind = kindT.charlit then
		    bind var resultext to type (string, LS2)
		    evaluateString (string@(ident.idents (tree.trees (resultTP).name)), tree.trees (resultTP).kind, resultext)
		    put : 0, resultext ..
		else
		    unparser.printLeaves (resultTP, 0, false)
		end if

		% Output the tail of the pattern
		if pcindex not=0 then
		    bind var pttail to type (string, LS3)
		    lsubstr (pttail, promptext, pcindex + 1, length (promptext))
		    put : 0, pttail
		else
		    put : 0, ""
		end if
		    
		matched := false

	    label indexR :
		% Replaces a number with the index of the first instance of S2 in S1, or zero if none is found
		% Number [index String1 String2]

		% Can't fail now ...
		bind var param1text to type (string, LS1), var param2text to type (string, LS2)
		evaluateString (string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name)),
		    tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind, param1text)
		evaluateString (string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 2)).name)),
		    tree.trees (valueTP (ruleEnvironment.valuesBase + 2)).kind, param2text)
		
		var ix := index (param1text, param2text)
		
		resultTP := tree.newTreeClone (originalTP)
		var resultT := ident.install (intstr (ix), kindT.number)
		tree.setName (resultTP, resultT)
		tree.setRawName (resultTP, resultT)
		matched := true

	    label grepR :
		% Succeeds iff S2 is a substring of S1
		% String1 [grep String2]

		bind var resultext to type (string, LS1)
		evaluateString (string@(ident.idents (tree.trees (resultTP).name)), tree.trees (resultTP).kind, resultext)

		bind var parameterText to type (string, LS2)
		evaluateString (string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name)), 
		    tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind, parameterText)

		matched := index (resultext, parameterText) not= 0

	    label repeatlengthR :
		% Replaces a number with the number of elements in the [repeat X] or [list X] parameter 
		% Number [length RepeatX]

		var paramTP := valueTP (ruleEnvironment.valuesBase + 1) 

		% find the first element of the repeat
		var repeatTP : treePT 
		var repeatLength := 0

		% repeat_0_X
		if tree.trees (tree.kid1TP (paramTP)).kind = kindT.empty then 
		    % an empty repeat - return length 0
		    resultTP := tree.newTreeClone (originalTP)
		    var resultT := ident.install ("0", kindT.number)
		    tree.setName (resultTP, resultT)
		    tree.setRawName (resultTP, resultT)
		    return
		end if 

		% nonempty repeat - compute the length
		var paramLength := 0
		loop 
		    exit when tree.trees (tree.kid2TP (paramTP)).kind = kindT.empty 
		    paramLength += 1
		    % go on to next "repeat_0_" tree 
		    paramTP := tree.kid2TP (paramTP) 
		end loop 

		% and return it
		resultTP := tree.newTreeClone (originalTP)
		var resultT := ident.install (intstr (paramLength, 0), kindT.number)
		tree.setName (resultTP, resultT)
		tree.setRawName (resultTP, resultT)
		matched := true

	    label selectR, headR, tailR :
		% Replaces a [repeat X] or [list X] sequence with the subsequence from N1..N2 
		% RepeatX [select Number1 Number2]
		% RepeatX [head Number]			== RepeatX [select 1 Number]
		% RepeatX [tail Number]			== RepeatX [select Number *]

		var i1, i2 := round (strreal (string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name))))

		if ruleIndex = selectR then
		    i2 := round (strreal (string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 2)).name))))
		elsif ruleIndex = tailR then
		    i2 := 999999
		elsif ruleIndex = headR then
		    i1 := 1
		end if

		% make the functions total
		if i1 < 1 then
		    i1 := 1
		end if
		
		if i2 < i1 - 1 then
		    i2 := i1 - 1
		end if
		
		% repeat_0_X	    
		if i2 < i1 then
		    % result is empty
		    tree.makeTwoKids (resultTP, emptyTP, emptyTP) 
		    matched := true
		    return
		end if
     
		assert i2 >= i1
     
		% find the i1'th [repeat X] node
		var s1 := resultTP
		var i := 1
		loop 
		    if tree.trees (tree.kid1TP (s1)).kind = kindT.empty  then
			% first index greater than length - make functions total by making result subsequence empty
			tree.makeTwoKids (resultTP, emptyTP, emptyTP) 
			matched := true
			return
		    end if
		    exit when i = i1
		    % go on to next "repeat_0_" tree 
		    s1 := tree.kid2TP (s1) 
		    i += 1
		end loop 
     
		% now we have the i1'th [repeat X] tree in s1
		% find the i2'th one
		var s2 := s1
		loop 
		    % New semantics - if i2 > length of repeat, means entire tail
		    exit when tree.trees (tree.kid1TP (s2)).kind = kindT.empty 
		    % Old normal semantics - finish at i2
		    exit when i = i2
		    % go on to next "repeat_0_" tree 
		    s2 := tree.kid2TP (s2) 
		    i += 1
		end loop 
     
		% made it - now cut off the tail of s2
		if tree.trees (tree.kid2TP (s2)).kind not= kindT.empty then
		    s2 := tree.kid2TP (s2)
		    tree.makeTwoKids (s2, emptyTP, emptyTP)
		end if
     
		% and change scope to the result
		resultTP := s1
		matched := true
		
	    label quitR :
		% Quits with the given exit code 
		% X [quit Number]
		const exitCode := round (strreal (string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name))))
		quit : exitCode
		
	    label fgetR :
		% Replace scope of type [X] with a parse of one line of file input as an [X]
		% Any [fget Filename]

		% Make sure we have room to scan and parse
		checkSufficientParseSpace
		
		% Check that the file is open
		bind var fileName to type (string, LS1)
		evaluateString (string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name)), 
		    tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind, fileName)
		ltruncate (fileName, maxTuringStringLength)

		var fs, ff := 0
		for f : 1 .. maxFgetputFiles
		    if fgetputFiles (f).name = tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name then
			fs := fgetputFiles (f).stream
		    elsif fgetputFiles (f).name = NOT_FOUND then
			ff := f
		    end if
		end for
		
		if fs = 0 then
		    % Try to open the file
		    if ff = 0 then
			predefinedError ("Unable to open input file '" + fileName + "' (too many open files)", applyingRuleName, callingRuleName)
		    end if

		    open : fs, fileName, get

		    if fs = 0 then
			predefinedError ("Unable to open input file '" + fileName + "'", applyingRuleName, callingRuleName)
		    end if
		    
		    fgetputFiles (ff).name := tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name
		    fgetputFiles (ff).stream := fs
		end if
		
		var parseTreeTP := nilTree
		
		% get the input line
		bind var input to type (string, LS2)
		get :fs, input : *

		% Set up the tokens to parse by scanning the input
		scanner.tokenize (input, false, false)

		% Find the grammar type of the scope
		var typename := tree.trees (resultTP).name

		if tree.trees (resultTP).kind >= firstLiteralKind then
		    typename := tree_ops.literalTypeName (tree.trees (resultTP).kind)
		end if

		const typeIndex := symbol.lookupSymbol (typename)
		assert typeIndex not= symbol.UNDEFINED

		% Now attempt to parse them as the scope type
		parser.initializeParse ("", false, false, false, 0, type (parser.parseVarOrExpProc, 0))
		parser.parse (symbol.symbols (typeIndex), parseTreeTP)

		% Make sure we got a parse
		if parseTreeTP = nilTree then
		    predefinedParseError (failTokenIndex, applyingRuleName, callingRuleName, typename, 
			"file '" + fileName + "'")
		end if

		% Got one!
		resultTP := parseTreeTP
		matched := true

	    label fputR, fputsR :
		% Output the leaves of the scope tree to the line-oriented file
		% Any [fput Filename]
		% S1 [fputs Filename]

		% Check that the file is open
		bind var fileName to type (string, LS1)
		evaluateString (string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name)), 
		    tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind, fileName)
		ltruncate (fileName, maxTuringStringLength)

		var fs, ff := 0
		for f : 1 .. maxFgetputFiles
		    if fgetputFiles (f).name = tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name then
			fs := fgetputFiles (f).stream
		    elsif fgetputFiles (f).name = NOT_FOUND then
			ff := f
		    end if
		end for
		
		if fs = 0 then
		    % Try to open the file
		    if ff = 0 then
			predefinedError ("Unable to open output file '" + fileName + "' (too many open files)", applyingRuleName, callingRuleName)
		    end if

		    open : fs, fileName, put

		    if fs = 0 then
			predefinedError ("Unable to open output file '" + fileName + "'", applyingRuleName, callingRuleName)
		    end if
		    
		    fgetputFiles (ff).name := tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name
		    fgetputFiles (ff).stream := fs
		end if

		% Output the scope
		if tree.trees (resultTP).kind = kindT.stringlit or tree.trees (resultTP).kind = kindT.charlit then
		    bind var resultext to type (string, LS2)
		    evaluateString (string@(ident.idents (tree.trees (resultTP).name)), tree.trees (resultTP).kind, resultext)
		    put : fs, resultext
		else
		    unparser.printLeaves (resultTP, fs, true)
		end if
		
		% Flush all output streams to keep synchronous
		external "TL_TLI_TLIFS" procedure flushstreams
		flushstreams
		
		matched := false

	    label fputpR :
		% The second parameter is a pattern of the form "here it is % there it went"
		% where the "%" marks the point at which put the output
		% Any [fputp Filename Stringlit]

		% Check that the file is open
		bind var fileName to type (string, LS1)
		evaluateString (string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name)), 
		    tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind, fileName)
		ltruncate (fileName, maxTuringStringLength)

		var fs, ff := 0
		for f : 1 .. maxFgetputFiles
		    if fgetputFiles (f).name = tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name then
			fs := fgetputFiles (f).stream
		    elsif fgetputFiles (f).name = NOT_FOUND then
			ff := f
		    end if
		end for
		
		if fs = 0 then
		    % Try to open the file
		    if ff = 0 then
			predefinedError ("Unable to open output file '" + fileName + "' (too many open files)", applyingRuleName, callingRuleName)
		    end if

		    open : fs, fileName, put

		    if fs = 0 then
			predefinedError ("Unable to open output file '" + fileName + "'", applyingRuleName, callingRuleName)
		    end if
		    
		    fgetputFiles (ff).name := tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name
		    fgetputFiles (ff).stream := fs
		end if

		% Output the first part of the pattern
		bind var promptext to type (string, LS2)
		evaluateString (string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 2)).name)),
		    tree.trees (valueTP (ruleEnvironment.valuesBase + 2)).kind, promptext)
		    
		const pcindex := index (promptext, "%") 
		if pcindex not= 0 then
		    bind var pthead to type (string, LS3)
		    lsubstr (pthead, promptext, 1, pcindex - 1)
		    put : fs, pthead ..
		else
		    put : fs, promptext ..
		end if

		% Output the scope
		if tree.trees (resultTP).kind = kindT.stringlit or tree.trees (resultTP).kind = kindT.charlit then
		    bind var resultext to type (string, LS3)
		    evaluateString (string@(ident.idents (tree.trees (resultTP).name)), tree.trees (resultTP).kind, resultext)
		    put : fs, resultext ..
		else
		    unparser.printLeaves (resultTP, fs, false)
		end if

		% Output the tail of the pattern
		if pcindex not= 0 then
		    bind var pttail to type (string, LS3)
		    lsubstr (pttail, promptext, pcindex + 1, length (promptext))
		    put : fs, pttail
		else
		    put : fs, ""
		end if
		    
		% Flush all output streams to keep synchronous
		external "TL_TLI_TLIFS" procedure flushstreams
		flushstreams

		matched := false

	    label fopenR :
		% Explicitly open a line-oriented input/output file
		% Any [fopen Filename Method], where Method = in[put]/get, out[put]/put or mod/append

		% Get filename
		bind var fileName to type (string, LS1)
		evaluateString (string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name)), 
		    tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind, fileName)
		ltruncate (fileName, maxTuringStringLength)
		
		% Get method
		bind var method to type (string, LS2)
		evaluateString (string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 2)).name)), 
		    tree.trees (valueTP (ruleEnvironment.valuesBase + 2)).kind, method)
		ltruncate (method, maxTuringStringLength)

		% Check we have a slot for the file
		var fs, ff := 0
		for f : 1 .. maxFgetputFiles
		    if fgetputFiles (f).name = tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name then
			fs := fgetputFiles (f).stream
		    elsif fgetputFiles (f).name = NOT_FOUND then
			ff := f
		    end if
		end for
		
		if fs not= 0 then
		    % It's already open - oops!
		    predefinedError ("Unable to open file '" + fileName + "' (already open)", applyingRuleName, callingRuleName)
		else
		    % Try to open the file
		    if ff = 0 then
			predefinedError ("Unable to open file '" + fileName + "' (too many open files)", applyingRuleName, callingRuleName)
		    end if

		    % What kind of open do we need?  in[put]/get, out[put]/put or mod/append
		    if index (method, "in") = 1 or index (method, "get") = 1 then
			open : fs, fileName, get
		    elsif index (method, "out") = 1 or index (method, "put") = 1 then
			open : fs, fileName, put
		    elsif index (method, "mod") = 1 or index (method, "app") = 1 then
			open : fs, fileName, put, mod, seek
		    else
			predefinedError ("Unknown open mode '" + method + "' (must be one of get, put, append)", applyingRuleName, callingRuleName)
		    end if
		    
		    if fs = 0 then
			predefinedError ("Unable to open file '" + fileName + "'", applyingRuleName, callingRuleName)
		    elsif index (method, "mod") = 1 or index (method, "app") = 1 then
			seek : fs, *
		    end if
		    
		    fgetputFiles (ff).name := tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name
		    fgetputFiles (ff).stream := fs
		end if

		matched := false

	    label fcloseR :
		% Close a line-oriented input/output file
		% Any [fclose Filename]

		% Check that the file is open
		bind var fileName to type (string, LS1)
		evaluateString (string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name)), 
		    tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind, fileName)
		ltruncate (fileName, maxTuringStringLength)

		var fs, ff := 0
		for f : 1 .. maxFgetputFiles
		    if fgetputFiles (f).name = tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name then
			fs := fgetputFiles (f).stream
			ff := f
		    end if
		end for
		
		if fs not= 0 then
		    close : fgetputFiles (ff).stream
		    fgetputFiles (ff).name := NOT_FOUND
		    fgetputFiles (ff).stream := 0
		end if

		matched := false
		
	    label pragmaR :
		% Dynamically change TXL options
		% Any [pragma OptionsString]

		assert tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind = kindT.stringlit 
			or tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind = kindT.charlit 
		
		bind var optionsString to type (string, LS1)
		evaluateString (string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name)), 
		    tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind, optionsString)

		options.processOptionsString (optionsString)

		matched := false
		
	    label systemR :
		% Invoke system command (dangerous!)
		% Any [system CommandString]

		assert tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind = kindT.stringlit 
			or tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind = kindT.charlit 
		
		bind var commandString to type (string, LS1)
		evaluateString (string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name)), 
		    tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind, commandString)

		#if LIGHT then
		    predefinedError ("[system] is not available on this platform", applyingRuleName, callingRuleName)
		#else
		    external function system (command : string) : int
		    const retcode : int := system (commandString)
		    
		    if retcode = 0 then 
			matched := true
		    else
			matched:= false
		    end if
		#end if
		
	    label pipeR :
		% Invoke system command (dangerous!)
		% S1 [pipe CommandString]

		assert tree.trees (resultTP).kind = kindT.stringlit 
			or tree.trees (resultTP).kind = kindT.charlit 

		assert tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind = kindT.stringlit 
			or tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind = kindT.charlit 
		
		bind var scopeString to type (string, LS1)
		evaluateString (string@(ident.idents (tree.trees (resultTP).name)), 
		    tree.trees (resultTP).kind, scopeString)
		
		bind var commandString to type (string, LS2)
		evaluateString (string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name)), 
		    tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind, commandString)
		
		bind var systemString to type (string, LS3)

		% create command line
		systemString := "echo '"
		lconcat (systemString, scopeString)
		lconcat (systemString, "' | ")
		lconcat (systemString, commandString)
		lconcat (systemString, " > _TXsRsL_")
		
		#if LIGHT then
		    predefinedError ("[pipe] is not available on this platform", applyingRuleName, callingRuleName)
		#else
		    % run the command
		    external function system (command : string) : int
		    var retcode := system (systemString)
		    
		    if retcode = 0 then 
			matched := true
		    else
			matched:= false
		    end if
		    
		    % get the result ...
		    var f : int
		    open : f, "_TXsRsL_", get
		    
		    if f = 0 then
			matched := false
			scopeString := ""
		    else
			get : f, scopeString : *
			unevaluateString (tree.trees (resultTP).kind, scopeString)
			close : f
		    end if
		    
		    % ... and return it
		    const oldresultTP := resultTP
		    resultTP := tree.newTreeClone (oldresultTP)
		    const resultT := ident.install (scopeString, tree.trees (resultTP).kind)
		    tree.setName (resultTP, resultT)
		    tree.setRawName (resultTP, resultT)

		    % Clean up the mess!
		    if directoryChar = "/" then
			retcode := system ("/bin/rm -f _TXsRsL_")
		    else
			% Windows
			retcode := system ("del _TXsRsL_")
		    end if
		#end if

	    label tolowerR :
		% Id [tolower]
		% make any token lower case

		% can't fail since types are right
		matched := true

		const oldresultTP := resultTP
		resultTP := tree.newTreeClone (oldresultTP)
		
		bind var tokentext to type (string, LS1)
		evaluateString (string@(ident.idents (tree.trees (resultTP).name)), tree.trees (resultTP).kind, tokentext)
		ltolower (tokentext)
		unevaluateString (tree.trees (resultTP).kind, tokentext)

		const resultT := ident.install (tokentext, tree.trees (resultTP).kind)
		tree.setName (resultTP, resultT)
		tree.setRawName (resultTP, resultT)

	    label toupperR :
		% Id [toupper]
		% make any token upper case

		% can't fail since types are right
		matched := true

		const oldresultTP := resultTP
		resultTP := tree.newTreeClone (oldresultTP)
		
		bind var tokentext to type (string, LS1)
		evaluateString (string@(ident.idents (tree.trees (resultTP).rawname)), tree.trees (resultTP).kind, tokentext)
		ltoupper (tokentext)
		unevaluateString (tree.trees (resultTP).kind, tokentext)
		
		var resultT := ident.install (tokentext, tree.trees (resultTP).kind)
		tree.setRawName (resultTP, resultT)

		% If -case is on, normalize the internal name, otherwise it is the same
		if options.option (case_p) and tree.trees (resultTP).kind not= kindT.stringlit 
			and tree.trees (resultTP).kind not= kindT.charlit then
		    ltolower (tokentext)
		    resultT := ident.install (tokentext, tree.trees (resultTP).kind)
		    tree.setName (resultTP, resultT)
		else
		    tree.setName (resultTP, resultT)
		end if
		
	    label typeofR :
		% I [typeof X]
		% Set I to type of tree X as an [id]

		resultTP := tree.newTreeClone (originalTP)
		assert tree.trees (resultTP).kind = kindT.id

		if tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind < firstLiteralKind then
		    tree.setName (resultTP, tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name)
		    tree.setRawName (resultTP, tree.trees (resultTP).name)
		else
		    tree.setName (resultTP, kindType (ord (tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind)))
		    tree.setRawName (resultTP, tree.trees (resultTP).name)
		end if

		matched := true

	    label istypeR :
		% X [istype I]
		% Succeed iff the type of tree X as an [id] is I

		assert tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind = kindT.id
		
		if tree.trees (resultTP).kind < firstLiteralKind then
		    matched := tree.trees (resultTP).name = tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name
		else
		    matched := kindType (ord (tree.trees (resultTP).kind)) = tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name
		end if
		
	    label roundR :
		% N1 [round]
		% N1 := round (N1)

		% can't fail since types are ok
		matched := true

		const oldresultTP := resultTP
		resultTP := tree.newTreeClone (oldresultTP)
		
		var N1 := strreal (string@(ident.idents (tree.trees (resultTP).name)))
		N1 := round (N1)
		
		bind var resultValue to type (string, LS1)
		convertRealToString (N1, resultValue)
		const resultT := ident.install (resultValue, kindT.number)
		tree.setName (resultTP, resultT)
		tree.setRawName (resultTP, resultT)
		
	    label truncR :
		% N1 [trunc]
		% N1 := trunc (N1)

		% can't fail since types are ok
		matched := true

		const oldresultTP := resultTP
		resultTP := tree.newTreeClone (oldresultTP)
		
		var N1 := strreal (string@(ident.idents (tree.trees (resultTP).name)))
		N1 := floor (N1)	% trunc is floor in Turing!
		
		bind var resultValue to type (string, LS1)
		convertRealToString (N1, resultValue)
		const resultT := ident.install (resultValue, kindT.number)
		tree.setName (resultTP, resultT)
		tree.setRawName (resultTP, resultT)

	    label getsR :
		% Replace scope of type [stringlit] or [charlit] with the text of one line of input 
		% S1 [gets]

		% Make sure we have room to scan and parse
		checkSufficientParseSpace
		
		% get the input line
		bind var input to type (string, LS1)
		get input : *
			
		% And return it as a string
		unevaluateString (tree.trees (resultTP).kind, input)

		const oldresultTP := resultTP
		resultTP := tree.newTreeClone (oldresultTP)
		const resultT := ident.install (input, tree.trees (resultTP).kind)
		tree.setName (resultTP, resultT)
		tree.setRawName (resultTP, resultT)

		matched := true

	    label fgetsR :
		% Replace scope of type [stringlit] or [charlit] with the text of one line of file input 
		% S1 [fgets Filename]

		% Check that the file is open
		bind var fileName to type (string, LS1)
		evaluateString (string@(ident.idents (tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name)), 
		    tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).kind, fileName)
		ltruncate (fileName, maxTuringStringLength)
		var fs, ff := 0
		for f : 1 .. maxFgetputFiles
		    if fgetputFiles (f).name = tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name then
			fs := fgetputFiles (f).stream
		    elsif fgetputFiles (f).name = NOT_FOUND then
			ff := f
		    end if
		end for
		
		if fs = 0 then
		    % Try to open the file
		    if ff = 0 then
			predefinedError ("Unable to open input file '" + fileName + "' (too many open files)", applyingRuleName, callingRuleName)
		    end if

		    open : fs, fileName, get

		    if fs = 0 then
			predefinedError ("Unable to open input file '" + fileName + "'", applyingRuleName, callingRuleName)
		    end if
		    
		    fgetputFiles (ff).name := tree.trees (valueTP (ruleEnvironment.valuesBase + 1)).name
		    fgetputFiles (ff).stream := fs
		end if
		
		% get the input line
		bind var input to type (string, LS2)
		get : fs, input : *
		
		% And return it as a string
		unevaluateString (tree.trees (resultTP).kind, input)

		const oldresultTP := resultTP
		resultTP := tree.newTreeClone (oldresultTP)
		const resultT := ident.install (input, tree.trees (resultTP).kind)
		tree.setName (resultTP, resultT)
		tree.setRawName (resultTP, resultT)

		matched := true
		
	end case

    end applyPredefinedFunction

end predefs
