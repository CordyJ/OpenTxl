% OpenTxl Version 11 compiled app store/load facility
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

% Compiled TXL bytecode store/load facility
% Provides storing and loading of compiled TXL program as bytecode
% Used by TXL app compiler (txlc) to compile C-based standalone TXL apps

% Modification Log

% v11.0	Initial revision, revised from FreeTXL 10.8b (c) 1988-2022 Queen's University at Kingston


% TXL Load/Store/Standalone Facility

parent "txl.t"

stub module LoadStore

    import 
	var ident, var tree, var charset, var symbol, var scanner,
	var rule, var mainRule, 
	var inputGrammarTreeTP, var kindType, var options, 
	error

    export 
	Save, Restore

    procedure Save (tofile : string)
    procedure Restore (fromfile : string)

end LoadStore


body module LoadStore

    % Compressed save and restore for compiled TXL programs as structured bytecode.
    %
    % The optimizations used in this module depend implicitly on several things.
    %
    %	(i) The implementation of the 'trees' and 'kids' used to represent
    %		trees must be in arrays rather than the more natural collections.
    %
    %	(ii) The parser (parse.ch), grammar tree builder (compdef.ch)
    %		and rule table builder (comprul.ch) must not try to 
    %		'share' any trees or kids with the bootstrap or parse of the 
    %		TXL program (i.e., they must explicitly create new trees
    %		and kids for everything they build).
    %		
    %	(iii) All pre-initialized trees and kids, such as 'empty', are always
    %		allocated first and lie completely within the first 'reservedTrees', 'reservedKids' 
    %		elements of the 'kids' and 'trees' arrays.
    %		

    % Magic number used to detect synchronization / version errors in stored bytecode
    var MAGNUM : int := 0721696969  % pizza in Karlsruhe

    % Type used to map any kind of data to bytes
    type char4096 : char (4096)

