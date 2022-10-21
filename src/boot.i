% OpenTxl Version 11 bootstrap
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

% This is the bootstrap of the parser for the TXL Source Language itself, used to parse TXL programs.
% This module builds the grammar tree for the TXL language from the pre-scanned version of the TXL grammar 
% (boot.i) automatically generated from the TXL boostrap grammar (bootstrap/Txl-11-boostrap.grm). 

% Modification Log

% v11.0	Initial revision, revised from FreeTXL 10.8b (c) 1988-2022 Queen's University at Kingston
%	Remodularized to improve maintainability

module bootstrap
    import 
	var tree, var ident, error

    export 
	makeGrammarTree

    % Automatically generated pre-scanned encoding of the TXL language grammar
    include "bootgrm.i"

    var nextToken : string

    var bootSymbols : array 1 .. maxBootstrapSymbols of treePT
    var nBootSymbols := 0


    function enterBootSymbol (partId : tokenT, kind : kindT) : int
	for s : 1 .. nBootSymbols
	    if tree.trees (bootSymbols (s)).name = partId then
		assert tree.trees (bootSymbols (s)).kind = kind
		result s
	    end if
	end for

	if nBootSymbols = maxBootstrapSymbols then
	    error ("TXL bootstrap", "Too many symbols in TXL bootstrap", INTERNAL_FATAL, 931)
	end if

	nBootSymbols += 1
	bootSymbols (nBootSymbols) := tree.newTreeInit (kind, partId, partId, 0, nilKid)
	result nBootSymbols
    end enterBootSymbol


    procedure getNextToken (expectedToken : string)
	bootstrapToken += 1
        nextToken := bootstrapStrings (bootstrapTokens (bootstrapToken))
	if expectedToken not= "" and nextToken not= expectedToken then
	    error ("TXL bootstrap", "Syntax error in TXL bootstrap - expected '" + expectedToken + "' + got '" + nextToken + "'", INTERNAL_FATAL, 932)
        end if
    end getNextToken


    procedure processDefineBody (parentIndex : int)

	% it's an order tree until we see otherwise
	tree.setKind (bootSymbols (parentIndex), kindT.order)

	% allocate first kid 
	var nKids := 0
	var kidListKP := tree.newKid
	tree.setKids (bootSymbols (parentIndex), kidListKP)

        getNextToken ("")

	loop
	    var kidTP : treePT

	    if nextToken = "[" then
		% non-terminal or builtin
		getNextToken ("")
		const identIndex := ident.install (nextToken, kindT.id)
		var kidIndex := enterBootSymbol (identIndex, kindT.id)
		kidTP := bootSymbols (kidIndex)
		getNextToken ("]")

	    else
		% literal
		if nextToken = "'" then
		    % quoted literal
		    getNextToken ("")
		end if
		const identIndex := ident.install (nextToken, kindT.id)
		kidTP := tree.newTreeInit (kindT.literal, identIndex, identIndex, 0, nilKid)
	    end if

	    nKids += 1
	    assert nKids < maxDefineKids

	    tree.setKidTree (kidListKP, kidTP)

	    getNextToken ("")

	    exit when nextToken = "end"

	    if tree.trees (bootSymbols (parentIndex)).kind = kindT.choose then
		if nextToken = "|" then
		    getNextToken ("")
		else
		    error ("TXL bootstrap", "Syntax error in TXL bootstrap - expected '|', got '" + nextToken + "'", INTERNAL_FATAL, 933)
		end if
	    elsif nextToken = "|" then
		if nKids = 1 then
		    tree.setKind (bootSymbols (parentIndex), kindT.choose)
		    getNextToken ("")
		else
		    error ("TXL bootstrap", "Syntax error in TXL bootstrap - multiple tokens in choice alternative", INTERNAL_FATAL, 934)
		end if
	    end if

	    % allocate next kid
	    kidListKP := tree.newKid 
	end loop

	% These necessary conditions for high-falutin' parser optimizations!
	tree.setCount (bootSymbols (parentIndex), nKids)

    end processDefineBody


    procedure processDefine

        getNextToken ("define")

        % get name of production
        getNextToken ("")
        const identIndex := ident.install (nextToken, kindT.id)
        const symbolIndex := enterBootSymbol (identIndex, kindT.id)

        % now process the body - in the TXL bootstrap it can only be one 
	% of two simple forms:
        %     "order", a sequence of single terminals and nonterminals,     
	%	        e.g., A [B] C [D] E, 
	%  or "choose", a choice between single terminals and nonterminals,
	%		e.g., A | [B] | C | [D] | E

	processDefineBody (symbolIndex)

	assert nextToken = "end"
	getNextToken ("define")

    end processDefine


    procedure setUpBuiltins

        var symbolIndex : int
        var identIndex : tokenT

	identIndex := ident.install ("stringlit", kindT.id)
	symbolIndex := enterBootSymbol (identIndex, kindT.stringlit)

	identIndex := ident.install ("charlit", kindT.id)
	symbolIndex := enterBootSymbol (identIndex, kindT.charlit)

	identIndex := ident.install ("number", kindT.id)
        symbolIndex := enterBootSymbol (identIndex, kindT.number)

        identIndex := ident.install ("id", kindT.id)
        symbolIndex := enterBootSymbol (identIndex, kindT.id)

        identIndex := ident.install ("token", kindT.id)
        symbolIndex := enterBootSymbol (identIndex, kindT.token)

        identIndex := ident.install ("key", kindT.id)
        symbolIndex := enterBootSymbol (identIndex, kindT.key)

	identIndex := ident.install ("empty", kindT.id)
	symbolIndex := enterBootSymbol (identIndex, kindT.empty)

        identIndex := ident.install ("KEEP", kindT.id)
        symbolIndex := enterBootSymbol (identIndex, kindT.empty)
    end setUpBuiltins
 

    procedure makeGrammarTree (var grammarTreeTP : treePT)

        % TXL grammar tree root
        const identIndex := ident.install ("program", kindT.id)
        const symbolIndex := enterBootSymbol (identIndex, kindT.id)

        grammarTreeTP := bootSymbols (symbolIndex)

	% Install the TXL built-in symbols
	setUpBuiltins

        % TXL grammar defines 
        loop
	    processDefine
            exit when bootstrapToken = numBootstrapTokens
        end loop

        % Check that there are no undefined symbols
        var errorcount := 0

        for i : 1 .. nBootSymbols
            if tree.trees (bootSymbols (i)).kind = kindT.undefined then
		error ("TXL bootstrap", "[" +
		    string@(ident.idents (tree.trees (bootSymbols (i)).name)) +
                    "] has not been defined", INTERNAL_FATAL, 935)
                errorcount += 1
            end if
        end for

        if errorcount not= 0 then
            quit
        end if

    end makeGrammarTree

end bootstrap
