% OpenTxl Version 11 parser
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

% The TXL parser.
% Uses a top-down, recursive descent algorithm to parse the array of tokens produced by the scanner 
% according to the TXL or object language grammar to produce a parse tree instance of the grammar tree.
% The algorithm walks the grammar tree matching input tokens to terminal nodes (literals, ids, numbers, ...), 
% sequences to order nodes, and alternatives to choose nodes. When a sequence element fails to match,
% backtracking retries previous element choices one by one to exhaustively explore alternatives.
% Backtracking is artificially limited to help avoid lengthy parses.

% Modification Log

% v11.0	Initial revision, revised from FreeTXL 10.8b (c) 1988-2022 Queen's University at Kingston
%	Remodularized to aid maintenance and understanding.

parent "txl.t"

stub module parser

    import 
	var tree, var ident, charset, 
	inputTokens, var currentTokenIndex, var failTokenIndex, lastTokenIndex, 
	error, parseInterruptError, parseStackError, fileNames, stackBase,
	options, kindType
	#if PROFILER then
	    , var symbol
	#end if

    export 
	parseVarOrExpProc, initializeParse, parse

    type parseVarOrExpProc : 
	procedure parseVarOrExp (patternTokensTP : treePT, localVarsAddr : addressint, 
		productionTP : treePT, var parseTP : treePT,
		var isVarOrExp : boolean, var varOrExpMatches : boolean)

    procedure initializeParse (context : string, isMain, isPattern, isTxl : boolean, localVarsAddr : addressint, 
	parseVarOrExp : parseVarOrExpProc)

    procedure parse (productionTP : treePT, var parseTP : treePT)

end parser

body module parser

    % Current input token
    var nextToken, nextRawToken : tokenT 
    var nextTokenKind : kindT

    % Parse stack for detecting infinite parses -
    % these days we use it only for choices (choose, leftchoose)
    var parseDepth := 0
    % parseStack (0..parseDepth) are the names of the choices we are currently parsing
    var parseStack : array 0 .. maxParseDepth of tokenT
    % parseTokenIndex (0..parseDepth) are the handles of the last token accepted by each choice
    % parseTokenIndex (d) = K means the choice accepted the token with handle K
    % parseTokenIndex (d) = 0 means we don't know for sure whether the choice has accepted any tokens
    var parseTokenIndex : array 0 .. maxParseDepth of tokenIndexT
    
    % If we give up at the same point twice, we are likely in permanent trouble.
    % So we keep track, and give up permanently the second time.
    var maxRecursionTokenIndex := -1

    % Is this txl we are parsing?
    var txlParse := false

    % Is this a pattern we are parsing?
    var patternParse := false

    % Symbol table of pattern parse
    var patternVarsAddr : addressint

    % Description of our current parsing context, for error messages
    var parseContext := ""

    % Procedure to parse TXL variable bindings and references in patterns and replacements
    var parsePatternVarOrExp : parseVarOrExpProc
    
    % Implementation of backtrack fences [!]
    var fenceState : boolean := false
    
    % Hard limit to prevent infinite parses
    var parseCycles := 0
    
    % Implementation of [push] / [pop] - JRC 22.9.07
    var matchStack : array 0 .. maxParseDepth of tokenT
    var matchTop := 0
    
    proc matchPush (token : tokenT)
        assert matchTop < maxParseDepth 
	matchTop += 1
	matchStack (matchTop) := token
    end matchPush
	        
    proc matchPop 
        pre matchTop > 0 
	matchTop -= 1
    end matchPop
	        
    function matchToken : tokenT
        if matchTop > 0 then
	    result matchStack (matchTop)
	else
	    result NOT_FOUND
	end if
    end matchToken
    
    #if PROFILER then
	external function clock : nat
    
    	% We only want to profile the main parse
	var mainParse := false
	
        % Cycle counts 
	var backtrackCycles : nat
	
	% Nonterminal symbol stats 
	type symbolStatisticsT :
	    record
		calls : nat
		matches : nat
		parsecycles : nat
		backtrackcycles : nat
		time : nat
		trees : nat
		kids : nat
	    end record
	    
	var symbolStatistics : array 1 .. maxSymbols of symbolStatisticsT
	var oldStatistics, startStatistics : array 0 .. maxParseDepth of symbolStatisticsT
    #end if


    body procedure initializeParse % (context : string, isMain, isPattern, isTxl : boolean, 
	    % localVarsAddr : addressint, parseVarOrExp : parseVarOrExpProc)

	% Tokens to be parsed are in inputTokens array - begin at the beginning
	currentTokenIndex := 1
	nextToken := inputTokens (currentTokenIndex).token
	nextRawToken := inputTokens (currentTokenIndex).rawtoken
	nextTokenKind := inputTokens (currentTokenIndex).kind
	failTokenIndex := 1

	% Initialize the parse stack
	parseDepth := 0
	parseStack (parseDepth) := undefined_T
	parseTokenIndex (parseDepth) := 1
	maxRecursionTokenIndex := -1

	% What are we parsing?
	parseContext := context
	patternParse := isPattern
	txlParse := isTxl

	% If we're parsing a pattern or replacement, 
	% we need the local variables and local variable reference parser from the rule compiler
	patternVarsAddr := localVarsAddr
	parsePatternVarOrExp := parseVarOrExp

	% Keep track of parse limit
	parseCycles := 0
	#if PROFILER then
	    backtrackCycles := 0
	    mainParse := isMain
	#end if
    end initializeParse


    procedure accept
	pre currentTokenIndex < lastTokenIndex
	currentTokenIndex += 1
	if currentTokenIndex > failTokenIndex then
	    failTokenIndex := currentTokenIndex
	end if
	% Optimize subscripting of input tokens arrays
	nextToken := inputTokens (currentTokenIndex).token
	nextRawToken := inputTokens (currentTokenIndex).rawtoken
	nextTokenKind := inputTokens (currentTokenIndex).kind
    end accept


    procedure backup
	pre currentTokenIndex > 1
	currentTokenIndex -= 1
	% Optimize subscripting of input tokens arrays
	nextToken := inputTokens (currentTokenIndex).token
	nextRawToken := inputTokens (currentTokenIndex).rawtoken
	nextTokenKind := inputTokens (currentTokenIndex).kind
    end backup


    procedure backup_tree (subtreeTP : treePT)
    	% Back up over all of the tokens in an entire parse tree.
	% Order is not important, just the total number.
	
	case tree.trees (subtreeTP).kind of
	    label kindT.choose :
		% optimize by skipping choose chains -- JRC 4.1.94
		var chainTP := tree.kids (tree.trees (subtreeTP).kidsKP)
		loop
		    exit when tree.trees (chainTP).kind not= kindT.choose 
		    chainTP := tree.kids (tree.trees (chainTP).kidsKP)
		end loop
		backup_tree (chainTP)
	
	    label kindT.order :
		var subtreeKidsKP := tree.trees (subtreeTP).kidsKP
		for : 1 .. tree.trees (subtreeTP).count 
		    backup_tree (tree.kids (subtreeKidsKP))
		    subtreeKidsKP += 1
		end for
	
	    label kindT.repeat :
		var subtreeKidsKP := tree.trees (subtreeTP).kidsKP
		assert subtreeKidsKP not= nilKid
		loop
		    backup_tree (tree.kids (subtreeKidsKP))
		    exit when tree.trees (tree.kids (subtreeKidsKP + 1)).kind >= firstSpecialKind	 % tail is pattern variable
		    	or tree.trees (tree.kids (subtreeKidsKP + 1)).kind = kindT.empty
		    subtreeKidsKP := tree.trees (tree.kids (subtreeKidsKP + 1)).kidsKP
		end loop
	
	    label kindT.list :
		var subtreeKidsKP := tree.trees (subtreeTP).kidsKP
		assert subtreeKidsKP not= nilKid
		loop
		    backup_tree (tree.kids (subtreeKidsKP))
		    exit when tree.trees (tree.kids (subtreeKidsKP + 1)).kind >= firstSpecialKind	 % tail is pattern variable
		    	or tree.trees (tree.kids (subtreeKidsKP + 1)).kind = kindT.empty
		        or tree.trees (tree.kids (subtreeKidsKP + 1)).kind = kindT.list 
		            and tree.trees (tree.kids (tree.trees (tree.kids (subtreeKidsKP + 1)).kidsKP + 1)).kind = kindT.empty
		    assert currentTokenIndex > 0 
		    backup  % the separator terminal
		    subtreeKidsKP := tree.trees (tree.kids (subtreeKidsKP + 1)).kidsKP
		end loop
	
	    label kindT.empty :
		% do nothing
	
	    label kindT.srclinenumber, kindT.srcfilename :	% JRC 14.12.07
		% do nothing
		
	    label kindT.literal, kindT.stringlit, kindT.charlit, kindT.token,
		    kindT.id, kindT.upperlowerid, kindT.upperid,
		    kindT.lowerupperid, kindT.lowerid, kindT.number,
		    kindT.floatnumber, kindT.decimalnumber, kindT.integernumber,
		    kindT.key, kindT.comment, kindT.space, kindT.newline,
		    kindT.usertoken1, kindT.usertoken2, kindT.usertoken3, kindT.usertoken4, kindT.usertoken5, 
		    kindT.usertoken6, kindT.usertoken7, kindT.usertoken8, kindT.usertoken9, kindT.usertoken10,
		    kindT.usertoken11, kindT.usertoken12, kindT.usertoken13, kindT.usertoken14, kindT.usertoken15, 
		    kindT.usertoken16, kindT.usertoken17, kindT.usertoken18, kindT.usertoken19, kindT.usertoken20,
		    kindT.usertoken21, kindT.usertoken22, kindT.usertoken23, kindT.usertoken24, kindT.usertoken25, 
		    kindT.usertoken26, kindT.usertoken27, kindT.usertoken28, kindT.usertoken29, kindT.usertoken30 :
		% it's a terminal - back up over it
		backup
		
	    label kindT.firstTime, kindT.subsequentUse, kindT.expression, kindT.lastExpression :
		% pattern variable - back up over it
		backup

		% If the variable we are backing up over was a binding occurence,
		% undo the binding
		if tree.trees (subtreeTP).kind = kindT.firstTime then
		    localsListT@(patternVarsAddr).nlocals -= 1
		end if
		    
	    label :
		error ("", "Fatal TXL error in backup_tree", INTERNAL_FATAL, 121)
	end case
    end backup_tree


    function is_empty (subtreeTP : treePT) : boolean
	
	case tree.trees (subtreeTP).kind of
	    label kindT.choose :
		% optimize by skipping choose chains -- JRC 4.1.94
		var chainTP := tree.kids (tree.trees (subtreeTP).kidsKP)
		loop
		    exit when tree.trees (chainTP).kind not= kindT.choose 
		    chainTP := tree.kids (tree.trees (chainTP).kidsKP)
		end loop
		result is_empty (chainTP)
	
	    label kindT.order :
		var subtreeKidsKP := tree.trees (subtreeTP).kidsKP
		for : 1 .. tree.trees (subtreeTP).count 
		    if not is_empty (tree.kids (subtreeKidsKP)) then
		        result false
		    end if
		    subtreeKidsKP += 1
		end for
		result true
	
	    label kindT.repeat :
		var subtreeKidsKP := tree.trees (subtreeTP).kidsKP
		assert subtreeKidsKP not= nilKid
		loop
		    if not is_empty (tree.kids (subtreeKidsKP)) then
		        result false
		    end if
		    exit when tree.trees (tree.kids (subtreeKidsKP + 1)).kind = kindT.empty
		    subtreeKidsKP := tree.trees (tree.kids (subtreeKidsKP + 1)).kidsKP
		end loop
		result true
	
	    label kindT.list :
		const subtreeKidsKP := tree.trees (subtreeTP).kidsKP
		assert subtreeKidsKP not= nilKid
		if not is_empty (tree.kids (subtreeKidsKP)) then
		    result false
		end if
		result tree.trees (tree.kids (subtreeKidsKP + 1)).kind = kindT.empty 
	
	    label kindT.empty :
		result true
	
	    label kindT.srclinenumber, kindT.srcfilename :	% JRC 14.12.07
		result true
	
	    label kindT.literal, kindT.stringlit, kindT.charlit, kindT.token,
		    kindT.id, kindT.upperlowerid, kindT.upperid,
		    kindT.lowerupperid, kindT.lowerid, kindT.number,
		    kindT.floatnumber, kindT.decimalnumber, kindT.integernumber,
		    kindT.key, kindT.comment, kindT.space, kindT.newline,
		    kindT.usertoken1, kindT.usertoken2, kindT.usertoken3, kindT.usertoken4, kindT.usertoken5, 
		    kindT.usertoken6, kindT.usertoken7, kindT.usertoken8, kindT.usertoken9, kindT.usertoken10,
		    kindT.usertoken11, kindT.usertoken12, kindT.usertoken13, kindT.usertoken14, kindT.usertoken15, 
		    kindT.usertoken16, kindT.usertoken17, kindT.usertoken18, kindT.usertoken19, kindT.usertoken20,
		    kindT.usertoken21, kindT.usertoken22, kindT.usertoken23, kindT.usertoken24, kindT.usertoken25, 
		    kindT.usertoken26, kindT.usertoken27, kindT.usertoken28, kindT.usertoken29, kindT.usertoken30 :
		result false

	    label kindT.firstTime, kindT.subsequentUse, kindT.expression, kindT.lastExpression :
		% pattern variable - assume nonempty
		result false
		    
	    label :
		error ("", "Fatal TXL error in is_empty", INTERNAL_FATAL, 122)
	end case
    end is_empty


    function depthOfLastAccept : int
	for decreasing d : parseDepth .. 0
	    if parseTokenIndex (d) < currentTokenIndex and parseTokenIndex (d) not= 0 then
		result d
	    end if
	end for
	result 0
    end depthOfLastAccept