#if not NOCOMPILE then

    procedure CompressKids
	% This procedure compresses out tree kids used in the bootstrap and txl source analysis stages 
	% to compact kids used in the user's TXL program to the beginning of the kids array.
	% This maximizes the free kid space available for transformation when the compiled app is run.

	% We can't compress if we've already run out of kid space
	pre tree.allocationStrategy = simple
	
	% Step 1. Compress Kids
	%
	% tree kid pointers appear only in one place:
	%
	%	tree.trees(*).kidsKP

	if tree.firstUserKid <= reservedKids then
	    % no point in compressing it!
	    return
	end if

	% kid compression shift - we can eliminate any kids used before the user's TXL program
	const kidShift := reservedKids - tree.firstUserKid

	% (i) shift all kid pointers in tree.trees(*).kidsKP
	for n : tree.firstUserTree .. tree.treeCount
	    case tree.trees (n).kind of
		label kindT.order, kindT.choose, kindT.repeat, kindT.leftchoose, kindT.generaterepeat,
			kindT.list, kindT.generatelist, kindT.lookahead, kindT.push, kindT.pop,
			kindT.ruleCall, kindT.expression, kindT.lastExpression :
		    if tree.trees (n).kidsKP >= tree.firstUserKid then
			kidPT@(addr(tree.trees (n).kidsKP)) += kidShift
		    end if
		label :
	    end case
	end for

	% (ii) move the actual shifted kids down to the beginning of the array
	for c : tree.firstUserKid .. tree.kidCount
	    treePT@(addr(tree.kids (c + kidShift))) := tree.kids (c)
	end for

	% document what we've done
	int@(addr(tree.firstUserKid)) += kidShift
	int@(addr(tree.kidCount)) += kidShift
    end CompressKids

    procedure CompressTrees
	% This procedure compresses out tree nodes used in the bootstrap and txl source analysis stages 
	% to compact tree nodes used in the user's TXL program to the beginning of the trees array.
	% This maximizes the free tree space available for transformation when the compiled app is run.

	% We can't compress if we've already run out of tree space
        pre tree.allocationStrategy = simple

	% Step 2. Compress Trees
	%
	% tree pointers appear only in four places:
	%
	%	(i) tree.kids(*)
	%	(ii) rules(*).patternTP, rules(*).replacementTP, 
	%	     rules(*).prePattern.partsBase(*).patternTP,
	%	     rules(*).prePattern.partsBase(*).replacementTP,
	%	     rules(*).postPattern.partsBase(*).patternTP,
	%	     rules(*).postPattern.partsBase(*).replacementTP
	%	(iii) inputGrammarTreeTP
	%	(iv) symbol.symbols

	if tree.firstUserTree <= reservedTrees then
	    % no point in compressing it!
	    return
	end if

	% tree compression shift - we can eliminate any tree nodes used before the user's TXL program
	const treeShift := reservedTrees - tree.firstUserTree

	% (i) shift tree pointers in kids(*)
	for c : tree.firstUserKid .. tree.kidCount
	    if tree.kids (c) >= tree.firstUserTree then
		treePT@(addr(tree.kids (c))) += treeShift
	    end if
	end for

	% (ii) shift tree pointers in rules(*)
	for i : 1 .. rule.nRules
	    bind var r to ruleT@(addr(rule.rules (i)))
	    % rules(*).patternTP
	    if r.patternTP >= tree.firstUserTree then
		r.patternTP += treeShift
	    end if
	    % rules(*).replacementTP
	    if r.replacementTP >= tree.firstUserTree then
		r.replacementTP += treeShift
	    end if
	    % rules(*).prePattern.partsBase(*).patternTP, rules(*).prePattern.partsBase(*).replacementTP
	    for p : 1 .. r.prePattern.nparts
		if rule.ruleParts (r.prePattern.partsBase + p).patternTP >= tree.firstUserTree then
		    treePT@(addr(rule.ruleParts (r.prePattern.partsBase + p).patternTP)) += treeShift
		end if
		if rule.ruleParts (r.prePattern.partsBase + p).replacementTP >= tree.firstUserTree then
		    treePT@(addr(rule.ruleParts (r.prePattern.partsBase + p).replacementTP)) += treeShift
		end if
	    end for
	    % rules(*).postPattern.partsBase(*).patternTP, rules(*).postPattern.partsBase(*).replacementTP
	    for p : 1 .. r.postPattern.nparts
		if rule.ruleParts (r.postPattern.partsBase + p).patternTP >= tree.firstUserTree then
		    treePT@(addr(rule.ruleParts (r.postPattern.partsBase + p).patternTP)) += treeShift
		end if
		if rule.ruleParts (r.postPattern.partsBase + p).replacementTP >= tree.firstUserTree then
		    treePT@(addr(rule.ruleParts (r.postPattern.partsBase + p).replacementTP)) += treeShift
		end if
	    end for
	end for

	% (iii) shift inputGrammarTreeTP
	if inputGrammarTreeTP >= tree.firstUserTree then
	    inputGrammarTreeTP += treeShift
	end if

	% (iv) shift tree pointers in the symbols
	for s : 1 .. symbol.nSymbols
	    treePT@(addr (symbol.symbols (s))) += treeShift
	end for

	% (v) move the actual shifted trees down to the beginning of the trees array
	for n : tree.firstUserTree .. tree.treeCount
	    parseTreeT@(addr(tree.trees (n + treeShift))) := tree.trees (n)
	end for

	% document what we've done
	int@(addr(tree.firstUserTree)) += treeShift
	int@(addr(tree.treeCount)) += treeShift
    end CompressTrees

    body procedure Save % (tofile : string)

	% Make sure that we didn't run out of space compiling 
	% (Otherwise the save/restore cannot work)
        if tree.allocationStrategy not= simple then
	    error ("", "Not enough memory to compile TXL program (a larger size is required for this program)", FATAL, 401)
        end if
	
	% Compress the trees and kids in the TXL program to maximize available transformation space when run
	CompressKids
	CompressTrees
	
	% Now store the compiled TXL program as structured bytecode
	var tf : int
	open : tf, tofile, write

	if tf = 0 then
		error ("", "Unable to create TXL bytecode file '" + tofile + "'", FATAL, 409)
	end if
	
	% 0. Header
	var nbytes := 0
	write : tf, MAGNUM
	write : tf, options.txlSize	% MUST be first!
	nbytes += 8
	var rlen : nat1 := length (version)
	var vversion := version
	write : tf, rlen 
	write : tf, vversion : rlen + 1
	nbytes += rlen + 2
	rlen := length (options.txlSourceFileName)
	write : tf, rlen
	write : tf, options.txlSourceFileName : rlen + 1
	nbytes += rlen + 2
	write : tf, MAGNUM
	nbytes += 4
	if options.option (verbose_p) then
	    put : 0, "Header: ", nbytes
	end if
	
	% 1. compoundTokens and commentTokens
	nbytes := 0
	write : tf, scanner.nCompounds
	nbytes += 4
	for i : 1 .. scanner.nCompounds
	    var len : nat1 := scanner.compoundTokens (i).length_ 
	    write : tf, len
	    write : tf, scanner.compoundTokens (i).literal : len + 1 % (sic)
	    nbytes += len + 2
	end for
	for i : chr (0) .. chr (255)
	    assert maxCompoundTokens <= 255
	    var ci : nat1 := scanner.compoundIndex (i)
	    write : tf, ci
	end for
	nbytes += 256 
	write : tf, scanner.nComments
	nbytes += 4
	write : tf, scanner.commentStart (1) : scanner.nComments * size (tokenT)
	nbytes += scanner.nComments * size (tokenT)
	write : tf, scanner.commentEnd (1) : scanner.nComments * size (tokenT)
	nbytes += scanner.nComments * size (tokenT)
	write : tf, MAGNUM
	nbytes += 4
	if options.option (verbose_p) then
	    put : 0, "Compounds/comments: ", nbytes
	end if
	
	% 2. keywords
	write : tf, scanner.nKeys
	write : tf, scanner.keywordTokens (1) : scanner.nKeys * size (tokenT)
	write : tf, MAGNUM
	if options.option (verbose_p) then
	    put : 0, "Keywords: ", 8 + scanner.nKeys * size (tokenT)
	end if
	
	% 3. tokenPatterns
	nbytes := 0
	write : tf, scanner.nPatterns
	nbytes += 4
	for i : 1 .. scanner.nPatterns
	    bind tp to scanner.tokenPatterns (i)
	    write : tf, tp.kind 
	    write : tf, tp.name 
	    write : tf, tp.next
	    nbytes += 9
	    var len : int2 := tp.length_
	    write : tf, len
	    for j : 1 .. len + 1
	        var pj : int2 := tp.pattern (j)
		write : tf, pj
	    end for
	    nbytes += 2 + 2 * (len+1)
	end for
	for i : chr (0) .. chr (255)
	    assert maxTokenPatterns <= 255
	    var pi : nat1 := scanner.patternIndex (i)
	    write : tf, pi
	end for
	nbytes += 256
	write : tf, scanner.patternNLCommentIndex
	nbytes += 4
	write : tf, scanner.nPatternLinks
	nbytes += 4
	for i : 1 .. scanner.nPatternLinks
	    assert maxTokenPatterns <= 255
	    var pi : nat1 := scanner.patternLink (i)
	    write : tf, pi
	end for
	nbytes += scanner.nPatternLinks
	write : tf, kindType (ord (firstUserTokenKind)) : 
	    (ord (lastUserTokenKind) - ord (firstUserTokenKind) + 1) * size (tokenT)
	nbytes += (ord (lastUserTokenKind) - ord (firstUserTokenKind) + 1) * size (tokenT)
	write : tf, MAGNUM
	nbytes += 4
	if options.option (verbose_p) then
	    put : 0, "Patterns: ", nbytes
	end if
	
	% 4. idents
	nbytes := 0
	write : tf, ident.nIdentChars
	write : tf, ident.identText (1) : ident.nIdentChars
	nbytes += 4 + ident.nIdentChars
	write : tf, ident.nIdents
	for i : 0 .. maxIdents - 1
	    if ident.idents (i) not= ident.nilIdent then
		var ii := i
		var idtai : addressint := ident.idents (i) - addr (ident.identText (1))
		var idti := idtai
		write : tf, ii, idti, ident.identKind (i)
		nbytes += 9
	    end if
	end for
	write : tf, MAGNUM
	if options.option (verbose_p) then
	    put : 0, "IdentTable: ", 4 + nbytes
	end if
	
	% 5. trees
	write : tf, tree.treeCount, tree.firstUserTree
	write : tf, tree.trees (tree.firstUserTree) : 
	    (tree.treeCount - tree.firstUserTree + 1) * size (parseTreeT)
	write : tf, MAGNUM
	if options.option (verbose_p) then
	    put : 0, "Trees: ", 12 + (tree.treeCount - tree.firstUserTree + 1) * size (parseTreeT)
	end if
	
	% 6. kids
	write : tf, tree.kidCount, tree.firstUserKid
	write : tf, tree.kids (tree.firstUserKid) : (tree.kidCount - tree.firstUserKid + 1) * size (treePT)
	write : tf, inputGrammarTreeTP
	write : tf, MAGNUM
	if options.option (verbose_p) then
	    put : 0, "Kids: ", 12 + (tree.kidCount - tree.firstUserKid + 1) * size (treePT)
	end if
	
	% 7. symbols
	write : tf, symbol.nSymbols
	write : tf, symbol.symbols (1) : symbol.nSymbols * size (treePT)
	write : tf, MAGNUM
	if options.option (verbose_p) then
	    put : 0, "SymbolTable: ", 4 + symbol.nSymbols * size (treePT)
	end if
	
	% 8. rules
	write : tf, rule.nRules
	nbytes := 0
	for i : 1 .. rule.nRules
	    bind var r to ruleT@(addr(rule.rules (i)))
	    write : tf, r.name, r.target, r.skipName, r.patternTP, r.replacementTP, r.kind, 
		r.starred, r.isCondition, r.defined, r.called, r.skipRepeat
	    write : tf, r.prePattern.nparts
	    for pp : 1 .. r.prePattern.nparts
		write : tf, rule.ruleParts (r.prePattern.partsBase + pp) : size (partDescriptor)
	    end for
	    write : tf, r.postPattern.nparts
	    for pp : 1 .. r.postPattern.nparts
		write : tf, rule.ruleParts (r.postPattern.partsBase + pp) : size (partDescriptor)
	    end for
	    write : tf, r.localVars.nformals, r.localVars.nprelocals, r.localVars.nlocals
	    for lc : 1 .. r.localVars.nlocals
		write : tf, rule.ruleLocals (r.localVars.localBase + lc) : size (localInfoT)
	    end for
	    nbytes += 60 + 
		(r.prePattern.nparts + r.postPattern.nparts) * size (partDescriptor) +
		r.localVars.nlocals * size (localInfoT)
	end for
	write : tf, mainRule
	write : tf, MAGNUM
	if options.option (verbose_p) then
	    put : 0, "Rules: ", 12 + nbytes
	end if
	
	% 9. options
	options.setOption (compile_p, false)
	options.setOption (load_p, true)
	write : tf, options.option
	options.setOption (compile_p, true)
	options.setOption (load_p, false)
	nbytes := size (options.option)
	var len : nat1 := length (options.txlLibrary)
	write : tf, len 
	write : tf, options.txlLibrary : len + 1
	nbytes += len + 2
	write : tf, options.outputLineLength
	nbytes += 4
	write : tf, options.indentIncrement
	nbytes += 4
	len := length (options.optionIdChars)
	write : tf, len 
	write : tf, options.optionIdChars : len + 1
	nbytes += len + 2
	len := length (options.optionSpChars)
	write : tf, len 
	write : tf, options.optionSpChars : len  + 1
	nbytes += len + 2
	write : tf, charset.stringlitEscapeChar
	write : tf, charset.charlitEscapeChar
	nbytes += 2
	write : tf, MAGNUM
	nbytes += 4
	if options.option (verbose_p) then
	    put : 0, "Options: ", nbytes
	end if
	
	% 10. EOF
	write : tf, MAGNUM
	if options.option (verbose_p) then
	    put : 0, "Trailer: ", 4
	end if
	close : tf
    end Save

