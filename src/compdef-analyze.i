% OpenTxl Version 11 grammar compiler
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

% The TXL grammar analyzer.
% Analyzes the compiled grammar for a number of common problems.

% Modification Log

% v11.0 Initial revision, revised from FreeTXL 10.8b (c) 1988-2022 Queen's University at Kingston
%       Remodularized to improve maintainability

module analyzeGrammar
    % Grammar analysis tools - used by the grammar compiler when the -analyze command line option is specified

    import 
        var tree, tree_ops, ident, symbol, externalType, error

    export 
        initialize, checkAdjacentCombinatorialAmbiguity, checkEmbeddedCombinatorialAmbiguity, 
        checkRepeatEmptyAmbiguity, checkHiddenLeftRecursionAmbiguity
    
    % Bounded empty derivation analysis

    function boundedDerivesEmpty (defineTP : treePT, depth : int) : boolean
        % derives_empty (X)   = true if X is of kind and name empty,
        %                     = true if X is of type generatelist or generaterepeat,
        %                     = true if X is of type choose, and derives_empty (one kid of X)
        %                     = true if X is of type order, and derives_empty (all kids of X)

        if depth > symbol.nSymbols then
            % give up, don't know, probably no
            result false
        end if
        
        % Is this the one we're looking for?
        if tree.trees (defineTP).kind = kindT.empty then 
            result true
        end if
        
        % If not, is it worth looking deeper?
        if tree.trees (defineTP).kind >= firstLeafKind then
            result false
        end if
        
        % Cached result - do we already know?
        if tree.trees (defineTP).derivesEmpty = derivesT.yes then
            result true
        elsif  tree.trees (defineTP).derivesEmpty = derivesT.no then
            result false
        end if

        % Now look deeper
        if tree.trees (defineTP).kind = kindT.generaterepeat
                or tree.trees (defineTP).kind = kindT.generatelist 
                or tree.trees (defineTP).kind = kindT.lookahead then
            tree.setDerivesEmpty (defineTP, derivesT.yes)
            result true
        elsif tree.trees (defineTP).kind = kindT.leftchoose then 
            if boundedDerivesEmpty (tree.kid1TP (defineTP), depth + 1) then
                tree.setDerivesEmpty (defineTP, derivesT.yes)
                result true
            else
                tree.setDerivesEmpty (defineTP, derivesT.no)
                result false
            end if
        elsif tree.trees (defineTP).kind = kindT.choose then
            for i : 1 .. tree.trees (defineTP).count
                if boundedDerivesEmpty (tree.kidTP (i, defineTP), depth + 1) then
                    tree.setDerivesEmpty (defineTP, derivesT.yes)
                    result true
                end if
            end for
            tree.setDerivesEmpty (defineTP, derivesT.no)
            result false
        elsif tree.trees (defineTP).kind = kindT.order then
            for i : 1 .. tree.trees (defineTP).count
                if not boundedDerivesEmpty (tree.kidTP (i, defineTP), depth + 1) then
                    tree.setDerivesEmpty (defineTP, derivesT.no)
                    result false
                end if
            end for
            tree.setDerivesEmpty (defineTP, derivesT.yes)
            result true
        elsif tree.trees (defineTP).kind = kindT.repeat or tree.trees (defineTP).kind = kindT.list
                or tree.trees (defineTP).kind = kindT.push or tree.trees (defineTP).kind = kindT.pop then
            if boundedDerivesEmpty (tree.kid1TP (defineTP), depth + 1) then
                tree.setDerivesEmpty (defineTP, derivesT.yes)
                result true
            else
                tree.setDerivesEmpty (defineTP, derivesT.no)
                result false
            end if
        else 
            tree.setDerivesEmpty (defineTP, derivesT.no)
            result false
        end if
    end boundedDerivesEmpty


    % Bounded derivation analysis
    var derivesList : array 1 .. maxSymbols of treePT
    var derivesLength := 0
    var derivesThroughRepeat := false
    
    function boundedDerives (defineTP, targetTP : treePT, throughRepeat : boolean, depth : int) : boolean
        % derives (X,Y)   = true if X is of type Y,
        %                 = true if X is of type choose, and derives (one kid of X,Y)
        %                 = true if X is of type order, and derives (one kid of X,Y)
        %                                               and derives (other kids of X,empty)

        if depth > symbol.nSymbols then
            % give up, don't know, probably no
            result false
        end if
        
        % Is this the one we're looking for?
        if tree.trees (defineTP).kind = tree.trees (targetTP).kind 
                and (tree.trees (defineTP).name = tree.trees (targetTP).name or tree.trees (targetTP).kind = kindT.empty) then 
            derivesThroughRepeat := throughRepeat
            result true
        end if
        
        % If not, is it worth looking deeper?
        if tree.trees (defineTP).kind >= firstLeafKind then
            result tree.trees (defineTP).kind = kindT.token and tree.trees (targetTP).kind >= firstLiteralKind
        end if

        % Keep track of where we've already looked
        if depth = 0 then
            derivesLength := 0
        end if
        
        for i : 1 .. derivesLength
            if tree.trees (derivesList (i)).name = tree.trees (defineTP).name
                    and tree.trees (derivesList (i)).kind = tree.trees (defineTP).kind then
                % been there, done that
                result false    % ??? true, no?
            end if
        end for
        
        assert derivesLength < symbol.nSymbols
        derivesLength += 1
        derivesList (derivesLength) := defineTP
        
        % Now look deeper
        if tree.trees (defineTP).kind = kindT.generaterepeat
                or tree.trees (defineTP).kind = kindT.generatelist then
            result tree.trees (targetTP).kind = kindT.empty
                    or boundedDerives (tree.kid1TP (defineTP), targetTP, true, depth + 1)
        elsif tree.trees (defineTP).kind = kindT.lookahead then
            result tree.trees (targetTP).kind = kindT.empty
        elsif tree.trees (defineTP).kind = kindT.leftchoose then 
            result boundedDerives (tree.kid1TP (defineTP), targetTP, throughRepeat, depth + 1)
                or boundedDerives (tree.kid1TP (defineTP), emptyTP, throughRepeat, depth + 1)
                   and boundedDerives (tree.kid2TP (tree.kid2TP (defineTP)), targetTP, throughRepeat, depth + 1)
        elsif tree.trees (defineTP).kind = kindT.choose then
            for i : 1 .. tree.trees (defineTP).count
                if boundedDerives (tree.kidTP (i, defineTP), targetTP, throughRepeat, depth + 1) then
                    result true
                end if
            end for
            result false
        elsif tree.trees (defineTP).kind = kindT.order then
            for i : 1 .. tree.trees (defineTP).count
                if boundedDerives (tree.kidTP (i, defineTP), targetTP, throughRepeat, depth + 1) then
                    if i < tree.trees (defineTP).count then
                        for j : i + 1 .. tree.trees (defineTP).count
                            exit when not boundedDerivesEmpty (tree.kidTP (j, defineTP), depth + 1)
                            if j = tree.trees (defineTP).count then
                                derivesThroughRepeat := throughRepeat
                                result true
                            end if
                        end for
                    else
                        result true
                    end if
                end if
                exit when not boundedDerivesEmpty (tree.kidTP (i, defineTP), depth + 1)
            end for
            result false
        elsif tree.trees (defineTP).kind = kindT.repeat or tree.trees (defineTP).kind = kindT.list then
            assert tree.trees (defineTP).count = 2
            result boundedDerives (tree.kid1TP (defineTP), targetTP, true, depth + 1)
                or (boundedDerives (tree.kid1TP (defineTP), emptyTP, false, depth + 1)
                    and boundedDerives (tree.kid2TP (defineTP), targetTP, true, depth + 1))
        elsif tree.trees (defineTP).kind = kindT.push or tree.trees (defineTP).kind = kindT.pop then
            result boundedDerives (tree.kid1TP (defineTP), targetTP, true, depth + 1)
        else 
            result false
        end if
    end boundedDerives
    
    
    function derives (defineTP, targetTP : treePT) : boolean
        if tree.trees (targetTP).kind = kindT.empty then
            result boundedDerivesEmpty (defineTP, 0)
        else
            result boundedDerives (defineTP, targetTP, false, 0)
        end if
    end derives


    var derivesLeadingList : array 1 .. maxSymbols of treePT
    var derivesLeadingLength := 0

    function boundedDerivesLeading (defineTP, targetTP : treePT, depth : int) : boolean
        % derivesLeading (X,Y)   = true if X is of type Y,
        %                 = true if X is of type choose, and derivesLeading (one kid of X,Y)
        %                 = true if X is of type order, and derivesLeading (one kid of X,Y)
        %                                               and derivesLeading (previous kids of X,empty)
        
        if depth > symbol.nSymbols then
            % give up, don't know, probably no
            result false
        end if
        
        % Is this the one we're looking for?
        if tree.trees (defineTP).kind = tree.trees (targetTP).kind 
            and (tree.trees (defineTP).name = tree.trees (targetTP).name or tree.trees (targetTP).kind = kindT.empty) then 
            result true
        end if
        
        % If not, is it worth looking deeper?
        if tree.trees (defineTP).kind >= firstLeafKind then
            result tree.trees (defineTP).kind = kindT.token and tree.trees (targetTP).kind >= firstLiteralKind 
        end if

        % Keep track of where we've already looked
        if depth = 0 then
            derivesLeadingLength := 0
        end if
        
        for i : 1 .. derivesLeadingLength
            if tree.trees (derivesLeadingList (i)).name = tree.trees (defineTP).name
                    and tree.trees (derivesLeadingList (i)).kind = tree.trees (defineTP).kind then
                % been there, done that
                result false
            end if
        end for
        
        assert derivesLeadingLength < symbol.nSymbols
        derivesLeadingLength += 1
        derivesLeadingList (derivesLeadingLength) := defineTP
        
        % Now look deeper
        if tree.trees (defineTP).kind = kindT.generaterepeat
                or tree.trees (defineTP).kind = kindT.generatelist then
            result tree.trees (targetTP).kind = kindT.empty
                    or boundedDerivesLeading (tree.kid1TP (defineTP), targetTP, depth + 1) 
        elsif tree.trees (defineTP).kind = kindT.lookahead then
            result tree.trees (targetTP).kind = kindT.empty
        elsif tree.trees (defineTP).kind = kindT.leftchoose then 
            result boundedDerivesLeading (tree.kid1TP (defineTP), targetTP, depth + 1)
                or derives (tree.kid1TP (defineTP), emptyTP)
                   and boundedDerivesLeading (tree.kid2TP (tree.kid2TP (defineTP)), targetTP, depth + 1) 
        elsif tree.trees (defineTP).kind = kindT.choose then
            for i : 1 .. tree.trees (defineTP).count
                if boundedDerivesLeading (tree.kidTP (i, defineTP), targetTP, depth + 1) then
                    result true
                end if
            end for
            result false
        elsif tree.trees (defineTP).kind = kindT.order then
            for i : 1 .. tree.trees (defineTP).count
                if boundedDerivesLeading (tree.kidTP (i, defineTP), targetTP, depth + 1) then
                    result true
                end if
                exit when not derives (tree.kidTP (i, defineTP), emptyTP)
            end for
            result false
        elsif tree.trees (defineTP).kind = kindT.repeat or tree.trees (defineTP).kind = kindT.list then
            assert tree.trees (defineTP).count = 2
            result boundedDerivesLeading (tree.kid1TP (defineTP), targetTP, depth + 1)
                or (derives (tree.kid1TP (defineTP), emptyTP)
                    and boundedDerivesLeading (tree.kid2TP (defineTP), targetTP, depth + 1)) 
        elsif tree.trees (defineTP).kind = kindT.push or tree.trees (defineTP).kind = kindT.pop then
            result boundedDerivesLeading (tree.kid1TP (defineTP), targetTP, depth + 1)
        else 
            result false
        end if
    end boundedDerivesLeading
    
    
    function derivesLeading (defineTP, targetTP : treePT) : boolean
        result boundedDerivesLeading (defineTP, targetTP, 0)
    end derivesLeading


    function boundedContains (defineTP, targetTP : treePT, depth : int) : boolean
        % contains (X,Y)  = true if X is of type Y,
        %                 = true if X is of type choose or order, and contains (one kid of X,Y)

        if depth > symbol.nSymbols then
            % give up, don't know, probably no
            result false
        end if
        
        % Is this the one we're looking for?
        if tree.trees (defineTP).kind = tree.trees (targetTP).kind 
                and (tree.trees (defineTP).name = tree.trees (targetTP).name or tree.trees (targetTP).kind = kindT.empty) then 
            result true
        end if
        
        % If not, is it worth looking deeper?
        if tree.trees (defineTP).kind >= firstLeafKind then
            result tree.trees (defineTP).kind = kindT.token and tree.trees (targetTP).kind >= firstLiteralKind
        end if

        % Keep track of where we've already looked, using same list as derives()
        if depth = 0 then
            derivesLength := 0
        end if
        
        for i : 1 .. derivesLength
            if tree.trees (derivesList (i)).name = tree.trees (defineTP).name
                    and tree.trees (derivesList (i)).kind = tree.trees (defineTP).kind then
                % been there, done that
                result false
            end if
        end for
        
        assert derivesLength < symbol.nSymbols
        derivesLength += 1
        derivesList (derivesLength) := defineTP
        
        % Now look deeper
        if tree.trees (defineTP).kind = kindT.generaterepeat or tree.trees (defineTP).kind = kindT.generatelist then
            result boundedContains (tree.kid1TP (defineTP), targetTP, depth + 1)
        elsif tree.trees (defineTP).kind = kindT.choose or tree.trees (defineTP).kind = kindT.order 
                or tree.trees (defineTP).kind = kindT.repeat or tree.trees (defineTP).kind = kindT.list
                or tree.trees (defineTP).kind = kindT.leftchoose then
            for i : 1 .. tree.trees (defineTP).count
                if boundedContains (tree.kidTP (i, defineTP), targetTP, depth + 1) then
                    result true
                end if
            end for
            result false
        else 
            result false
        end if
    end boundedContains

        
    function contains (defineTP, targetTP : treePT) : boolean
        result boundedContains (defineTP, targetTP, 0)
    end contains


    var nSortedSymbols := 0
    var sortedSymbols : array 1 .. maxSymbols of treePT
    var sortedSymbolDepth : array 1 .. maxSymbols of int
    
    procedure sortGrammarSymbolsTraversal (grammarTP : treePT, depth : int)
    
        if grammarTP = nilTree 
                or tree.trees (grammarTP).kind = kindT.literal 
                or tree.trees (grammarTP).kind = kindT.empty then
            return
        end if
    
        % if we've already visited it, don't do so again
        for decreasing g : nSortedSymbols .. 1
            if grammarTP = sortedSymbols (g) then
                return
            end if
        end for
    
        nSortedSymbols += 1
        sortedSymbols (nSortedSymbols) := grammarTP
        sortedSymbolDepth (nSortedSymbols) := depth
    
        case tree.trees (grammarTP).kind of
            label kindT.order, kindT.repeat, kindT.list, kindT.choose, kindT.leftchoose, kindT.generaterepeat, kindT.generatelist, 
                    kindT.lookahead, kindT.push, kindT.pop :
                const kidBase := tree.trees (grammarTP).kidsKP - 1
                for k : 1 .. tree.trees (grammarTP).count
                    sortGrammarSymbolsTraversal (tree.kids (kidBase + k), depth + 1)
                end for
            label :
        end case
    end sortGrammarSymbolsTraversal
    
    
    procedure sortGrammarSymbols (grammarTP : treePT)
        nSortedSymbols := 0
        sortGrammarSymbolsTraversal (grammarTP, 1)
        for i : 1 .. nSortedSymbols - 1
            var j := i
            for k : i + 1 .. nSortedSymbols
                if sortedSymbolDepth (k) < sortedSymbolDepth (j) then
                    j := k
                end if
            end for
            if j not= i then
                const ssti := sortedSymbols (i)
                const sstd := sortedSymbolDepth (i)
                sortedSymbols (i) := sortedSymbols (j)
                sortedSymbolDepth (i) := sortedSymbolDepth (j)
                sortedSymbols (j) := ssti
                sortedSymbolDepth (j) := sstd
            end if
        end for
    end sortGrammarSymbols
    
    
    procedure checkAdjacentCombinatorialAmbiguity (defineTP : treePT, grammarTP : treePT)
        % We have an adjacent combinatorial ambiguity if an order node
        % has two effectively adjacent kids that can derive a common symbol through a repeat or list
        if tree.trees (defineTP).kind = kindT.order then
        
            sortGrammarSymbols (defineTP)
            
            const kidBase := tree.trees (defineTP).kidsKP - 1

            for i : 2 .. nSortedSymbols
                const symbolTP := sortedSymbols (i)
                
                if tree.trees (symbolTP).kind not= kindT.literal and tree.trees (symbolTP).kind not= kindT.empty then
                    for k : 1 .. tree.trees (defineTP).count - 1
                        if derives (tree.kids (kidBase + k), symbolTP) and derivesThroughRepeat then
                            for k2 : k + 1 .. tree.trees (defineTP).count
                                if derives (tree.kids (kidBase + k2), symbolTP) and derivesThroughRepeat then
                                    error ("define '" + externalType (string@(ident.idents (tree.trees (defineTP).name))) + "'",
                                        "[" + externalType (string@(ident.idents (tree.trees (defineTP).name))) 
                                        + "] is combinatorially ambiguous when parsing sequences of [" 
                                        + externalType (string@(ident.idents (tree.trees (symbolTP).name))) + "]", WARNING, 215)
                                    put : 0, "  since [", externalType (string@(ident.idents (tree.trees (defineTP).name))), "] -> " ..
                                    if k > 1 then
                                        put : 0, "... " ..
                                    end if
                                    for j : k .. k2
                                        put : 0, "[", externalType (string@(ident.idents (tree.trees (tree.kids (kidBase + j)).name))), "] " ..
                                    end for
                                    if k2 < tree.trees (defineTP).count then
                                        put : 0, " ..."
                                    else
                                        put : 0, ""
                                    end if
                                    put : 0, "   and  [", externalType (string@(ident.idents (tree.trees (tree.kids (kidBase + k)).name))), "] ->* " ..
                                    if tree.trees (tree.kids (kidBase + k)).kind not= kindT.generaterepeat and tree.trees (tree.kids (kidBase + k)).kind not= kindT.repeat 
                                            and tree.trees (tree.kids (kidBase + k)).kind not= kindT.generatelist and tree.trees (tree.kids (kidBase + k)).kind not= kindT.list then
                                        for j : 2 .. nSortedSymbols
                                            const sjTP := sortedSymbols (j)
                                            if (tree.trees (sjTP).kind = kindT.generaterepeat or tree.trees (sjTP).kind = kindT.repeat or
                                                        tree.trees (sjTP).kind = kindT.generatelist or tree.trees (sjTP).kind = kindT.list)
                                                    and derives (sjTP, symbolTP)
                                                    and derives (tree.kids (kidBase + k), sjTP) then
                                                put : 0, "[", externalType (string@(ident.idents (tree.trees (sjTP).name))), "] ->* " .. 
                                                exit
                                            end if
                                            assert j not= nSortedSymbols
                                        end for
                                    end if
                                    put : 0, "[", externalType (string@(ident.idents (tree.trees (symbolTP).name))), "]"
                                    for j : k + 1 .. k2 - 1
                                        put : 0, "   and  [", externalType (string@(ident.idents (tree.trees (tree.kids (kidBase + j)).name))), 
                                            "] ->" ..
                                        if tree.trees (tree.kids (kidBase + j)).kind not= kindT.empty then
                                            put : 0, "*" ..
                                        end if
                                        put : 0, " [empty]"
                                    end for
                                    put : 0, "   and  [", externalType (string@(ident.idents (tree.trees (tree.kids (kidBase + k2)).name))), "] ->* " ..
                                    if tree.trees (tree.kids (kidBase + k2)).kind not= kindT.generaterepeat and tree.trees (tree.kids (kidBase + k2)).kind not= kindT.repeat 
                                            and tree.trees (tree.kids (kidBase + k2)).kind not= kindT.generatelist and tree.trees (tree.kids (kidBase + k2)).kind not= kindT.list then
                                        for j : 2 .. nSortedSymbols
                                            const sjTP := sortedSymbols (j)
                                            if (tree.trees (sjTP).kind = kindT.generaterepeat or tree.trees (sjTP).kind = kindT.repeat or
                                                        tree.trees (sjTP).kind = kindT.generatelist or tree.trees (sjTP).kind = kindT.list)
                                                    and derives (sjTP, symbolTP)
                                                    and derives (tree.kids (kidBase + k2), sjTP) then
                                                put : 0, "[", externalType (string@(ident.idents (tree.trees (sjTP).name))), "] ->* " ..
                                                exit
                                            end if
                                            assert j not= nSortedSymbols
                                        end for
                                    end if
                                    put : 0, "[", externalType (string@(ident.idents (tree.trees (symbolTP).name))), "]"
                                    put : 0, "  (parsing and/or syntax error detection may be slow)"
                                    % Show only the first one we hit - in a sorted subgrammar,
                                    % this is the highest level symbol with the problem
                                    return
                                end if
                                exit when not derives (tree.kids (kidBase + k2), emptyTP)
                            end for
                        end if
                    end for
                end if
            end for
        end if
    end checkAdjacentCombinatorialAmbiguity
        
        
    procedure checkEmbeddedCombinatorialAmbiguity (defineTP : treePT, grammarTP : treePT)
        % We have a recursive combinatorial ambiguity if a repeat can derive another repeat
        if (tree.trees (defineTP).kind = kindT.generaterepeat or tree.trees (defineTP).kind = kindT.generatelist
            or tree.trees (defineTP).kind = kindT.repeat or tree.trees (defineTP).kind = kindT.list)
                and contains (grammarTP, defineTP) then
                            
            var realdefineTP := defineTP
            
            if tree.trees (defineTP).kind = kindT.repeat or tree.trees (defineTP).kind = kindT.list then
                realdefineTP := tree.kid2TP (defineTP)
            end if
            
            assert tree.trees (realdefineTP).kind = kindT.generaterepeat or tree.trees (realdefineTP).kind = kindT.generatelist

            const islist := tree.trees (realdefineTP).kind = kindT.generatelist
            realdefineTP := tree.kid1TP (realdefineTP)
                
            sortGrammarSymbols (realdefineTP)

            for k : 1 .. nSortedSymbols
                const symbolTP := sortedSymbols (k)
                if (((not islist) => (tree.trees (symbolTP).kind = kindT.generaterepeat or tree.trees (symbolTP).kind = kindT.repeat))
                            and ((islist) => (tree.trees (symbolTP).kind = kindT.generatelist or tree.trees (symbolTP).kind = kindT.list))) then
                    if derives (realdefineTP, symbolTP) then
                        error ("define '" + externalType (string@(ident.idents (tree.trees (defineTP).name))) + "'",
                            "[" + externalType (string@(ident.idents (tree.trees (defineTP).name))) 
                            + "] is combinatorially ambiguous when parsing sequences of [" 
                            + externalType (string@(ident.idents (tree.trees (tree.kid1TP (symbolTP)).name))) + "]", WARNING, 216)
                        put : 0, "  since [", externalType (string@(ident.idents (tree.trees (tree.kid1TP (defineTP)).name))), 
                            "] ->* [", externalType (string@(ident.idents (tree.trees (symbolTP).name))), "]"
                        put : 0, "  (parsing and/or syntax error detection may be slow)"
                    end if
                end if
            end for
            if derivesLeading (realdefineTP, defineTP) and not derives (realdefineTP, defineTP) then
                error ("define '" + externalType (string@(ident.idents (tree.trees (defineTP).name))) + "'",
                    "[" + externalType (string@(ident.idents (tree.trees (defineTP).name))) 
                    + "] is locally ambiguous when parsing sequences of [" 
                    + externalType (string@(ident.idents (tree.trees (tree.kid1TP (defineTP)).name))) + "]", WARNING, 217)
                put : 0, "  since [", externalType (string@(ident.idents (tree.trees (tree.kid1TP (defineTP)).name))), 
                    "] ->* [empty]* [", externalType (string@(ident.idents (tree.trees (realdefineTP).name))), "] ..."
                put : 0, "  (parsing and/or syntax error detection may be slow)"
            end if
        end if
    end checkEmbeddedCombinatorialAmbiguity


    procedure checkRepeatEmptyAmbiguity (defineTP : treePT, grammarTP : treePT)
        % We have a repeat that can derive empty
        if (tree.trees (defineTP).kind = kindT.generaterepeat or tree.trees (defineTP).kind = kindT.generatelist
            or tree.trees (defineTP).kind = kindT.repeat or tree.trees (defineTP).kind = kindT.list)
                and contains (grammarTP, defineTP) then
                            
            var realdefineTP := defineTP
            
            if tree.trees (defineTP).kind = kindT.repeat or tree.trees (defineTP).kind = kindT.list then
                realdefineTP := tree.kid2TP (defineTP)
            end if
            
            assert tree.trees (realdefineTP).kind = kindT.generaterepeat or tree.trees (realdefineTP).kind = kindT.generatelist

            if derives (tree.kid1TP (realdefineTP), emptyTP) then
                error ("define '" + externalType (string@(ident.idents (tree.trees (defineTP).name))) + "'",
                    "[" + externalType (string@(ident.idents (tree.trees (defineTP).name)))
                    + "] is locally ambiguous when parsing sequences of ["
                    + externalType (string@(ident.idents (tree.trees (tree.kid1TP (defineTP)).name))) + "]", WARNING, 220)
                put : 0, "  since [", externalType (string@(ident.idents (tree.trees (tree.kid1TP (defineTP)).name))),
                    "] ->* [empty]"
                put : 0, "  (parsing and/or syntax error detection may be slow)"
            end if
        end if
    end checkRepeatEmptyAmbiguity


    procedure checkHiddenLeftRecursionAmbiguity (defineTP : treePT, grammarTP : treePT)
        % We have a nonterminal that can directly recur on the left
        var hiddenRecursion : boolean := false

        % Don't check leaves and internal types
        if (tree.trees (defineTP).kind >= firstLeafKind and tree.trees (defineTP).kind not= kindT.literal) 
                or index (string@(ident.idents (tree.trees (defineTP).name)), "__") = 1 then
            return
        end if

        % For repeats, no need to check because repeat problems checked separately
        if tree.trees (defineTP).kind = kindT.generaterepeat or tree.trees (defineTP).kind = kindT.generatelist 
                or tree.trees (defineTP).kind = kindT.repeat or tree.trees (defineTP).kind = kindT.list 
                or tree.trees (defineTP).kind = kindT.push or tree.trees (defineTP).kind = kindT.pop then
            return
        % For lookaheads, the lookahead could go on forever if it leads with this type
        elsif tree.trees (defineTP).kind = kindT.lookahead then
            hiddenRecursion := derivesLeading (tree.kid1TP (defineTP), defineTP)
        % For leftchooses, the only problem is the first choice
        elsif tree.trees (defineTP).kind = kindT.leftchoose then 
            hiddenRecursion := derivesLeading (tree.kid1TP (defineTP), defineTP)
        % For chooses, we have a problem if any choice leads with this type
        elsif tree.trees (defineTP).kind = kindT.choose then
            for i : 1 .. tree.trees (defineTP).count
                hiddenRecursion := derivesLeading (tree.kidTP (i, defineTP), defineTP) 
                exit when hiddenRecursion
            end for
        % For orders, we have a problem if the first child leads with it, 
        % or a child that leads with it follows empty possibilities
        elsif tree.trees (defineTP).kind = kindT.order then
            for i : 1 .. tree.trees (defineTP).count
                hiddenRecursion := derivesLeading (tree.kidTP (i, defineTP), defineTP)
                exit when hiddenRecursion or not derives (tree.kidTP (i, defineTP), emptyTP)
            end for
        else 
            return
        end if

        % Warn if we find one
        if hiddenRecursion then
            error ("define '" + externalType (string@(ident.idents (tree.trees (defineTP).name))) + "'",
                "[" + externalType (string@(ident.idents (tree.trees (defineTP).name))) + "] is deeply left recursive",
                WARNING, 221)
            put : 0, "  (parsing and/or syntax error detection may be slow)"
        end if
    end checkHiddenLeftRecursionAmbiguity


    procedure initialize
        % Precompute empty potential for each type
        for i : 1 .. symbol.nSymbols
            tree.setDerivesEmpty (symbol.symbols (i), derivesT.dontknow)
        end for

        for i : 1 .. symbol.nSymbols
            if boundedDerivesEmpty (symbol.symbols (i), 0) then
                tree.setDerivesEmpty (symbol.symbols (i), derivesT.yes)
            else
                tree.setDerivesEmpty (symbol.symbols (i), derivesT.no)
            end if
        end for
    end initialize

end analyzeGrammar
