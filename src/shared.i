% OpenTxl Version 11 pre-hashed tokens and names
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

% TXL pre-hashed tokens and names.
% Common names and tokens frequently used by the TXL processor are pre-hashed into the ident table 
% and globally named here to avoid repeated lookups.

% Modification Log

% v11.0	Initial revision, revised from FreeTXL 10.8b (c) 1988-2022 Queen's University at Kingston
%	Removed old COBOL specializations.


% Shared pre-hashed global common names and trees

% empty
const * empty_T := ident.install ("empty", kindT.empty)
const * emptyTP := tree.newTreeInit (kindT.empty, empty_T, empty_T, 0, nilKid)

% needed by trees.i, which precedes us and can't use emptyTP directly
tree_emptyTP := emptyTP		

% comma, dot
const * comma_T := ident.install (",", kindT.literal)
const * commaTP := tree.newTreeInit (kindT.literal, comma_T, comma_T, 0, nilKid)
const * dot_T := ident.install (".", kindT.literal)

% anonymous variable _
const * anonymous_T := ident.install ("_", kindT.id)

% formatting cues
const * NL_T := ident.install ("NL", kindT.id)
const * FL_T := ident.install ("FL", kindT.id)
const * IN_T := ident.install ("IN", kindT.id)
const * EX_T := ident.install ("EX", kindT.id)
const * SP_T := ident.install ("SP", kindT.id)
const * TAB_T := ident.install ("TAB", kindT.id)
const * SPOFF_T := ident.install ("SPOFF", kindT.id)
const * SPON_T := ident.install ("SPON", kindT.id)

% attributes (internal, implements [attr])
const * ATTR_T := ident.install ("TXL_ATTR_", kindT.id)

% parsing fences
const * KEEP_T := ident.install ("KEEP", kindT.id)
const * FENCE_T := ident.install ("FENCE", kindT.id)

% lookaheads (internal, implement [see] and [not])
const * SEE_T := ident.install ("TXL_SEE_", kindT.id)
const * NOT_T := ident.install ("TXL_NOT_", kindT.id)

% any, the polymorphic type
const * any_T := ident.install ("any", kindT.id)

% TXL language tokens
const * quote_T := ident.install ("'", kindT.literal)
const * underscore_T := ident.install ("_", kindT.id)
const * openbracket_T := ident.install ("[", kindT.literal)
const * include_T := ident.install ("include", kindT.id)
const * compounds_T := ident.install ("compounds", kindT.id)
const * comments_T := ident.install ("comments", kindT.id)
const * keys_T := ident.install ("keys", kindT.id)
const * tokens_T := ident.install ("tokens", kindT.id)
const * end_T := ident.install ("end", kindT.id)
const * redefine_T := ident.install ("redefine", kindT.id)
const * star_T := ident.install ("*", kindT.literal)
const * dollar_T := ident.install ("$", kindT.literal)
const * dotDotDot_T := ident.install ("...", kindT.literal)
const * bar_T := ident.install ("|", kindT.literal)
const * quit_T := ident.install ("quit", kindT.id)
const * assert_T := ident.install ("assert", kindT.id)
const * ignore_T := ident.install ("ignore", kindT.id)	
const * each_T := ident.install ("each", kindT.id)	
const * match_T := ident.install ("match", kindT.id)	
const * replace_T := ident.install ("replace", kindT.id)	

% internal TXL name, helps resolve unresolvable TXL parse ambiguity
const * TXL_optBar_T := ident.install ("TXL_optBar_", kindT.literal)

% TXL built-in type names, visible to the user
const * stringlit_T := ident.install ("stringlit", kindT.id)
const * charlit_T := ident.install ("charlit", kindT.id)
const * token_T := ident.install ("token", kindT.id)
const * key_T := ident.install ("key", kindT.id)
const * number_T := ident.install ("number", kindT.id)
const * floatnumber_T := ident.install ("floatnumber", kindT.id)
const * decimalnumber_T := ident.install ("decimalnumber", kindT.id)
const * integernumber_T := ident.install ("integernumber", kindT.id)
const * id_T := ident.install ("id", kindT.id)
const * comment_T := ident.install ("comment", kindT.id)
const * upperlowerid_T := ident.install ("upperlowerid", kindT.id)
const * upperid_T := ident.install ("upperid", kindT.id)
const * lowerupperid_T := ident.install ("lowerupperid", kindT.id)
const * lowerid_T := ident.install ("lowerid", kindT.id)
const * space_T := ident.install ("space", kindT.id)
const * newline_T := ident.install ("newline", kindT.id)
const * srclinenumber_T := ident.install ("srclinenumber", kindT.id)
const * srcfilename_T := ident.install ("srcfilename", kindT.id)