#else
    body procedure Save % (tofile : string)
    end Save
#end if

    procedure synchError (n : int) 
        error ("", "Synchronization error " + intstr (n,0) + " on compiled file", INTERNAL_FATAL, 405)
    end synchError

#if not STANDALONE then

    % Stored bytecode (.ctxl) version, for use with -c/-l command line arguments

    body procedure Restore % (fromfile : string)
	var tf : int
	var mn : int
	open : tf, fromfile, read
	
	% 0. Header
	if options.option (verbose_p) then
	    put : 0, "Header"
	end if
	read : tf, mn
	if mn not= MAGNUM then
	    error ("", "Load file is not a compiled TXL object file", FATAL, 402)
	end if
	read : tf, mn
	if mn not= options.txlSize then
	    error ("", "TXL size does not match compiled size", INTERNAL_FATAL, 403)
	end if
	var rlen : nat1
	read : tf, rlen
	var storedversion : string 
	read : tf, storedversion : rlen + 1
	if storedversion not= version then
	    error ("", "TXL object file was compiled by a different version of TXL", FATAL, 404)
	end if
	read : tf, rlen
	read : tf, string@(addr(options.txlSourceFileName)) : rlen + 1
	read : tf, mn
	if mn not= MAGNUM then
	    synchError (0)
	end if
	
	% 1. compoundTokens and commentTokens
	if options.option (verbose_p) then
	    put : 0, "Compounds/comments"
	end if
	read : tf, int@(addr(scanner.nCompounds))
	for i : 1 .. scanner.nCompounds
	    var len : nat1 
	    read : tf, len
	    int@(addr(scanner.compoundTokens (i).length_)) := len
	    read : tf, string@(addr(scanner.compoundTokens (i).literal)) : len + 1 % (sic)
	end for
	for i : chr (0) .. chr (255)
	    assert maxCompoundTokens <= 255
	    var ci : nat1 
	    read : tf, ci
	    int@(addr(scanner.compoundIndex (i))) := ci
	end for
	read : tf, int@(addr(scanner.nComments))
	read : tf, tokenT@(addr(scanner.commentStart (1))) : scanner.nComments * size (tokenT)
	read : tf, tokenT@(addr(scanner.commentEnd (1))) : scanner.nComments * size (tokenT)
	read : tf, mn
	if mn not= MAGNUM then
	    synchError (1)
	end if
	
	% 2. keywords
	if options.option (verbose_p) then
	    put : 0, "Keywords"
	end if
	read : tf, int@(addr(scanner.nKeys))
	read : tf, tokenT@(addr(scanner.keywordTokens (1))) : scanner.nKeys * size (tokenT)
	read : tf, mn
	if mn not= MAGNUM then
	    synchError (2)
	end if
	
	% 3. tokenPatterns
	if options.option (verbose_p) then
	    put : 0, "Patterns"
	end if
	read : tf, int@(addr(scanner.nPatterns))
	for i : 1 .. scanner.nPatterns
	    bind var tp to scanner.patternEntryT@(addr(scanner.tokenPatterns (i)))
	    read : tf, tp.kind
	    read : tf, tp.name
	    read : tf, tp.next
	    var len : int2
	    read : tf, len
	    tp.length_ := len
	    for j : 1 .. len + 1
		var pj : int2
		read : tf, pj
		tp.pattern (j) := pj
	    end for
	end for
	for i : chr (0) .. chr (255)
	    assert maxTokenPatterns <= 255
	    var pi : nat1 
	    read : tf, pi
	    int@(addr(scanner.patternIndex (i))) := pi
	end for
	read : tf, int@(addr(scanner.patternNLCommentIndex))
	read : tf, int@(addr(scanner.nPatternLinks))
	for i : 1 .. scanner.nPatternLinks
	    assert maxTokenPatterns <= 255
	    var pi : nat1 
	    read : tf, pi
	    int@(addr(scanner.patternLink (i))) := pi
	end for
	read : tf, kindType (ord (firstUserTokenKind)) : 
	    (ord (lastUserTokenKind) - ord (firstUserTokenKind) + 1) * size (tokenT)
	read : tf, mn
	if mn not= MAGNUM then
	    synchError (3)
	end if
	
	% 4. idents
	if options.option (verbose_p) then
	    put : 0, "IdentTable"
	end if
	% The idents belongs to the ident module, so technically we cannot assign to it
	% We get around that by cheating through its address
	read : tf, int@(addr(ident.nIdentChars))
	read : tf, char@(addr(ident.identText (1))) : ident.nIdentChars
	read : tf, int@(addr(ident.nIdents))
	loop
	    var i : int
	    read : tf, i
	    exit when i = MAGNUM
	    var idti : int
	    read : tf, idti
	    addressint@(addr(ident.idents (i))) := addr (ident.identText (1)) + idti
	    read : tf, kindT@(addr(ident.identKind (i)))
	end loop
	if mn not= MAGNUM then
	    synchError (4)
	end if
	
	% 5. trees
	if options.option (verbose_p) then
	    put : 0, "Trees"
	end if
	read : tf, int@(addr(tree.treeCount)), int@(addr(tree.firstUserTree))
	read : tf, parseTreeT@(addr(tree.trees (tree.firstUserTree))) : 
	    (tree.treeCount - tree.firstUserTree + 1) * size (parseTreeT)
	read : tf, mn
	if mn not= MAGNUM then
	    synchError (5)
	end if
	
	% 6. kids
	if options.option (verbose_p) then
	    put : 0, "Kids"
	end if
	read : tf, int@(addr(tree.kidCount)), int@(addr(tree.firstUserKid))
	read : tf, treePT@(addr(tree.kids (tree.firstUserKid))) : 
	    (tree.kidCount - tree.firstUserKid + 1) * size (treePT)
	read : tf, inputGrammarTreeTP
	read : tf, mn
	if mn not= MAGNUM then
	    synchError (6)
	end if
	
	% 7. symbols
	if options.option (verbose_p) then
	    put : 0, "SymbolTable"
	end if
	read : tf, int@(addr(symbol.nSymbols))
	read : tf, treePT@(addr(symbol.symbols (1))) : symbol.nSymbols * size (treePT)
	read : tf, mn
	if mn not= MAGNUM then
	    synchError (7)
	end if
	
	% 8. rules
	if options.option (verbose_p) then
	    put : 0, "Rules"
	end if
	read : tf, int@(addr(rule.nRules))
	for i : 1 .. rule.nRules
	    bind var r to ruleT@(addr(rule.rules (i)))
	    read : tf, r.name, r.target, r.skipName, 
		r.patternTP, r.replacementTP, r.kind, 
		r.starred, r.isCondition, r.defined, r.called, r.skipRepeat
	    r.prePattern.partsBase := rule.rulePartCount
	    read : tf, r.prePattern.nparts
	    for pp : 1 .. r.prePattern.nparts
		read : tf, partDescriptor@(addr(rule.ruleParts (r.prePattern.partsBase + pp))) : size (partDescriptor)
	    end for
	    int@(addr(rule.rulePartCount)) += r.prePattern.nparts
	    r.postPattern.partsBase := rule.rulePartCount
	    read : tf, r.postPattern.nparts
	    for pp : 1 .. r.postPattern.nparts
		read : tf, partDescriptor@(addr(rule.ruleParts (r.postPattern.partsBase + pp))) : size (partDescriptor)
	    end for
	    int@(addr(rule.rulePartCount)) += r.postPattern.nparts
	    r.localVars.localBase := rule.ruleLocalCount
	    read : tf, r.localVars.nformals, r.localVars.nprelocals, r.localVars.nlocals
	    for lc : 1 .. r.localVars.nlocals
		read : tf, localInfoT@(addr(rule.ruleLocals (r.localVars.localBase + lc))) : size (localInfoT)
	    end for
	    int@(addr(rule.ruleLocalCount)) += r.localVars.nlocals
	    r.calledRules.callBase := 0
	    r.calledRules.ncalls := 0
	end for
	read : tf, mainRule
	read : tf, mn
	if mn not= MAGNUM then
	    synchError (8)
	end if
	
	% 9. options
	if options.option (verbose_p) then
	    put : 0, "Options"
	end if
	read : tf, boolean@(addr(options.option)) : size (options.option)
	var len : nat1 
	read : tf, len 
	read : tf, string@(addr(options.txlLibrary)) : len + 1
	read : tf, int@(addr(options.outputLineLength))
	read : tf, int@(addr(options.indentIncrement))
	read : tf, len 
	read : tf, string@(addr(options.optionIdChars)) :len + 1
	for i : 1 .. len
	    const c : char := type (char4096, options.optionIdChars) (i)
	    charset.addIdChar (c, true)
	end for
	read : tf, len 
	read : tf, string@(addr(options.optionSpChars)) : len  + 1
	for i : 1 .. len
	    const c : char := type (char4096, options.optionSpChars) (i)
	    charset.addSpaceChar (c, true)
	end for
	var c : char
	read : tf, c
	charset.setEscapeChar (c, true)
	read : tf, c
	charset.setEscapeChar (c, true)
	read : tf, mn
	if mn not= MAGNUM then
	    synchError (9)
	end if
	
	% 10. EOF
	if options.option (verbose_p) then
	    put : 0, "EOF"
	end if
	read : tf, mn
	if mn not= MAGNUM then
	    synchError (10)
	end if
	close : tf
    end Restore

