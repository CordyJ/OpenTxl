% OpenTxl Version 11 input tokens
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

% The TXL input token array.
% The scanner converts input text into this array of input tokens.

% Modification Log

% v11.0	Initial revision, revised from FreeTXL 10.8b (c) 1988-2022 Queen's University at Kingston
%	Removed unused external rule statement.
%	Removed old COBOL specializations.

% Tokens are represented by their ident table index for efficiency
type * tokenT : int		% allows maxIdents as large as we like
const * NOT_FOUND := 0		% actually index of chr (0), but that is meaningless

% Trees are represented by their tree table index
type * treePT : int		% allows maxTrees as large as we like

% Kinds of trees in TXL trees - defined here so that we can encode
% literal kinds in the token table
type * kindT :
    packed enum (
	% structuring trees
	    order, choose, repeat, list,
	% structure generator trees
	    leftchoose, generaterepeat, generatelist, lookahead, push, pop,
	% the empty tree
	    empty, 
	% leaf trees 
	    literal, stringlit, charlit, token, id, upperlowerid, upperid, 
	    lowerupperid, lowerid, number, floatnumber, decimalnumber, 
	    integernumber, comment, key, space, newline, srclinenumber, srcfilename,
	% user specified leaves
	    usertoken1, usertoken2, usertoken3, usertoken4, usertoken5, 
	    usertoken6, usertoken7, usertoken8, usertoken9, usertoken10,
	    usertoken11, usertoken12, usertoken13, usertoken14, usertoken15, 
	    usertoken16, usertoken17, usertoken18, usertoken19, usertoken20,
	    usertoken21, usertoken22, usertoken23, usertoken24, usertoken25, 
	    usertoken26, usertoken27, usertoken28, usertoken29, usertoken30,
	% special trees 
	    firstTime, subsequentUse, expression, lastExpression, ruleCall, 
	    undefined)
	    
% Order of the above is very important - it is used to optimize the transformation!
const * firstTreeKind := kindT.order
const * firstStructureKind := kindT.order
const * lastStructureKind := kindT.list
const * firstLeafKind := kindT.empty
const * firstLiteralKind := kindT.literal
const * lastLiteralKind := kindT.usertoken30
const * lastLeafKind := kindT.usertoken30
const * firstSpecialKind := kindT.firstTime
const * lastSpecialKind := kindT.ruleCall
const * lastTreeKind := kindT.undefined

assert lastStructureKind < firstLeafKind and ord (firstLiteralKind) = ord (firstLeafKind) + 1
    and firstLeafKind = kindT.empty and firstLiteralKind = kindT.literal and lastLeafKind < firstSpecialKind
	    
const * firstUserTokenKind : kindT := kindT.usertoken1
const * lastUserTokenKind : kindT := kindT.usertoken30

% Token kind to type identifier mapping - initialized in shared.i
var kindType : array ord (firstTreeKind) .. ord (lastTreeKind) of tokenT 

% The input token table - assists in full backup parsing of both input and tokenPatterns
type * tokenTableT :
    record
	token :	    tokenT	% ident index
	rawtoken:   tokenT	% raw ident index
	kind :	    kindT	% token/tree kind
	linenum :   int		% source file and line number
	tree :	    treePT	% shared tree optimization - all instances of the same token share one tree
    end record

type * tokenIndexT : int

var inputTokens : array 1 .. maxTokens of tokenTableT

% The current, last and furthest accepted token in the table
var currentTokenIndex, lastTokenIndex, failTokenIndex : tokenIndexT

