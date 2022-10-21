% OpenTxl Version 11 garbage collector
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

% The TXL treespace garbage collector
% Identifies and frees unused tree and kid nodes when transformation runs out

% Modification Log

% v11.0	Initial revision, revised from FreeTXL 10.8b (c) 1988-2022 Queen's University at Kingston
%	Reprogrammed and remodularized to improve maintainability


% Treespace used by compiled TXL program - filled in by xform.applyMainRule
% We don't disturb the trees and kids of the compiled TXL program when recovering garbage

var lastCompileTree, lastCompileKid := 0


module garbageRecovery

    import 
	var tree, ident, options, var rule, 
	callEnvironment, callDepth, valueTP, 
	lastCompileTree, lastCompileKid, 
	error, stackBase

    export
	recoverGarbage

    procedure markTree (t : treePT)
	% Mark as in use all subtree and kid nodes of the given tree
	% We mark as in use by negating kid trees (for kids) and the kidsKP link (for trees)
	% Empty trees are marked using NILMARK

	% Stack use limitation - to avoid recursion crashes
	var dummy : int
	if stackBase - addr (dummy) > maxStackUse then 
	    quit : stackLimitReached
	end if

	if t = nilTree then
	    return
	end if
	
	if tree.trees (t).kidsKP > 0 then
	    % not marked yet - mark the kids if any

	    case tree.trees (t).kind of

		label kindT.order, kindT.repeat, kindT.list, kindT.generatelist, kindT.lookahead :
		    for k : tree.trees (t).kidsKP .. tree.trees (t).kidsKP + tree.trees (t).count - 1
			if tree.kids (k) > 0 then
			    % kid unmarked so far
			    markTree (tree.kids (k))
			    tree.setKidTree (k, - tree.kids (k))
			elsif tree.kids (k) = nilTree then
			    tree.setKidTree (k, NILMARK)
			end if
		    end for

		label kindT.choose, kindT.leftchoose, kindT.generaterepeat :
		    const k := tree.trees (t).kidsKP
		    if tree.kids (k) > 0 then
			% kid unmarked so far
			markTree (tree.kids (k))
			tree.setKidTree (k, - tree.kids (k))
		    elsif tree.kids (k) = nilTree then
			tree.setKidTree (k, NILMARK)
		    end if

		label kindT.expression, kindT.lastExpression, kindT.ruleCall :
		    for k : tree.trees (t).kidsKP .. maxKids
			if tree.kids (k) = nilTree then
			    tree.setKidTree (k, NILMARK)
			    exit
			end if
			if tree.kids (k) > 0 then
			    % kid unmarked so far
			    markTree (tree.kids (k))
			    tree.setKidTree (k, - tree.kids (k))
			elsif tree.kids (k) = nilTree then
			    tree.setKidTree (k, NILMARK)
			end if
		    end for

		label :
		    % other kinds don't have kids
	    end case
	    
	    % mark this node
	    tree.setKids (t, - tree.trees (t).kidsKP)

	elsif tree.trees (t).kidsKP = nilKid then
	    % mark this node
	    tree.setKids (t, NILMARK)
	end if
    end markTree


    procedure unmarkTrees
	% Unmark all tree nodes marked as in use by re-negating their kidsKP link

	% Since we don't disturb trees in the compiled TXL program, they are all still in use
	var treesUsed := lastCompileTree

	for t : 1 .. maxTrees

	    % If the tree node is marked as in use, restore its kids link by re-negating
	    if tree.trees (t).kidsKP < 0 then
		% this one is in use!
		if t > lastCompileTree then
		    treesUsed += 1
		end if

		if tree.trees (t).kidsKP = NILMARK then
		    tree.setKids (t, nilKid)
		else
		    tree.setKids (t, - tree.trees (t).kidsKP)
		end if

	    % Otherwise, we can free it unless it's in the compiled TXL program
	    elsif t > lastCompileTree then
		% not in use - mark it as available
		tree.setKids (t, AVAILABLE)
		#if CHECKED then
		    tree.setKind (t, kindT.undefined)
		    tree.setCount (t, 0)
		    tree.setName (t, NOT_FOUND)
		#end if
	    end if
	end for

	% Report stats if verbose
	if options.option (verbose_p) then
	    put :0, "--- ", tree.treeCount, " trees were allocated, ", treesUsed, " were in use"
	end if

	tree.setTreeCount (treesUsed)
    end unmarkTrees


    procedure unmarkKids
	% Unmark all kid nodes marked as in use by re-negating their tree node link

	% Since we don't disturb trees and kids in the compiled TXL program, they are all still in use
	var kidsUsed := lastCompileKid

	for k : 1 .. maxKids
            % If the kid node is marked as in use, restore its tree link by re-negating
	    if tree.kids (k) < 0 then
		% this one is in use!
		if k > lastCompileKid then
		    kidsUsed += 1
		end if
		if tree.kids (k) = NILMARK then
		    tree.setKidTree (k, nilTree)
		else
		    tree.setKidTree (k, - tree.kids (k))
		end if

	    % Otherwise, we can free it unless it's in the compiled TXL program
	    elsif k > lastCompileKid then
		% not in use - mark it as available
		tree.setKidTree (k, AVAILABLE)
	    end if
	end for

	% Report stats if verbose
	if options.option (verbose_p) then
	    put :0, "--- ", tree.kidCount, " kids were allocated, ", kidsUsed, " were in use"
	end if

	tree.setKidCount (kidsUsed)
    end unmarkKids


    #if CHECKED then
	% Check the global integrity of the tree space after each garbage collection

	procedure garbageCollectionError (checkRule, checkContext : addressint)
	    error ("rule/function '" + string@(checkRule) + "'", 
		"Garbage collection failure, variable '" + string@(checkContext) + "'", 
		INTERNAL_FATAL, 921)
	end garbageCollectionError
	
	var checkContext, checkRule : addressint
	
	procedure checkTree (t : treePT)
	    % Stack use limitation - to avoid crashes
	    var dummy : int
	    if stackBase - addr (dummy) > maxStackUse then 
		quit : stackLimitReached
	    end if
	
	    if t = nilTree then
		return
	    end if
	    
	    if tree.trees (t).kidsKP < 0 or tree.trees (t).kidsKP = AVAILABLE then
		garbageCollectionError (checkRule, checkContext)
	    end if
	    
	    case tree.trees (t).kind of
		label kindT.order, kindT.repeat, kindT.list, kindT.generatelist, kindT.lookahead :
		    for k : tree.trees (t).kidsKP .. tree.trees (t).kidsKP + tree.trees (t).count - 1
			checkTree (tree.kids (k))
		    end for
		label kindT.choose, kindT.leftchoose, kindT.generaterepeat :
		    const k := tree.trees (t).kidsKP
		    checkTree (tree.kids (k))
		label kindT.expression, kindT.lastExpression, kindT.ruleCall :
		    for k : tree.trees (t).kidsKP .. maxKids
			exit when tree.kids (k) = nilTree
			checkTree (tree.kids (k))
		    end for
		label :
		    % other kinds don't have kids
	    end case
	
	end checkTree
	
	procedure checkActiveTrees
	    % check the integrity of the trees
	    var scopeString := "scope"
	    var resultString := "result"
	    var newscopeString := "newscope"
	    % check top five scopes and global scope (can't afford to check all in Andrew's code!)
	    for cc : callDepth - 4 .. callDepth + 1
		if cc > 0 then
		    var c := cc
		    if c = callDepth + 1 then
			c := 0
		    end if
		    checkRule := ident.idents (callEnvironment (c).name)
		    bind localVars to localsListT@(callEnvironment (c).localsListAddr)
		    checkContext := addr (scopeString)
		    checkTree (callEnvironment (c).scopeTP)
		    for v : 1 .. localVars.nlocals
			checkContext := ident.idents (rule.ruleLocals (localVars.localBase + v).name)
			checkTree (valueTP (callEnvironment (c).valuesBase + v))
		    end for
		    checkContext := addr (resultString)
		    checkTree (callEnvironment (c).resultTP)
		    checkContext := addr (newscopeString)
		    checkTree (callEnvironment (c).newscopeTP)
		end if
	    end for
	end checkActiveTrees
    #end if


    procedure recoverGarbage
	% Attempt to recover garbage after the transformation runs out of treespace 

	% Strategy: 
	%	(1) We leave everything from the compiled TXL program alone.
	%	    Thus we don't bugger up the ruleset.
	%	(2) We trace the scope and bound local variable trees of all active 
	%	    rule call environments (including the present one), 
	%	    marking all active trees and kids as in use by negating their links.
	%	(3) We zero all unmarked trees and kids to indicate they are free, 
	%	    unmark all active trees and kids by re-negating their links,
	%	    and change allocation strategy to scavenge free trees and kids.

	%  if we're still using linear allocation, mark all remaining free nodes and kids as free
	if tree.allocationStrategy = simple then
	    for t : tree.treeCount + 1 .. maxTrees
		tree.setKind (t, kindT.empty)
		tree.setKids (t, nilKid)
	    end for
	    for k : tree.kidCount + 1 .. maxKids
		tree.setKidTree (k, nilTree)
	    end for  
	end if

	%  mark all trees and kids used in the ident table as active
	for id : 0 .. maxIdents - 1
	    if ident.identTree (id) not= nilTree then
		markTree (ident.identTree (id))
	    end if
	end for
	
	%  mark all trees and kids used in the rule table as active
	for i : 1 .. rule.nRules
	    bind r to rule.rules (i)
	    % rules(*).patternTP
	    markTree (r.patternTP)
	    % rules(*).replacementTP
	    markTree (r.replacementTP)
	    % rules(*).prePattern(*).patternTP, rules(*).prePattern(*).replacementTP
	    for p : 1 .. r.prePattern.nparts
		markTree (rule.ruleParts (r.prePattern.partsBase + p).patternTP)
		markTree (rule.ruleParts (r.prePattern.partsBase + p).replacementTP)
	    end for
	    % rules(*).postPattern(*).patternTP, rules(*).postPattern(*).replacementTP
	    for p : 1 .. r.postPattern.nparts
		markTree (rule.ruleParts (r.postPattern.partsBase + p).patternTP)
		markTree (rule.ruleParts (r.postPattern.partsBase + p).replacementTP)
	    end for
	end for

	%  mark all trees and kids used in called rules we are in as active
	for c : 0 .. callDepth
	    bind localVars to localsListT@(callEnvironment (c).localsListAddr)
	    markTree (callEnvironment (c).scopeTP)
	    for v : 1 .. localVars.nlocals
		markTree (valueTP (callEnvironment (c).valuesBase + v))
	    end for
	    markTree (callEnvironment (c).resultTP)
	    markTree (callEnvironment (c).newscopeTP)
	end for
	
	% zero all inactive trees and kids to indicate they are free
	unmarkTrees 
	unmarkKids 
	
	% check we have enough space left to work in
	if (maxTrees - tree.treeCount) < maxTrees div 10 or (maxKids - tree.kidCount) < maxKids div 10 then
	    error ("", "Garbage recovery unable to recover enough space to continue (a larger size is required for this transform)", FATAL, 922)
	end if

	% change strategies to scavenge from free trees and kids
	tree.setAllocationStrategy (scavenge)

	#if CHECKED then
	    % Verify treespace integrity after garbage collection
	    checkActiveTrees
	#end if

    end recoverGarbage

end garbageRecovery