#if not NOCOMPILE then
    procedure trace_enter (productionTP : treePT, retry : boolean)
	put : 0, repeat (".", parseDepth), "?", string@(ident.idents (tree.trees (productionTP).rawname)) ..
	if retry then
	    put : 0, " <-*-> " ..
	end if
	if nextToken = empty_T then
	    put : 0, " EOF"
	else
	    put : 0, " ", string@(ident.idents (nextToken))
	end if
    end trace_enter


    procedure trace_exit (productionTP, parseTP : treePT)
	if parseTP = nilTree then
	    put : 0, repeat (".", parseDepth), "#", string@(ident.idents (tree.trees (productionTP).rawname)) ..
	    if nextToken = empty_T then
		put : 0, " EOF"
	    else
		put : 0, " ", string@(ident.idents (nextToken))
	    end if
	else
	    put : 0, repeat (".", parseDepth), "!", string@(ident.idents (tree.trees (productionTP).rawname))
	end if
    end trace_exit


    procedure dumpparsestack
	put : 0, "=== Parse Stack Dump ==="
	for decreasing i : parseDepth .. 0
	    put : 0, string@(ident.idents (parseStack (i))), " ", parseTokenIndex (i) ..
	    if parseTokenIndex (i) not= 0 then
		put : 0, " ", string@(ident.idents (inputTokens (parseTokenIndex (i)).token)) ..
	    end if
	    put :0, ""
	end for
	put : 0, "=== ==="
    end dumpparsestack