#else

    % Standalone TXL app version - bytecode is stored in C program's 'TXL_CTXL' byte array 

    % Bytecode array access routines 
    external var TXL_CTXL: addressint

    var ctxlptr := 0
    type bytearray : array 0 .. 999999999 of nat1

    type dummyint : int
    const intsize := size (dummyint)
    type dummynat2 : nat2
    const nat2size := size (dummynat2)
    type dummyboolean : boolean
    const booleansize := size (dummyboolean)

    procedure ctxlinitialize 
	ctxlptr := 0
    end ctxlinitialize

    procedure ctxlgetint (target : addressint)
	for b : 0 .. intsize - 1
	    bytearray@(target) (b) := bytearray@(TXL_CTXL) (ctxlptr)
	    ctxlptr += 1
	end for
    end ctxlgetint

    procedure ctxlgetnat2 (target : addressint)
	for b : 0 .. nat2size - 1
	    bytearray@(target) (b) := bytearray@(TXL_CTXL) (ctxlptr)
	    ctxlptr += 1
	end for
    end ctxlgetnat2

    procedure ctxlgetboolean (target : addressint)
	for b : 0 .. booleansize - 1
	    bytearray@(target) (b) := bytearray@(TXL_CTXL) (ctxlptr)
	    ctxlptr += 1
	end for
    end ctxlgetboolean

    procedure ctxlgetbyte (target : addressint)
	nat1@(target) := bytearray@(TXL_CTXL) (ctxlptr)
	ctxlptr += 1
    end ctxlgetbyte

    procedure ctxlgetbytes (target : addressint, nbytes : int)
	for b : 0 .. nbytes - 1
	    bytearray@(target) (b) := bytearray@(TXL_CTXL) (ctxlptr)
	    ctxlptr += 1
	end for
    end ctxlgetbytes

    body procedure Restore % (fromfile : string)
	% Actual bytecode restore using the above
	var mn : int
	ctxlinitialize
	
	% 0. Header
	ctxlgetint (addr (mn))
	if mn not= MAGNUM then
	    error ("", "Load file is not a compiled TXL object file", FATAL, 402)
	end if
	ctxlgetint (addr (mn))
	if mn not= options.txlSize then
	    error ("", "TXL size does not match compiled size", INTERNAL_FATAL, 403)
	end if
	var rlen : nat1
	ctxlgetbyte (addr (rlen))
	var storedversion : string 
	ctxlgetbytes (addr (storedversion), rlen + 1)
	if storedversion not= version then
	    error ("", "TXL object file was compiled by a different version of TXL", FATAL, 404)
	end if
	ctxlgetbyte (addr (rlen))
	ctxlgetbytes (addr (options.txlSourceFileName), rlen + 1)
	ctxlgetint (addr (mn))
	if mn not= MAGNUM then
	    synchError (0)
	end if
	
	% 1. compoundTokens and commentTokens
	ctxlgetint (addr (scanner.nCompounds))
	for i : 1 .. scanner.nCompounds
	    var len : nat1 
	    ctxlgetbyte (addr (len))
	    int@(addr(scanner.compoundTokens (i).length_)) := len
	    ctxlgetbytes ( addr (scanner.compoundTokens (i).literal), len + 1)
	end for
	for i : chr (0) .. chr (255)
	    assert maxCompoundTokens <= 255
	    var ci : nat1 
	    ctxlgetbyte (addr (ci))
	    int@(addr(scanner.compoundIndex (i))) := ci
	end for
	ctxlgetint (addr (scanner.nComments))
	ctxlgetbytes (addr (scanner.commentStart (1)), scanner.nComments * size (tokenT))
	ctxlgetbytes (addr (scanner.commentEnd (1)), scanner.nComments * size (tokenT))
	ctxlgetint (addr (mn))
	if mn not= MAGNUM then
	    synchError (1)
	end if
	
	% 2. keywords
	ctxlgetint (addr (scanner.nKeys))
	ctxlgetbytes (addr (scanner.keywordTokens (1)), scanner.nKeys * size (tokenT))
	ctxlgetint (addr (mn))
	if mn not= MAGNUM then
	    synchError (2)
	end if
	
	% 3. tokenPatterns
	ctxlgetint (addr (scanner.nPatterns))
	for i : 1 .. scanner.nPatterns
	    bind var tp to scanner.patternEntryT@(addr(scanner.tokenPatterns (i)))
	    ctxlgetbytes (addr (tp.kind), size (kindT))
	    ctxlgetbytes (addr (tp.name), size (tokenT))
	    ctxlgetint (addr (tp.next))
	    var len : int2 
	    ctxlgetbytes (addr (len), size (len))
	    tp.length_ := len
	    % read : tf, tp.pattern : len + 1 % (sic)
	    % ctxlgetbytes (addr (tp.pattern), len + 1)
	    for j : 1 .. len + 1
		var pj : int2
		ctxlgetbytes (addr (pj), size (pj))
		tp.pattern (j) := pj
	    end for
	    %
	end for
	for i : chr (0) .. chr (255)
	    assert maxTokenPatterns <= 255
	    var pi : nat1 
	    ctxlgetbyte (addr (pi))
	    int@(addr(scanner.patternIndex (i))) := pi
	end for
	ctxlgetint (addr (scanner.patternNLCommentIndex))
	ctxlgetint (addr (scanner.nPatternLinks))
	for i : 1 .. scanner.nPatternLinks
	    assert maxTokenPatterns <= 255
	    var pi : nat1 
	    ctxlgetbyte (addr (pi))
	    int@(addr(scanner.patternLink (i))) := pi
	end for
	ctxlgetbytes (addr (kindType (ord (firstUserTokenKind))),
	    (ord (lastUserTokenKind) - ord (firstUserTokenKind) + 1) * size (tokenT))
	ctxlgetint (addr (mn))
	if mn not= MAGNUM then
	    synchError (3)
	end if
	
	% 4. idents
	ctxlgetint (addr (ident.nIdentChars))
	ctxlgetbytes (addr (ident.identText (1)), ident.nIdentChars)
	ctxlgetint (addr (ident.nIdents))
	loop
	    var i : int
	    ctxlgetint (addr (i))
	    exit when i = MAGNUM
	    var idti : int
	    ctxlgetint (addr (idti))
	    addressint@(addr(ident.idents (i))) := addr (ident.identText (1)) + idti
	    ctxlgetbyte (addr (ident.identKind (i)))
	end loop
	if mn not= MAGNUM then
	    synchError (4)
	end if
	
	% 5. trees
	ctxlgetint (addr (tree.treeCount))
	ctxlgetint (addr (tree.firstUserTree))
	ctxlgetbytes (addr (tree.trees (tree.firstUserTree)),
	    (tree.treeCount - tree.firstUserTree + 1) * size (parseTreeT))
	ctxlgetint (addr (mn))
	if mn not= MAGNUM then
	    synchError (5)
	end if
	
	% 6. kids
	ctxlgetint (addr (tree.kidCount))
	ctxlgetint (addr (tree.firstUserKid))
	ctxlgetbytes (addr (tree.kids (tree.firstUserKid)),
	    (tree.kidCount - tree.firstUserKid + 1) * size (treePT))
	ctxlgetint (addr (inputGrammarTreeTP))
	ctxlgetint (addr (mn))
	if mn not= MAGNUM then
	    synchError (6)
	end if
	
	% 7. symbols
	ctxlgetint (addr (symbol.nSymbols))
	ctxlgetbytes (addr (symbol.symbols (1)), symbol.nSymbols * size (treePT))
	ctxlgetint (addr (mn))
	if mn not= MAGNUM then
	    synchError (7)
	end if
	
	% 8. rules
	ctxlgetint (addr (rule.nRules))
	for i : 1 .. rule.nRules
	    bind var r to ruleT@(addr(rule.rules (i)))
	    ctxlgetbytes (addr (r.name), size (tokenT))
	    ctxlgetbytes (addr (r.target), size (tokenT))
	    ctxlgetbytes (addr (r.skipName), size (tokenT))
	    ctxlgetint (addr (r.patternTP))
	    ctxlgetint (addr (r.replacementTP))
	    ctxlgetbytes (addr (r.kind), size (ruleKind))
	    ctxlgetboolean (addr (r.starred))
	    ctxlgetboolean (addr (r.isCondition))
	    ctxlgetboolean (addr (r.defined))
	    ctxlgetboolean (addr (r.called))
	    ctxlgetboolean (addr (r.skipRepeat))
	    r.prePattern.partsBase := rule.rulePartCount
	    ctxlgetnat2 (addr (r.prePattern.nparts))
	    for pp : 1 .. r.prePattern.nparts
		ctxlgetbytes (addr (rule.ruleParts (r.prePattern.partsBase + pp)), size (partDescriptor))
	    end for
	    int@(addr(rule.rulePartCount)) += r.prePattern.nparts
	    r.postPattern.partsBase := rule.rulePartCount
	    ctxlgetnat2 (addr (r.postPattern.nparts))
	    for pp : 1 .. r.postPattern.nparts
		ctxlgetbytes (addr (rule.ruleParts (r.postPattern.partsBase + pp)), size (partDescriptor))
	    end for
	    int@(addr(rule.rulePartCount)) += r.postPattern.nparts
	    r.localVars.localBase := rule.ruleLocalCount
	    ctxlgetnat2 (addr (r.localVars.nformals))
	    ctxlgetnat2 (addr (r.localVars.nprelocals))
	    ctxlgetnat2 (addr (r.localVars.nlocals))
	    for lc : 1 .. r.localVars.nlocals
		ctxlgetbytes (addr (rule.ruleLocals (r.localVars.localBase + lc)), size (localInfoT))
	    end for
	    int@(addr(rule.ruleLocalCount)) += r.localVars.nlocals
	    r.calledRules.callBase := 0
	    r.calledRules.ncalls := 0
	end for
	ctxlgetint (addr (mainRule))
	ctxlgetint (addr (mn))
	if mn not= MAGNUM then
	    synchError (8)
	end if
	
	% 9. options
	const oldoptions := options.option
	ctxlgetbytes (addr (options.option), size (options.option))
	for i : firstOption .. lastOption
	    options.setOption (i, options.option (i) or oldoptions (i))
	end for
	var len : nat1 
	ctxlgetbyte (addr (len))
	ctxlgetbytes (addr (options.txlLibrary), len + 1)
	const oldOutputLineLength := options.outputLineLength
	ctxlgetint (addr (options.outputLineLength))
	if oldoptions (width_p) then
	    options.setOutputLineLength (oldOutputLineLength)
	end if
	const oldIndentIncrement := options.indentIncrement
	ctxlgetint (addr (options.indentIncrement))
	if oldoptions (indent_p) then
	    options.setIndentIncrement (oldIndentIncrement)
	end if
	ctxlgetbyte (addr (len))
	ctxlgetbytes (addr (options.optionIdChars), len  + 1)
	for i : 1 .. len
	    const c : char := type (char4096, options.optionIdChars) (i)
	    charset.addIdChar (c, true)
	end for
	ctxlgetbyte (addr (len))
	ctxlgetbytes (addr (options.optionSpChars), len  + 1)
	for i : 1 .. len
	    const c : char := type (char4096, options.optionSpChars) (i)
	    charset.addSpaceChar (c, true)
	end for
	var c : char
	ctxlgetbyte (addr (c))
	charset.setEscapeChar (c, true)
	ctxlgetbyte (addr (c))
	charset.setEscapeChar (c, true)
	ctxlgetint (addr (mn))
	if mn not= MAGNUM then
	    synchError (9)
	end if
	
	% 10. EOF
	ctxlgetint (addr (mn))
	if mn not= MAGNUM then
	    synchError (10)
	end if
    end Restore
#end if

end LoadStore
