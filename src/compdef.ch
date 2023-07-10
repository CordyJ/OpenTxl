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

% The TXL grammar compiler.
% Compiles the grammar defines in the TXL program into a grammar tree which encodes the generic
% parse tree used by the parser to generate a parse tree for the input language input tokens.
% Takes as input the parsed TXL program as a parse tree according to the TXL bootstrap grammar
% and processes the contents of each parsed define statement. Builds a table of grammar trees
% for each defined symbol, and returns the grammar tree for the [program] symbol.

% Modification Log

% v11.0 Initial revision, revised from FreeTXL 10.8b (c) 1988-2022 Queen's University at Kingston
%       Remodularized to improve maintainability

parent "txl.t"

stub module defineCompiler
    import 
        var tree, var tree_ops, var ident, var symbol, txltree,
        error, options, kindType, externalType

    export 
        makeGrammarTree

    procedure makeGrammarTree (txlParseTreeTP : treePT, var inputGrammarTreeTP : treePT)

end defineCompiler


body module defineCompiler

    procedure processOpt (XT : tokenT, var optTP : treePT)

        %  [opt X]   ==>   opt__X  where
        %       opt__X     -->   [X]   |   [empty]

        % First check to see if we've already done one of these
        const optXtoken := ident.install ("opt__" + string@(ident.idents (XT)), kindT.id)
        var optIndex := symbol.lookupSymbol (optXtoken)

        if optIndex not= symbol.UNDEFINED then
            % We're in luck, one exists already, so share it!
            optTP := symbol.symbols (optIndex)

        else
            % It's a new one, so build it
            const Xindex := symbol.enterSymbol (XT, kindT.undefined)    % possibly not defined yet 
            const XTP := symbol.symbols (Xindex)
        
            optIndex := symbol.enterSymbol (optXtoken, kindT.choose)
            optTP := symbol.symbols (optIndex)
        
            tree.makeTwoKids (optTP, XTP, emptyTP)
        end if

    end processOpt


    procedure processAttribute (XT : tokenT, var attrTP : treePT)

        %  [attr X]   ==>   attr__X  where
        %       attr__X    -->   [attr_1_X]   |   [empty]
        %       attr_1_X   -->   [ATTR] [X]

        % First check to see if we've already done one of these
        const attrXtoken := ident.install ("attr__" + string@(ident.idents (XT)), kindT.id)
        var attrIndex := symbol.lookupSymbol (attrXtoken)

        if attrIndex not= symbol.UNDEFINED then
            % We're in luck, one exists already, so share it!
            attrTP := symbol.symbols (attrIndex)

        else
            % It's a new one, so build it
            const Xindex := symbol.enterSymbol (XT, kindT.undefined)    % possibly not defined yet
            const XTP := symbol.symbols (Xindex)
        
            attrIndex := symbol.enterSymbol (attrXtoken, kindT.choose)
            attrTP := symbol.symbols (attrIndex)
        
            const attr1XToken := ident.install ("attr_1_" + string@(ident.idents (XT)), kindT.id)
            const attr1XIndex := symbol.enterSymbol (attr1XToken, kindT.order)
            const attr1XTP := symbol.symbols (attr1XIndex)

            const ATTRindex := symbol.lookupSymbol (ATTR_T)
            const ATTR_TP := symbol.symbols (ATTRindex)
        
            tree.makeTwoKids (attr1XTP, ATTR_TP, XTP)
            tree.makeTwoKids (attrTP, attr1XTP, emptyTP)
        end if

    end processAttribute


    procedure processLookahead (XT : tokenT, var seeTP : treePT, seeNot : string)

        %  [see X]   ==>   [(look)see__X]  where
        %       (look)see__X  -->   [X]  |  [SEE]
        %       SEE           -->   [empty]
        
        % ( and similarly for [not X] )

        % First check to see if we've already done one of these
        const seeXtoken := ident.install (seeNot + "__" + string@(ident.idents (XT)), kindT.id)
        var seeIndex := symbol.lookupSymbol (seeXtoken)

        if seeIndex not= symbol.UNDEFINED then
            % We're in luck, one exists already, so share it!
            seeTP := symbol.symbols (seeIndex)

        else
            % It's a new one, so build it
            const Xindex := symbol.enterSymbol (XT, kindT.undefined)    % possibly not defined yet
            const XTP := symbol.symbols (Xindex)
        
            seeIndex := symbol.enterSymbol (seeXtoken, kindT.lookahead)
            seeTP := symbol.symbols (seeIndex)
        
            var SEEindex : int
            if seeNot = "see" then
                SEEindex := symbol.lookupSymbol (SEE_T)
            else
                SEEindex := symbol.lookupSymbol (NOT_T)
            end if
            const SEE_TP := symbol.symbols (SEEindex)
        
            tree.makeTwoKids (seeTP, XTP, SEE_TP)
        end if

    end processLookahead
    
    
    procedure processPushPop (XT : tokenT, var pushTP : treePT, pushPop : string)

        %  [push X]   ==>   [(push)push__X]  where
        %       (push)push__X  -->   [X] 
        
        % ( and similarly for [pop X] )

        % First check to see if we've already done one of these
        const pushXtoken := ident.install (pushPop + "__" + string@(ident.idents (XT)), kindT.id)
        var pushIndex := symbol.lookupSymbol (pushXtoken)

        if pushIndex not= symbol.UNDEFINED then
            % We're in luck, one exists already, so share it!
            pushTP := symbol.symbols (pushIndex)

        else
            % It's a new one, so build it
            const Xindex := symbol.enterSymbol (XT, kindT.undefined)    % possibly not defined yet
            const XTP := symbol.symbols (Xindex)
        
            if pushPop = "push" then
                pushIndex := symbol.enterSymbol (pushXtoken, kindT.push)
            else
                pushIndex := symbol.enterSymbol (pushXtoken, kindT.pop)
            end if

            pushTP := symbol.symbols (pushIndex)
        
            tree.makeOneKid (pushTP, XTP)
        end if

    end processPushPop
    

    procedure processRepeat (XT : tokenT, var repeatTP, repeatFirstTP : treePT)

        %  [repeat X]   ==>   [(gen)repeat_0_X], where
        %       (gen)repeat_0_X   -->   [X]
        %  [repeat X+]  ==>   [repeat_1_X], where
        %          repeat_1_X   -->  [X] [(gen)repeat_0_X]

        % First check to see if we've already done one of these
        const repeatXtoken := ident.install ("repeat_0_" + string@(ident.idents (XT)), kindT.id)
        var repeatIndex := symbol.lookupSymbol (repeatXtoken)

        if repeatIndex not= symbol.UNDEFINED then
            % We're in luck, one exists already, so share it!
            repeatTP := symbol.symbols (repeatIndex)
            assert tree.trees (symbol.symbols (repeatIndex + 1)).kind = kindT.repeat
            repeatFirstTP := symbol.symbols (repeatIndex + 1)
            
        else
            % It's a new one, so build it
            const Xindex := symbol.enterSymbol (XT, kindT.undefined)    % possibly not yet defined
            const XTP := symbol.symbols (Xindex)
        
            repeatIndex := symbol.enterSymbol (repeatXtoken, kindT.generaterepeat)
            repeatTP := symbol.symbols (repeatIndex)
            tree.makeOneKid (repeatTP, XTP)
        
            const repeatOneToken := ident.install ("repeat_1_" + string@(ident.idents (XT)), kindT.id)
            const repeatOneIndex := symbol.enterSymbol (repeatOneToken, kindT.repeat)
            assert repeatOneIndex = repeatIndex + 1

            repeatFirstTP := symbol.symbols (repeatOneIndex)
            tree.makeTwoKids (repeatFirstTP, XTP, repeatTP)
        end if

    end processRepeat


    procedure processList (XT :tokenT, var listTP, listFirstTP : treePT)

        %  [list X]   ==>   [(gen)list_0_X], where
        %       (gen)list_0_X   -->   [X]
        %  [list X+]  ==>   [list_1_X], where
        %          list_1_X   -->  [X] [(gen)list_0_X]

        % First check to see if we've already done one of these
        const listXtoken := ident.install ("list_0_" + string@(ident.idents (XT)), kindT.id)
        var listIndex := symbol.lookupSymbol (listXtoken)

        if listIndex not= symbol.UNDEFINED then
            % We're in luck, one exists already, so share it!
            listTP := symbol.symbols (listIndex)
            assert tree.trees (symbol.symbols (listIndex + 1)).kind = kindT.list
            listFirstTP := symbol.symbols (listIndex + 1)
            
        else
            % It's a new one, so build it
            const Xindex := symbol.enterSymbol (XT, kindT.undefined)    % possibly net yet defined
            const XTP := symbol.symbols (Xindex)
        
            listIndex := symbol.enterSymbol (listXtoken, kindT.generatelist)
            listTP := symbol.symbols (listIndex)
            tree.makeOneKid (listTP, XTP)
        
            const listOneToken := ident.install ("list_1_" + string@(ident.idents (XT)), kindT.id)
            const listOneIndex := symbol.enterSymbol (listOneToken, kindT.list)
            assert listOneIndex = listIndex + 1
            
            listFirstTP := symbol.symbols (listOneIndex)
            tree.makeTwoKids (listFirstTP, XTP, listTP)
        end if

    end processList


    function makeListRepeatOrOptTargetT (idOrLiteralTP : treePT) : tokenT
  
        pre string@(ident.idents (tree.trees (idOrLiteralTP).name)) = "TXL_idOrLiteral_"
        assert string@(ident.idents (tree.trees (tree.kid1TP (idOrLiteralTP)).name)) = "TXL_literal_" or
                tree.trees (tree.kid1TP (idOrLiteralTP)).kind = kindT.id

        if txltree.literalP (tree.kid1TP (idOrLiteralTP)) then
            % it's a literal, so make a phoney nonterminal for it
            assert string@(ident.idents (tree.trees (tree.kid1TP (idOrLiteralTP)).name)) = "TXL_literal_"
            const terminalT := txltree.literal_tokenT (tree.kid1TP (idOrLiteralTP))
            const rawterminalT := txltree.literal_rawtokenT (tree.kid1TP (idOrLiteralTP))
            const terminalTP := tree.newTreeInit (kindT.literal, terminalT, rawterminalT, 0, nilKid)
            const terminal := string@(ident.idents (terminalT))
            const targetT := ident.install ("lit__" + terminal, kindT.id)
            const targetIndex := symbol.enterSymbol (targetT, kindT.order)
            const targetTP := symbol.symbols (targetIndex)
            tree.makeOneKid (targetTP, terminalTP)
            result targetT
        else
            % it's a nonterminal id, so simply return it
            assert tree.trees (tree.kid1TP (idOrLiteralTP)).kind = kindT.id
            const idTP := tree.kid1TP (idOrLiteralTP)
            result tree.trees (idTP).name
        end if
            
    end makeListRepeatOrOptTargetT
    
    
    procedure processOneKid (defineNameT : tokenT, literalOrBracketedIdTP : treePT, var kidTP : treePT)

        var dummyTP : treePT
        
        const literalOrBracketedId_kid1TP := tree.kid1TP (literalOrBracketedIdTP)

        if txltree.literalP (literalOrBracketedId_kid1TP) then
            % terminal
            const terminalT := txltree.literal_tokenT (literalOrBracketedId_kid1TP)
            const rawterminalT := txltree.literal_rawtokenT (literalOrBracketedId_kid1TP)
            kidTP := tree.newTreeInit (kindT.literal, terminalT, rawterminalT, 0, nilKid)

            const terminalIndex := symbol.lookupSymbol (terminalT)

            if terminalIndex not= symbol.UNDEFINED and not txltree.isQuotedLiteral (literalOrBracketedId_kid1TP) then
                error ("define '" + string@(ident.idents (defineNameT)) + "'", 
                    "Type name '" + string@(ident.idents (terminalT)) + "' used as a literal identifier (use [" + 
                    string@(ident.idents (terminalT)) + "] or '" + string@(ident.idents (terminalT)) + 
                    " instead)", WARNING, 201)
            end if

        elsif txltree.listP (literalOrBracketedId_kid1TP) then
            % [list X]
            const XTP := txltree.bracketedDescription_listRepeatOrOptTargetTP (literalOrBracketedId_kid1TP)
            const XT := makeListRepeatOrOptTargetT (XTP)
            processList (XT, kidTP, dummyTP)
 
        elsif txltree.list1P (literalOrBracketedId_kid1TP) then
            % [list1 X]
            const XTP := txltree.bracketedDescription_listRepeatOrOptTargetTP (literalOrBracketedId_kid1TP)
            const XT := makeListRepeatOrOptTargetT (XTP)
            processList (XT, dummyTP, kidTP)
 
        elsif txltree.repeatP (literalOrBracketedId_kid1TP) then
            % [repeat X]
            const XTP := txltree.bracketedDescription_listRepeatOrOptTargetTP (literalOrBracketedId_kid1TP)
            const XT := makeListRepeatOrOptTargetT (XTP)
            processRepeat (XT, kidTP, dummyTP)
 
        elsif txltree.repeat1P (literalOrBracketedId_kid1TP) then
            % [repeat1 X]
            const XTP := txltree.bracketedDescription_listRepeatOrOptTargetTP (literalOrBracketedId_kid1TP)
            const XT := makeListRepeatOrOptTargetT (XTP)
            processRepeat (XT, dummyTP, kidTP)

        elsif txltree.optP (literalOrBracketedId_kid1TP) then
            % [opt X]
            const XTP := txltree.bracketedDescription_listRepeatOrOptTargetTP (literalOrBracketedId_kid1TP)
            const XT := makeListRepeatOrOptTargetT (XTP)
            processOpt (XT, kidTP)
 
        elsif txltree.attrP (literalOrBracketedId_kid1TP) then
            % [attr X]
            const XTP := txltree.bracketedDescription_listRepeatOrOptTargetTP (literalOrBracketedId_kid1TP)
            const XT := makeListRepeatOrOptTargetT (XTP)
            processAttribute (XT, kidTP)
 
        elsif txltree.seeP (literalOrBracketedId_kid1TP) then
            % [see X]
            const XTP := txltree.bracketedDescription_listRepeatOrOptTargetTP (literalOrBracketedId_kid1TP)
            const XT := makeListRepeatOrOptTargetT (XTP)
            processLookahead (XT, kidTP, "see")
 
        elsif txltree.notP (literalOrBracketedId_kid1TP) then
            % [not X]
            const XTP := txltree.bracketedDescription_listRepeatOrOptTargetTP (literalOrBracketedId_kid1TP)
            const XT := makeListRepeatOrOptTargetT (XTP)
            processLookahead (XT, kidTP, "not")
 
        elsif txltree.fenceP (literalOrBracketedId_kid1TP) then
            % [!]
            const FENCEindex := symbol.lookupSymbol (FENCE_T)
            kidTP := symbol.symbols (FENCEindex)

        elsif txltree.pushP (literalOrBracketedId_kid1TP) then
            % [push X]
            const XTP := txltree.bracketedDescription_listRepeatOrOptTargetTP (literalOrBracketedId_kid1TP)
            const XT := makeListRepeatOrOptTargetT (XTP)
            processPushPop (XT, kidTP, "push")
 
        elsif txltree.popP (literalOrBracketedId_kid1TP) then
            % [pop X]
            const XTP := txltree.bracketedDescription_listRepeatOrOptTargetTP (literalOrBracketedId_kid1TP)
            const XT := makeListRepeatOrOptTargetT (XTP)
            processPushPop (XT, kidTP, "pop")
 
        elsif txltree.bracketedDescriptionP (literalOrBracketedId_kid1TP) then
            % [X]
            const XT := txltree.bracketedDescription_idT (literalOrBracketedId_kid1TP)
            const kidIndex := symbol.enterSymbol (XT, kindT.undefined)  % possibly not yet defined
            kidTP := symbol.symbols (kidIndex)

        else
            error ("define '" + string@(ident.idents (defineNameT)) + "'",
                "Fatal TXL error in processOneKid", INTERNAL_FATAL, 202)
        end if

    end processOneKid


    procedure processKids (defineNameT : tokenT, kidsTP : treePT, parentIndex : int, extension : boolean)

        pre not tree.plural_emptyP (kidsTP) 

        const parentTP := symbol.symbols (parentIndex)

        % allocate kids contiguously -
        % necessary for high-falutin' parser speedups!
        var kidsToCountTP := kidsTP
        var nkids := 1
        loop
            kidsToCountTP := tree.plural_restTP (kidsToCountTP)
            exit when tree.plural_emptyP (kidsToCountTP)
            nkids += 1
        end loop
        
        % if this is an extension, then we already have one kid
        if extension then 
            nkids += tree.trees (parentTP).count
        end if

        if nkids > maxDefineKids then
            error ("define '" + string@(ident.idents (defineNameT)) + "'",
                "Too many elements or alternatives in one define" +
                " (maximum " + intstr (maxDefineKids, 1) + ")", LIMIT_FATAL, 203)
        end if

        var kidListKP := tree.newKids (nkids)
        const saveKidListKP := kidListKP
        
        var firstKid := 1
        if extension then
            % install the existing kids
            var oldKidListKP := tree.trees (parentTP).kidsKP
            for kid : 1 .. tree.trees (parentTP).count
                tree.setKidTree (kidListKP, tree.kids (oldKidListKP))
                oldKidListKP += 1
                kidListKP += 1
                firstKid += 1
            end for
        end if

        tree.setKids (parentTP, saveKidListKP)
        tree.setCount (parentTP, nkids)
        
        % Now fill them in
        var kidsLeftToProcessTP := kidsTP
        for kid : firstKid .. nkids
            const literalOrBracketedIdTP := tree.plural_firstTP (kidsLeftToProcessTP)
            assert txltree.literalOrBracketedIdP (literalOrBracketedIdTP)

            var kidTP : treePT
            processOneKid (defineNameT, literalOrBracketedIdTP, kidTP)
            tree.setKidTree (kidListKP, kidTP)

            kidsLeftToProcessTP := tree.plural_restTP (kidsLeftToProcessTP)
            kidListKP += 1
        end for

    end processKids


    procedure checkUserDefinedName (name : tokenT)
        if index (string@(ident.idents (name)), "list_") = 1 or
                index (string@(ident.idents (name)), "repeat_") = 1 or
                index (string@(ident.idents (name)), "opt_") = 1 or
                index (string@(ident.idents (name)), "attr_") = 1 or
                index (string@(ident.idents (name)), "lit_") = 1 or
                index (string@(ident.idents (name)), "push_") = 1 or
                index (string@(ident.idents (name)), "pop_") = 1 or
                index (string@(ident.idents (name)), "TXL_") = 1 then
            error ("define '" + string@(ident.idents (name)) + "'",
                "'list_', 'repeat_', 'opt_', 'attr_', 'lit_', 'push_', 'pop_' and 'TXL_' name prefixes are reserved for TXL internal use", 
                FATAL, 204)
        end if
    end checkUserDefinedName


    function generateNewName (nameT : tokenT) : tokenT
        % Generate an illegal name so user can't use it
        %     >>--  Leading underscores are not legal
        const baseName := string@(ident.idents (nameT))
        var newName : string
        for i : 1 .. 1000
            newName := "__" + baseName + "_" + intstr (i) + "__"
            exit when ident.lookup (newName) = NOT_FOUND
        end for
        result ident.install (newName, kindT.id)
    end generateNewName


    procedure processDefine (defineTP : treePT)

        const defineOrRedefineT := txltree.define_defineOrRedefineT (defineTP)
        const defineNameT := txltree.define_nameT (defineTP)
        const optPreDotDotDot := txltree.define_optDotDotDotBarTP (defineTP)
        const literalsAndBracketedIds := txltree.define_literalsAndBracketedIdsTP (defineTP)
        const barOrders := txltree.define_barOrdersTP (defineTP)
        const optPostDotDotDot := txltree.define_optBarDotDotDotTP (defineTP)

        checkUserDefinedName (defineNameT)

        const symbolIndex := symbol.enterSymbol (defineNameT, kindT.undefined)  % defining it now!

        var preextension := not tree.plural_emptyP (optPreDotDotDot)
        var postextension := not tree.plural_emptyP (optPostDotDotDot)
        var extension := preextension or postextension
        
        var chooseExtension := false
        if preextension then
            chooseExtension := not tree.plural_emptyP (tree.kid2TP (tree.kid1TP (optPreDotDotDot)))
        elsif postextension then
            chooseExtension := not tree.plural_emptyP (tree.kid1TP (tree.kid1TP (optPostDotDotDot)))
        end if
        
        % We have a problem if we have both pre- and post- extensions
        if preextension and postextension then
            error ("define/redefine '" + string@(ident.idents (defineNameT)) + "'", 
                "Defines cannot be both pre- and post-extended in the same definition (split into two redefines)", 
                FATAL, 212)
        end if

        if tree.trees (symbol.symbols (symbolIndex)).kind not= kindT.undefined then
            if tree.trees (symbol.symbols (symbolIndex)).kind > kindT.literal then
                % Override of a token - bad news!
                error ("define '" + string@(ident.idents (defineNameT)) + "'", 
                    "Define overrides token definition for [" + string@(ident.idents (defineNameT)) + "]", FATAL, 205)
            else
                if extension then
                    % A new-style extended define; it can be one of four cases
                    %   ... | [X]       add new post-alternatives
                    %   [X] | ...       add new pre-alternatives
                    %   ... [X]         add new tail
                    %   [X] ...         add new head
                    
                    if chooseExtension then
                        % make sure it is a choose
                        if tree.trees (symbol.symbols (symbolIndex)).kind = kindT.order then
                            % Make it a new one-kid choose with the previous order as the one kid
                            const newNameT := generateNewName (defineNameT)
                            const newSymIndex := symbol.enterSymbol (newNameT, kindT.undefined)
                            tree.cloneTree (symbol.symbols (newSymIndex), symbol.symbols (symbolIndex))
                            tree.setName (symbol.symbols (newSymIndex), newNameT)
                            tree.setRawName (symbol.symbols (newSymIndex), newNameT)
                            % now it's a choose with its former order self as kid
                            tree.setKind (symbol.symbols (symbolIndex), kindT.choose)
                            tree.makeOneKid (symbol.symbols (symbolIndex), symbol.symbols (newSymIndex))
                        end if
                    else
                        % make sure it is an order
                        if tree.trees (symbol.symbols (symbolIndex)).kind = kindT.choose then
                            % Make it a new one-kid order with the previous definition as the one kid
                            const newNameT := generateNewName (defineNameT)
                            const newSymIndex := symbol.enterSymbol (newNameT, kindT.undefined)
                            tree.cloneTree (symbol.symbols (newSymIndex), symbol.symbols (symbolIndex))
                            tree.setName (symbol.symbols (newSymIndex), newNameT)
                            tree.setRawName (symbol.symbols (newSymIndex), newNameT)
                            % now it's an order with its former choose self as kid
                            tree.setKind (symbol.symbols (symbolIndex), kindT.order)
                            tree.makeOneKid (symbol.symbols (symbolIndex), symbol.symbols (newSymIndex))
                        end if
                    end if

                elsif defineOrRedefineT not= redefine_T then
                    error ("define '" + string@(ident.idents (defineNameT)) + "'",
                        "Define overrides previous declaration ('redefine' should be used if override intended)", WARNING, 206)
                end if
            end if

        else
            if extension then
                error ("define/redefine '" + string@(ident.idents (defineNameT)) + "'",
                    "Extended define '" + string@(ident.idents (defineNameT)) 
                    + "' has not been previously defined", FATAL, 207)
            end if
        end if

        % Empty defines must be explicit
        if tree.plural_emptyP (literalsAndBracketedIds) then
            error ("define '" + string@(ident.idents (defineNameT)) + "'",
                "Empty defines not allowed - use [empty] instead", FATAL, 208)
        end if

        if tree.plural_emptyP (barOrders) and not chooseExtension then
            if not extension then
                % A new define
                tree.setKind (symbol.symbols (symbolIndex), kindT.order)
            end if

            var nOldKids : int
            
            if extension then
                % Preserve the existing kids in the new set of alternatives
                nOldKids := tree.trees (symbol.symbols (symbolIndex)).count
            end if

            processKids (defineNameT, literalsAndBracketedIds, symbolIndex, extension)

            if postextension then
                assert not preextension
                % Move the original kids to the end of the alternatives
                % E.G., [old1] [old2] [new1] [new2] => [new1] [new2] [old1] [old2]
                const kidBase := tree.trees (symbol.symbols (symbolIndex)).kidsKP
                const nkids := tree.trees (symbol.symbols (symbolIndex)).count
                for : 1 .. nOldKids
                     % Rotate the kids
                     const firstKid := tree.kids (kidBase)
                     for i : 1 .. nkids - 1
                        % (i-1)th kid := (i)th kid
                        tree.setKidTree (kidBase + i - 1, tree.kids (kidBase + i))
                     end for
                     tree.setKidTree (kidBase + nkids - 1, firstKid)
                end for
            end if
            
        else        
            if not extension then
                % A new define
                tree.setKind (symbol.symbols (symbolIndex), kindT.choose)
                tree.setKids (symbol.symbols (symbolIndex), nilKid)
            end if

            % Allocate the kids contiguously - necessary for high-falutin' parser speedups!
            var kidsToCountTP := barOrders
            var nkids := 1
            
            if extension then
                % Don't forget the previous kids!
                nkids += tree.trees (symbol.symbols (symbolIndex)).count
            end if
            
            loop
                exit when tree.plural_emptyP (kidsToCountTP)
                nkids += 1
                kidsToCountTP := tree.kid3TP (tree.kid1TP (kidsToCountTP))
            end loop

            if nkids > maxDefineKids then
                error ("define '" + string@(ident.idents (defineNameT)) + "'",
                    "Too many elements or alternatives in one define" +
                    " (maximum " + intstr (maxDefineKids, 1) + ")", LIMIT_FATAL, 210)
            end if

            var kidListKP := tree.newKids (nkids)
            
            var nextKid := 1
            var nOldKids : int
            
            if extension then
                % Preserve the existing kids in the new set of alternatives
                nOldKids := tree.trees (symbol.symbols (symbolIndex)).count
                for k : 0 .. nOldKids - 1
                    tree.setKidTree (kidListKP + k, tree.kids (tree.trees (symbol.symbols (symbolIndex)).kidsKP + k))
                end for

                tree.setKids (symbol.symbols (symbolIndex), kidListKP)
                tree.setCount (symbol.symbols (symbolIndex), nkids)

                kidListKP += nOldKids
                nextKid += nOldKids
            else
                % Begin a new set of alternative kids
                tree.setKids (symbol.symbols (symbolIndex), kidListKP)
                tree.setCount (symbol.symbols (symbolIndex), nkids)
            end if

            % Have to handle the first alternative specially since it parses slightly differently

            % A single element first alternative, e.g., [X], [opt X], [repeat X], ... 
            if tree.plural_emptyP (tree.plural_restTP (literalsAndBracketedIds)) then
                var kidTP : treePT
                processOneKid (defineNameT, tree.plural_firstTP (literalsAndBracketedIds), kidTP)
                tree.setKidTree (kidListKP, kidTP)

            % A multiple element first alternative, e.g., [X] [Y] [Z]
            else
                % Generate a new name for this first alternative, and enter it into the symbol table
                const newNameT := generateNewName (defineNameT)

                % It's an ordered sequence of elements
                const newSymIndex := symbol.enterSymbol (newNameT, kindT.order)
                processKids (defineNameT, literalsAndBracketedIds, newSymIndex, false)
                tree.setKidTree (kidListKP, symbol.symbols (newSymIndex))
            end if

            kidListKP += 1
            nextKid += 1

            var nextBarOrders := barOrders

            for barOrder : nextKid .. nkids
                % LAndBIds == LiteralsAndBracketedIds
                var nextLAndBIdsTP := tree.kid2TP (tree.kid1TP (nextBarOrders))

                if tree.plural_emptyP (nextLAndBIdsTP) then
                    error ("define '" + string@(ident.idents (defineNameT)) + "'",
                        "Empty alternatives not allowed - use [empty] instead", FATAL, 209)
                end if

                % A single element alternative, e.g., [X], [opt X], [repeat X], ... 
                if tree.plural_emptyP (tree.plural_restTP (nextLAndBIdsTP)) then
                    var kidTP : treePT
                    processOneKid (defineNameT, tree.plural_firstTP (nextLAndBIdsTP), kidTP)
                    tree.setKidTree (kidListKP, kidTP)

                % A multiple element alternative, e.g., [X] [Y] [Z]
                else
                    % Generate a new name for this alternative, and enter it into the symbol table
                    const newNameT := generateNewName (defineNameT)

                    % It's an ordered sequence of elements
                    const newSymIndex := symbol.enterSymbol (newNameT, kindT.order)
                    processKids (defineNameT, nextLAndBIdsTP, newSymIndex, false)
                    tree.setKidTree (kidListKP, symbol.symbols (newSymIndex))
                end if

                nextBarOrders := tree.kid3TP (tree.kid1TP (nextBarOrders))
                kidListKP += 1
            end for

            assert tree.plural_emptyP (nextBarOrders)
            
            if postextension then
                assert not preextension
                % Move the original kids to the end of the alternatives
                % E.G., [old1] | [old2] | [new1] | [new2] => [new1] | [new2] | [old1] | [old2]
                const kidBase := tree.trees (symbol.symbols (symbolIndex)).kidsKP
                for : 1 .. nOldKids
                     % Rotate the kids
                     const firstKid := tree.kids (kidBase)
                     for i : 1 .. nkids - 1
                        % (i-1)th kid := (i)th kid
                        tree.setKidTree (kidBase + i - 1, tree.kids (kidBase + i))
                     end for
                     tree.setKidTree (kidBase + nkids - 1, firstKid)
                end for
            end if
        end if

    end processDefine


    function isLeftRecursiveDefine (defineTP : treePT) : boolean
        % Check to see if a define is directly left recursive
        % Example :
        %       define expression
        %               [term]
        %           |   [expression1] 
        %       end define
        %
        %       define expression1
        %               [expression] + [term]
        %       end define

        if tree.trees (defineTP).kind = kindT.choose then
            % Because of overrides, we may end up with a family of names for the same nonterminal definition
            const originalDefineName := externalType (string@(ident.idents(tree.trees (defineTP).name)))

            % Check each alternative to see if it begins with a recursive reference
            const baseKid := tree.trees (defineTP).kidsKP - 1
            const nkids := tree.trees (defineTP).count

            for kid : 1 .. nkids
                % Is the first thing in this alternative a recursive reference?
                const defineKidTP := tree.kids (baseKid + kid)

                if tree.trees (defineKidTP).kind = kindT. order then 
                    % We must compare by original name in case it has been renamed by an override
                    const defineKidFirstRefName :=
                        externalType (string@(ident.idents (tree.trees (tree.kids (tree.trees (defineKidTP).kidsKP)).name))) 

                    if defineKidFirstRefName = originalDefineName then
                        % Yes, it's left recursive
                        result true
                    end if
                end if
            end for
        end if

        % Nope, it's not left recursive
        result false

    end isLeftRecursiveDefine


    procedure refactorLeftRecursiveDefine (defineTP : treePT)
        pre isLeftRecursiveDefine (defineTP) 

        % Change to left factored choice, so that the parser can build the original grammar's parse tree
        assert tree.trees (defineTP).kind = kindT.choose
        tree.setKind (defineTP, kindT.leftchoose)

        % Step 1. Sort alternatives to all non-recursives followed by all recursives 
        const baseKid := tree.trees (defineTP).kidsKP - 1
        const nkids := tree.trees (defineTP).count
        var lastNonRecursiveKid := 0

        % Bubble sort non-recursive alternativess before recursive alternatives
        for kid : 1 .. nkids
            const kidDefineTP := tree.kids (baseKid + kid)

            % Each non-recursive alternative
            if tree.trees (kidDefineTP).kind not= kindT. order 
                    or tree.kids (tree.trees (kidDefineTP).kidsKP) not= defineTP then

                % Bubble sort (to preserve order precedence) before recursive alternatives
                for decreasing k : kid .. 1
                %% for decreasing k : kid .. 2
                    lastNonRecursiveKid := k

                    exit when k = 1 %% 

                    const kDefineTP := tree.kids (baseKid + k - 1)

                    % Done when we hit a non-recursive alternative
                    exit when tree.trees (kDefineTP).kind not= kindT. order 
                        or tree.kids (tree.trees (kDefineTP).kidsKP) not= defineTP

                    % Swap
                    const thisKid := tree.kids (baseKid + k)
                    tree.setKidTree (baseKid + k, tree.kids (baseKid + k - 1))
                    tree.setKidTree (baseKid + k - 1, thisKid)
                end for
            end if
        end for

        % Step 2. Factor recursive and nonrecursive cases into subchoices 
        
            if options.option (verbose_p) then
                error ("define '" + string@(ident.idents (tree.trees (defineTP).name)) + "'", 
                    "Optimized left recursive define", INFORMATION, 213)
            end if

            % Convert E -> T | E + T to left-factored form  
            %   E -> E1 | E E2
            %   E1 -> T
            %   E2 -> + T

            % Number of non-recursive and recursive alternatives
            const nNonRecursiveKids := lastNonRecursiveKid
            const nRecursiveKids := nkids - lastNonRecursiveKid

            % First non-recursive and recursive alternatives
            const nonRecursiveKidsKP := baseKid + 1
            const recursiveKidsKP := baseKid + lastNonRecursiveKid + 1

            % Build the new define for E, with two alternatives, non-recursive (E1) and recursive (E E2)
            const newDefineKidsKP := tree.newKids (2)
            tree.setCount (defineTP, 2)
            tree.setKids (defineTP, newDefineKidsKP)

            % Build a define for E1 with all non-recursive alternatives, and enter it as first alternative of the new E
            if nNonRecursiveKids > 1 then
                % Build a define for E1
                const E1nameT := generateNewName (tree.trees (defineTP).name)
                const E1index := symbol.enterSymbol (E1nameT, kindT.choose)
                tree.setCount (symbol.symbols (E1index), nNonRecursiveKids)
                tree.setKids (symbol.symbols (E1index), nonRecursiveKidsKP)

                % Make an order node to reference E1 
                const orderNameT := generateNewName (tree.trees (defineTP).name)
                const orderIndex := symbol.enterSymbol (orderNameT, kindT.order)
                tree.setCount (symbol.symbols (orderIndex), 1)

                % Make it the first alternative of the new E
                var newKid := tree.newKid 
                tree.setKids (symbol.symbols (orderIndex), newKid)
                tree.setKidTree (tree.trees (symbol.symbols (orderIndex)).kidsKP, symbol.symbols (E1index))
                tree.setKidTree (newDefineKidsKP, symbol.symbols (orderIndex))
            else
                % Of course, if there is only one non-recursive alternative, it already is E1, 
                % so just make it the first alternative of the new E
                tree.setKidTree (newDefineKidsKP, tree.kids (nonRecursiveKidsKP))
            end if

            % Build a define for E2 with all recursive alternatives
            const E2nameT := generateNewName (tree.trees (defineTP).name)
            const E2index := symbol.enterSymbol (E2nameT, kindT.choose)
            tree.setCount (symbol.symbols (E2index), nRecursiveKids)
            tree.setKids (symbol.symbols (E2index), recursiveKidsKP)
            
            % Modify each recursive alternative to skip the recursive reference but preserve the tail
            for k : recursiveKidsKP .. recursiveKidsKP + nRecursiveKids - 1
                % Disconnect the alternative from its original nonterminal type in the symbol table,
                % since we're going to change it
                var newKidTP := tree.newTreeClone (tree.kids (k))
                tree.setKidTree (k, newKidTP)
                
                % Skip the first (recursive) element of the alternative, to leave the tail (e.g., E + T => + T)
                assert tree.trees (tree.kids (k)).kind = kindT.order
                tree.setKids (tree.kids (k), tree.trees (tree.kids (k)).kidsKP + 1)
                tree.setCount (tree.kids (k), tree.trees (tree.kids(k)).count - 1)

                % If there was no tail on it, it was a circular recursion!
                if tree.trees (tree.kids (k)).count = 0 then
                    error ("define '" + string@(ident.idents (tree.trees (defineTP).name)) + "'",
                        "Definition is circular", FATAL, 214) 
                end if
            end for
            
            % Build an order node for E E2 
            const orderNameT := generateNewName (tree.trees (defineTP).name)
            const orderIndex := symbol.enterSymbol (orderNameT, kindT.order)
            tree.makeTwoKids (symbol.symbols (orderIndex), defineTP, symbol.symbols (E2index))

            % Enter it as the second alternative for the new E
            tree.setKidTree (newDefineKidsKP + 1, symbol.symbols (orderIndex))
            
            % After tne optimization, the parse structure for a recursive alternative E -> A (E + T)
            % has been redefined to E -> A (E1 E2 (+ T)), so we must change the definition of nonterminal A 
            % to match for consistency (otherwise, for example, patterns targeted at A will fail, 
            % and other references to A will get a different parse)
            
            for k : 1 .. nRecursiveKids
                % We have to do this the hard way since copyTree will go too deep!
                
                % First the (+ T) structure - its name is presently A
                const AplusTTP := tree.kids (recursiveKidsKP + k - 1)
                const AplusTcopyTP := tree.newTreeClone (AplusTTP)      % we can share the kids here without worry, so no tree copy

                % Now build the selected E2 (+ T) structure, which is a choose with one choice
                const AE2TP := tree.newTreeClone (symbol.symbols (E2index))
                tree.makeOneKid (AE2TP, AplusTcopyTP)
                
                % Now the E1 E2 structure, which is an order
                const AE1E2TP := tree.newTreeClone (symbol.symbols (orderIndex))
                tree.makeTwoKids (AE1E2TP, tree.kids (tree.trees (symbol.symbols (orderIndex)).kidsKP) /*E1*/, AE2TP)
                                
                % Fix the names in the structure to the ones the parser will use at parse time
                % WARNING - this must be completely consistent with parse.ch!
                
                % Use redundancy of rawname to swap names without a temporary
                tree.setName (AE1E2TP, tree.trees (AplusTcopyTP).rawname)
                tree.setName (AplusTcopyTP,  tree.trees (AE1E2TP).rawname)
                tree.setRawName (AE1E2TP, tree.trees (AE1E2TP).name)
                tree.setRawName (AplusTcopyTP, tree.trees (AplusTcopyTP).name)
                                
                % Find the left recursive form's original symbol table entry
                const Aindex := symbol.lookupSymbol (tree.trees (AplusTTP).name)
                assert Aindex not= NOT_FOUND
                
                % Update rather than replace it, to make sure that all other uses
                % linked to it in the grammar are updated
                tree.cloneTree (symbol.symbols (Aindex), AE1E2TP)
            end for
        
    end refactorLeftRecursiveDefine


    procedure processImplicitType (typeT : tokenT, bracketedDescriptionTP : treePT)
        const typeIndex := symbol.lookupSymbol (typeT)

        if typeIndex = symbol.UNDEFINED then 
            % must create a grammatical form for the constructed type
            % if it is a repeat, list or opt
            var dummyTP1, dummyTP2 : treePT

            if txltree.listP (bracketedDescriptionTP) 
                    or txltree.list1P (bracketedDescriptionTP) then
                const XTP := txltree.bracketedDescription_listRepeatOrOptTargetTP (bracketedDescriptionTP)
                const XT := makeListRepeatOrOptTargetT (XTP)
                processList (XT, dummyTP1, dummyTP2)
            elsif txltree.repeatP (bracketedDescriptionTP) or txltree.repeat1P (bracketedDescriptionTP) then
                const XTP := txltree.bracketedDescription_listRepeatOrOptTargetTP (bracketedDescriptionTP)
                const XT := makeListRepeatOrOptTargetT (XTP)
                processRepeat (XT, dummyTP1, dummyTP2)
            elsif txltree.optP (bracketedDescriptionTP) then
                const XTP := txltree.bracketedDescription_listRepeatOrOptTargetTP (bracketedDescriptionTP)
                const XT := makeListRepeatOrOptTargetT (XTP)
                processOpt (XT, dummyTP1)
            elsif txltree.attrP (bracketedDescriptionTP) then
                const XTP := txltree.bracketedDescription_listRepeatOrOptTargetTP (bracketedDescriptionTP)
                const XT := makeListRepeatOrOptTargetT (XTP)
                processAttribute (XT, dummyTP1)
            elsif txltree.seeP (bracketedDescriptionTP) then
                const XTP := txltree.bracketedDescription_listRepeatOrOptTargetTP (bracketedDescriptionTP)
                const XT := makeListRepeatOrOptTargetT (XTP)
                processLookahead (XT, dummyTP1, "see")
            elsif txltree.notP (bracketedDescriptionTP) then
                const XTP := txltree.bracketedDescription_listRepeatOrOptTargetTP (bracketedDescriptionTP)
                const XT := makeListRepeatOrOptTargetT (XTP)
                processLookahead (XT, dummyTP1, "not")
            elsif txltree.pushP (bracketedDescriptionTP) then
                const XTP := txltree.bracketedDescription_listRepeatOrOptTargetTP (bracketedDescriptionTP)
                const XT := makeListRepeatOrOptTargetT (XTP)
                processPushPop (XT, dummyTP1, "push")
            elsif txltree.popP (bracketedDescriptionTP) then
                const XTP := txltree.bracketedDescription_listRepeatOrOptTargetTP (bracketedDescriptionTP)
                const XT := makeListRepeatOrOptTargetT (XTP)
                processPushPop (XT, dummyTP1, "pop")
            end if
        end if
    end processImplicitType


    procedure processRuleImplicitTypes (ruleTP : treePT)
        % make sure each constructed nonterminal is defined,
        % in case it doesn't appear in the grammar
        % (e.g. construct X [repeat blortz] )

        % TXL 11.1, optional match/replace part 
        if not tree.plural_emptyP (txltree.rule_optReplaceOrMatchPartTP (ruleTP)) then
            const ruleTargetT := txltree.rule_targetT (ruleTP)
            const targetBracketedDescriptionTP := txltree.rule_targetBracketedDescriptionTP (ruleTP)
            processImplicitType (ruleTargetT, targetBracketedDescriptionTP)
        end if

        var formalsTP := txltree.rule_formalsTP (ruleTP)
        loop
            exit when tree.plural_emptyP (formalsTP)
            const formalTargetT := txltree.formal_typeT (tree.plural_firstTP (formalsTP))
            const bracketedDescriptionTP := txltree.formal_bracketedDescriptionTP (tree.plural_firstTP (formalsTP))
            processImplicitType (formalTargetT, bracketedDescriptionTP)
            formalsTP := tree.plural_restTP (formalsTP)
        end loop
        
        var prePatternTP := txltree.rule_prePatternTP (ruleTP)
        loop
            exit when tree.plural_emptyP (prePatternTP) 
            const partTP := tree.kid1TP (tree.kid1TP (tree.kid1TP (prePatternTP)))
            if string@(ident.idents (tree.trees (partTP).name)) = "TXL_constructPart_" then
                const constructTargetT := txltree.construct_targetT (partTP)
                const bracketedDescriptionTP := txltree.construct_bracketedDescriptionTP (partTP)
                processImplicitType (constructTargetT, bracketedDescriptionTP)
            elsif string@(ident.idents (tree.trees (partTP).name)) = "TXL_exportPart_" 
                    or string@(ident.idents (tree.trees (partTP).name)) = "TXL_importPart_" then
                const importExportTargetT := txltree.import_export_targetT (partTP)
                if importExportTargetT not= NOT_FOUND then
                    const bracketedDescriptionTP := txltree.import_export_bracketedDescriptionTP (partTP)
                    processImplicitType (importExportTargetT, bracketedDescriptionTP)
                end if
            end if
            prePatternTP := tree.plural_restTP (prePatternTP)
        end loop

        var postPatternTP := txltree.rule_postPatternTP (ruleTP)
        loop
            exit when tree.plural_emptyP (postPatternTP) 
            const partTP := tree.kid1TP (tree.kid1TP (tree.kid1TP (postPatternTP)))
            if string@(ident.idents (tree.trees (partTP).name)) = "TXL_constructPart_" then
                const constructTargetT := txltree.construct_targetT (partTP)
                const bracketedDescriptionTP := txltree.construct_bracketedDescriptionTP (partTP)
                processImplicitType (constructTargetT, bracketedDescriptionTP)
            elsif string@(ident.idents (tree.trees (partTP).name)) = "TXL_exportPart_" 
                    or string@(ident.idents (tree.trees (partTP).name)) = "TXL_importPart_" then
                const importExportTargetT := txltree.import_export_targetT (partTP)
                if importExportTargetT not= NOT_FOUND then
                    const bracketedDescriptionTP := txltree.import_export_bracketedDescriptionTP (partTP)
                    processImplicitType (importExportTargetT, bracketedDescriptionTP)
                end if
            end if
            postPatternTP := tree.plural_restTP (postPatternTP)
        end loop
    end processRuleImplicitTypes


    procedure setUpBuiltins
        % Enter all of TXL's predefined nonterminals in the grammar symbol table

        var symbolIndex : int
        
        % [stringlit], e.g., "foo"
        symbolIndex := symbol.enterSymbol (stringlit_T, kindT.stringlit)

        % [charlit], e.g., 'foo'
        symbolIndex := symbol.enterSymbol (charlit_T, kindT.charlit)

        % [number], e.g. 42, 5.0, 2.4e-3
        symbolIndex := symbol.enterSymbol (number_T, kindT.number)

        % [floatnumber], [decimalnumber] and [integernumber] are specializations of [number]
        % that constrain particular [number] tokens in the grammar when parsing input,
        % but yield [number] as the parsed result 

        % [floatnumber], e.g. 2.4e-3
        symbolIndex := symbol.enterSymbol (floatnumber_T, kindT.floatnumber)

        % [decimalnumber], e.g. 2.4
        symbolIndex := symbol.enterSymbol (decimalnumber_T, kindT.decimalnumber)

        % [integernumber], e.g., 42
        symbolIndex := symbol.enterSymbol (integernumber_T, kindT.integernumber)

        % [id]
        symbolIndex := symbol.enterSymbol (id_T, kindT.id)

        % [upperlowerid], [upperid], [lowerupperid]  and [lowerid] are specializations of [id]
        % that constrain particular [id] tokens in the grammar when parsing input,
        % but yield [id] as the parsed result 

        % [upperlowerid]
        symbolIndex := symbol.enterSymbol (upperlowerid_T, kindT.upperlowerid)

        % [upperid]
        symbolIndex := symbol.enterSymbol (upperid_T, kindT.upperid)

        % [lowerupperid]
        symbolIndex := symbol.enterSymbol (lowerupperid_T, kindT.lowerupperid)

        % [lowerid]
        symbolIndex := symbol.enterSymbol (lowerid_T, kindT.lowerid)

        % [srclinenumber] and [srcfilename] are specializations of [empty]
        % that store the original input source coordinates in the parse tree

        % [srclinenumber]
        symbolIndex := symbol.enterSymbol (srclinenumber_T, kindT.srclinenumber)

        % [srcfilename]
        symbolIndex := symbol.enterSymbol (srcfilename_T, kindT.srcfilename)

        % [token] is a generalization of all input token nonterminals that accepts any kind
        % of input token ([id], [number], [stringlit], ...) that is not a defined keyword
        % in the grammar but yields the actual input token nonterminal as the parsed result

        % [token]
        symbolIndex := symbol.enterSymbol (token_T, kindT.token)

        % [key], any grammar defined keyword
        symbolIndex := symbol.enterSymbol (key_T, kindT.key)

        % [comment], any grammar defined comment 
        symbolIndex := symbol.enterSymbol (comment_T, kindT.comment)

        % [empty], always matches 
        symbolIndex := symbol.enterSymbol (empty_T, kindT.empty)

        % [space] and [newline] are only used in character input mode, -char

        % [space], any default or user defined blank space character
        symbolIndex := symbol.enterSymbol (space_T, kindT.space)

        % [newline], any default or user defined new line character
        symbolIndex := symbol.enterSymbol (newline_T, kindT.newline)

        % User-defined tokens of the "tokens" section of the language grammar
        for k : firstUserTokenKind .. lastUserTokenKind
            exit when kindType (ord (k)) = undefined_T
            symbolIndex := symbol.enterSymbol (kindType (ord (k)), k)
        end for

        % Output formatting hints [NL], [FL], [IN], [EX], [SP] and [TAB] are specializations of [empty] 
        % that always match on input. Used in the grammar to specify how output should be formatted when unparsed. 

        % [NL], a newline in the output
        symbolIndex := symbol.enterSymbol (NL_T, kindT.empty)

        % [FL] ("Fresh Line"), a newline in the output unless it is already on a new line
        symbolIndex := symbol.enterSymbol (FL_T, kindT.empty)

        % [IN], indent all following output lines by the default (4) or user-defined tab width
        symbolIndex := symbol.enterSymbol (IN_T, kindT.empty)

        % [EX], un-indent all following output lines by the default (4) or user-defined tab width
        symbolIndex := symbol.enterSymbol (EX_T, kindT.empty)

        % [SP], force a space in the output
        symbolIndex := symbol.enterSymbol (SP_T, kindT.empty)

        % [TAB], add spaces to the next default (4) or user-defined tab stop multiple in the output
        symbolIndex := symbol.enterSymbol (TAB_T, kindT.empty)

        % [TAB_NN], [IN_NN] and [EX_NN] are also allowed, where NN are digits, 
        % specifying custom columns or numbers of characters to tab or indent.
        % These are recognized as undefined symbols and added to the grammar symbol table as used.
        % See "custom formatting nonterminals" in makeGrammarTree below for details

        % [SPOFF] and [SPON] allow the grammar to specify unspaced sequences of unparsed tokens in output

        % [SPOFF], turn off all default and explicit output spacing
        symbolIndex := symbol.enterSymbol (SPOFF_T, kindT.empty)

        % [SPON], turn on all default and explicit output spacing
        symbolIndex := symbol.enterSymbol (SPON_T, kindT.empty)

        % Attributes, for adding contextual information to the parse tree
        % [attr X] is like [opt X] except that the X does not appear in the output

        % [attr X], allow for an attribute [X] at this point 
        % Represented internally using this symbol, [TXL_ATTR_]
        symbolIndex := symbol.enterSymbol (ATTR_T, kindT.empty)

        % Backup limiters, for tuning difficult grammars

        % [KEEP], permanently commit the parse to this point (backup to [KEEP] is a syntax error)
        symbolIndex := symbol.enterSymbol (KEEP_T, kindT.empty)

        % [!] or [FENCE], prevent backtracking before this point (backup to [!] fails the parent nonterminal) 
        % Represented internally by this symbol, [FENCE]
        symbolIndex := symbol.enterSymbol (FENCE_T, kindT.empty)

        % Lookahead indicators, for tuning difficult parsers

        % [see X], require that the lookahead begins with an [X]
        % Represented internally using this symbol, [TXL_SEE_]
        symbolIndex := symbol.enterSymbol (SEE_T, kindT.empty)

        % [not X], require that the lookahead does not begin with an [X]
        % Represented internally using this symbol, [TXL_NOT_]
        symbolIndex := symbol.enterSymbol (NOT_T, kindT.empty)

        % [any], the universal nonterminal, an item of any default or user-defined nonterminal type 
        % (used in patterns and rule parameters only)
        symbolIndex := symbol.enterSymbol (any_T, kindT.empty)
        
    end setUpBuiltins


    % Grammar analysis tools
    include "compdef-analyze.i"


    body procedure makeGrammarTree % (txlParseTreeTP : treePT, var inputGrammarTreeTP : treePT)
        
        % Begin by entering all the predefined nonterminals in the defined symbol table
        setUpBuiltins
        
        % The type of the TXL predefined global TXLargs [repeat stringlit], always needed
        var repeat_0_stringlit_TP, repeat_1_stringlit_TP : treePT
        processRepeat (stringlit_T, repeat_0_stringlit_TP, repeat_1_stringlit_TP)

        % Process the nonterminal define statements of the input language grammar
        var statementsLeftTP := txltree.program_statementsTP (txlParseTreeTP)

        loop
            % We're done when we've looked at every statement in the TXL program
            exit when tree.plural_emptyP (statementsLeftTP)

            % What kind of statement (define, rule, function) is it?
            const statementTP := txltree.statement_keyDefRuleTP (tree.plural_firstTP (statementsLeftTP))
            const statementKind := string@(ident.idents (tree.trees (statementTP).name))

            % If it's a nonterminal define statement, process it
            if statementKind = "TXL_defineStatement_" then
                processDefine (statementTP)

            % If it's a rule or function statement, it may use nonterminal types for which there is no define,
            % e.g., [opt X], [repeat X], [list X]
            else
                assert statementKind = "TXL_ruleStatement_" or statementKind = "TXL_functionStatement_" 
                processRuleImplicitTypes (statementTP)
            end if

            % On to the next statement
            statementsLeftTP := tree.plural_restTP (statementsLeftTP)
        end loop

        % We've processed all the statements of the TXL program -
        % make sure that there is a definition for every nonterminal type in the grammar symbol table
        var errorcount := 0

        for i : 1 .. symbol.nSymbols
            if tree.trees (symbol.symbols (i)).kind = kindT.undefined then
                const undefinedName := string@(ident.idents (tree.trees (symbol.symbols (i)).name))
                
                % The undefined nonterminal may be one of our custom formatting nonterminals
                % [TAB_NN], [IN_NN], [EX_NN] - if so, add a definition for it to the grammar symbol table
                if length (undefinedName) >= 4 
                        and (undefinedName (1..4) = "TAB_" or undefinedName (1..3) = "IN_" 
                            or undefinedName (1..3) = "EX_") then
                    % create custom output formatting symbol
                    const formatT := ident.install (undefinedName, kindT.id)
                    tree.setKind (symbol.symbols (i), kindT.empty)

                % Otherwise, it's a grammar symbol that is used but not defined
                else
                    error ("", "[" + undefinedName + "] has not been defined", DEFERRED, 218)
                    errorcount += 1
                end if
            end if
        end for

        % Undefined nonterminal grammar symbols are always fatal
        if errorcount not= 0 then
            quit
        end if
        
        % [push X] / [pop X] token matching only applies to token nonterminals
        % Check each one to be sure
        for i : 1 .. symbol.nSymbols
            if tree.trees (symbol.symbols (i)).kind = kindT.push or  tree.trees (symbol.symbols (i)).kind = kindT.pop then
                if tree.trees (tree.kid1TP (symbol.symbols (i))).kind < firstLeafKind then
                    error ("", "[push] / [pop] target must be token type", DEFERRED, 223)
                    errorcount += 1
                end if
            end if
        end for

        % Non-token [push/pop] errors are fatal
        if errorcount not= 0 then
            quit
        end if

        % Normalize left recursive defines
        for i : 1 .. symbol.nSymbols
            if isLeftRecursiveDefine (symbol.symbols (i)) then
                refactorLeftRecursiveDefine (symbol.symbols (i))
            end if
        end for
        
        % identify the root production [program]
        const programT := ident.install ("program", kindT.id)
        const programIndex := symbol.lookupSymbol (programT)
        
        if programIndex = symbol.UNDEFINED then
            error ("", "[program] has not been defined", FATAL, 219)
        end if

        inputGrammarTreeTP := symbol.symbols (programIndex)
        
        % Analyze the grammar for serious ambiguities
        if options.option (analyze_p) then
            error ("", "Analyzing the input language grammar (this may take a while)", INFORMATION, 222)

            analyzeGrammar.initialize

            for i : 1 .. symbol.nSymbols
                analyzeGrammar.checkAdjacentCombinatorialAmbiguity (symbol.symbols (i), inputGrammarTreeTP)
                analyzeGrammar.checkEmbeddedCombinatorialAmbiguity (symbol.symbols (i), inputGrammarTreeTP)
                analyzeGrammar.checkRepeatEmptyAmbiguity (symbol.symbols (i), inputGrammarTreeTP)
                analyzeGrammar.checkHiddenLeftRecursionAmbiguity (symbol.symbols (i), inputGrammarTreeTP)
            end for
        end if
        
    end makeGrammarTree

end defineCompiler