#end if


    var lastEmptyWarningTP := nilTree
    
    
    procedure recursion_error (productionTP : treePT)
	if productionTP not= lastEmptyWarningTP then
	    error ("define '" 
		+ string@(ident.idents (tree.trees (productionTP).name)) + "'",
		"Empty recursion could not be resolved with lookahead '" 
		+ string@(ident.idents (nextRawToken)) + "'"
		+ " after " + intstr (maxLeftRecursion, 1) + " recursions"
		+ " (using pruning heuristic to recover)", WARNING, 123) 
	    #if not NOCOMPILE then
	    if options.option (stack_print_p) then
		dumpparsestack
	    end if
	    #end if
	    lastEmptyWarningTP := productionTP
	end if
    end recursion_error


    procedure maxdepth_error
	error (parseContext, "Maximum parse depth exceeded", DEFERRED, 126)
	#if not NOCOMPILE then
	if options.option (stack_print_p) then
	    dumpparsestack
	end if
	#end if
    end maxdepth_error


    procedure cyclelimit_error
	error (parseContext, "Parse time limit (" + intstr (maxParseCycles, 0) + " cycles) exceeded", DEFERRED, 127)
	#if not NOCOMPILE then
	if options.option (stack_print_p) then
	    dumpparsestack
	end if
	#end if
    end cyclelimit_error


    procedure fatal_error (which : int)
	error (parseContext, "Fatal TXL error " + intstr (which, 0) +" in parse", INTERNAL_FATAL, 128)
	#if not NOCOMPILE then
	if options.option (stack_print_p) then
	    dumpparsestack
	end if
	#end if
    end fatal_error


    forward procedure real_parse (productionTP : treePT, var parseTP : treePT)


    procedure parse_extend (productionTP : treePT, var parseTP : treePT)

	% Bottom-up extension of an existing parse of a left recursive production
	pre tree.trees (productionTP).kind = kindT.order

	const productionKids := tree.trees (productionTP).count
	assert productionKids > 0

	% Recover wasted space if we fail
	const oldKidCount := tree.kidCount
	const oldTreeCount := tree.treeCount

	% Since they are contiguous, we can just run up and down
	% the production kid lists directly!
	const baseProductionKidsKP := tree.trees (productionTP).kidsKP - 1

	% Pre-allocate a chunk of the kids array and use it directly 
	% to fill in kids while trying to find a parse.
	% Link it up later to the new parse tree if we succeed, otherwise free it.
	% If we allocate the kids of the parse contiguously, 
	% we can use them in place too!
	const parseKidsKP := tree.newKids (productionKids)
	const baseParseKidsKP := parseKidsKP - 1

	% Now we parse!
	% If we are trying to optimize a recursion, then we will use the previous
	% parse as kid 1 and start at kid 2.
	
	% Link in our previous parse
	tree.setKidTree (baseParseKidsKP + 1, parseTP)
	% Mark the second item as a first parse
	tree.setKidTree (baseParseKidsKP + 2, nilTree)
	% Start with it
	var kid := 2
	% And with a nil parse tree
	parseTP := nilTree

	% Let's go!
	var retry := false
	loop
	    const oldTokenIndex := currentTokenIndex

	    var kidTP := tree.kids (baseParseKidsKP + kid)
	    real_parse (tree.kids (baseProductionKidsKP + kid), kidTP)
	    tree.setKidTree (baseParseKidsKP + kid, kidTP)

	    if tree.kids (baseParseKidsKP + kid) = nilTree then
		% Retry another match of the previous kid,
		% but don't back up over the original parse we are extending
		kid -= 1
		exit when kid < 2
		retry := true

	    elsif retry => currentTokenIndex not= oldTokenIndex then
		% Go on to the next one
		kid += 1
		exit when kid > productionKids 
		retry := false
		tree.setKidTree (baseParseKidsKP + kid, nilTree) % first try

	    % else
		% Re-parses of an embedded kid that yield the
		% same lookahead are uninteresting since the
		% rest will fail in the same way!
		%  - so just ask for another try of the same kid
	    end if
	end loop

	% We succeed if we made it all the way to the right.
	if kid > productionKids then
	    % Successful extension of existing parse
	    % Build the parent
	    parseTP := tree.newTreeClone (productionTP)	% sets kind, name and nKids
	    % Link in the kids we already sneakily allocated
	    % and filled in directly back there
	    tree.setKids (parseTP, parseKidsKP)
	else
	    % Failed to extend the parse
	    parseTP := nilTree
	    % Recover wasted space
	    if tree.allocationStrategy = simple then
		tree.setTreeCount (oldTreeCount)
		tree.setKidCount (oldKidCount)
	    end if
	end if
    end parse_extend


    % Utility routines to avoid causing string temporaries in the highly recursive real_parse

    procedure installNumber (number : int, kind : kindT, var name : tokenT)  
	name := ident.install (intstr (number, 1), kind)
    end installNumber

    procedure installAsId (stringname : tokenT, var idname : tokenT)
        idname := ident.install (string@(ident.idents (stringname))(2..*-1), kindT.id)
    end installAsId


   body procedure real_parse % (productionTP : treePT, var parseTP : treePT)

	% INPUT:
	%    productionTP - 	the target production
	%    parseTP -	either 	1) nil, or
	%			2) a previous parse yeilding the target
	% OUTPUT:
	%    parseTP -	either 	1) a parse yeilding the target production, or
	%			2) nil
	%
	% If input parseTP is nil, then output parseTP is the first possible parse.
	% If input parseTP is a previous parse, the output parseTP is the next possible parse.
	% In either case, if the parse is not possible then output parseTP will be nil.

	% **************************************************************************
	% NOTE: Since this routine is very highly recursive, it is desirable
	% to minimize the amount of local storage in order to avoid stack exhaustion.
	% In particular, string operations should not be done in this routine since 
	% they make local string temporaries that eat stack space. 
	% For this reason all multi-use local variables have been gathered here.
	% **************************************************************************

	% Keep all multi-use vars and consts here - to keep track of local space
	var parseKidTP : treePT
	var parseKidsKP, productionKidsKP, baseProductionKidsKP, baseParseKidsKP : kidPT
	var oldKidCount, oldTreeCount, productionKids, kidLastTime, oldMatchTop : int
	var oldTokenIndex : tokenIndexT
	#if not NOCOMPILE then
	    var isVarOrExp, varOrExpMatches : boolean := false 
	#end if
	var productionKind := tree.trees (productionTP).kind
	var retry : boolean 

	% Stack use limitation - to avoid crashes
	if stackBase - addr (retry) > maxStackUse then 
	    quit : stackLimitReached
	end if

	% Keep track of number of parse cycles
	parseCycles += 1 
	if parseCycles > maxParseCycles then
	    cyclelimit_error
	    quit : cycleLimitReached
	end if

	#if not NOCOMPILE then
	if options.option (tree_print_p) then
	    trace_enter (productionTP, parseTP not= nilTree)
	end if
	#end if

	#if not NOCOMPILE then

	    if patternParse then
		% We're parsing a TXL pattern or replacement

		% See if we're backing up over a variable
		if parseTP not= nilTree and
			(tree.trees (parseTP).kind = kindT.expression
			    or tree.trees (parseTP).kind = kindT.firstTime
			    or tree.trees (parseTP).kind = kindT.subsequentUse) then

		    % New heuristic check for infinite parse of variable
		    % JRC 19.12.94
		    if parseDepth > lastTokenIndex*2 then
			% We've failed to find a parse even after extending
			% twice as deep as we ought to have to - so backup 
			% and declare failure.
			
			backup

			% If the variable we are backing up over was a binding occurence,
			% undo the binding
			if tree.trees (parseTP).kind = kindT.firstTime then
			    localsListT@(patternVarsAddr).nlocals -= 1
			end if

			% Now fail
			parseTP := nilTree
			
			#if not NOCOMPILE then
			if options.option (tree_print_p) then
	    		    trace_exit (productionTP, parseTP)
			end if
			#end if

			return
		    end if

		    % Retrying a variable match -
		    %   what we do is look for a deeper match first, before coming back up.
		    % We can do that by fooling the parse algorithm into believing
		    % that we are trying the first match of a variable that doesn't match
		    % at this level.

		    % Note that we don't want to do this if the variable is matched
		    % to a leftchoose, since in that case we try embedding it directly.
		    % JRC 10.11.94

		    if productionKind = kindT.leftchoose then
			% So simply pass it on to the regular backtrack strategy.
			isVarOrExp := true
			varOrExpMatches := true

		    else
			% In all other cases we follow the old strategy
			
			backup

			% If the variable we are backing up over was a binding occurence,
			% undo the binding
			if tree.trees (parseTP).kind = kindT.firstTime then
			    localsListT@(patternVarsAddr).nlocals -= 1
			end if

			% Mark it as the first try of a variable that doesn't match
			parseTP := nilTree
			isVarOrExp := true
			varOrExpMatches := false
		    end if
		end if

		% If this is the first try, see if we have a TXL variable
		if parseTP = nilTree then
		    % If we don't know yet, see if we are dealing with a TXL variable 
		    if (not isVarOrExp) and (nextTokenKind = kindT.id or nextTokenKind = kindT.key) then
			% Could be a TXL variable
			const oldnlocals := localsListT@(patternVarsAddr).nlocals
    
			parsePatternVarOrExp (inputTokens (currentTokenIndex).tree, patternVarsAddr, 
			    productionTP, parseTP, isVarOrExp, varOrExpMatches)
    
			% If it's not going to match, then don't bind it now
			if isVarOrExp and not varOrExpMatches then
			    localsListT@(patternVarsAddr).nlocals := oldnlocals
			end if
		    end if
    
		    if isVarOrExp then 
			% a TXL variable ...
			if varOrExpMatches then
			    % ... that matches the production exactly
			    accept
			
			    #if not NOCOMPILE then
			    if options.option (tree_print_p) then
				trace_exit (productionTP, parseTP)
			    end if
			    #end if

			    return
    
			elsif productionKind >= firstLiteralKind then
			    % ... that does not match a terminal - nothing to do but fail
			    parseTP := nilTree
			
			    #if not NOCOMPILE then
			    if options.option (tree_print_p) then
				trace_exit (productionTP, parseTP)
			    end if
			    #end if

			    return
			end if
		    end if
    
		    % At this point, either it is not a TXL variable, 
		    % or it is a TXL variable that does not match an empty, order, or choose,
		    % in which case we must look further for a match to it.
		    assert isVarOrExp => not varOrExpMatches
		end if
	    end if

	#end if


	% Statistical profile of production kinds in typical large Legasys run
	
	% kind                first try              retry             combined
	% ----                ---------              -----             --------
	% literal          1643250   33.0%      102011    6.6%     1745261   26.8%
	% empty            1350270   27.2%     1216506   78.4%     2566776   39.3%
	% order            1115541   22.4%       30119    1.9%     1145660   17.6%
	% choose            504255   10.1%      132162    8.5%      636417    9.8%
	% generaterepeat    156275    3.1%       41153    2.7%      197428    3.0%
	% id                132517    2.7%       15609    1.0%      148126    2.3%
	% repeat             27520    0.6%       13754    0.9%       41274    0.6%
	% stringlit          17953    0.4%           0      0%       17953    0.3%
	% charlit            15996    0.3%           0      0%       15996    0.2%
	% number              8614    0.2%          77      0%        8691    0.1%
	% leftchoose             0      0%           0      0%           0      0%
	% generatelist           0      0%           0      0%           0      0%
	% list                   0      0%           0      0%           0      0%
	% all others             0      0%           0      0%           0      0%
	

	% Shortcut for the most common cases
	if productionKind = kindT.empty then
	    if parseTP = nilTree then
		% empty - first time we just match it.
		parseTP := productionTP
			
		#if not NOCOMPILE then
		if options.option (tree_print_p) then
		    trace_exit (productionTP, parseTP)
		end if
		#end if

		return
	    else
		% Backtracking over a match of empty!!
		% If this is a keeper, we can't back it up.
		if tree.trees (parseTP).name = KEEP_T then
		    quit : cutPoint
		end if
		
		% If this is a fence [!], then we have failed this sequence
		if tree.trees (parseTP).name = FENCE_T then
		    fenceState := true
		end if
		
		parseTP := nilTree
			
		#if not NOCOMPILE then
		if options.option (tree_print_p) then
		    trace_exit (productionTP, parseTP)
		end if
		#end if

		return
	    end if
	    
	elsif productionKind = kindT.literal then
	    if parseTP = nilTree then
		% Don't care what it is, but it must match exactly
		assert parseTP = nilTree
		if nextTokenKind not= kindT.comment and nextTokenKind not= kindT.empty and
			nextToken = tree.trees (productionTP).name then
		    %  accept
		    if nextRawToken = nextToken then
		    	parseTP := productionTP  % we can always share literals!
		    else
		    	parseTP := tree.newTreeClone (productionTP) % sets kind and name
			tree.setRawName (parseTP, nextRawToken)
		    end if
		    accept
		end if
			
		#if not NOCOMPILE then
		if options.option (tree_print_p) then
		    trace_exit (productionTP, parseTP)
		end if
		#end if

		return
	    else
		% Retrying a terminal - only thing left to do is back up!
		assert currentTokenIndex > 0
		assert tree.trees (parseTP).name = inputTokens (currentTokenIndex - 1).token
		
		parseTP := nilTree
		backup
			
		#if not NOCOMPILE then
		if options.option (tree_print_p) then
		    trace_exit (productionTP, parseTP)
		end if
		#end if

		return
	    end if
	end if


	#if PROFILER then
	    % Keep track of nonterminal symbol statistics
	    bind var oldStats to oldStatistics (parseDepth), 
	    	 var startStats to startStatistics (parseDepth)	
	    var symbolIndex : int
	    if mainParse and tree.trees (productionTP).kind < kindT.empty then
		symbolIndex := symbol.findSymbol (tree.trees (productionTP).name)
		bind var symbolStats to symbolStatistics (symbolIndex)
		oldStats.parsecycles := symbolStats.parsecycles 
		oldStats.backtrackcycles := symbolStats.backtrackcycles 
		oldStats.time := symbolStats.time
		oldStats.trees := symbolStats.trees
		oldStats.kids := symbolStats.kids
		startStats.parsecycles := parseCycles
		startStats.backtrackcycles := backtrackCycles
		startStats.time := clock
		startStats.trees := tree.treeCount
		startStats.kids := tree.kidCount
	    end if
	#end if


	if parseTP = nilTree then

	    % First attempt - not a retry

	    case productionKind of

		label kindT.empty :

		    % empty - first time we just match it.
		    parseTP := productionTP


		label kindT.order :

		    % Parse an order node
		    productionKids := tree.trees (productionTP).count
		    assert productionKids > 0

		    % Recover wasted space if we fail
		    oldKidCount := tree.kidCount
		    oldTreeCount := tree.treeCount

		    % Since they are contiguous, we can just run up and down
		    % the production kid lists directly!
		    baseProductionKidsKP := tree.trees (productionTP).kidsKP - 1

		    % If we allocate the kids of the parse contiguously, 
		    % we can use them in place too!

		    % Pre-allocate a chunk of the kids array and use it directly 
		    % to fill in kids while trying to find a parse.
		    % Link it up later to the new parse tree if we succeed, otherwise free it.
		    parseKidsKP := tree.newKids (productionKids)
		    baseParseKidsKP := parseKidsKP - 1

		    % Now we parse!

		    % If we are trying for the first time, we start with kid 1.
		    retry := false
		    var kid := 1
		    tree.setKidTree (baseParseKidsKP + 1, nilTree)
		    
		    % Let's go!
		    loop
			oldTokenIndex := currentTokenIndex

			var kidTP := tree.kids (baseParseKidsKP + kid)
			real_parse (tree.kids (baseProductionKidsKP + kid), kidTP)
			tree.setKidTree (baseParseKidsKP + kid, kidTP)

			if tree.kids (baseParseKidsKP + kid) = nilTree then
			    % Retry another match of the previous kid
			    kid -= 1
			    exit when kid < 1
			    retry := true
			    
			    % If we backtracked into a fence, we've failed the sequence
			    exit when fenceState
			    
			elsif retry => currentTokenIndex not= oldTokenIndex then
			    % Go on to the next one
			    kid += 1
			    exit when kid > productionKids 
			    retry := false
			    tree.setKidTree (baseParseKidsKP + kid, nilTree) % first try

			% else
			    % Re-parses of an embedded kid that yield the
			    % same lookahead are uninteresting since the
			    % rest will fail in the same way!
			    %  - so just ask for another try of the same kid
			end if
		    end loop

		    % We fail if we're at the left, succeed if we made it all the way to the right.
		    if kid > 0 then
			if not fenceState then
			    % Build the parent
			    parseTP := tree.newTreeClone (productionTP) % sets kind, name and nKids
			    % Link in the kids we already sneakily allocated
			    % and filled in directly back there
			    tree.setKids (parseTP, parseKidsKP)
			else
			    % Hit a fence - we must undo the partial parse and fail
			    loop
			        exit when kid = 0
			        backup_tree (tree.kids (baseParseKidsKP + kid))
				kid -= 1
			    end loop
			    % Failed to get a parse
			    parseTP := nilTree
			    % Recover wasted space
			    if tree.allocationStrategy = simple then
				tree.setTreeCount (oldTreeCount)
				tree.setKidCount (oldKidCount)
			    end if
			end if
		    else
			% Failed to get a parse
			parseTP := nilTree
			% Recover wasted space
			if tree.allocationStrategy = simple then
			    tree.setTreeCount (oldTreeCount)
			    tree.setKidCount (oldKidCount)
			end if
		    end if
		    
		    % Reset the fence flag
		    fenceState := false
		    
		    
		label kindT.choose :

		    % Parse a choose node

		    % Check for infinite parse loop
		    if (parseDepth - depthOfLastAccept) > maxBlindParseDepth then
			% we're deep - better check for an infinite loop!
			var nrepeats := 1
			for decreasing pd : parseDepth .. depthOfLastAccept + 1
			    if parseStack (pd) = tree.trees (productionTP).name then
				nrepeats += 1
			    end if
			end for

			if nrepeats > maxLeftRecursion then
			    % the never-ending story ...
			    if nrepeats > maxLeftRecursion + 1 and maxRecursionTokenIndex = currentTokenIndex then
				% we've already given them one chance ...
				quit : parseTooDeep
			    end if
			    
			    if options.option (verbose_p) then
				recursion_error (productionTP)
			    end if

			    % remember where we caught it
			    maxRecursionTokenIndex := currentTokenIndex

			    parseTP := nilTree
				    
			    #if not NOCOMPILE then
			    if options.option (tree_print_p) then
				trace_exit (productionTP, parseTP)
			    end if
			    #end if

			    return
			end if
		    end if
					    
		    % Check for unsolvable TXL 10.1 parse ambiguity - this is a serious cheat, and I'll never admit to it!
		    if txlParse and nextToken = dotDotDot_T and tree.trees (productionTP).name = TXL_optBar_T
		    	    and currentTokenIndex > 0 and inputTokens (currentTokenIndex - 1).token = bar_T then
		    	parseTP := nilTree
			return
		    end if

		    % Update parse stack 
		    if parseDepth = maxParseDepth then
			maxdepth_error
			quit : parseTooDeep
		    end if

		    parseDepth += 1
		    parseStack (parseDepth) := tree.trees (productionTP).name
		    parseTokenIndex (parseDepth) := currentTokenIndex

		    % Recover wasted space if we fail
		    oldKidCount := tree.kidCount
		    oldTreeCount := tree.treeCount

		    % Total number of choices we have
		    productionKids := tree.trees (productionTP).count

		    % Since production kids are allocated contiguously,
		    % we can walk through them directly in the kids array.
		    productionKidsKP := tree.trees (productionTP).kidsKP

		    % We begin with the first choice
		    parseKidTP := nilTree

		    % Try each alternative until we get a match
		    for kid : 1 .. productionKids

			real_parse (tree.kids (productionKidsKP), parseKidTP)

			if parseKidTP not= nilTree then
			    % Allocate new parse tree and kid
			    parseTP := tree.newTreeClone (productionTP) 
			    tree.setKind (parseTP, kindT.choose)
			    % Link in the kid we managed to parse
			    tree.makeOneKid (parseTP, parseKidTP)
			    % Encode the choice we made in the parse tree, in case we must retry
			    tree.setCount (parseTP, kid)
			    exit
			end if

			% try the next alternative
			productionKidsKP += 1
		    end for

		    if parseKidTP = nilTree then
			parseTP := nilTree
			% Recover wasted space
			if tree.allocationStrategy = simple then
			    tree.setTreeCount (oldTreeCount)
			    tree.setKidCount (oldKidCount)
			end if
		    end if

		    parseDepth -= 1


		label kindT.generaterepeat :

		    % New style generate repeat node
		    % (No need to check for infinite parse loop on repeats)
		    % (Empty repeated items handled automatically now)

		    % update parse stack (for choose/generate nodes only!)
		    parseDepth += 1
		    parseStack (parseDepth) := tree.trees (productionTP).name
		    parseTokenIndex (parseDepth) := currentTokenIndex

		    % The generated item type
		    productionKidsKP := tree.trees (productionTP).kidsKP

		    % We begin with the first choice.
		    % If it fails, then we take the second (empty) choice.
		    % One or the other always succeeds.

		    % Allocate new parse tree and kids
		    parseKidsKP := tree.newKids (2)
		    parseTP := tree.newTreeInit (kindT.repeat, tree.trees (productionTP).name, tree.trees (productionTP).rawname, 2, parseKidsKP)

		    % Recover wasted space if we end up with the empty case
		    oldKidCount := tree.kidCount
		    oldTreeCount := tree.treeCount

		    % No empty items allowed ...
		    oldTokenIndex := currentTokenIndex
		    
		    % Look for a parse of an item
		    loop
			var kidTP := tree.kids (parseKidsKP)
			real_parse (tree.kids (productionKidsKP), kidTP)
			tree.setKidTree (parseKidsKP, kidTP)
			exit when tree.kids (parseKidsKP) = nilTree or currentTokenIndex not= oldTokenIndex 
		    end loop
		    
		    if tree.kids (parseKidsKP) not= nilTree then
			% Got one - now parse a tail
			var kidTP := tree.kids (parseKidsKP + 1)
		        real_parse (productionTP, kidTP)
			tree.setKidTree (parseKidsKP + 1, kidTP)
			assert tree.kids (parseKidsKP + 1) not= nilTree
		    else
			% We failed to get a parse - but the empty case always succeeds
			#if not NOCOMPILE then
			if patternParse then
			    % allow an [empty] variable binding
			    tree.setKidTree (parseKidsKP, emptyTP)
			    var kidTP := tree.kids (parseKidsKP + 1)
			    real_parse (emptyTP, kidTP)
			    tree.setKidTree (parseKidsKP + 1, kidTP)
			    assert tree.kids (parseKidsKP + 1) not= nilTree	% variable or not, we can always parse an [empty}
			else
			#end if
			    tree.setKidTree (parseKidsKP, emptyTP)
			    tree.setKidTree (parseKidsKP + 1, emptyTP)
			#if not NOCOMPILE then
			end if
			#end if
			if tree.allocationStrategy = simple then
			    tree.setTreeCount (oldTreeCount)
			    tree.setKidCount (oldKidCount)
			end if
		    end if

		    parseDepth -= 1


		label kindT.repeat :

		    % New style repeat+ node
		    % (No need to check for infinite parse loop on repeats)
		    % (Empty repeated items handled automatically now)
		    % (Parse stack gets updated for choose nodes only!)

		    % Recover wasted space if we fail
		    oldKidCount := tree.kidCount
		    oldTreeCount := tree.treeCount

		    % The generated item type
		    productionKidsKP := tree.trees (productionTP).kidsKP

		    % We must have an item, otherwise repeat+ fails.

		    % Allocate new parse tree and kids
		    % Name and kind of the parsed node must be the same as for any other repeat!
		    parseKidsKP := tree.newKids (2)
		    parseTP := tree.newTreeInit (kindT.repeat, tree.trees (tree.kids (productionKidsKP + 1)).name, 
			tree.trees (tree.kids (productionKidsKP + 1)).rawname, 2, parseKidsKP)

		    % No empty items allowed ...
		    oldTokenIndex := currentTokenIndex
		    
		    % Look for a parse of an item
		    loop
			var kidTP := tree.kids (parseKidsKP)
			real_parse (tree.kids (productionKidsKP), kidTP)
			tree.setKidTree (parseKidsKP, kidTP)
			exit when tree.kids (parseKidsKP) = nilTree or currentTokenIndex not= oldTokenIndex 
		    end loop
		    
		    if tree.kids (parseKidsKP) not= nilTree then
			% Got one - now parse a tail
			var kidTP := tree.kids (parseKidsKP + 1)
		        real_parse (tree.kids (productionKidsKP + 1), kidTP)
			tree.setKidTree (parseKidsKP + 1, kidTP)
			assert tree.kids (parseKidsKP + 1) not= nilTree
		    else
			% We failed to get a parse - no empty case for repeat+
			parseTP := nilTree
			if tree.allocationStrategy = simple then
			    tree.setTreeCount (oldTreeCount)
			    tree.setKidCount (oldKidCount)
			end if
		    end if


		label kindT.generatelist :

		    % New style generate list node
		    % (No need to check for infinite parse loop on lists)
		    % (Empty listed items handled automatically now)
		    % (Parse stack gets updated for choose nodes only!)

		    % The generated item type
		    productionKidsKP := tree.trees (productionTP).kidsKP

		    % We begin with the first choice.
		    % If it fails, then we take the second (empty) choice.
		    % One or the other always succeeds.

		    % Allocate new parse tree and kids
		    parseKidsKP := tree.newKids (2)
		    parseTP := tree.newTreeInit (kindT.list, tree.trees (productionTP).name, tree.trees (productionTP).rawname, 2, parseKidsKP)

		    % Recover wasted space if we end up with the empty case
		    oldKidCount := tree.kidCount
		    oldTreeCount := tree.treeCount

		    % Look for a parse of an item
		    var kidTP := tree.kids (parseKidsKP)
		    real_parse (tree.kids (productionKidsKP), kidTP)
		    tree.setKidTree (parseKidsKP, kidTP)
		    
		    if tree.kids (parseKidsKP) not= nilTree then
			% Got one - now if we have a separator, parse a tail, otherwise make an empty tail
			if nextTokenKind not= kindT.comment and nextToken = comma_T then
			    % Look for more
			    accept
			    kidTP := tree.kids (parseKidsKP + 1)
			    real_parse (productionTP, kidTP)
			    tree.setKidTree (parseKidsKP + 1, kidTP)
			    assert tree.kids (parseKidsKP + 1) not= nilTree
			    % If the more we got was empty, back off the separator
			    if tree.trees (tree.kids (parseKidsKP + 1)).kind = kindT.list
			    	    and tree.trees (tree.kids (tree.trees (tree.kids (parseKidsKP + 1)).kidsKP + 1)).kind = kindT.empty then
				backup
			    end if
			else
			    % Create an empty tail
		    	    parseKidTP := tree.newTreeInit (kindT.list, tree.trees (productionTP).name, tree.trees (productionTP).rawname, 0, nilKid)
			    tree.makeTwoKids (parseKidTP, emptyTP, emptyTP)
			    tree.setKidTree (parseKidsKP + 1, parseKidTP)
			end if
		    else
			% We failed to get a parse - but the empty case always succeeds
			#if not NOCOMPILE then
			if patternParse then
			    % allow an [empty] variable binding
			    tree.setKidTree (parseKidsKP, emptyTP)
			    kidTP := tree.kids (parseKidsKP + 1)
			    real_parse (emptyTP, kidTP)
			    tree.setKidTree (parseKidsKP + 1, kidTP)
			    assert tree.kids (parseKidsKP + 1) not= nilTree	% variable or not, we can always parse an [empty}
			else
			#end if
			    tree.setKidTree (parseKidsKP, emptyTP)
			    tree.setKidTree (parseKidsKP + 1, emptyTP)
			#if not NOCOMPILE then
			end if
			#end if
			if tree.allocationStrategy = simple then
			    tree.setTreeCount (oldTreeCount)
			    tree.setKidCount (oldKidCount)
			end if
		    end if


		label kindT.list :

		    % New style list+ node
		    % (No need to check for infinite parse loop on lists)
		    % (Empty listed items handled automatically now)
		    % (Parse stack gets updated for choose nodes only!)

		    % Recover wasted space if we fail
		    oldKidCount := tree.kidCount
		    oldTreeCount := tree.treeCount

		    % The generated item type
		    productionKidsKP := tree.trees (productionTP).kidsKP

		    % We must have an item, otherwise list+ fails.

		    % Allocate new parse tree and kids
		    % Name and kind of the parsed node must be the same as for any other list!
		    parseKidsKP := tree.newKids (2)
		    parseTP := tree.newTreeInit (kindT.list, tree.trees (tree.kids (productionKidsKP + 1)).name, 
			tree.trees (tree.kids (productionKidsKP + 1)).rawname, 2, parseKidsKP)

		    % Look for a parse of an item
		    var kidTP := tree.kids (parseKidsKP)
		    real_parse (tree.kids (productionKidsKP), kidTP)
		    tree.setKidTree (parseKidsKP, kidTP)
		    
		    if tree.kids (parseKidsKP) not= nilTree then
			% Got one - now if we have a separator, parse a tail, otherwise make an empty tail
			if nextTokenKind not= kindT.comment and nextToken = comma_T then
			    % Look for more
			    accept
			    kidTP := tree.kids (parseKidsKP + 1)
			    real_parse (tree.kids (productionKidsKP + 1), kidTP)
			    tree.setKidTree (parseKidsKP + 1, kidTP)
			    assert tree.kids (parseKidsKP + 1) not= nilTree
			    % If the more we got was empty, back off the separator
			    if tree.trees (tree.kids (parseKidsKP + 1)).kind = kindT.list
			    	    and tree.trees (tree.kids (tree.trees (tree.kids (parseKidsKP + 1)).kidsKP + 1)).kind = kindT.empty then
				backup
			    end if
			else
			    % Create an empty tail
		    	    parseKidTP := tree.newTreeInit (kindT.list, tree.trees (tree.kids (productionKidsKP + 1)).name, 
				tree.trees (tree.kids (productionKidsKP + 1)).rawname, 0, nilKid)
			    tree.makeTwoKids (parseKidTP, emptyTP, emptyTP) 
			    tree.setKidTree (parseKidsKP + 1, parseKidTP)
			end if
		    else
			% We failed to get a parse - no empty case for list+
			parseTP := nilTree
			if tree.allocationStrategy = simple then
			    tree.setTreeCount (oldTreeCount)
			    tree.setKidCount (oldKidCount)
			end if
		    end if


		label kindT.leftchoose :

		    % Optimized direct left recursion node

		    % (No need to check for infinite parse loop for optimized left recursions)

		    % Update parse stack 
		    if parseDepth = maxParseDepth then
			maxdepth_error
			quit : parseTooDeep
		    end if

		    parseDepth += 1
		    parseStack (parseDepth) := tree.trees (productionTP).name
		    parseTokenIndex (parseDepth) := currentTokenIndex 

		    % Recover wasted space if we fail
		    oldKidCount := tree.kidCount
		    oldTreeCount := tree.treeCount

		    % Since production kids are allocated contiguously,
		    % we can walk through them directly in the kids array.
		    productionKidsKP := tree.trees (productionTP).kidsKP

		    % We try only the first choice for optimized left recursive productions
		    parseKidTP := nilTree

		    real_parse (tree.kids (productionKidsKP), parseKidTP)

		    if parseKidTP not= nilTree then
			% Allocate new parse tree and kid
			parseTP := tree.newTreeClone (productionTP) 
			tree.setKind (parseTP, kindT.choose)
			% Link in the kid we managed to parse
			tree.makeOneKid (parseTP, parseKidTP)
			% Encode the choice we made in the parse tree, in case we must retry
			tree.setCount (parseTP, 1)
		    else
			parseTP := nilTree
			% Recover wasted space
			if tree.allocationStrategy = simple then
			    tree.setTreeCount (oldTreeCount)
			    tree.setKidCount (oldKidCount)
			end if
		    end if

		    parseDepth -= 1


		label kindT.lookahead :

		    % Check for a lookahead
		    assert tree.trees (productionTP).count = 2

		    % Recover wasted space (always!)
		    oldKidCount := tree.kidCount
		    oldTreeCount := tree.treeCount
		    
		    % Preserve match stack state - JRC 29.12.07
		    oldMatchTop := matchTop
		    
		    % Let's go!
		    real_parse (tree.kids (tree.trees (productionTP).kidsKP), parseTP)

		    % If we got one, then backup over it - this was just a lookahead
		    if parseTP not= nilTree then
		    	% Throw away the successful parse
			backup_tree (parseTP)
			% If we were looking for it, we indicate success using the empty tree
			% otherwise we indicate failure using a null tree
			if tree.trees (tree.kids (tree.trees (productionTP).kidsKP + 1)).name = SEE_T then
			    parseTP := emptyTP
			else
			    assert tree.trees (tree.kids (tree.trees (productionTP).kidsKP + 1)).name = NOT_T 
			    parseTP := nilTree
			end if
		    else
			% If we were looking for it, we indicate failure using a null tree
			% otherwise we indicate success using the empty tree
			if tree.trees (tree.kids (tree.trees (productionTP).kidsKP + 1)).name = SEE_T then
			    if patternParse then
			        % we must assume that the pattern is valid anyway - JRC 15.2.00
			        parseTP := emptyTP
			    else
			        parseTP := nilTree
			    end if
			else
			    assert tree.trees (tree.kids (tree.trees (productionTP).kidsKP + 1)).name = NOT_T 
			    parseTP := emptyTP
			end if
		    end if

		    % Recover wasted space, if any
		    if tree.allocationStrategy = simple then
			tree.setTreeCount (oldTreeCount)
			tree.setKidCount (oldKidCount)
		    end if
		    
		    % Restore match stack state - JRC 29.12.07
		    matchTop := oldMatchTop
		    
		    % The empty result indicates success, a null tree indicates failure
		    if parseTP not= nilTree then
			% Allocate new parse tree for the empty result
			parseTP := tree.newTreeClone (productionTP) 
			tree.setKind (parseTP, kindT.choose)
			% Link in the empty kid from the production
			tree.makeOneKid (parseTP, tree.kids (tree.trees (productionTP).kidsKP + 1))
			% Encode the choice we made in the parse tree (always 2, the empty result)
			tree.setCount (parseTP, 2)
		    end if


		label kindT.push :
		    % [push X] - JRC 22.9.07
		    assert tree.trees (productionTP).count = 1

		    % Recover wasted space if we fail
		    oldKidCount := tree.kidCount
		    oldTreeCount := tree.treeCount

		    % See if we have the token we want to push
		    parseKidTP := nilTree
		    real_parse (tree.kids (tree.trees (productionTP).kidsKP), parseKidTP)

		    if parseKidTP not= nilTree then
			% We do, so build the parent
			parseTP := tree.newTreeClone (productionTP)  % sets kind, name and nKids
			tree.setKind (parseTP, kindT.order)        % hide matching from xformer
			% Link in the kid we managed to parse
		 	tree.makeOneKid (parseTP, parseKidTP) 
			% And push it to the match stack
		    	if not patternParse then
			    var pushtoken := tree.trees (parseKidTP).name
			    if tree.trees (parseKidTP).kind not= kindT.id then
				if tree.trees (parseKidTP).kind = kindT.charlit and
					    string@(ident.idents (tree.trees (parseKidTP).name))(1) = "'" or 
                                	tree.trees (parseKidTP).kind = kindT.stringlit and
					    string@(ident.idents (tree.trees (parseKidTP).name))(1) = "\"" then
				    installAsId (tree.trees (parseKidTP).name, pushtoken)
				end if
			    end if
			    matchPush (pushtoken)
			end if
		    else
			% No such luck
			parseTP := nilTree
			% Recover wasted space
			if tree.allocationStrategy = simple then
			    tree.setTreeCount (oldTreeCount)
			    tree.setKidCount (oldKidCount)
			end if
		    end if


		label kindT.pop :
		    % [pop X] - JRC 22.9.07
		    assert tree.trees (productionTP).count = 1

		    % Recover wasted space (always!)
		    oldKidCount := tree.kidCount
		    oldTreeCount := tree.treeCount

		    % Let's go!
		    parseKidTP := nilTree
		    real_parse (tree.kids (tree.trees (productionTP).kidsKP), parseKidTP)

		    % If we got one, then check it
		    if parseKidTP not= nilTree then
		    
		        if patternParse or tree.trees (parseKidTP).name = matchToken then
			    % It's a successful match, so pop it
			    if not patternParse then
			        matchPop
			    end if
			    % Build the parent
			    parseTP := tree.newTreeClone (productionTP)  % sets kind, name and nKids
			    tree.setKind (parseTP, kindT.order)        % hide matching from xformer
			    % Link in the kid we managed to parse and match
			    tree.makeOneKid (parseTP, parseKidTP)
		        else
			    % This one doesn't match, so throw away the successful parse and don't pop
			    real_parse (tree.kids (tree.trees (productionTP).kidsKP), parseKidTP)
			    assert parseKidTP = nilTree
			    
			    % Recover wasted space, if any
			    if tree.allocationStrategy = simple then
				tree.setTreeCount (oldTreeCount)
				tree.setKidCount (oldKidCount)
			    end if
			    
			    parseTP := nilTree
			end if
			
		    else
			% No such luck
			parseTP := nilTree
			% Recover wasted space
			if tree.allocationStrategy = simple then
			    tree.setTreeCount (oldTreeCount)
			    tree.setKidCount (oldKidCount)
			end if
		    end if


		% Terminals

		label kindT.literal :
		    % Don't care what it is, but it must match exactly
		    assert parseTP = nilTree
		    if nextTokenKind not= kindT.comment and nextTokenKind not= kindT.empty and
			    nextToken = tree.trees (productionTP).name then
			%  accept
			if nextRawToken = nextToken then
			    parseTP := productionTP  % we can always share literals!
			else
			    parseTP := tree.newTreeClone (productionTP) % sets kind and name
			    tree.setRawName (parseTP, nextRawToken)
			end if
			accept
		    end if

		label kindT.stringlit, kindT.charlit, kindT.number, kindT.id, kindT.space, kindT.newline,
			kindT.usertoken1, kindT.usertoken2, kindT.usertoken3, kindT.usertoken4, kindT.usertoken5, 
			kindT.usertoken6, kindT.usertoken7, kindT.usertoken8, kindT.usertoken9, kindT.usertoken10,
			kindT.usertoken11, kindT.usertoken12, kindT.usertoken13, kindT.usertoken14, kindT.usertoken15, 
			kindT.usertoken16, kindT.usertoken17, kindT.usertoken18, kindT.usertoken19, kindT.usertoken20,
			kindT.usertoken21, kindT.usertoken22, kindT.usertoken23, kindT.usertoken24, kindT.usertoken25, 
			kindT.usertoken26, kindT.usertoken27, kindT.usertoken28, kindT.usertoken29, kindT.usertoken30 :
		    assert parseTP = nilTree
		    if nextTokenKind = productionKind then
			%  accept
			#if not NOCOMPILE then
			if patternParse then
			    % Warning - cannot share when compiling because of load/store!
			    parseTP := tree.newTreeClone (ident.identTree (nextToken))
			    tree.setRawName (parseTP, nextRawToken)
			    tree.setKind (parseTP, nextTokenKind)
			else
			#end if
			    % Can always share leaves when parsing
			    if ident.identTree (nextToken) = nilTree then
			        % This may happen on a reparse in a compiled program -
				% the identTree was optimized out by load/store, 
				% but has come back in a run-time [reparse].  
				% Correct it by re-installing the token to get a new tree to share.
				nextToken := ident.install (string@(ident.idents (nextToken)), nextTokenKind)
			    end if
			    if ident.identTree (nextRawToken) = nilTree then
			        % Ditto.
				nextRawToken := ident.install (string@(ident.idents (nextRawToken)), nextTokenKind)
			    end if
			    % Now we can share it for sure
			    assert tree.trees (ident.identTree (nextToken)).kind = nextTokenKind
			        and tree.trees (ident.identTree (nextToken)).name = nextToken
			    % This line had the strange -case bug in 10.5f and earlier- JRC
			    if tree.trees (ident.identTree (nextToken)).rawname = nextRawToken then
			    	parseTP := ident.identTree (nextToken)
			    else
			    	parseTP := tree.newTreeClone (ident.identTree (nextToken))	% sets name and kind
				tree.setRawName (parseTP, nextRawToken)
			    end if
			#if not NOCOMPILE then
			end if
			#end if
			accept
		    end if

		label kindT.floatnumber :
		    assert parseTP = nilTree
		    if nextTokenKind = kindT.number
			    and (index (string@(ident.idents (nextToken)), "e") not= 0
				or index (string@(ident.idents (nextToken)), "E") not= 0) then
			%  accept
			parseTP := tree.newTreeClone (productionTP)
			tree.setName (parseTP, nextToken)
			tree.setRawName (parseTP, nextRawToken)
			accept
		    end if

		label kindT.decimalnumber :
		    if nextTokenKind = kindT.number and index (string@(ident.idents (nextToken)), ".") not= 0 
			    and index (string@(ident.idents (nextToken)), "e") = 0  % added check not float - JRC 21.8.07
			    and index (string@(ident.idents (nextToken)), "E") = 0  then
			%  accept
			parseTP := tree.newTreeClone (productionTP)
			tree.setName (parseTP, nextToken)
			tree.setRawName (parseTP, nextRawToken)
			accept
		    end if

		label kindT.integernumber :
		    assert parseTP = nilTree
		    if nextTokenKind = kindT.number 
			    % not decimal or float - JRC 21.8.07
		    	    and index (string@(ident.idents (nextToken)), ".") = 0 
			    and index (string@(ident.idents (nextToken)), "e") = 0
			    and index (string@(ident.idents (nextToken)), "E") = 0  then
			%  accept
			parseTP := tree.newTreeClone (productionTP)
			tree.setName (parseTP, nextToken)
			tree.setRawName (parseTP, nextRawToken)
			accept
		    end if

		label kindT.upperlowerid :
		    assert parseTP = nilTree
		    if nextTokenKind = kindT.id and (charset.upperP (char@(ident.idents (nextToken))) 
		    	    or length (string@(ident.idents (nextToken))) = 0) then
			%  accept
			parseTP := tree.newTreeClone (productionTP)
			tree.setName (parseTP, nextToken)
			tree.setRawName (parseTP, nextRawToken)
			accept
		    end if

		label kindT.lowerupperid :
		    if nextTokenKind = kindT.id and (charset.lowerP (char@(ident.idents (nextToken))) 
		    	    or length (string@(ident.idents (nextToken))) = 0) then
			%  accept
			parseTP := tree.newTreeClone (productionTP)
			tree.setName (parseTP, nextToken)
			tree.setRawName (parseTP, nextRawToken)
			accept
		    end if

		label kindT.upperid :
		    assert parseTP = nilTree
		    if nextTokenKind = kindT.id 
			    and charset.upperP (char@(ident.idents (nextToken)))
			    and charset.uniformlyP (string@(ident.idents (nextToken)), charset.upperidP) then
			%  accept
			parseTP := tree.newTreeClone (productionTP)
			tree.setName (parseTP, nextToken)
			tree.setRawName (parseTP, nextRawToken)
			accept
		    end if

		label kindT.lowerid :
		    assert parseTP = nilTree
 		    if nextTokenKind = kindT.id 
			    and charset.lowerP (char@(ident.idents (nextToken)))
 			    and charset.uniformlyP (string@(ident.idents (nextToken)), charset.loweridP) then
 			%  accept
 			parseTP := tree.newTreeClone (productionTP)
 			tree.setName (parseTP, nextToken)
			tree.setRawName (parseTP, nextRawToken)
 			accept
		    end if

		label kindT.token :
		    % generic token - used only for TXL source itself
		    % anything is ok unless it's a key symbol
		    % whatever it is, it retains its own kind!
		    assert parseTP = nilTree
		    if nextTokenKind not= kindT.key and nextTokenKind not= kindT.empty then
			%  accept
			parseTP := tree.newTreeClone (productionTP)
			tree.setKind (parseTP, nextTokenKind)
			tree.setName (parseTP, nextToken)
			tree.setRawName (parseTP, nextRawToken)
			accept
		    end if

		label kindT.key :
		    % generic keyword - used only for TXL source itself
		    assert parseTP = nilTree
		    if nextTokenKind = kindT.key then 
			parseTP := tree.newTreeClone (productionTP)
			tree.setKind (parseTP, kindT.literal)
			tree.setName (parseTP, nextToken)
			tree.setRawName (parseTP, nextRawToken)
			accept
		    end if

		label kindT.comment :
		    % optional comment
		    assert parseTP = nilTree
		    if nextTokenKind = kindT.comment then
			parseTP := tree.newTreeClone (productionTP)
			tree.setName (parseTP, nextToken)
			tree.setRawName (parseTP, nextRawToken)
			accept
		    end if

		% Support for source line number and file name - JRC 14.12.07
		
		label kindT.srclinenumber :	
		    assert parseTP = nilTree
		    parseTP := tree.newTree 
		    tree.setKind (parseTP, kindT.srclinenumber)
		    if patternParse then
			tree.setName (parseTP, ident.nilIdent)
		    else
			var numberT : tokenT
		        installNumber (inputTokens (currentTokenIndex).linenum mod maxLines, kindT.number, numberT)
			tree.setName (parseTP, numberT)
		    end if
		    tree.setRawName (parseTP, tree.trees (parseTP).name)

		label kindT.srcfilename :
		    assert parseTP = nilTree
		    parseTP := tree.newTree 
		    tree.setKind (parseTP, kindT.srcfilename)
		    if patternParse then
			tree.setName (parseTP, ident.nilIdent)
		    else
			var numberT := ident.install (fileNames (inputTokens (currentTokenIndex).linenum div maxLines), kindT.id)
			tree.setName (parseTP, numberT)
		    end if
		    tree.setRawName (parseTP, tree.trees (parseTP).name)

		label :
		    fatal_error (1)

	    end case


	else

	    % Backtrack
	    assert parseTP not= nilTree

	    #if PROFILER then
		backtrackCycles += 1
	    #end if
    
	    case productionKind of

		label kindT.empty :

		    % Backtracking over a match of empty!!
		    % If this is a keeper, we can't back it up.
		    if tree.trees (parseTP).name = KEEP_T then
			quit : cutPoint
		    end if
		
		    % If this is a fence [!], then we have failed this sequence
		    if tree.trees (parseTP).name = FENCE_T then
			fenceState := true
		    end if

		    parseTP := nilTree


		label kindT.order :

		    % Retrying an order tree

		    productionKids := tree.trees (productionTP).count
		    assert productionKids > 0

		    % Recover wasted space if we fail
		    oldKidCount := tree.kidCount
		    oldTreeCount := tree.treeCount

		    % Since they are contiguous, we can just run up and down
		    % the production kid lists directly!
		    baseProductionKidsKP := tree.trees (productionTP).kidsKP - 1

		    % Since we allocate the kids of the parse contiguously, 
		    % we can use them in place too!
		    baseParseKidsKP := tree.trees (parseTP).kidsKP - 1

		    % Now we parse!

		    % If we are backtracking, we will start at the last kid of the previous parse
		    % and retry, working backwards.
		    retry := true
		    var kid := productionKids
		    		    
		    % Let's go!
		    loop
			oldTokenIndex := currentTokenIndex

			var kidTP := tree.kids (baseParseKidsKP + kid)
			real_parse (tree.kids (baseProductionKidsKP + kid), kidTP)
			tree.setKidTree (baseParseKidsKP + kid, kidTP)

			if tree.kids (baseParseKidsKP + kid) = nilTree then
			    % Retry another match of the previous kid
			    kid -= 1
			    exit when kid < 1
			    retry := true

			    % If we backtracked into a fence, we've failed the sequence
			    exit when fenceState
			    
			elsif retry => currentTokenIndex not= oldTokenIndex then
			    % Go on to the next one
			    kid += 1
			    exit when kid > productionKids 
			    retry := false
			    tree.setKidTree (baseParseKidsKP + kid, nilTree) % first try

			% else
			    % Re-parses of an embedded kid that yield the
			    % same lookahead are uninteresting since the
			    % rest will fail in the same way!
			    %  - so just ask for another try of the same kid
			end if
		    end loop

		    % We fail if we're at the left, succeed if we made it all the way to the right.

		    if kid > 0 then
			% Successful backtrack - everything has already been previously built!
			if fenceState then
			    % Hit a fence - we must undo the partial parse and fail
			    loop
			        exit when kid = 0
			        backup_tree (tree.kids (baseParseKidsKP + kid))
				kid -= 1
			    end loop
			    % Failed to get a parse
			    parseTP := nilTree
			    % Recover wasted space
			    if tree.allocationStrategy = simple then
				tree.setTreeCount (oldTreeCount)
				tree.setKidCount (oldKidCount)
			    end if
			end if
		    else
			% Failed to get a parse
			parseTP := nilTree
			% Recover wasted space
			if tree.allocationStrategy = simple then
			    tree.setTreeCount (oldTreeCount)
			    tree.setKidCount (oldKidCount)
			end if
		    end if

		    % Reset the fence flag
		    fenceState := false


		label kindT.choose :

		    % Retrying a regular choose tree

		    % update parse stack (for choose trees only!)
		    assert parseDepth < maxParseDepth 	% must be so, if we are retrying!

		    parseDepth += 1
		    parseStack (parseDepth) := tree.trees (productionTP).name
		    parseTokenIndex (parseDepth) := 0

		    % Recover wasted space if we fail
		    oldKidCount := tree.kidCount
		    oldTreeCount := tree.treeCount

		    % Total number of choices we have
		    productionKids := tree.trees (productionTP).count

		    % Since production kids are allocated contiguously,
		    % we can walk through them directly in the kids array.
		    productionKidsKP := tree.trees (productionTP).kidsKP

		    % Since we are backtracking, parseTP is the previous parse and
		    % tree.trees (parseTP).count encodes the number of the choice we used last time.
		    % First we give that one a chance to retry, then try the other 
		    % alternatives if it fails.
		    parseKidTP := tree.kids (tree.trees (parseTP).kidsKP)
		    kidLastTime := tree.trees (parseTP).count

		    % Since kids are allocated contiguously, we can address the 
		    % corresponding production kid directly
		    productionKidsKP := tree.trees (productionTP).kidsKP + kidLastTime - 1

		    % Since we are retrying, not much use exploring same tail ...
		    oldTokenIndex := currentTokenIndex
		    
		    % Try each alternative until we get a new match
		    var kid := kidLastTime
		    loop

			real_parse (tree.kids (productionKidsKP), parseKidTP)

			if parseKidTP not= nilTree then
			    if currentTokenIndex not= oldTokenIndex then
				% We re-use the tree and kid structure we allocated
				% on the first try
				tree.setKidTree (tree.trees (parseTP).kidsKP, parseKidTP)
				% Encode the new choice we made in the parse tree,
				% in case we must retry again
				tree.setCount (parseTP, kid)
				exit
			    else
				% Re-parses that yield the
				% same lookahead are uninteresting since the
				% rest will fail in the same way!
				%  - so just ask for another try of the same alternative
			    end if
			else
			    % Try the next alternative
			    exit when kid = productionKids
			    kid += 1
			    productionKidsKP += 1
			    parseTokenIndex (parseDepth) := currentTokenIndex
			end if
		    end loop

		    if parseKidTP = nilTree then
			parseTP := nilTree
			% recover wasted space
			if tree.allocationStrategy = simple then
			    tree.setTreeCount (oldTreeCount)
			    tree.setKidCount (oldKidCount)
			end if
		    elsif currentTokenIndex = oldTokenIndex then
		        backup_tree (parseKidTP)
			parseTP := nilTree
		    end if

		    parseDepth -= 1


		label kindT.generaterepeat :

		    % Retrying a new-style generate repeat node
		    
		    % The generated item type
		    productionKidsKP := tree.trees (productionTP).kidsKP

		    % If the previous parse was an [empty] repeat, there is nothing to do but fail.
		    if tree.kids (tree.trees (parseTP).kidsKP) = emptyTP then
			#if not NOCOMPILE then
			if patternParse then
			    if  tree.kids (tree.trees (parseTP).kidsKP + 1) not= emptyTP then
				assert tree.trees (tree.kids (tree.trees (parseTP).kidsKP + 1)).kind = kindT.firstTime
				    or tree.trees (tree.kids (tree.trees (parseTP).kidsKP + 1)).kind = kindT.subsequentUse
				    or tree.trees (tree.kids (tree.trees (parseTP).kidsKP + 1)).kind = kindT.expression
				backup
				
				% If the variable we are backing up over was a binding occurence,
				% undo the binding
				if tree.trees (tree.kids (tree.trees (parseTP).kidsKP + 1)).kind = kindT.firstTime then
				    localsListT@(patternVarsAddr).nlocals -= 1
				end if
			    end if
			else
			#end if
			    assert tree.kids (tree.trees (parseTP).kidsKP + 1) = emptyTP
			#if not NOCOMPILE then
			end if
			#end if
			
			parseTP := nilTree
				    
			#if not NOCOMPILE then
			if options.option (tree_print_p) then
			    trace_exit (productionTP, parseTP)
			end if
			#end if

			return
		    end if

		    % update parse stack (for choose/generate trees only!)
		    assert parseDepth < maxParseDepth 	% must be so, if we are retrying!
		    parseDepth += 1
		    parseStack (parseDepth) := tree.trees (productionTP).name
		    % Important - need to be sure that we know we were this far ...
		    parseTokenIndex (parseDepth) := currentTokenIndex 

		    % Otherwise, we first retry the tail, then the item.
		    % If it fails, then we replace it by the empty choice.
		    % One or the other always succeeds.
		    retry := false

		    loop
			% Since we are backtracking, parseTP is the previous parse.
			parseKidTP := tree.kids (tree.trees (parseTP).kidsKP + 1)
		    
			% No use exploring the same case ...
			oldTokenIndex := currentTokenIndex
			
			% Retry the tail
			loop
			    real_parse (productionTP, parseKidTP)
			    exit when parseKidTP = nilTree or currentTokenIndex not= oldTokenIndex or retry
			end loop
			
			exit when parseKidTP not= nilTree
			
		        % No new parse of the tail - try for a new parse of the item
			parseKidTP := tree.kids (tree.trees (parseTP).kidsKP)
			
			% No use exploring the same case, or empty items ...
			oldTokenIndex := currentTokenIndex
			
			loop
			    % Retry the item
			    real_parse (tree.kids (productionKidsKP), parseKidTP)
			    exit when parseKidTP = nilTree 
			    	or currentTokenIndex not= oldTokenIndex and not is_empty (parseKidTP)
			end loop
			
			exit when parseKidTP = nilTree
			
			% Got a new item - now looking for a new tail
			tree.setKidTree (tree.trees (parseTP).kidsKP, parseKidTP)
			tree.setKidTree (tree.trees (parseTP).kidsKP + 1, nilTree)
			retry := true
		    end loop
		    
		    if parseKidTP = nilTree then
			% We failed to get any interesting new parse - but the empty case always succeeds
			tree.setKidTree (tree.trees (parseTP).kidsKP, emptyTP)
			tree.setKidTree (tree.trees (parseTP).kidsKP + 1, emptyTP)
		    else
			% Got an interesting new parse of the tail
			tree.setKidTree (tree.trees (parseTP).kidsKP + 1, parseKidTP)
		    end if
		    
		    parseDepth -= 1


		label kindT.repeat :

		    % Retrying a new style repeat+ node

		    % The generated item type
		    productionKidsKP := tree.trees (productionTP).kidsKP

		    % We must have an item, otherwise repeat+ fails.

		    % No empty items allowed ...
		    oldTokenIndex := currentTokenIndex
		    
		    % First we retry the tail, then the item.
		    % If it fails, then we must fail since at least one item is required.
		    retry := false

		    loop
			% Since we are backtracking, parseTP is the previous parse.
			parseKidTP := tree.kids (tree.trees (parseTP).kidsKP + 1)
		    
			% No use exploring the same case ...
			oldTokenIndex := currentTokenIndex
			
			% Retry the tail
			loop
			    real_parse (tree.kids (productionKidsKP + 1), parseKidTP)
			    exit when parseKidTP = nilTree or currentTokenIndex not= oldTokenIndex or retry
			end loop
			
			exit when parseKidTP not= nilTree
			
		        % No new parse of the tail - try for a new parse of the item
			parseKidTP := tree.kids (tree.trees (parseTP).kidsKP)
			
			% No use exploring the same case, or empty items ...
			oldTokenIndex := currentTokenIndex
			
			loop
			    % Retry the item
			    real_parse (tree.kids (productionKidsKP), parseKidTP)
			    exit when parseKidTP = nilTree 
			    	or currentTokenIndex not= oldTokenIndex and not is_empty (parseKidTP)
			end loop
			
			exit when parseKidTP = nilTree
			
			% Got a new item - now looking for a new tail
			tree.setKidTree (tree.trees (parseTP).kidsKP, parseKidTP)
			tree.setKidTree (tree.trees (parseTP).kidsKP + 1, nilTree)
			retry := true
		    end loop
		    
		    if parseKidTP = nilTree then
			% We failed to get any interesting new parse of an item - so we must fail
			parseTP := nilTree
		    else
			% Got an interesting new parse of the tail
			tree.setKidTree (tree.trees (parseTP).kidsKP + 1, parseKidTP)
		    end if


		label kindT.generatelist :

		    % Retrying a new-style generate list node
		    
		    % The generated item type
		    productionKidsKP := tree.trees (productionTP).kidsKP

		    % If the previous parse was an [empty] list, there is nothing to do but fail.
		    if tree.kids (tree.trees (parseTP).kidsKP) = emptyTP then
			#if not NOCOMPILE then
			if patternParse then
			    if  tree.kids (tree.trees (parseTP).kidsKP + 1) not= emptyTP then
				assert tree.trees (tree.kids (tree.trees (parseTP).kidsKP + 1)).kind = kindT.firstTime
				    or tree.trees (tree.kids (tree.trees (parseTP).kidsKP + 1)).kind = kindT.subsequentUse
				    or tree.trees (tree.kids (tree.trees (parseTP).kidsKP + 1)).kind = kindT.expression
				backup
				
				% If the variable we are backing up over was a binding occurence,
				% undo the binding
				if tree.trees (tree.kids (tree.trees (parseTP).kidsKP + 1)).kind = kindT.firstTime then
				    localsListT@(patternVarsAddr).nlocals -= 1
				end if
			    end if
			else
			#end if
			    assert tree.kids (tree.trees (parseTP).kidsKP + 1) = emptyTP
			#if not NOCOMPILE then
			end if
			#end if

			parseTP := nilTree
				
			#if not NOCOMPILE then
			if options.option (tree_print_p) then
			    trace_exit (productionTP, parseTP)
			end if
			#end if

			return
		    end if

		    % Otherwise, we first retry the tail, then the item.
		    % If it fails, then we replace it by the empty choice.
		    % One or the other always succeeds.
		    retry := false
		    
		    % Keep track of whether we originally had a comma 
		    var hadComma := tree.trees (parseTP).kind = kindT.list 
		        and (tree.trees (tree.kids (tree.trees (parseTP).kidsKP + 1)).kind = kindT.list
		    	    => tree.trees (tree.kids (tree.trees (tree.kids (tree.trees (parseTP).kidsKP + 1)).kidsKP + 1)).kind not= kindT.empty)

		    loop
			% Since we are backtracking, parseTP is the previous parse.
			parseKidTP := tree.kids (tree.trees (parseTP).kidsKP + 1)
		    
			% No use exploring the same case ...
			oldTokenIndex := currentTokenIndex
			
			% Retry the tail
			loop
			    real_parse (productionTP, parseKidTP)
			    exit when parseKidTP = nilTree or currentTokenIndex not= oldTokenIndex or retry
			end loop
			
			exit when parseKidTP not= nilTree
			
		        % No new parse of the tail - backup the separator, then try for a new parse of the item
			if hadComma then
			    assert currentTokenIndex > 0 and inputTokens (currentTokenIndex - 1).token = comma_T
			    backup
			end if
			
			% We are not longer holding an implicit comma
			hadComma := false
			
			% Try for a new parse of the item 
			parseKidTP := tree.kids (tree.trees (parseTP).kidsKP)
			
			% No use exploring the same case ...
			oldTokenIndex := currentTokenIndex
			
			loop
			    % Retry the item
			    real_parse (tree.kids (productionKidsKP), parseKidTP)
			    exit when parseKidTP = nilTree 
			    	or currentTokenIndex not= oldTokenIndex
			end loop
			
			exit when parseKidTP = nilTree
			
			% Link in the new item
			tree.setKidTree (tree.trees (parseTP).kidsKP, parseKidTP)
			
			% If we have a separator, parse a new tail, otherwise make an empty tail
			if nextTokenKind not= kindT.comment and nextToken = comma_T then
			    accept
			    hadComma := true
			else
			    % Create an empty tail and we're done
			    parseKidTP := tree.newTreeInit (kindT.list, tree.trees (productionTP).name, tree.trees (productionTP).rawname, 0, nilKid)
			    tree.makeTwoKids (parseKidTP, emptyTP, emptyTP)
			    exit
			end if
			
			% Got a separator - parse a new tail
			tree.setKidTree (tree.trees (parseTP).kidsKP + 1, nilTree)
			retry := true
		    end loop
		    
		    if parseKidTP = nilTree then
			% We failed to get any interesting new parse - but the empty case always succeeds
			tree.setKidTree (tree.trees (parseTP).kidsKP, emptyTP)
			tree.setKidTree (tree.trees (parseTP).kidsKP + 1, emptyTP)
			if hadComma then
			    assert currentTokenIndex > 0 and inputTokens (currentTokenIndex - 1).token = comma_T
			    backup
			end if
		    else
			% Got an interesting new parse of the tail
			tree.setKidTree (tree.trees (parseTP).kidsKP + 1, parseKidTP)
		        % If the new parse is an empty tail, then we already backed up the separator
			if tree.trees (parseKidTP).kind = kindT.list 
				and tree.trees (tree.kids (tree.trees (parseKidTP).kidsKP + 1)).kind = kindT.empty 
				and hadComma then
			    if currentTokenIndex > 0 and inputTokens (currentTokenIndex - 1).token = comma_T then
			    	backup
			    end if
			    assert nextToken = comma_T
			end if
		    end if


		label kindT.list :

		    % Retrying a new style list+ node

		    % The generated item type
		    productionKidsKP := tree.trees (productionTP).kidsKP

		    % We must have an item, otherwise list+ fails.
		    assert tree.trees (parseTP).kind = kindT.list

		    % First we retry the tail, then the item.
		    % If it fails, then we must fail since at least one item is required.
		    retry := false

		    % Keep track of whether we originally had a comma 
		    var hadComma := tree.trees (parseTP).kind = kindT.list 
		        and (tree.trees (tree.kids (tree.trees (parseTP).kidsKP + 1)).kind = kindT.list
		    	    => tree.trees (tree.kids (tree.trees (tree.kids (tree.trees (parseTP).kidsKP + 1)).kidsKP + 1)).kind not= kindT.empty)
			        
		    loop
			% Since we are backtracking, parseTP is the previous parse.
			parseKidTP := tree.kids (tree.trees (parseTP).kidsKP + 1)
		    
			% No use exploring the same case ...
			oldTokenIndex := currentTokenIndex
			
			% Retry the tail
			loop
			    real_parse (tree.kids (productionKidsKP + 1), parseKidTP)
			    exit when parseKidTP = nilTree or currentTokenIndex not= oldTokenIndex or retry
			end loop
			
			exit when parseKidTP not= nilTree
			
		        % No new parse of the tail - backup the separator, then try for a new parse of the item
			if hadComma then
			    assert currentTokenIndex > 0 and inputTokens (currentTokenIndex - 1).token = comma_T
			    backup
			end if
			
			% We are not longer holding an implicit comma
			hadComma := false
			
			% Try for a new parse of the item 
			parseKidTP := tree.kids (tree.trees (parseTP).kidsKP)
			
			% No use exploring the same case ...
			oldTokenIndex := currentTokenIndex
			
			loop
			    % Retry the item
			    real_parse (tree.kids (productionKidsKP), parseKidTP)
			    exit when parseKidTP = nilTree 
			    	or currentTokenIndex not= oldTokenIndex
			end loop
			
			exit when parseKidTP = nilTree
			
			% Link in the new item
			tree.setKidTree (tree.trees (parseTP).kidsKP, parseKidTP)

			% If we have a separator, parse a new tail, otherwise make an empty tail
			if nextTokenKind not= kindT.comment and nextToken = comma_T then
			    accept
			    hadComma := true
			else
			    % Create an empty tail and we're done
			    parseKidTP := tree.newTreeInit (kindT.list, tree.trees (tree.kids (productionKidsKP + 1)).name,
			    	tree.trees (tree.kids (productionKidsKP + 1)).rawname, 0, nilKid) 
			    tree.makeTwoKids (parseKidTP, emptyTP, emptyTP)
			    exit
			end if
			
			% Got a separator - parse a new tail
			tree.setKidTree (tree.trees (parseTP).kidsKP + 1, nilTree)
			retry := true
		    end loop
		    
		    if parseKidTP = nilTree then
			% We failed to get any interesting new parse of an item - so we must fail
			if hadComma then
			    assert currentTokenIndex > 0 and inputTokens (currentTokenIndex - 1).token = comma_T
			    backup
			end if
			parseTP := nilTree
		    else
			% Got an interesting new parse of the tail
			tree.setKidTree (tree.trees (parseTP).kidsKP + 1, parseKidTP)
		        % If the new parse is an empty tail, then we already backed up the separator
			if tree.trees (parseKidTP).kind = kindT.list 
				and tree.trees (tree.kids (tree.trees (parseKidTP).kidsKP + 1)).kind = kindT.empty 
				and hadComma then
			    if currentTokenIndex > 0 and inputTokens (currentTokenIndex - 1).token = comma_T then
			    	backup
			    end if
			    assert nextToken = comma_T
			end if
		    end if


		label kindT.leftchoose :

		    % Retrying an optimized left recursive choose tree

		    % update parse stack (for choose trees only!)
		    assert parseDepth < maxParseDepth 	% must be so, if we are retrying!

		    parseDepth += 1
		    parseStack (parseDepth) := tree.trees (productionTP).name
		    parseTokenIndex (parseDepth) := 0

		    % Recover wasted space if we fail
		    oldKidCount := tree.kidCount
		    oldTreeCount := tree.treeCount

		    % Left recursive chooses always have exactly 2 choices
		    assert tree.trees (productionTP).count = 2

		    % Since we are backtracking, parseTP is the previous parse and
		    % tree.trees (parseTP).count encodes the number of the choice we used last time.
		    % If tree.trees (parseTP).count is greater than the number of choices,
		    % we've already tried to extend it.
		    kidLastTime := tree.trees (parseTP).count

		    % Optimization of direct left recursive productions to avoid 
		    % infinite backtracking loops.  The define compiler has reduced 
		    % all direct left recursions to the form:
		    %	E -> E1		
		    %	  |  E E2		

		    % Can we optimize?

		    if kidLastTime <= 2 
			#if not NOCOMPILE then
		    	    or isVarOrExp 
			#end if
			    then
			% Haven't tried to extend this one yet ...
			% so try extending our present parse from the bottom up.
			% We have:  parseTP -> E -> E1 
			% We want:  parseTP -> E' -> E E2
			productionKidsKP := tree.trees (productionTP).kidsKP 
			parseKidTP := parseTP

			% Try to extend previously parsed E with an E2
			% tree.kids (productionKidsKP + 1) is the grammar for E -> E E2
			% parseKidTP is initially our previously parsed E, and on return our extended E -> E E2, if any
			parse_extend (tree.kids (productionKidsKP + 1), parseKidTP)

			if parseKidTP not= nilTree then
			    % Bottom up extension worked! 
			    % Mark the embedded tree as already extended in case we back up over it.
			    #if not NOCOMPILE then
			    if not isVarOrExp then
			    #end if
				tree.setCount (parseTP, tree.trees (productionTP).count + 1) 	% sic
			    #if not NOCOMPILE then
			    end if
			    #end if

			    % Must allocate new tree and kid for the extended parse!
			    parseTP := tree.newTreeClone (productionTP)
			    tree.setKind (parseTP, kindT.choose)
			    tree.makeOneKid (parseTP, parseKidTP)

			    % Remember which alternative we chose last time.
			    tree.setCount (parseTP, 2)
			    
			    % Rename trees to give specified parse (even though we got it using left factoring) - JRC 8.5.08
			    % We lift the name (e.g. expn -> addition (expn + term) ) 
			    % from the left-factored form (e.g., expn -> expn addition (+ term) )
			    % and give the left-factored form the anonymous name instead.
			    const anonorderTP := tree.kids (tree.trees (parseTP).kidsKP)
			    const leftfactoredTP := tree.kids (tree.trees ( tree.kids (tree.trees (anonorderTP).kidsKP + 1)).kidsKP)
			    
			    % Use redundancy of rawname to swap without a temporary
			    tree.setName (anonorderTP, tree.trees (leftfactoredTP).rawname)
			    tree.setName (leftfactoredTP,  tree.trees (anonorderTP).rawname)
			    tree.setRawName (anonorderTP, tree.trees (anonorderTP).name)
			    tree.setRawName (leftfactoredTP, tree.trees (leftfactoredTP).name)

			else
			    % Attempt to extend failed - 
			    % Nothing to do but retry the original parse.
			    
			    #if not NOCOMPILE then
			    if isVarOrExp then
				% If extension of pattern var failed, simply back up over it
				backup
	
				% If the variable we are backing up over was a binding occurence,
				% undo the binding
				if tree.trees (parseTP).kind = kindT.firstTime then
				    localsListT@(patternVarsAddr).nlocals -= 1
				end if
	
				% No other parse possible, so give up
				parseTP := nilTree
				% Recover wasted space
				if tree.allocationStrategy = simple then
				    tree.setTreeCount (oldTreeCount)
				    tree.setKidCount (oldKidCount)
				end if

			    else
			    #end if
			    
			    	% Retry the original parse
				parseKidTP := tree.kids (tree.trees (parseTP).kidsKP)
				productionKidsKP += kidLastTime - 1 
	
				real_parse (tree.kids (productionKidsKP), parseKidTP)
	
				if parseKidTP not= nilTree then
				    % Another parse of the original case - 
				    % we re-use the old tree and kid structure.
				    tree.setKidTree (tree.trees (parseTP).kidsKP, parseKidTP)
				    % Same choice this time
				    #if not NOCOMPILE then
				    	assert not isVarOrExp
				    #end if
				    tree.setCount (parseTP, kidLastTime)
				else
				    % No new parse, so give up
				    parseTP := nilTree
				    % Recover wasted space
				    if tree.allocationStrategy = simple then
					tree.setTreeCount (oldTreeCount)
					tree.setKidCount (oldKidCount)
				    end if
				end if
			    #if not NOCOMPILE then
			    end if
			    #end if
			end if

		    else
			% Already tried extending - nothing to do but give up.
			% NOTE: In this particular case, we cannot retry the parse since
			% that is the infinite loop we are avoiding!  The side effect
			% of this is that we have to back up over all of the accepted tokens
			% in the parse tree at once.  'backup_tree' does this.
			backup_tree (parseTP)
			parseTP := nilTree
			% Recover wasted space
			if tree.allocationStrategy = simple then
			    tree.setTreeCount (oldTreeCount)
			    tree.setKidCount (oldKidCount)
			end if
		    end if

		    parseDepth -= 1


		label kindT.lookahead :
		
		    % Retrying a lookahead - just fail back 
		    parseTP := nilTree


		label kindT.push :
		
		    % Retrying a push - nothing to do but pop the match token and retry - JRC 22.9.07
		    var prevMatchToken : tokenT
		    if not patternParse then
		        prevMatchToken := matchToken
		        matchPop
		    end if
		    
		    % This reparse will always fail, but we must do it in case it's a variable definition in a pattern
		    parseKidTP := tree.kids (tree.trees (parseTP).kidsKP)
		    real_parse (tree.kids (tree.trees (productionTP).kidsKP), parseKidTP)
		    assert parseKidTP = nilTree
		    
		    if not patternParse then
		        assert nextToken = prevMatchToken
		    end if

		    parseTP := nilTree
		    

		label kindT.pop :
		
		    % Retrying a pop - nothing to do but retry and push the match token - JRC 22.9.07
		    
		    % This reparse will always fail, but we must do it in case it's a variable definition in a pattern
		    parseKidTP := tree.kids (tree.trees (parseTP).kidsKP)
		    real_parse (tree.kids (tree.trees (productionTP).kidsKP), parseKidTP)
		    assert parseKidTP = nilTree
		    
		    if not patternParse then
		        matchPush (nextToken)
		    end if
		    
		    parseTP := nilTree


		label kindT.srclinenumber, kindT.srcfilename :	% JRC 14.12.07
		    % Retrying a source coordinate - just fail and retry above
		    parseTP := nilTree
		
		
		label kindT.literal, kindT.stringlit, kindT.charlit, kindT.token,
			kindT.id, kindT.upperlowerid, kindT.upperid,
			kindT.lowerupperid, kindT.lowerid, 
			kindT.number,
			kindT.floatnumber, kindT.decimalnumber, kindT.integernumber,
			kindT.key, kindT.comment, kindT.space, kindT.newline,
			kindT.usertoken1, kindT.usertoken2, kindT.usertoken3, kindT.usertoken4, kindT.usertoken5, 
			kindT.usertoken6, kindT.usertoken7, kindT.usertoken8, kindT.usertoken9, kindT.usertoken10,
			kindT.usertoken11, kindT.usertoken12, kindT.usertoken13, kindT.usertoken14, kindT.usertoken15, 
			kindT.usertoken16, kindT.usertoken17, kindT.usertoken18, kindT.usertoken19, kindT.usertoken20,
			kindT.usertoken21, kindT.usertoken22, kindT.usertoken23, kindT.usertoken24, kindT.usertoken25, 
			kindT.usertoken26, kindT.usertoken27, kindT.usertoken28, kindT.usertoken29, kindT.usertoken30 :
		    % Retrying a terminal - only thing left to do is back up!
		    if currentTokenIndex <= 0 
		    	    or not (productionKind = kindT.literal 
			    		=> tree.trees (parseTP).name = inputTokens (currentTokenIndex - 1).token) then
		    	fatal_error (2) 
		    end if
		    parseTP := nilTree
		    backup
		    
		label :
		    fatal_error (3)

	    end case

	end if

	#if not NOCOMPILE then
	if options.option (tree_print_p) then
	    trace_exit (productionTP, parseTP)
	end if
	#end if
	
	#if PROFILER then
	    if mainParse and tree.trees (productionTP).kind < kindT.empty then
		bind var symbolStats to symbolStatistics (symbolIndex)
		symbolStats.calls += 1
		if parseTP not= nilTree then
		    symbolStats.matches += 1
		end if
		symbolStats.parsecycles := oldStats.parsecycles + (parseCycles - startStats.parsecycles)
		symbolStats.backtrackcycles := oldStats.backtrackcycles + (backtrackCycles - startStats.backtrackcycles)
		symbolStats.time := oldStats.time + (clock - startStats.time)
		symbolStats.trees := oldStats.trees + (tree.treeCount - startStats.trees)
		symbolStats.kids := oldStats.kids + (tree.kidCount - startStats.kids)
	    end if
	#end if

    end real_parse

