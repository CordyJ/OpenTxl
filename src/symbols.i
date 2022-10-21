% OpenTxl Version 11 symbol table
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

% The nonterminal symbol table.
% Define and maintain the table of nonterminal symbol grammar tree.
% Not used for the TXL boostrap, which has its own private nonterminal symbol table.

% Modification Log

% v11.0	Initial revision, revised from FreeTXL 10.8b (c) 1988-2022 Queen's University at Kingston


module symbol
    import 
	var ident, var tree, 
	error, externalType

    export 
	symbols, nSymbols, UNDEFINED,
	enterSymbol, lookupSymbol, findSymbol
    
    % The TXL program nonterminal symbol table 
    % Nonterminal defines are compiled into grammar trees for the defined nonterminal symbols, stored here
    var symbols : array 1 .. maxSymbols of treePT
    var nSymbols := 0
    const * UNDEFINED := - 1

    % Symbol Table Operations

    function enterSymbol (partId : tokenT, kind : kindT) : int
	#if not NOCOMPILE then
	    for p : 1 .. nSymbols
		if tree.trees (symbols (p)).name = partId then
		    assert kind = kindT.undefined or tree.trees (symbols (p)).kind = kind
		    result p
		end if
	    end for

	    if nSymbols = maxSymbols then
		error ("", "Too many defined nonterminal types (> " + intstr (maxSymbols, 1) + ")", LIMIT_FATAL, 111)
	    end if

	    nSymbols += 1
	    symbols (nSymbols) := tree.newTreeInit (kind, partId, partId, 0, nilKid)
	    result nSymbols
	#end if
    end enterSymbol

    function lookupSymbol (partId : tokenT) : int
	% returns UNDEFINED if symbol is not defined
	for p : 1 .. nSymbols
	    if tree.trees (symbols (p)).name = partId then
		result p
	    end if
	end for

	result UNDEFINED
    end lookupSymbol

    function findSymbol (partId : tokenT) : int
	#if not NOCOMPILE then
	    for p : 1 .. nSymbols
		if tree.trees (symbols (p)).name = partId then
		    result p
		end if
	    end for

	    error ("", "[" + externalType (string@(ident.idents (partId))) + "] has not been defined", FATAL, 112)
	    result UNDEFINED
	#end if
    end findSymbol

end symbol