% TXL internal type names, not visible to the user
const * order_T := ident.install ("*order", kindT.id)
const * choose_T := ident.install ("*choose", kindT.id)
const * literal_T := ident.install ("*literal", kindT.id)
const * firstTime_T := ident.install ("*firstTime", kindT.id)
const * subsequentUse_T := ident.install ("*subsequentUse", kindT.id)
const * expression_T := ident.install ("*expression", kindT.id)
const * lastExpression_T := ident.install ("*lastExpression", kindT.id)
const * ruleCall_T := ident.install ("*ruleCall", kindT.id)
const * leftchoose_T := ident.install ("*leftchoose", kindT.id)
const * generaterepeat_T := ident.install ("*generaterepeat", kindT.id)
const * repeat_T := ident.install ("*repeat", kindT.id)
const * generatelist_T := ident.install ("*generatelist", kindT.id)
const * list_T := ident.install ("*list", kindT.id)
const * lookahead_T := ident.install ("*lookahead", kindT.id)
const * push_T := ident.install ("*push", kindT.id)
const * pop_T := ident.install ("*pop", kindT.id)
const * undefined_T := ident.install ("*undefined", kindT.id)

% TXL built-in globals, visible to the user
const * TXLargs_T := ident.install ("TXLargs", kindT.id)
const * TXLprogram_T := ident.install ("TXLprogram", kindT.id)
const * TXLinput_T := ident.install ("TXLinput", kindT.id)
const * TXLexitcode_T := ident.install ("TXLexitcode", kindT.id)


% Tree kind name maps
% var kindType : array ord (firstTreeKind) .. ord (lastTreeKind) of tokenT (declared in tokens.i)

% structuring trees - order, choose, repeat, list
kindType (ord (kindT.order)) := order_T
kindType (ord (kindT.choose)) := choose_T
kindType (ord (kindT.repeat)) := repeat_T
kindType (ord (kindT.list)) := list_T

% structure generator trees - leftchoose, generaterepeat, generatelist, lookahead, push, pop
kindType (ord (kindT.leftchoose)) := leftchoose_T
kindType (ord (kindT.generaterepeat)) := generaterepeat_T
kindType (ord (kindT.generatelist)) := generatelist_T
kindType (ord (kindT.lookahead)) := lookahead_T
kindType (ord (kindT.push)) := push_T
kindType (ord (kindT.pop)) := pop_T

% the empty tree
kindType (ord (kindT.empty)) := empty_T

% leaf trees - literal, stringlit, charlit, token, id, upperlowerid, upperid, 
% lowerupperid, lowerid, number, floatnumber, decimalnumber, 
% integernumber, comment, key, space, newline, srclinenumber, srcfilename
kindType (ord (kindT.literal)) := literal_T
kindType (ord (kindT.stringlit)) := stringlit_T
kindType (ord (kindT.charlit)) := charlit_T
kindType (ord (kindT.token)) := token_T
kindType (ord (kindT.id)) := id_T
kindType (ord (kindT.upperlowerid)) := upperlowerid_T
kindType (ord (kindT.upperid)) := upperid_T
kindType (ord (kindT.lowerupperid)) := lowerupperid_T
kindType (ord (kindT.lowerid)) := lowerid_T
kindType (ord (kindT.number)) := number_T
kindType (ord (kindT.floatnumber)) := floatnumber_T
kindType (ord (kindT.decimalnumber)) := decimalnumber_T
kindType (ord (kindT.integernumber)) := integernumber_T
kindType (ord (kindT.comment)) := comment_T
kindType (ord (kindT.key)) := key_T
kindType (ord (kindT.space)) := space_T
kindType (ord (kindT.newline)) := newline_T
kindType (ord (kindT.srclinenumber)) := srclinenumber_T
kindType (ord (kindT.srcfilename)) := srcfilename_T

% user specified leaves - actual names set by scanner
for ut : ord (kindT.usertoken1) .. ord (kindT.usertoken30)
    kindType (ut) := undefined_T
end for

% special trees - firstTime, subsequentUse, expression, lastExpression, ruleCall, undefined
kindType (ord (kindT.firstTime)) := firstTime_T
kindType (ord (kindT.subsequentUse)) := subsequentUse_T
kindType (ord (kindT.expression)) := expression_T
kindType (ord (kindT.lastExpression)) := lastExpression_T
kindType (ord (kindT.ruleCall)) := ruleCall_T
kindType (ord (kindT.undefined)) := undefined_T

% Inverse map - type kind name to tree type
function typeKind (name : tokenT) : kindT
    #if not NOCOMPILE then
	for k : firstTreeKind .. lastTreeKind
	    if kindType (ord(k)) = name then
		result k
	    end if
	end for
	result kindT.undefined
    #end if
end typeKind

% check that we haven't violated TXL compiling limits
assert tree.kidCount <= reservedKids
assert tree.treeCount <= reservedTrees