#if PROFILER then
    procedure write_profile
	var profout : int
	open : profout, "txl.pprofout", put
	if profout not= 0 then
	    put : profout, "name calls matches parsecycles backtrackcycles time trees kids"
	    for r : 1 .. symbol.nSymbols
		var symbolname := string@(ident.idents (tree.trees (symbol.symbols (r)).name))
		if tree.trees (symbol.symbols (r)).kind < kindT.empty 
			and index (symbolname, "__") not= 1		% internal type
			and index (symbolname, "lit__") not= 1		% terminal literal
			and index (symbolname, "opt__") not= 1		% covered by opt'ed type
			and index (symbolname, "repeat_1_") not= 1	% covered by repeat_0_
			and index (symbolname, "list_1_") not= 1	% covered by list_0_
			then
		    bind var symbolStats to symbolStatistics (r)
		    if index (symbolname, "repeat_0_") not= 0 or index (symbolname, "list_0_") not= 0 then
			const zindex := index (symbolname, "_0_")
			symbolname := symbolname (1 .. zindex) + symbolname (zindex + 2 .. *)
		    end if
		    put : profout, symbolname, " ",
			symbolStats.calls, " ", symbolStats.matches, " ", symbolStats.parsecycles, " ", 
			symbolStats.backtrackcycles, " ", symbolStats.time, " ", symbolStats.trees, " ", symbolStats.kids
		end if
	    end for
	    close : profout
	else
	    error ("", "Unable to create TXL profile file 'txl.pprofout'", FATAL, 129)
	end if
    end write_profile
#end if

    body procedure parse % (productionTP : treePT, var parseTP : treePT)
	handler (code)
	    if code = outOfKids or code = outOfTrees 
		    or code = parseTooDeep or code = cutPoint 
		    or code = timeLimitReached
		    or code = cycleLimitReached then
		parseTP := nilTree
		#if PROFILER then
		    % this may be useful information (or not!)
		    write_profile
		#end if
		return
	    elsif code = 2 then
		parseInterruptError (failTokenIndex, patternParse, parseContext)
	    elsif code = stackLimitReached then
		parseStackError (failTokenIndex, patternParse, parseContext)
	    elsif code not= 1 then
		error (parseContext, "Fatal TXL error in parse (signal)", DEFERRED, 130)  % (sic)
	    end if
	    quit > : code
	end handler

	% Initialize hard limit on parse
	parseCycles := 0
	
	#if PROFILER then
	    for r : 1 .. symbol.nSymbols
		bind var symbolStats to symbolStatistics (r)
		symbolStats.calls := 0
		symbolStats.matches := 0
		symbolStats.parsecycles := 0
		symbolStats.backtrackcycles := 0
		symbolStats.time := 0
		symbolStats.trees := 0
		symbolStats.kids := 0
	    end for
	    backtrackCycles := 0
	#end if

	parseTP := nilTree
	loop
	    real_parse (productionTP, parseTP)
	    exit when (currentTokenIndex = lastTokenIndex) or parseTP = nilTree
	end loop

	if currentTokenIndex not= lastTokenIndex then 
	    parseTP := nilTree 
	end if
	
	#if PROFILER then
	    if mainParse then
	    	write_profile
	    end if
	#end if

    end parse
end parser
