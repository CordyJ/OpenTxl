% OpenTxl Version 11 rule compiler
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

% The TXL rule compiler.
% Compiles the rule and functions in the TXL program into a rule table which encodes the pattern
% and replacement parse trees to be matched or instantiated when the rules are run.
% Takes as input the parsed TXL program as a parse tree according to the TXL bootstrap grammar
% and processes the contents of each parsed rule and function statement.

% Modification Log

% v11.0 Initial revision, revised from FreeTXL 10.8b (c) 1988-2022 Queen's University at Kingston
%       Remodularized to improve maintainability
% v11.1 Added anonymous conditions, e.g., where _ [test]
%       Fixed local variable binding bug
% v11.3 Added multiple skip criteria, e.g., skipping [x] [y] replace [z] ...

parent "txl.t"

stub module ruleCompiler
    import
        var tree, tree_ops, var ident, charset, symbol, scanner, txltree,
        var rule, var mainRule,
        var inputTokens, var lastTokenIndex, var failTokenIndex,
        var parser, var unparser,
        kindType, typeKind,
        options, error, patternError, externalType, stackBase

    export
        makeRuleTable

    procedure makeRuleTable (txlParseTreeTP : treePT)

end ruleCompiler


body module ruleCompiler

    % Current compiling context
    var context := ""
    var currentRuleIndex := 0

    % Is this program polymorphic?
    var polymorphicProgram : boolean := false


    procedure processRuleCall (scopetype : tokenT,
            ruleCallTP : treePT, varsSoFar : localsListT,
            var parsedCallTP : treePT, isConditionCall : boolean)

        var isCondition := isConditionCall

        const ruleName := txltree.ruleCall_nameT (ruleCallTP)
        var ruleIndex := rule.enterRule (ruleName)

        % Remember that we called this rule
        rule.enterRuleCall (context, currentRuleIndex, ruleIndex)

        % for rule calls, name represents called rule index
        parsedCallTP := tree.newTreeInit (kindT.ruleCall, ruleIndex, ruleIndex, 0, nilKid)

        % We process query rule calls [?R] as calls to [R]
        % The relation betweeh them is resolved later, when we discover [?R] is undefined
        if string@(ident.idents (ruleName)) (1) = "?" then
            rule.setCalled (ruleIndex, true)
            rule.setTarget (ruleIndex, scopetype)
            rule.setIsCondition (ruleIndex, true)
            const realRuleName := ident.install (string@(ident.idents (ruleName)) (2..*), kindT.id)
            ruleIndex := rule.enterRule (realRuleName)
            % Remember that we called the target rule
            rule.enterRuleCall (context, currentRuleIndex, ruleIndex)
            % And that is it not itslef a condition rule
            isCondition := false
        end if

        var eaching := false

        bind r to rule.rules (ruleIndex)

        if r.called or r.defined then
            % already defined or a successive call - must check scope and
            % parameter type consistency

            if scopetype not= r.target and r.target not= any_T and scopetype not= any_T then
                if r.defined then
                    if r.kind = ruleKind.functionRule and not r.starred then
                        error (context, "Scope of function '" + string@(ident.idents (r.name)) +
                            "' is not of target type", WARNING, 301)
                    end if
                else
                    % previously called with a different scope type
                    rule.setTarget (ruleIndex, any_T)
                end if
            end if


            if isCondition then
                if r.defined and (not r.isCondition) then
                    error (context, "'replace' rule '" + string@(ident.idents (r.name)) +
                        "' used as 'where' condition", FATAL, 302)
                end if
                rule.setIsCondition (ruleIndex, true)
            end if

            % actuals parse like literals, even when they are not!
            var literalsTP := txltree.ruleCall_literalsTP (ruleCallTP)

            var p1type, p2type := any_T

            if tree.plural_emptyP (literalsTP) then
                if r.localVars.nformals not= 0 then
                    error (context, "Number of parameters to rule/function '" +
                        string@(ident.idents (r.name)) + "' differs from definition or previous call", FATAL, 303)
                end if

                % if it is a (polymorphic) predefined function, check the type of the scope
                % now to save doing it at run time
                if r.kind = ruleKind.predefinedFunction then
                    rule.checkPredefinedFunctionScopeAndParameters (context, ruleIndex,
                        scopetype, empty_T, empty_T)
                end if

            else
                var newKid := tree.newKid
                tree.setKids (parsedCallTP, newKid)
                var parsedActualsKP : kidPT := tree.trees (parsedCallTP).kidsKP

                for actualCount : 1 .. r.localVars.nformals
                    var actualName := txltree.literal_tokenT (tree.plural_firstTP (literalsTP))
                    var actualRawName := txltree.literal_rawtokenT (tree.plural_firstTP (literalsTP))

                    % It might be an 'each' indicator
                    if actualName = each_T then
                        literalsTP := tree.plural_restTP (literalsTP)

                        if eaching or tree.plural_emptyP (literalsTP) then
                           error (context, "Rule/function '" + string@(ident.idents (r.name)) +
                                "' used with empty or double 'each'", FATAL, 304)
                        end if

                        eaching := true
                        actualName := txltree.literal_tokenT (tree.plural_firstTP (literalsTP))
                        actualRawName := txltree.literal_rawtokenT (tree.plural_firstTP (literalsTP))
                    end if

                    var newTP := tree.newTreeInit (kindT.empty, actualName, actualRawName, 0, nilKid)
                    tree.setKidTree (parsedActualsKP, newTP)

                    % We know the name, but is it a literal or a TXL variable?
                    var localIndex := 0
                    if not txltree.isQuotedLiteral (tree.plural_firstTP (literalsTP)) then
                        for i : 1 .. varsSoFar.nlocals
                            if rule.ruleLocals (varsSoFar.localBase + i).name = actualName then
                                localIndex := i
                                exit
                            end if
                        end for
                    end if

                    if localIndex not= 0 then
                        % it's a variable
                        rule.incLocalRefs (varsSoFar.localBase + localIndex, 1)

                        % keep track of the last reference if in a replacement
                        rule.setLocalLastRef (varsSoFar.localBase + localIndex, tree.kids (parsedActualsKP))
                        tree.setKind (tree.kids (parsedActualsKP), kindT.subsequentUse)
                        tree.setCount (tree.kids (parsedActualsKP), localIndex) % save looking for it later!

                        % figure out the effective type
                        var effectiveType := rule.ruleLocals (varsSoFar.localBase + localIndex).typename
                        if eaching then
                            % we're in the scope of an 'each' - indicate with non-null kidsKP
                            tree.setKids (tree.kids (parsedActualsKP), maxKids)
                            if tree_ops.isListOrRepeatType (effectiveType) then
                                effectiveType := tree_ops.listOrRepeatBaseType (effectiveType)
                            else
                               error (context, "'each' argument of rule/function '" +
                                    string@(ident.idents (r.name)) + "' is not a list or repeat", FATAL, 305)
                            end if
                        else
                            % make sure we mark it as NOT an each!
                            tree.setKids (tree.kids (parsedActualsKP), nilKid)
                        end if

                        const formalType := rule.ruleLocals (r.localVars.localBase + actualCount).typename

                        if formalType not= effectiveType and formalType not= any_T then
                            error (context, "Type of actual parameter '" +
                                string@(ident.idents (rule.ruleLocals (varsSoFar.localBase + localIndex).name)) + "'" +
                                " of rule/function '" + string@(ident.idents (r.name)) +
                                "' does not agree with definition or previous call", FATAL, 306)
                        end if

                        if actualCount = 1 then
                            p1type := effectiveType
                        elsif actualCount = 2 then
                            p2type := effectiveType
                        end if

                    else
                        % it's a literal
                        const literalKind := txltree.literal_kindT (tree.plural_firstTP (literalsTP))

                        if literalKind = kindT.id
                                and not txltree.isQuotedLiteral (tree.plural_firstTP (literalsTP)) then
                            error (context, "Literal actual parameter '" +
                                string@(ident.idents (actualRawName)) + "' of rule/function '" +
                                string@(ident.idents (r.name)) + "' is not quoted", WARNING, 307)
                        end if

                        tree.setKind (tree.kids (parsedActualsKP), literalKind)

                        const literalType := tree_ops.literalTypeName (tree.trees (tree.kids (parsedActualsKP)).kind)

                        if eaching then
                            % we're in the scope of an 'each' - so a literal can't be right!
                            error (context, "'each' argument of rule/function '" +
                                string@(ident.idents (r.name)) + "' is not a list or repeat", FATAL, 305)
                        end if

                        const formalType := rule.ruleLocals (r.localVars.localBase + actualCount).typename

                        if literalType not= formalType and formalType not= any_T then
                            error (context, "Type of actual parameter '" +
                                string@(ident.idents (actualName)) +
                                "' of rule/function '" + string@(ident.idents (r.name)) +
                                "' does not agree with definition or previous call", FATAL, 306)
                        end if

                        if actualCount = 1 then
                            p1type := literalType
                        elsif actualCount = 2 then
                            p2type := literalType
                        end if
                    end if

                    literalsTP := tree.plural_restTP (literalsTP)

                    if tree.plural_emptyP (literalsTP) then
                        if actualCount < r.localVars.nformals then
                            error (context, "Number of parameters passed to rule/function '" +
                                string@(ident.idents (r.name)) + "' differs from definition or previous call",
                                FATAL, 309)
                        end if
                        exit
                    end if

                    parsedActualsKP := tree.newKid
                end for

                % mark end of actuals with nilTree
                parsedActualsKP := tree.newKid
                tree.setKidTree (parsedActualsKP, nilTree)

                if not tree.plural_emptyP (literalsTP) then
                    error (context, "Number of parameters passed to rule/function '" +
                        string@(ident.idents (r.name)) + "' differs from definition or previous call", FATAL, 309)
                end if

                % if it is a (polymorphic) predefined function, check the types of scope
                % and parameters now to save doing it at run time
                if r.kind = ruleKind.predefinedFunction then
                    rule.checkPredefinedFunctionScopeAndParameters (context, ruleIndex, scopetype, p1type, p2type)
                end if

            end if

        else
            % first call - must enter parameter types and count
            rule.setCalled (ruleIndex, true)
            rule.setTarget (ruleIndex, scopetype)
            rule.setIsCondition (ruleIndex, isCondition)
            rule.setLocalBase (ruleIndex, rule.ruleFormalCount) % special temporary space for formal info

            % allow for maximum parameters
            if rule.ruleFormalCount + maxParameters > maxTotalParameters then
                error (context, "Too many total parameters of rules in TXL program (>" +
                    intstr (maxTotalParameters, 0) + ")", LIMIT_FATAL, 336)
            end if

            % actuals parse like literals, even when they are not!
            var literalsTP := txltree.ruleCall_literalsTP (ruleCallTP)
            var actualCount := 0

            if not tree.plural_emptyP (literalsTP) then
                var newKid := tree.newKid
                tree.setKids (parsedCallTP, newKid)
                var parsedActualsKP : kidPT := tree.trees (parsedCallTP).kidsKP
                loop
                    if actualCount = maxParameters then
                       error (context, "Too many rule/function parameters, rule/function '" +
                           string@(ident.idents (r.name)) + "' (>" + intstr (maxParameters, 0) + ")", LIMIT_FATAL, 311)
                    end if

                    actualCount += 1

                    var actualName := txltree.literal_tokenT (tree.plural_firstTP (literalsTP))
                    var actualRawName := txltree.literal_rawtokenT (tree.plural_firstTP (literalsTP))

                    % It might be an 'each' indicator
                    if actualName = each_T then
                        literalsTP := tree.plural_restTP (literalsTP)

                        if eaching or tree.plural_emptyP (literalsTP) then
                           error (context, "Rule/function '" + string@(ident.idents (r.name)) +
                                "' used with empty or double 'each'", FATAL, 312)
                        end if

                        eaching := true
                        actualName := txltree.literal_tokenT (tree.plural_firstTP (literalsTP))
                        actualRawName := txltree.literal_rawtokenT (tree.plural_firstTP (literalsTP))
                    end if

                    var newTP := tree.newTreeInit (kindT.empty, actualName, actualRawName, 0, nilKid)
                    tree.setKidTree (parsedActualsKP, newTP)

                    % We know the name, but is it a literal or a TXL variable?
                    var localIndex := 0
                    if not txltree.isQuotedLiteral (tree.plural_firstTP (literalsTP)) then
                        for i : 1 .. varsSoFar.nlocals
                            if rule.ruleLocals (varsSoFar.localBase + i).name = actualName then
                                localIndex := i
                                exit
                            end if
                        end for
                    end if

                    if localIndex not= 0 then
                        % it's a variable
                        rule.incLocalRefs (varsSoFar.localBase + localIndex, 1)

                        % keep track of the last reference if in a replacement
                        rule.setLocalLastRef (varsSoFar.localBase + localIndex, tree.kids (parsedActualsKP))
                        tree.setKind (tree.kids (parsedActualsKP), kindT.subsequentUse)
                        tree.setCount (tree.kids (parsedActualsKP), localIndex) % save looking for it later!

                        % figure out the effective type
                        var effectiveType := rule.ruleLocals (varsSoFar.localBase + localIndex).typename
                        if eaching then
                            % we're in the scope of an 'each' - indicate with non-null kidsKP
                            tree.setKids (tree.kids (parsedActualsKP), maxKids)
                            if tree_ops.isListOrRepeatType (effectiveType) then
                                effectiveType := tree_ops.listOrRepeatBaseType (effectiveType)
                            else
                               error (context, "'each' argument of rule/function '" +
                                    string@(ident.idents (r.name)) + "' is not a list or repeat", FATAL, 313)
                            end if
                        else
                            % make sure we mark it as NOT an each!
                            tree.setKids (tree.kids (parsedActualsKP), nilKid)
                        end if
                        rule.setLocalType (r.localVars.localBase + actualCount, effectiveType)
                    else
                        % it's a literal
                        const literalKind := txltree.literal_kindT (tree.plural_firstTP (literalsTP))

                        if literalKind = kindT.id
                                and not txltree.isQuotedLiteral (tree.plural_firstTP (literalsTP)) then
                            error (context, "Literal actual parameter '" +
                                string@(ident.idents (actualRawName)) + "' of rule/function '" +
                                string@(ident.idents (r.name)) + "' is not quoted", WARNING, 307)
                        end if

                        tree.setKind (tree.kids (parsedActualsKP), literalKind)

                        const literalType := tree_ops.literalTypeName (tree.trees (tree.kids (parsedActualsKP)).kind)
                        rule.setLocalType (r.localVars.localBase + actualCount, literalType)

                        if eaching then
                            % we're in the scope of an 'each' - so a literal can't be right!
                            error (context, "'each' argument of rule/function '" +
                                string@(ident.idents (r.name)) + "' is not a list or repeat", FATAL, 305)
                        end if
                    end if

                    literalsTP := tree.plural_restTP (literalsTP)
                    exit when tree.plural_emptyP (literalsTP)

                    parsedActualsKP := tree.newKid
                end loop

                % mark end of actuals with nilTree
                parsedActualsKP := tree.newKid
                tree.setKidTree (parsedActualsKP, nilTree)
            end if

            rule.setNFormals (ruleIndex, actualCount)
            rule.setNPreLocals (ruleIndex, actualCount)
            rule.setNLocals (ruleIndex, actualCount)

            % already checked this above
            rule.incFormalCount (r.localVars.nformals)
        end if

        rule.setCalled (ruleIndex, true)

    end processRuleCall


    var lastWarningTokensTP := nilTree


    procedure parseVarOrExp (patternTokensTP : treePT,
            varsSoFarAddress : addressint, productionTP : treePT, var parseTP : treePT,
            var isVarOrExp : boolean, var varOrExpMatches : boolean)

        bind var varsSoFar to localsListT@(varsSoFarAddress)

        % Parse a local variable binding or reference (patternTokensTP) in a pattern or replacement.

        % Given a local variable binding (kindT.firstTime, e.g. X[T]),
        % reference (kindT.subsequentUse or kindT.expression), or potential reference (kindT.literal),
        % determine if it really is a local variable reference (isVarOrExp),
        % and whether it matches the production nonterminal type (varOrExpMatches).

        % If so, return its parse node (parseTP) and enter or bind it to the corresponding local variable (in varsSoFar).

        if patternTokensTP = emptyTP then
            isVarOrExp := false
            return
        end if

        % Case 1: A literal identifier in a pattern or replacement
        %         may be a context-dependent reference to a local variable

        if string@(ident.idents (tree.trees (patternTokensTP).name)) = "TXL_literal_" then

            % May not be a literal: could be a subsequent use of a local variable
            var localIndex := rule.lookupLocalVar ("", varsSoFar, txltree.literal_tokenT (patternTokensTP))

            if localIndex = 0 then
                % It really was a literal after all
                isVarOrExp := false

                if not txltree.isQuotedLiteral (patternTokensTP) then
                    % Warn if it is a type name, possibly unintended error
                    const terminalT := txltree.literal_tokenT (patternTokensTP)
                    var terminalIndex := symbol.lookupSymbol (terminalT)

                    if terminalIndex not= symbol.UNDEFINED and lastWarningTokensTP not= patternTokensTP then
                        error (context, "Type name '" +
                            string@(ident.idents (terminalT)) + "' used as a literal identifier (use [" +
                            string@(ident.idents (terminalT)) + "] or '" + string@(ident.idents (terminalT)) +
                            " instead)", WARNING, 315)
                        lastWarningTokensTP := patternTokensTP
                    end if
                end if

                return
            end if

            if txltree.isQuotedLiteral (patternTokensTP) then
                % If it's quoted it really is a literal after all
                isVarOrExp := false

                % Warn if it's also a local variable name, possibly unintended error
                if lastWarningTokensTP not= patternTokensTP then
                    error (context, "Variable name '" +
                        string@(ident.idents(txltree.literal_tokenT (patternTokensTP))) +
                        "' is quoted as a literal identifier (possibly by mistake?)", WARNING, 316)
                    lastWarningTokensTP := patternTokensTP
                end if

                return
            end if

            % OK, it's not a literal, it really is a reference to a local variable
            isVarOrExp := true

            % Does it match the production nonterminal type?
            if tree_ops.treeIsTypeP (productionTP, rule.ruleLocals (varsSoFar.localBase + localIndex).typename) then
                varOrExpMatches := true

                % Successful parse of a local variable reference
                const localName := rule.ruleLocals (varsSoFar.localBase + localIndex).name
                parseTP := tree.newTreeInit (kindT.subsequentUse, localName, localName, localIndex /*save looking for it later*/, nilKid)

                % Note: subsequent uses do not count as references!

            else
                % It's a local variable reference, but doesn't match the production type, so parse fails
                varOrExpMatches := false
            end if


        % Case 2: A binding occurence of a local variable in a pattern (e.g., X[T])

        elsif string@(ident.idents (tree.trees (patternTokensTP).name)) = "TXL_firstTime_" then

            isVarOrExp := true

            var ftname := txltree.firstTime_nameT (patternTokensTP)
            if ftname = anonymous_T then
                % If it's the anonymous variable, generate a unique name for it
                ftname := ident.install ("_anonymous_" + intstr (varsSoFar.nlocals+1, 0), kindT.id)
            end if

            % Enter it in the rule's local variables
            const localIndex := rule.enterLocalVar (context, varsSoFar, ftname, txltree.firstTime_typeT (patternTokensTP))

            % Check that its production type is defined
            const symbolIndex := symbol.findSymbol (rule.ruleLocals (varsSoFar.localBase + localIndex).typename)

            % Does it match the production nonterminal type?
            if tree_ops.treeIsTypeP (productionTP, rule.ruleLocals (varsSoFar.localBase + localIndex).typename) then
                varOrExpMatches := true

                % Successful parse of a local variable binding
                const localName := rule.ruleLocals (varsSoFar.localBase + localIndex).name
                parseTP := tree.newTreeInit (kindT.firstTime, localName, localName, localIndex /*save looking for it later*/, nilKid)

            else
                % It's a local variable binding, but it doesn't match the production type, so parse fails
                varOrExpMatches := false
                % Don't forget to unenter it from the locals table, it may be tried again
                rule.unenterLocalVar (context, varsSoFar, ftname)
            end if


        % Case 3: A reference to a local variable in a replacement, possibly with rule calls

        elsif string@(ident.idents (tree.trees (patternTokensTP).name)) = "TXL_expression_" then

            % In a replacement, a reference to a local variable identifier gets parsed as a kindT.expression
            % If it's not a defined local variable, it may be a literal identifier

            var localIndex := rule.lookupLocalVar ("", varsSoFar, txltree.expression_baseT (patternTokensTP))

            if localIndex = 0 then
                % It is a literal
                isVarOrExp := false

                % Check for rule calls
                if not tree.plural_emptyP ( txltree.expression_ruleCallsTP (patternTokensTP)) then
                    % Rule calls on a literal!
                    % We force a syntax error by pretending it is a variable reference that did not match
                    isVarOrExp := true
                    varOrExpMatches := false
                end if

                if not txltree.isQuotedLiteral (patternTokensTP) then
                    % Warn if it is a type name, possibly unintended error
                    const terminalT := txltree.literal_tokenT (patternTokensTP)
                    var terminalIndex := symbol.lookupSymbol (terminalT)

                    if terminalIndex not= symbol.UNDEFINED and lastWarningTokensTP not= patternTokensTP then
                        error (context, "Type name '" +
                            string@(ident.idents (terminalT)) + "' used as a literal identifier (use [" +
                            string@(ident.idents (terminalT)) + "] or '" + string@(ident.idents (terminalT)) +
                            " instead)", WARNING, 315)
                        lastWarningTokensTP := patternTokensTP
                    end if
                end if

                return
            end if

            % OK, it's not a literal, it really is a reference to a local variable
            isVarOrExp := true

            % Does it match the production nonterminal type?
            const localVarType := rule.ruleLocals (varsSoFar.localBase + localIndex).typename

            if tree_ops.treeIsTypeP (productionTP, localVarType) then
                varOrExpMatches := true

                % Successful parse of a local variable reference in a replacement
                const expName := txltree.expression_baseT (patternTokensTP)
                parseTP := tree.newTreeInit (kindT.expression, expName, expName, localIndex /*save looking for it later*/, nilKid)

                % Counts as a use of the variable
                rule.incLocalRefs (varsSoFar.localBase + localIndex, 1)
                rule.setLocalLastRef (varsSoFar.localBase + localIndex, parseTP)

                % A local variable reference in a replacement may have rule calls (e.g., X[R1][R2})
                % Make children of type ruleCall
                var ruleCallsTP := txltree.expression_ruleCallsTP (patternTokensTP)
                const ruleCallsTPcopy := ruleCallsTP

                % Are there any rule calls?
                if not tree.plural_emptyP (ruleCallsTP) then
                    % If so, remember that they act on the local variable
                    rule.setLocalChanged (varsSoFar.localBase + localIndex, true)

                    % Pre-allocate the rule call kids to keep them contiguous for speed when transforming
                    var nkids := 1
                    loop
                        ruleCallsTP := tree.plural_restTP (ruleCallsTP)
                        exit when tree.plural_emptyP (ruleCallsTP)
                        nkids += 1
                    end loop

                    var lastKidKP := tree.newKids (nkids + 1)
                    tree.setKids (parseTP, lastKidKP)

                    % Mark the end of the rule calls with a nilTree
                    tree.setKidTree (lastKidKP + nkids, nilTree)

                    % Now fill in the kids we allocated with the rule calls
                    ruleCallsTP := ruleCallsTPcopy

                    for k : 1 .. nkids
                        var parsedCallTP : treePT
                        processRuleCall (localVarType, tree.plural_firstTP (ruleCallsTP), varsSoFar, parsedCallTP, false)
                        tree.setKidTree (lastKidKP, parsedCallTP)
                        ruleCallsTP := tree.plural_restTP (ruleCallsTP)
                        lastKidKP += 1
                    end for
                    assert tree.kids (lastKidKP) = nilTree
                end if

            else
                % It's a local variable reference, but it doesn't match the production type, so parse fails
                varOrExpMatches := false
            end if

        else
            error (context, "Fatal TXL error in parseVarOrExp", INTERNAL_FATAL, 318)
        end if

    end parseVarOrExp


    procedure parsePattern (var litsAndVarsAndExpsTP : treePT,
            varsSoFar : localsListT, productionTP : treePT, var parseTP : treePT)

        % Initialize the pattern's input tokens for parsing
        var lves := litsAndVarsAndExpsTP
        lastTokenIndex := 0
        loop
            lastTokenIndex += 1

            exit when lastTokenIndex > maxPatternTokens

            exit when tree.plural_emptyP (lves)

            bind var inputToken to inputTokens (lastTokenIndex)
            inputToken.tree := tree.kid1TP (tree.plural_firstTP (lves))
            inputToken.token := txltree.literal_tokenT (inputTokens (lastTokenIndex).tree)
            inputToken.rawtoken := txltree.literal_rawtokenT (inputTokens (lastTokenIndex).tree)
            inputToken.kind := txltree.literal_kindT (inputTokens (lastTokenIndex).tree)

            % A token may have been an id or keyword when parsed as TXL,
            % but what it is in the object language may be different!
            if inputToken.kind = kindT.id
                    or inputToken.kind = kindT.key then
                if scanner.keyP (inputToken.token) then
                    % this language thinks it's a keyword
                    inputToken.kind := kindT.key
                else
                    % nope, just a normal id
                    inputToken.kind := kindT.id
                end if
            end if

            lves := tree.plural_restTP (lves)
        end loop

        if lastTokenIndex > maxPatternTokens then
            error (context, "Pattern or replacement too large (> " + intstr (maxPatternTokens, 1) + " tokens)", LIMIT_FATAL, 319)
        end if

        bind var inputToken to inputTokens (lastTokenIndex)
        inputToken.tree := emptyTP
        inputToken.token := empty_T
        inputToken.rawtoken := empty_T
        inputToken.kind := kindT.empty

        if options.option (tree_print_p) then
            put : 0, ""
        end if

        parser.initializeParse (context, false, true, false, addr (varsSoFar), parseVarOrExp)
        parser.parse (productionTP, parseTP)

        if parseTP = nilTree then
            patternError (failTokenIndex, context, productionTP)
        end if

        if options.option (pattern_print_p) then
            var pcontext := context
            loop
                const qindex := index (pcontext, "'")
                exit when qindex = 0
                pcontext := pcontext (1 .. qindex-1) + "\"" + pcontext (qindex+1 .. *)
            end loop
            put : 0, "----- Parse Tree for ", pcontext, " -----"
            unparser.printPatternParse (parseTP, varsSoFar, 0)
            put : 0, "----- End Parse Tree -----", skip
        end if
    end parsePattern


    procedure processPatternOrReplacement (goalName : tokenT,
            patternOrReplacementTP : treePT,
            var parseTP : treePT,
            varsSoFar : localsListT)

        % This is designed to work for both patterns and replacements
        var litsAndVarsAndExpsTP :treePT :=
            txltree.patternOrReplacement_litsAndVarsAndExpsTP (patternOrReplacementTP)
        var symbolIndex := symbol.findSymbol (goalName)
        const goalTP := symbol.symbols (symbolIndex)

        parsePattern (litsAndVarsAndExpsTP, varsSoFar, goalTP, parseTP)

    end processPatternOrReplacement


    procedure processConstruct (ruleNameT : tokenT,
            constructTP : treePT,
            partIndex : partsBaseT,
            localVars : localsListT)

        rule.setPartKind (partIndex, partKind.construct)
        var nameT := txltree.construct_varNameT (constructTP)
        rule.setPartName (partIndex, nameT)

        context := "construct '" + string@(ident.idents (nameT)) + "' of rule/function '"
            + string@(ident.idents (ruleNameT)) + "'"

        if nameT = anonymous_T then
            const anonName := "_" + intstr (localVars.nlocals+1, 0) + "_"
            nameT := ident.install (anonName, kindT.id)
        end if

        % lookup name in VarsSo far.  If it's there, then it's an error
        var localIndex := rule.lookupLocalVar (context, localVars, nameT)
        if localIndex not= 0 then
            error (context, "Constructed variable has already been defined", FATAL, 320)
        end if

        var targetT := txltree.construct_targetT (constructTP)
        rule.setPartTarget (partIndex, targetT)

        const replacementTP := txltree.construct_replacementTP (constructTP)

        var resultTP : treePT
        processPatternOrReplacement (targetT, replacementTP, resultTP, localVars)
        rule.setPartReplacement (partIndex, resultTP)

        % now enter variable in LocalVars
        localIndex := rule.enterLocalVar (context, localVars, nameT, targetT)
        rule.setPartNameRef (partIndex, localIndex)

    end processConstruct


    procedure makeAnonymousConstruct (targetT : tokenT,
            partIndex : partsBaseT,
            localVars : localsListT)

        % create a new anonymous local construct as a parse of [empty]

        % create new anonymous local variable
        var anonT := ident.install ("_anonymous_" + intstr (localVars.nlocals+1, 0), kindT.id)

        rule.setPartKind (partIndex, partKind.construct)
        rule.setPartName (partIndex, anonT)
        rule.setPartTarget (partIndex, targetT)

        const localIndex := rule.enterLocalVar (context, localVars, anonT, targetT)
        rule.setPartNameRef (partIndex, localIndex)

        % make a replacement to be the value
        var replacementTP, expsAndLitsTP : treePT
        replacementTP := tree.newTree
        expsAndLitsTP := tree.newTree

        var TXLreplacementT := ident.install ("TXL_replacement_", kindT.id)
        var TXLexpsAndLitsT := ident.install ("TXL_expsAndLits_", kindT.id)

        tree.setKind (replacementTP, kindT.choose)
        tree.setName (replacementTP, TXLreplacementT)
        tree.setRawName (replacementTP, TXLreplacementT)
        var newKid := tree.newKid
        tree.setKidTree (newKid, expsAndLitsTP)
        tree.setKids (replacementTP, newKid)

        tree.setKind (expsAndLitsTP, kindT.choose)
        tree.setName (expsAndLitsTP, TXLexpsAndLitsT)
        tree.setRawName (expsAndLitsTP, TXLexpsAndLitsT)
        newKid := tree.newKid
        tree.setKids (expsAndLitsTP, newKid)

        % make the appropriate default value -
        % for [number], it is 0, for [id] or [comment], it is _,
        % for [stringlit], it is "", for [charlit], it is ''
        % for any other type it is [empty]
        var defaultTP := emptyTP

        if typeKind (targetT) not= kindT.undefined then
            % build a phoney TXL parse of a literal of the appropriate kind

            % names of the TXL replacement parse nodes
             var TXLindExpsAndLitsT := ident.install ("TXL_indExpsAndLits_", kindT.id)
             var TXLexpOrLitT := ident.install ("TXL_expOrLit_", kindT.id)
             var TXLexpressionT := ident.install ("TXL_expression_", kindT.id)
             var TXLliteralT := ident.install ("TXL_literal_", kindT.id)
             var TXLruleCallsT := ident.install ("TXL_ruleCalls_", kindT.id)

            % make a TXL replacement tree
            var indExpsAndLitsTP, expOrLitTP, emptyExpsAndLitsTP : treePT

            newKid := tree.newKid
            tree.setKidTree (newKid, emptyTP)
            emptyExpsAndLitsTP := tree.newTreeInit (kindT.choose, TXLexpsAndLitsT, TXLexpsAndLitsT, 1, newKid)

            var expOrLitKidKP := tree.newKid
            % kid tree to be filled in below
            expOrLitTP := tree.newTreeInit (kindT.choose, TXLexpOrLitT, TXLexpOrLitT, 1, expOrLitKidKP)

            var newKids := tree.newKids (2)
            tree.setKidTree (newKids, expOrLitTP)
            tree.setKidTree (newKids + 1, emptyExpsAndLitsTP)
            indExpsAndLitsTP := tree.newTreeInit (kindT.order, TXLindExpsAndLitsT, TXLindExpsAndLitsT, 2, newKids)

            % it only remains to fill in  tree.kids (expOrLitKidKP)
            % with the literal or id expression for the default

            if typeKind (targetT) >= firstLeafKind and typeKind (targetT) <= lastLeafKind then

                var tokenTP := tree.newTree
                % real kind and value (.name) filled in below, depending on kind

                newKid := tree.newKid
                tree.setKidTree (newKid, tokenTP)

                var literalTP := tree.newTreeInit (kindT.choose, TXLliteralT, TXLliteralT, 1, newKid)

                var tokenName : tokenT

                if targetT = stringlit_T then
                    tree.setKind (tokenTP, kindT.stringlit)
                    tokenName := ident.install ("\"\"", kindT.stringlit)
                    tree.setName (tokenTP, tokenName)
                    tree.setRawName (tokenTP, tokenName)
                elsif targetT = charlit_T then
                    tree.setKind (tokenTP, kindT.charlit)
                    tokenName := ident.install ("''", kindT.charlit)
                    tree.setName (tokenTP, tokenName)
                    tree.setRawName (tokenTP, tokenName)
                elsif targetT = number_T or targetT = floatnumber_T
                        or targetT = decimalnumber_T or targetT = integernumber_T then
                    % kind must be number for all of them!
                    tree.setKind (tokenTP, kindT.number)
                    tokenName := ident.install ("0", kindT.number)
                    tree.setName (tokenTP, tokenName)
                    tree.setRawName (tokenTP, tokenName)
                else
                    tree.setKind (tokenTP, typeKind (targetT))
                    tokenName := ident.install ("", kindT.id)
                    tree.setName (tokenTP, tokenName)
                    tree.setRawName (tokenTP, tokenName)
                end if

                tree.setKidTree (expOrLitKidKP, literalTP)

            else
                error (context, "Anonymous construct/replacement cannot be of type [" +
                    string@(ident.idents (targetT)) + "]", FATAL, 322)
            end if

            defaultTP := indExpsAndLitsTP
        end if

        tree.setKidTree (tree.trees (expsAndLitsTP).kidsKP, defaultTP)

        % build a parse of the empty as the value of the variable
        var resultTP : treePT
        processPatternOrReplacement (targetT, replacementTP, resultTP, localVars)
        rule.setPartReplacement (partIndex, resultTP)

    end makeAnonymousConstruct


    procedure processConstructAnonymous (ruleNameT : tokenT,
            constructOrExportTP : treePT,
            partIndex : partsBaseT,
            localVars : localsListT)

        % create a new anonymous local construct as a parse of [empty],
        % and replace the original anonymous variable in the real construct
        % with the new anonymous local

        const partName := string@(ident.idents (tree.trees (constructOrExportTP).name))
        assert partName = "TXL_constructPart_" or partName = "TXL_exportPart_"

        const nameT := txltree.construct_varNameT (constructOrExportTP)

        if partName = "TXL_constructPart_" then
            context := "construct '" + string@(ident.idents (nameT)) + "' of rule/function '" +
                string@(ident.idents (ruleNameT)) + "'"
        else
            context := "export '" + string@(ident.idents (nameT)) + "' of rule/function '" +
                string@(ident.idents (ruleNameT)) + "'"
        end if

        % the target of the anonymous construct is the same as the target of the real construct
        var targetT : tokenT
        if partName = "TXL_constructPart_" then
            targetT := txltree.construct_targetT (constructOrExportTP)
        else
            const localIndex := rule.lookupLocalVar (context, localVars, nameT)

            targetT := txltree.import_export_targetT (constructOrExportTP)

            if targetT = NOT_FOUND then
                if localIndex not= 0 then
                    targetT := rule.ruleLocals (localVars.localBase + localIndex).typename
                else
                    error (context, "Type required for exported variable", FATAL, 321)
                end if
            else
                if localIndex not= 0 then
                    % (warning for this will be given by processExport)
                    targetT := rule.ruleLocals (localVars.localBase + localIndex).typename
                end if
            end if
        end if

        % create the actual anonymous construct of that type
        makeAnonymousConstruct (targetT, partIndex, localVars)

        % make a reference for the new local and replace the anonymous
        % with it in the real construct
        var anonTP := tree.newTreeInit (kindT.id, rule.ruleParts (partIndex).name, rule.ruleParts (partIndex).name, 0, nilKid)

        % replace the anonymous in the real construct with the new local
        var anonymousExpressionTP : treePT
        anonymousExpressionTP := txltree.construct_anonymousExpressionTP (constructOrExportTP)

        assert tree.trees (tree.kid1TP (anonymousExpressionTP)).name = anonymous_T
        tree.setKidTree (tree.trees (anonymousExpressionTP).kidsKP, anonTP)

    end processConstructAnonymous


    procedure processDeconstruct (ruleNameT : tokenT,
            deconstructTP : treePT,
            partIndex : partsBaseT,
            localVars : localsListT)

        rule.setPartKind (partIndex, partKind.deconstruct)
        const nameT := txltree.deconstruct_varNameT (deconstructTP)
        rule.setPartName (partIndex, nameT)

        context := "deconstruct '" + string@(ident.idents (nameT)) + "' of rule/function '" +
            string@(ident.idents (ruleNameT)) + "'"

        % lookup name in varsSoFar - it must be there if we're deconstructing it!
        const localIndex := rule.findLocalVar (context, localVars, nameT)

        const oldVarCount := localVars.nlocals
        const parentRefs := rule.ruleLocals (localVars.localBase + localIndex).refs

        % deconstruct itself counts as a reference
        rule.incLocalRefs (localVars.localBase + localIndex, 1)

        rule.setPartNameRef (partIndex, localIndex)
        rule.setPartStarred (partIndex, txltree.deconstruct_isStarred (deconstructTP))

        var targetT := rule.ruleLocals (localVars.localBase + localIndex).typename
        if txltree.deconstruct_isTyped (deconstructTP) then
            % search is explicitly typed
            targetT := txltree.deconstruct_targetT (deconstructTP)

            % Warn if we can't get a match
            if targetT not= rule.ruleLocals (localVars.localBase + localIndex).typename
                    and rule.ruleLocals (localVars.localBase + localIndex).typename not= any_T
                    and not rule.ruleParts (partIndex).starred then
                error (context, "Typed deconstruct can never match", WARNING, 323)
            end if
        end if
        rule.setPartTarget (partIndex, targetT)

        % process skipping
        const optSkippingTP := txltree.deconstruct_optSkippingTP (deconstructTP)

        % Now up to three of them allowed
        rule.setPartSkipName (partIndex, NOT_FOUND)
        rule.setPartSkipName (partIndex, NOT_FOUND)
        rule.setPartSkipName (partIndex, NOT_FOUND)

        if not tree.plural_emptyP (optSkippingTP) then
            var skippingNameT := txltree.optSkippingNameT (optSkippingTP, 1)
            rule.setPartSkipName (partIndex, skippingNameT)
            % Check that the skipped production has been defined
            var symbolIndex := symbol.findSymbol (rule.ruleParts (partIndex).skipName)

            % Is there a second one?
            skippingNameT := txltree.optSkippingNameT (optSkippingTP, 2)
            if skippingNameT not= NOT_FOUND then
                rule.setPartSkipName (partIndex, skippingNameT)
                % Check that the skipped production has been defined
                symbolIndex := symbol.findSymbol (rule.ruleParts (partIndex).skipName2)

                % How about a third one?
                skippingNameT := txltree.optSkippingNameT (optSkippingTP, 3)
                if skippingNameT not= NOT_FOUND then
                    rule.setPartSkipName (partIndex, skippingNameT)
                    % Check that the skipped production has been defined
                    symbolIndex := symbol.findSymbol (rule.ruleParts (partIndex).skipName3)
                end if

            else
                % Only one - check for optimizable case
                if rule.ruleParts (partIndex).skipName = targetT
                        and tree_ops.isListOrRepeatType (rule.ruleLocals (localVars.localBase + localIndex).typename)
                        and targetT = tree_ops.listOrRepeatBaseType (rule.ruleLocals (localVars.localBase + localIndex).typename) then
                    % skipping [X] deconstruct * [X] V [repeat/list X]
                    rule.setPartSkipRepeat (partIndex, true)
                else
                    rule.setPartSkipRepeat (partIndex, false)
                end if
            end if
        end if

        const patternTP := txltree.deconstruct_patternTP (deconstructTP)

        var resultTP : treePT
        processPatternOrReplacement (targetT, patternTP, resultTP, localVars)
        rule.setPartPattern (partIndex, resultTP)

        for newlocal : oldVarCount + 1 .. localVars.nlocals
            rule.setLocalPartOf (localVars.localBase + newlocal, rule.ruleParts (partIndex).nameRef)
            rule.setLocalRefs (localVars.localBase + newlocal, 0)
        end for

        rule.setPartNegated (partIndex, txltree.deconstruct_negated (deconstructTP))

        if rule.ruleParts (partIndex).negated then
            % all the bound variables are really anonymous, since they don't exist after the deconstruct
            for newlocal : oldVarCount + 1 .. localVars.nlocals
                var anonT := ident.install ("_anonymous_" + intstr (newlocal, 0), kindT.id)
                rule.setLocalName (localVars.localBase + newlocal, anonT)
                rule.setLocalRefs (localVars.localBase + newlocal, 0)
            end for
        end if

        if localVars.nlocals = oldVarCount or rule.ruleParts (partIndex).negated then
            % a trivial deconstruct that binds no new variables -
            % in this case, we need not count the deconstruct as a reference,
            % if this is the first use of the deconstructed variable!
            if rule.ruleLocals (localVars.localBase + localIndex).refs = 1 then
                rule.setLocalRefs (localVars.localBase + localIndex, 0)
            end if
        end if

    end processDeconstruct


    procedure processCondition (ruleNameT : tokenT, conditionTP : treePT,
            partIndex : partsBaseT, localVars : localsListT)
        % condition ::= 'condition [expression]
        const expressionTP := txltree.condition_expressionTP (conditionTP)

        if txltree.condition_is_assert (conditionTP) then
            rule.setPartKind (partIndex, partKind.assert_)
        else
            rule.setPartKind (partIndex, partKind.cond)
        end if

        const nameT := txltree.expression_baseT (expressionTP)
        rule.setPartName (partIndex, nameT)

        context := "where condition '" + string@(ident.idents (nameT)) + "' of rule/function '" +
            string@(ident.idents (ruleNameT)) + "'"

        % lookup name in varsSoFar - It must be there if we have a condition on it!
        const localIndex := rule.findLocalVar (context, localVars, nameT)

        % condition (where) counts as a reference
        rule.incLocalRefs (localVars.localBase + localIndex, 1)

        rule.setPartNameRef (partIndex, localIndex)

        const targetT := rule.ruleLocals (localVars.localBase + localIndex).typename
        rule.setPartTarget (partIndex, targetT)

        % OK, now we cheat like hell.  What we are going to do is to embed
        % the expression in an expsAndLitsAndVars tree so we can call
        % processPatternOrReplacement

        var parseTP := tree.newTreeInit (kindT.expression, nameT, nameT, localIndex /*save looking for it later*/, nilKid)

        % make kids of rule call
        var ruleCallsTP := txltree.expression_ruleCallsTP (expressionTP)
        if tree.plural_emptyP (ruleCallsTP) then
            error (context, "'where' condition requires a rule call", FATAL, 324)
        end if
        const ruleCallsTPcopy := ruleCallsTP

        % pre-allocate the kids to keep them contiguous
        var nkids := 1
        loop
            ruleCallsTP := tree.plural_restTP (ruleCallsTP)
            exit when tree.plural_emptyP (ruleCallsTP)
            nkids += 1
        end loop

        var lastKidKP := tree.newKids (nkids + 1)
        tree.setKids (parseTP, lastKidKP)

        % mark the end of the list with a nilTree
        tree.setKidTree (lastKidKP + nkids, nilTree)

        % now fill in the kids
        ruleCallsTP := ruleCallsTPcopy
        for k : 1 .. nkids
            var parsedCallTP : treePT
            processRuleCall (targetT, tree.plural_firstTP (ruleCallsTP), localVars, parsedCallTP, true)
            tree.setKidTree (lastKidKP, parsedCallTP)
            ruleCallsTP := tree.plural_restTP (ruleCallsTP)
            lastKidKP += 1
        end for
        assert tree.kids (lastKidKP) = nilTree

        rule.setPartReplacement (partIndex, parseTP)

        rule.setPartNegated (partIndex, txltree.condition_negated (conditionTP))
        rule.setPartAnded (partIndex, txltree.condition_anded (conditionTP))

    end processCondition


    procedure processConditionAnonymous (ruleNameT : tokenT,
            conditionTP : treePT,
            partIndex : partsBaseT,
            localVars : localsListT)

        % create a new anonymous local construct as a parse of [empty],
        % and replace the original anonymous variable in the condition
        % with the new anonymous local

        const partName := string@(ident.idents (tree.trees (conditionTP).name))
        assert partName = "TXL_conditionPart_"

        % create an anonymous construct of type [empty]
        makeAnonymousConstruct (id_T, partIndex, localVars)

        % make a reference for the new local and replace the anonymous
        % with it in the real construct
        var anonTP := tree.newTreeInit (kindT.id, rule.ruleParts (partIndex).name, rule.ruleParts (partIndex).name, 0, nilKid)

        % replace the anonymous in the real construct with the new local
        var anonymousExpressionTP : treePT
        anonymousExpressionTP := txltree.condition_expressionTP (conditionTP)

        assert tree.trees (tree.kid1TP (anonymousExpressionTP)).name = anonymous_T
        tree.setKidTree (tree.trees (anonymousExpressionTP).kidsKP, anonTP)

    end processConditionAnonymous


    procedure processImport (ruleNameT : tokenT,
            importTP : treePT,
            partIndex : partsBaseT,
            localVars : localsListT)

        const nameT := txltree.construct_varNameT (importTP)

        rule.setPartKind (partIndex, partKind.import_)
        rule.setPartName (partIndex, nameT)

        context := "import '" + string@(ident.idents (nameT)) + "' of rule/function '" +
            string@(ident.idents (ruleNameT)) + "'"

        % lookup name in VarsSo far.  If it's there, then it's an error
        var localIndex := rule.lookupLocalVar (context, localVars, nameT)
        if localIndex not= 0 and not rule.ruleLocals (localVars.localBase + localIndex).global then
            error (context, "Imported variable has already been defined", FATAL, 325)
        end if

        % find the target type of the import
        var targetT := txltree.import_export_targetT (importTP)

        if targetT = NOT_FOUND then
            if localIndex not= 0 then
                targetT := rule.ruleLocals (localVars.localBase + localIndex).typename
            else
                error (context, "Type required for imported variable", FATAL, 326)
            end if
        else
            if localIndex not= 0 then
                error (context, "Imported variable already has a type (import type ignored)", WARNING, 327)
                targetT := rule.ruleLocals (localVars.localBase + localIndex).typename
            end if
        end if

        rule.setPartTarget (partIndex, targetT)

        % process pattern, if any
        const patternTP := txltree.import_patternTP (importTP)
        const oldVarCount := localVars.nlocals

        if tree.plural_emptyP (tree.kid1TP (patternTP)) then
            rule.setPartPattern (partIndex, nilTree)
        else
            var resultTP : treePT
            processPatternOrReplacement (targetT, patternTP, resultTP, localVars)
            rule.setPartPattern (partIndex, resultTP)
        end if

        % now enter the variable in LocalVars
        if localIndex = 0 then
            localIndex := rule.enterLocalVar (context, localVars, nameT, targetT)
            rule.setLocalGlobal (localVars.localBase + localIndex, true)
        end if
        rule.setPartNameRef (partIndex, localIndex)

        % mark any deconstructed parts as parts of this import
        for newlocal : oldVarCount + 1 .. localVars.nlocals
            if newlocal not= localIndex then
                rule.setLocalPartOf (localVars.localBase + newlocal, rule.ruleParts (partIndex).nameRef)
                rule.setLocalRefs (localVars.localBase + newlocal, 0)
            end if
        end for

        % we start each import with TWO references to account for its
        % probable use elsewhere
        rule.setLocalRefs (localVars.localBase + localIndex, 2)  % One is not enough here, see Adrian's bug! -- JRC 10.4

    end processImport


    procedure processExport (ruleNameT : tokenT,
            exportTP : treePT,
            partIndex : partsBaseT,
            localVars : localsListT)

        const nameT := txltree.construct_varNameT (exportTP)

        rule.setPartKind (partIndex, partKind.export_)
        rule.setPartName (partIndex, nameT)

        context := "export '" + string@(ident.idents (nameT)) + "' of rule/function '" +
            string@(ident.idents (ruleNameT)) + "'"

        % lookup name in VarsSo far.
        var localIndex := rule.lookupLocalVar (context, localVars, nameT)

        % find the target type of the export
        var targetT := txltree.import_export_targetT (exportTP)

        if targetT = NOT_FOUND then
            if localIndex not= 0 then
                targetT := rule.ruleLocals (localVars.localBase + localIndex).typename
            else
                error (context, "Type required for exported variable", FATAL, 328)
            end if
        else
            if localIndex not= 0 then
                error (context, "Exported variable already has a type (export type ignored)", WARNING, 329)
                targetT := rule.ruleLocals (localVars.localBase + localIndex).typename
            end if
        end if

        rule.setPartTarget (partIndex, targetT)

        % process replacement, if any
        const replacementTP := txltree.construct_replacementTP (exportTP)

        if tree.plural_emptyP (tree.kid1TP (replacementTP)) then
            if localIndex = 0 then
                error (context, "Exported variable has not been bound (export value required)", FATAL, 330)
            else
                rule.setPartReplacement (partIndex, nilTree)
            end if
        else
            var resultTP : treePT
            processPatternOrReplacement (targetT, replacementTP, resultTP, localVars)
            rule.setPartReplacement (partIndex, resultTP)
            if localIndex = 0 then
                localIndex := rule.enterLocalVar (context, localVars, nameT, targetT)
            end if
        end if

        % even if it wasn't global before, it is now!
        rule.setLocalGlobal (localVars.localBase + localIndex, true)

        rule.setPartNameRef (partIndex, localIndex)

        % we start each export with one reference to account for its probable use elsewhere.
        % if it was already bound, then we just increment its count
        rule.incLocalRefs (localVars.localBase + localIndex, 1)

    end processExport


    procedure makeDefaultMatchPart (ruleTP : treePT)

        % In TXL 11.1, match/replace parts are optional, to assist in writing utility rules.
        % The default is a pattern that matches anything:
        %
        %       match [any]
        %           _ [any]
        %
        % We implement this by constructing the TXL bootstrap parse of that pattern.

        % TXL_pattern order -> TXL_firstsAndLits choose -> TXL_indFirstsAndLits order ->
        %       TXL_firstOrLit choose ->
        %           (TXL_firstTime order ->
        %               (id (_), empty ([), TXL_description choose -> id (any), empty (])),
        %                   TXL_firstsAndLits choose -> emptyTP)

        % The target type [any]
        const TXLdescriptionT := ident.install ("TXL_description_", kindT.id)
        const TXLdescription_anyTP := tree.newTreeInit (kindT.choose, TXLdescriptionT, TXLdescriptionT, 0, nilKid)
        const anyTP := tree.newTreeInit (kindT.id, any_T, any_T, 0, nilKid)
        tree.makeOneKid (TXLdescription_anyTP, anyTP)

        const TXLbracketedDescriptionT := ident.install ("TXL_bracketedDescription_", kindT.id)
        const TXLbracketedDescription_anyTP :=
            tree.newTreeInit (kindT.order, TXLbracketedDescriptionT, TXLbracketedDescriptionT, 0, nilKid)
        tree.makeThreeKids (TXLbracketedDescription_anyTP, emptyTP, TXLdescription_anyTP, emptyTP)

        % The pattern _ [any]
        const TXLpatternT := ident.install ("TXL_pattern_", kindT.id)
        const TXLfirstsAndLitsT := ident.install ("TXL_firstsAndLits_", kindT.id)
        const TXLindFirstsAndLitsT := ident.install ("TXL_indFirstsAndLits_", kindT.id)
        const TXLfirstOrLitT := ident.install ("TXL_firstOrLit_", kindT.id)
        const TXLfirstTimeT := ident.install ("TXL_firstTime_", kindT.id)

        const TXLfirstTime_anyTP := tree.newTreeInit (kindT.order, TXLfirstTimeT, TXLfirstTimeT, 0, nilKid)
        const underscoreTP := tree.newTreeInit (kindT.id, underscore_T, underscore_T, 0, nilKid)
        tree.makeFourKids (TXLfirstTime_anyTP, underscoreTP, emptyTP, TXLdescription_anyTP, emptyTP)

        const TXLfirstOrLit_anyTP := tree.newTreeInit (kindT.choose, TXLfirstOrLitT, TXLfirstOrLitT, 0, nilKid)
        tree.makeOneKid (TXLfirstOrLit_anyTP, TXLfirstTime_anyTP)

        const TXLfirstsAndLits_emptyTP :=
            tree.newTreeInit (kindT.choose, TXLfirstsAndLitsT, TXLfirstsAndLitsT, 0, nilKid)
        tree.makeOneKid (TXLfirstsAndLits_emptyTP, emptyTP)

        const TXLindFirstsAndLits_anyTP :=
            tree.newTreeInit (kindT.order, TXLindFirstsAndLitsT, TXLindFirstsAndLitsT, 0, nilKid)
        tree.makeTwoKids (TXLindFirstsAndLits_anyTP, TXLfirstOrLit_anyTP, TXLfirstsAndLits_emptyTP)

        const TXLfirstsAndLits_anyTP := tree.newTreeInit (kindT.choose, TXLfirstsAndLitsT, TXLfirstsAndLitsT, 0, nilKid)
        tree.makeOneKid (TXLfirstsAndLits_anyTP, TXLindFirstsAndLits_anyTP)

        const TXLpattern_anyTP := tree.newTreeInit (kindT.order, TXLpatternT, TXLpatternT, 0, nilKid)
        tree.makeOneKid (TXLpattern_anyTP, TXLfirstsAndLits_anyTP)

        % The match part match [any] _ [any]

        % TXL_replaceOrMatchPart order ->
        %       (TXL_optSkippingBracketedDescription choose -> empty,
        %           TXL_replaceOrMatch choose -> id (match),
        %               TXL_optStarDollarHash choose -> empty,
        %                   TXL_bracketedDescription_anyTP, TXL_pattern_anyTP)

        const TXLreplaceOrMatchPartT := ident.install ("TXL_replaceOrMatchPart_", kindT.id)
        const TXLoptSkippingBracketedDescriptionT := ident.install ("TXL_optSkippingBracketedDescription_", kindT.id)
        const TXLreplaceOrMatchT := ident.install ("TXL_replaceOrMatch_", kindT.id)
        const TXLoptStarDollarHashT := ident.install ("TXL_optStarDollarHash_", kindT.id)

        const TXLoptSkippingBracketedDescription_emptyTP := tree.newTreeInit (kindT.choose,
            TXLoptSkippingBracketedDescriptionT, TXLoptSkippingBracketedDescriptionT, 0, nilKid)
        tree.makeOneKid (TXLoptSkippingBracketedDescription_emptyTP, emptyTP)

        const TXLreplaceOrMatch_matchTP :=
            tree.newTreeInit (kindT.choose, TXLreplaceOrMatchT, TXLreplaceOrMatchT, 0, nilKid)
        const matchTP := tree.newTreeInit (kindT.id, match_T, match_T, 0, nilKid)
        tree.makeOneKid (TXLreplaceOrMatch_matchTP, matchTP)

        const TXLoptStarDollarHash_emptyTP :=
            tree.newTreeInit (kindT.choose, TXLoptStarDollarHashT, TXLoptStarDollarHashT, 0, nilKid)
        tree.makeOneKid (TXLoptStarDollarHash_emptyTP, emptyTP)

        const TXLreplaceOrMatchPart_anyTP :=
            tree.newTreeInit (kindT.order, TXLreplaceOrMatchPartT, TXLreplaceOrMatchPartT, 0, nilKid)
        tree.makeFiveKids (TXLreplaceOrMatchPart_anyTP, TXLoptSkippingBracketedDescription_emptyTP,
            TXLreplaceOrMatch_matchTP, TXLoptStarDollarHash_emptyTP, TXLbracketedDescription_anyTP, TXLpattern_anyTP)

        % Link the constructed match part into the rule's parse tree
        assert string@(ident.idents (tree.trees (tree.kid5TP (ruleTP)).name)) = "TXL_optReplaceOrMatchPart_"
        assert tree.trees (tree.kid1TP (tree.kid5TP (ruleTP))).name = empty_T
        tree.setKidTree (tree.trees (tree.kid5TP (ruleTP)).kidsKP, TXLreplaceOrMatchPart_anyTP)

    end makeDefaultMatchPart


    procedure processReplacementAnonymous (targetT : tokenT,
            optByPartTP : treePT,
            partIndex : partsBaseT,
            localVars : localsListT)

        % create a new anonymous local construct as a parse of [empty],
        % replace the original anonymous in the replacement
        % with the new anonymous local

        % create the actual anonymous construct of the target type
        makeAnonymousConstruct (targetT, partIndex, localVars)

        % make a reference for the new local and replace the anonymous
        % with it in the real construct
        var anonTP := tree.newTreeInit (kindT.id, rule.ruleParts (partIndex).name, rule.ruleParts (partIndex).name, 0, nilKid)

        % replace the anonymous in the real construct with the new local
        var anonymousExpressionTP : treePT
        anonymousExpressionTP := txltree.optByPart_anonymousExpressionTP (optByPartTP)

        assert tree.trees (tree.kid1TP (anonymousExpressionTP)).name = anonymous_T
        tree.setKidTree (tree.trees (anonymousExpressionTP).kidsKP, anonTP)

    end processReplacementAnonymous


    procedure enterRuleFormals (ruleIndex : int, arg_formalsTP : treePT)

        var formalsTP := arg_formalsTP

        bind r to rule.rules (ruleIndex)

        if r.called then
            % rule has been previously called; back-check the parameter types

            % we need to copy the predicted formals to the new localBase
            const formalBase := r.localVars.localBase
            rule.setLocalBase (ruleIndex, rule.ruleLocalCount)

            if rule.ruleLocalCount + r.localVars.nformals > maxTotalLocals then
                error (context, "Too many total local variables in rules of TXL program (> "
                    + intstr (maxTotalLocals, 1) + ")", LIMIT_FATAL, 334)
            end if

            for formalNum : 1 .. r.localVars.nformals
                if tree.plural_emptyP (formalsTP) then
                    error (context, "Number of formal parameters does not agree with previous call", FATAL, 331)
                end if

                % make the copy
                rule.cloneLocal (r.localVars.localBase + formalNum, formalBase + formalNum)

                bind formal to rule.ruleLocals (r.localVars.localBase + formalNum)
                rule.setLocalName (r.localVars.localBase + formalNum, txltree.formal_nameT (tree.plural_firstTP (formalsTP)))

                const declaredFormalType := txltree.formal_typeT (tree.plural_firstTP (formalsTP))

                % Check that the declared target production has been defined
                var symbolIndex := symbol.findSymbol (declaredFormalType)

                if formal.typename not= declaredFormalType then
                    error (context, "Type of formal parameter '" + string@(ident.idents (formal.name)) +
                        "' does not agree with previous call", FATAL, 332)
                end if

                % we start each formal with one reference to account for its
                % probable use in the calling scope
                rule.setLocalRefs (r.localVars.localBase + formalNum, 1)
                rule.setLocalChanged (r.localVars.localBase + formalNum, false)

                formalsTP := tree.plural_restTP (formalsTP)
            end for

            if not tree.plural_emptyP (formalsTP) then
                error (context, "Number of formal parameters does not agree with previous call", FATAL, 331)
            end if

            rule.setNPreLocals (ruleIndex, r.localVars.nformals)
            rule.setNLocals (ruleIndex, r.localVars.nformals)

            % already checked above
            rule.incLocalCount (r.localVars.nformals)

        else
            % rule has not been called yet - nothing to check against
            var formalNum := 0
            rule.setLocalBase (ruleIndex, rule.ruleLocalCount)

            if rule.ruleLocalCount + maxParameters > maxTotalLocals then
                error (context, "Too many total local variables in rules of TXL program (> "
                    + intstr (maxTotalLocals, 1) + ")", LIMIT_FATAL, 334)
            end if

            loop
                exit when tree.plural_emptyP (formalsTP)

                if formalNum = maxParameters then
                   error (context, "Too many rule/function parameters, rule/function '" +
                        string@(ident.idents (r.name)) + "' (>" + intstr (maxParameters, 0) + ")", LIMIT_FATAL, 311)
                end if

                formalNum += 1

                const formalIndex := r.localVars.localBase + formalNum
                rule.setLocalName (formalIndex, txltree.formal_nameT (tree.plural_firstTP (formalsTP)))
                rule.setLocalType (formalIndex, txltree.formal_typeT (tree.plural_firstTP (formalsTP)))

                % Check that the declared target production has been defined
                var symbolIndex := symbol.findSymbol (rule.ruleLocals (formalIndex).typename)

                % we start each formal with one reference to account for its
                % probable use in the calling scope
                rule.setLocalRefs (formalIndex, 1)
                rule.setLocalChanged (formalIndex, false)

                formalsTP := tree.plural_restTP (formalsTP)
            end loop

            rule.setNFormals (ruleIndex, formalNum)
            rule.setNPreLocals (ruleIndex, formalNum)
            rule.setNLocals (ruleIndex, formalNum)

            % already checked above
            rule.incLocalCount (r.localVars.nformals)
        end if
    end enterRuleFormals


    function findLastRef (name : tokenT, replacementTP : treePT) : treePT

        var lastrefTP := nilTree

        if replacementTP = nilTree then
            result nilTree
        end if

        var treeTP := replacementTP

        const maxSearchDepth := 100
        var searchStack : array 1 .. maxSearchDepth of
            record
                kidsKP, endKP : kidPT
            end record
        var searchTop := 0
        const searchBase := searchTop

        loop
            if tree.trees (treeTP).kind = kindT.expression and tree.trees (treeTP).name = name then
                lastrefTP := treeTP
            end if

            if tree.trees (treeTP).kind >= firstLeafKind then
                % A terminal -
                % Pop any completed sequences ...
                loop
                    if searchTop = 0 then
                        result lastrefTP
                    end if
                    exit when searchStack (searchTop).kidsKP < searchStack (searchTop).endKP
                    searchTop -= 1
                end loop
                % ... and move on to the next subtree in the sequence
                searchStack (searchTop).kidsKP += 1
                treeTP := tree.kids (searchStack (searchTop).kidsKP)

            elsif tree.trees (treeTP).kind = kindT.choose then
                % One child - just go down to it (no need to come back)
                treeTP := tree.kids (tree.trees (treeTP).kidsKP)

            else
                % Push a new sequence of subtrees to check
                assert tree.trees (treeTP).kind = kindT.order or tree.trees (treeTP).kind = kindT.repeat or tree.trees (treeTP).kind = kindT.list

                if searchTop >= maxSearchDepth then
                    result nilTree      % can't find out
                end if

                searchTop += 1
                searchStack (searchTop).kidsKP := tree.trees (treeTP).kidsKP
                searchStack (searchTop).endKP := searchStack (searchTop).kidsKP + tree.trees (treeTP).count - 1
                treeTP := tree.kids (tree.trees (treeTP).kidsKP)
            end if
        end loop

    end findLastRef


    procedure enterRuleBody (ruleIndex : int, ruleTP : treePT)

        const rulecontext := context
        const ruleorfunction := context (1 .. index (context, " '") - 1)

        bind r to rule.rules (ruleIndex)

        % TXL 11.1, optional match/replace part
        if tree.plural_emptyP (txltree.rule_optReplaceOrMatchPartTP (ruleTP)) then
            % Add default target [any]
            rule.setTarget (ruleIndex, any_T)
        else
            % enter target name and kind
            rule.setTarget (ruleIndex, txltree.rule_targetT (ruleTP))
        end if

        var symbolIndex := symbol.findSymbol (r.target)

        % keep track of calls
        rule.setCallBase (ruleIndex, rule.ruleCallCount)
        rule.setNCalls (ruleIndex, 0)

        % process prePattern
        rule.setPrePatternPartsBase (ruleIndex, rule.rulePartCount)
        var prePatternCount := 0
        var prePatternTP := txltree.rule_prePatternTP (ruleTP)
        loop
            context := rulecontext      % in case we exit

            exit when tree.plural_emptyP (prePatternTP) % is this right?

            if prePatternCount + 1  % (sic)
                                    >= maxParts then
               error (context, "Rule/function is too complex - simplify using subrules", LIMIT_FATAL, 335)
            end if

            if rule.rulePartCount + prePatternCount + 1  % (sic)
                                    >= maxTotalParts then
               error (context, "Too many total constructs, deconstructs and conditions in TXL program" +
                    " (>" + intstr (maxTotalParts, 0) + ")", LIMIT_FATAL, 337)
            end if

            prePatternCount += 1

            const partTP := tree.kid1TP (tree.kid1TP (tree.kid1TP (prePatternTP)))
            const partName := string@(ident.idents (tree.trees (partTP).name))

            if partName = "TXL_conditionPart_" then
                if txltree.condition_isAnonymous (partTP) then
                    % add a construct for the empty anonymous
                    processConditionAnonymous (txltree.rule_nameT (ruleTP), partTP, r.prePattern.partsBase + prePatternCount, r.localVars)
                    prePatternCount += 1        % checked above (see 'sic')
                    % now process the condition that uses it
                end if

                processCondition (txltree.rule_nameT (ruleTP), partTP, r.prePattern.partsBase + prePatternCount, r.localVars)

            elsif partName = "TXL_constructPart_" then
                if txltree.construct_isAnonymous (partTP) then
                    % add a construct for the empty anonymous
                    processConstructAnonymous (txltree.rule_nameT (ruleTP), partTP, r.prePattern.partsBase + prePatternCount, r.localVars)
                    prePatternCount += 1        % checked above (see 'sic')
                    % now process the real construct that uses it
                end if

                processConstruct (txltree.rule_nameT (ruleTP), partTP, r.prePattern.partsBase + prePatternCount, r.localVars)

                if r.kind not= ruleKind.functionRule then
                    % we start each pre-construct with one reference to account for its
                    % probable use in subsequent iterations of the rule
                    rule.setLocalRefs (r.localVars.localBase + rule.ruleParts (r.prePattern.partsBase + prePatternCount).nameRef, 1)
                end if

            elsif partName = "TXL_importPart_" then

                processImport (txltree.rule_nameT (ruleTP), partTP, r.prePattern.partsBase + prePatternCount, r.localVars)

            elsif partName = "TXL_exportPart_" then
                if txltree.construct_isAnonymous (partTP) then
                    % add a construct for the empty anonymous
                    processConstructAnonymous (txltree.rule_nameT (ruleTP), partTP, r.prePattern.partsBase + prePatternCount, r.localVars)
                    prePatternCount += 1        % checked above (see 'sic')
                    % now process the export construct that uses it
                end if

                processExport (txltree.rule_nameT (ruleTP), partTP, r.prePattern.partsBase + prePatternCount, r.localVars)

            else
                assert partName = "TXL_deconstructPart_"
                processDeconstruct (txltree.rule_nameT (ruleTP), partTP, r.prePattern.partsBase + prePatternCount, r.localVars)
            end if

            prePatternTP := tree.plural_restTP (prePatternTP)
        end loop

        rule.setNPreLocals (ruleIndex, r.localVars.nlocals)
        rule.setPrePatternNParts (ruleIndex, prePatternCount)

        % already checked above
        rule.incPartCount (prePatternCount)

        % TXL 11.1, optional match/replace part
        if tree.plural_emptyP (txltree.rule_optReplaceOrMatchPartTP (ruleTP)) then
            % Add default match [any]
            makeDefaultMatchPart (ruleTP)
        end if

        % process skipping
        var optSkippingTP := txltree.rule_optSkippingTP (ruleTP)

        % Now up to three of them allowed
        rule.setSkipName (ruleIndex, NOT_FOUND)
        rule.setSkipName (ruleIndex, NOT_FOUND)
        rule.setSkipName (ruleIndex, NOT_FOUND)
        
        if not tree.plural_emptyP (optSkippingTP) then
            var skippingNameT := txltree.optSkippingNameT (optSkippingTP, 1)
            rule.setSkipName (ruleIndex, skippingNameT)
            % Check that the skipped production has been defined
            symbolIndex := symbol.findSymbol (r.skipName)
        
            % Is there a second one? 
            skippingNameT := txltree.optSkippingNameT (optSkippingTP, 2)
            if skippingNameT not= NOT_FOUND then
                rule.setSkipName (ruleIndex, skippingNameT)
                % Check that the skipped production has been defined
                symbolIndex := symbol.findSymbol (r.skipName)
        
                % How about a third one?
                skippingNameT := txltree.optSkippingNameT (optSkippingTP, 3)
                if skippingNameT not= NOT_FOUND then
                    rule.setSkipName (ruleIndex, skippingNameT)
                    % Check that the skipped production has been defined
                    symbolIndex := symbol.findSymbol (r.skipName)
                end if

            else
                % Check for optimizable case
                if r.skipName = r.target then
                    % skipping [X] match/replace * [X]
                    % potentially optimizable if all scopes are [repeat/list X]
                    rule.setSkipRepeat (ruleIndex, true)
                else
                    rule.setSkipRepeat (ruleIndex, false)
                end if
            end if
        end if

        % process pattern
        context := "pattern of " + ruleorfunction + " '" + string@(ident.idents (txltree.rule_nameT (ruleTP))) + "'"

        var resultTP : treePT
        processPatternOrReplacement (txltree.rule_targetT (ruleTP), txltree.rule_patternTP (ruleTP), resultTP, r.localVars)
        rule.setPattern (ruleIndex, resultTP)

        rule.setStarred (ruleIndex, txltree.rule_isStarred (ruleTP))

        % process postPattern
        rule.setPostPatternPartsBase (ruleIndex, rule.rulePartCount)
        var postPatternCount := 0
        var hasPostConstruct := false
        var postPatternTP := txltree.rule_postPatternTP (ruleTP)
        loop
            context := rulecontext      % in case we exit

            exit when tree.plural_emptyP (postPatternTP) % is this right?

            if postPatternCount + 1  % (sic)
                                    >= maxParts then
               error (context, "Rule/function is too complex - simplify using subrules", LIMIT_FATAL, 335)
            end if

            if rule.rulePartCount + postPatternCount + 1  % (sic)
                                    >= maxTotalParts then
               error (context, "Too many total constructs, deconstructs and conditions in TXL program" +
                    " (>" + intstr (maxTotalParts, 0) + ")", LIMIT_FATAL, 337)
            end if

            postPatternCount += 1

            const partTP := tree.kid1TP (tree.kid1TP (tree.kid1TP (postPatternTP)))
            const partName := string@(ident.idents (tree.trees (partTP).name))

            if partName = "TXL_conditionPart_" then
                % If we've already done a post construct, it may be discarded
                % when this condition fails.
                % We correct for this possibility by marking each main pattern variable
                % (or descendant thereof) that has been changed in a post construct
                % as having an extra reference.
                % This accounts for the possibility that its original value will be needed
                % in the calling scope if/when this post condition fails.
                if hasPostConstruct then
                    for i : r.localVars.nformals + 1 .. r.localVars.nlocals
                        if rule.ruleLocals (r.localVars.localBase + i).changed
                                and rule.ruleLocals (r.localVars.localBase + i).refs = 1 then
                            rule.incLocalRefs (r.localVars.localBase + i, 1)
                        end if
                    end for
                end if

                if txltree.condition_isAnonymous (partTP) then
                    % add a construct for the empty anonymous
                    processConditionAnonymous (txltree.rule_nameT (ruleTP), partTP, r.postPattern.partsBase + postPatternCount, r.localVars)
                    postPatternCount += 1       % checked above (see 'sic')
                    % now process the condition that uses it
                end if

                processCondition (txltree.rule_nameT (ruleTP), partTP, r.postPattern.partsBase + postPatternCount, r.localVars)

            elsif partName = "TXL_constructPart_" then
                hasPostConstruct := true

                if txltree.construct_isAnonymous (partTP) then
                    % add a construct for the empty anonymous
                    processConstructAnonymous (txltree.rule_nameT (ruleTP), partTP, r.postPattern.partsBase + postPatternCount, r.localVars)
                    postPatternCount += 1       % checked above (see 'sic')
                    % now process the real construct that uses it
                end if

                processConstruct (txltree.rule_nameT (ruleTP), partTP, r.postPattern.partsBase + postPatternCount, r.localVars)

            elsif partName = "TXL_importPart_" then

                processImport (txltree.rule_nameT (ruleTP), partTP, r.postPattern.partsBase + postPatternCount, r.localVars)

            elsif partName = "TXL_exportPart_" then
                if txltree.construct_isAnonymous (partTP) then
                    % add a construct for the empty anonymous
                    processConstructAnonymous (txltree.rule_nameT (ruleTP), partTP, r.postPattern.partsBase + postPatternCount, r.localVars)
                    postPatternCount += 1       % checked above (see 'sic')
                    % now process the export construct that uses it
                end if

                processExport (txltree.rule_nameT (ruleTP), partTP, r.postPattern.partsBase + postPatternCount, r.localVars)

            else
                assert partName = "TXL_deconstructPart_"

                % If we've already done a post construct, it may be discarded
                % when this condition fails.
                % We correct for this possibility by marking each main pattern variable
                % (or descendant thereof) that has been changed in a post construct
                % as having an extra reference.
                % This accounts for the possibility that its original value will be needed
                % in the calling scope if/when this post condition fails.
                if hasPostConstruct then
                    for i : r.localVars.nformals + 1 .. r.localVars.nlocals
                        if rule.ruleLocals (r.localVars.localBase + i).changed
                                and rule.ruleLocals (r.localVars.localBase + i).refs = 1 then
                            rule.incLocalRefs (r.localVars.localBase + i, 1)
                        end if
                    end for
                end if

                processDeconstruct (txltree.rule_nameT (ruleTP), partTP, r.postPattern.partsBase + postPatternCount, r.localVars)
            end if

            postPatternTP := tree.plural_restTP (postPatternTP)
        end loop

        rule.setPostPatternNParts (ruleIndex, postPatternCount)

        % already checked above
        rule.incPartCount (postPatternCount)

        % process replacement
        const optByPartTP := txltree.rule_optByPartTP (ruleTP)

        if txltree.rule_replaceOrMatchT (ruleTP) = replace_T then
            if tree.plural_emptyP (optByPartTP) then
                error (context, "'replace' rule/function must have a replacement", FATAL, 338)
            else
                context := "replacement of " + ruleorfunction + " '" +
                    string@(ident.idents (txltree.rule_nameT (ruleTP))) + "'"

                if txltree.optByPart_isAnonymous (optByPartTP) then
                    % add a construct for the empty anonymous
                    hasPostConstruct := true

                    if postPatternCount >= maxParts then
                        error (context, "Rule/function is too complex - simplify using subrules", LIMIT_FATAL, 335)
                    end if

                    if rule.rulePartCount + postPatternCount >= maxTotalParts then
                       error (context, "Too many total constructs, deconstructs and conditions in TXL program" +
                            " (>" + intstr (maxTotalParts, 0) + ")", LIMIT_FATAL, 337)
                    end if

                    postPatternCount += 1
                    rule.incPartCount (1)
                    rule.setPostPatternNParts (ruleIndex, postPatternCount)     % don't forget!!

                    processReplacementAnonymous (txltree.rule_targetT (ruleTP),
                        optByPartTP, r.postPattern.partsBase + postPatternCount, r.localVars)
                end if

                % can only optimize last references if they are in the replacement
                for i : r.localVars.nformals + 1 .. r.localVars.nlocals
                    rule.setLocalLastRef (r.localVars.localBase + i, nilTree)
                end for

                %% var resultTP : treePT
                processPatternOrReplacement (txltree.rule_targetT (ruleTP),
                    txltree.optByPart_replacementTP (optByPartTP), resultTP, r.localVars)
                rule.setReplacement (ruleIndex, resultTP)

                % mark the last reference of each main- or post-pattern variable as optimizable
                % pre-pattern variables are not optimizable!
                for i : r.localVars.nformals + 1 .. r.localVars.nlocals
                    if rule.ruleLocals (r.localVars.localBase + i).lastref not= nilTree
                            and tree.trees (rule.ruleLocals (r.localVars.localBase + i).lastref).kind = kindT.expression
                            and rule.ruleLocals (r.localVars.localBase + i).basetypename not= key_T             % JRC 10.6.99
                            and rule.ruleLocals (r.localVars.localBase + i).basetypename not= token_T then      % JRC 10.6.99
                        % we must be careful that the variable was not *deconstructed* from
                        % a pre-pattern variable!
                        var reali := i
                        loop
                            exit when rule.ruleLocals (r.localVars.localBase + reali).partof = 0
                            reali := rule.ruleLocals (r.localVars.localBase + reali).partof
                        end loop
                        if reali > r.localVars.nprelocals
                                % and that it is not a global variable or deconstructed from one!
                                and (not rule.ruleLocals (r.localVars.localBase + i).global)
                                and (not rule.ruleLocals (r.localVars.localBase + reali).global) then
                            tree.setKind (rule.ruleLocals (r.localVars.localBase + i).lastref, kindT.lastExpression)
                        end if
                    end if
                end for
            end if

        else
            assert txltree.rule_replaceOrMatchT (ruleTP) = match_T
            if not tree.plural_emptyP (optByPartTP) then
                error (context, "'match' rule/function cannot have a replacement", FATAL, 339)
            end if
            rule.setReplacement (ruleIndex, nilTree)

            % If the match rule has a post construct, it may change a pattern
            % variable - but match rules are not permitted to change anything.
            % We correct for this possibility by marking each main pattern variable
            % (or descendant thereof) that has been changed in a post construct
            % as having an extra reference.
            % This accounts for the possibility that its original value will be needed
            % in the calling scope if the condition calling this match rule succeeds.
            if hasPostConstruct then
                for i : r.localVars.nformals + 1 .. r.localVars.nlocals
                    if rule.ruleLocals (r.localVars.localBase + i).changed and rule.ruleLocals (r.localVars.localBase + i).refs = 1 then
                        rule.incLocalRefs (r.localVars.localBase + i, 1)
                    end if
                end for
            end if
        end if

        % synchronize the reference counts of children of deconstructed variables
        for i : r.localVars.nformals + 1 .. r.localVars.nlocals
            const parentvar := rule.ruleLocals (r.localVars.localBase + i).partof
            if parentvar not= 0 then
                rule.incLocalRefs (r.localVars.localBase + i, rule.ruleLocals (r.localVars.localBase + parentvar).refs - 1)

                % if the deconstructed parent is referenced in the replacement,
                % we cannot safely optimize the last reference to the child
                if rule.ruleLocals (r.localVars.localBase + parentvar).lastref not= nilTree then
                    if rule.ruleLocals (r.localVars.localBase + i).lastref not= nilTree
                            and tree.trees (rule.ruleLocals (r.localVars.localBase + i).lastref).kind = kindT.lastExpression then
                        tree.setKind (rule.ruleLocals (r.localVars.localBase + i).lastref, kindT.expression)
                    end if
                end if

                % if the child is referenced in the replacement,
                % we cannot safely optimize the last reference to the deconstructed parent
                if rule.ruleLocals (r.localVars.localBase + i).lastref not= nilTree then
                    if rule.ruleLocals (r.localVars.localBase + parentvar).lastref not= nilTree
                            and tree.trees (rule.ruleLocals (r.localVars.localBase + parentvar).lastref).kind = kindT.lastExpression then
                        tree.setKind (rule.ruleLocals (r.localVars.localBase + parentvar).lastref, kindT.expression)
                    end if
                end if
            end if
        end for

        % fix the reference counts of local variables of special types [key] and [token] - JRC 10.6.99
        for i : r.localVars.nformals + 1 .. r.localVars.nlocals
            if rule.ruleLocals (r.localVars.localBase + i).basetypename = key_T
                or rule.ruleLocals (r.localVars.localBase + i).basetypename = token_T then
                % not optimizable!
                rule.setLocalRefs (r.localVars.localBase + i, 9)
            end if
        end for

        context := rulecontext

    end enterRuleBody


    procedure checkUserDefinedRuleName (name : tokenT)
        if index (string@(ident.idents (name)), "list_") = 1 or
                index (string@(ident.idents (name)), "repeat_") = 1 or
                index (string@(ident.idents (name)), "opt_") = 1 or
                index (string@(ident.idents (name)), "attr_") = 1 or
                index (string@(ident.idents (name)), "lit_") = 1 or
                index (string@(ident.idents (name)), "push_") = 1 or
                index (string@(ident.idents (name)), "pop_") = 1 or
                index (string@(ident.idents (name)), "TXL_") = 1 then
            error (context, "'list_', 'repeat_', 'opt_', 'attr_', 'lit_', 'push_', 'pop_' and 'TXL_' name prefixes are reserved for TXL internal use", FATAL, 340)
        end if
    end checkUserDefinedRuleName


    procedure processRule (ruleTP : treePT)

        const ruleNameT := txltree.rule_nameT (ruleTP)
        context := "rule '" + string@(ident.idents (ruleNameT)) + "'"
        checkUserDefinedRuleName (ruleNameT)

        const ruleIndex := rule.enterRule (ruleNameT)
        currentRuleIndex := ruleIndex

        bind r to rule.rules (ruleIndex)

        if r.defined then
            if ruleIndex <= nPredefinedRules then
                error (context, "Rule/function declaration overrides predefined function", WARNING, 341)
            else
                error (context, "Rule/function has been previously defined", FATAL, 342)
            end if
        end if

        rule.setDefined (ruleIndex, true)
        rule.setKind (ruleIndex, ruleKind.normalRule)

        if not r.called then
            % TXL 11.1, optional match/replace part
            if tree.plural_emptyP (txltree.rule_optReplaceOrMatchPartTP (ruleTP)) then
                rule.setIsCondition (ruleIndex, true)
            else
                rule.setIsCondition (ruleIndex, txltree.rule_replaceOrMatchT (ruleTP) = match_T)
            end if
        end if

        enterRuleFormals (ruleIndex, txltree.rule_formalsTP (ruleTP))
        enterRuleBody (ruleIndex, ruleTP)

        if r.called and r.isCondition and r.replacementTP not= nilTree then
            error (context, "'replace' rule/function has been previously used as a 'where' condition", FATAL, 343)
        else
            rule.setIsCondition (ruleIndex, r.replacementTP = nilTree)

            if r.isCondition then
                % optimize by treating it as a deep function
                rule.setStarred (ruleIndex, true)
                rule.setKind (ruleIndex, ruleKind.functionRule)
            end if
        end if

        if txltree.rule_isDollared (ruleTP) and
                ((not r.isCondition)
                   or r.postPattern.nparts not= 0) then % allow for visit-only match $ rules
            rule.setKind (ruleIndex, ruleKind.onepassRule)
        end if

        if r.target = any_T and r.postPattern.nparts not= 0 and not r.isCondition then
             polymorphicProgram := true
             if options.option (verbose_p) then
                error (context, "'replace' rule/function has target type [any] (results may not be well-formed)", WARNING, 344)
            end if
        end if

    end processRule


    procedure processFunction (ruleTP : treePT)

        const ruleNameT := txltree.rule_nameT (ruleTP)
        context := "function '" + string@(ident.idents (ruleNameT)) + "'"
        checkUserDefinedRuleName (ruleNameT)

        var ruleIndex := rule.enterRule (ruleNameT)
        currentRuleIndex := ruleIndex

        bind r to rule.rules (ruleIndex)

        if r.defined then
            if ruleIndex <= nPredefinedRules then
                error (context, "Rule/function declaration overrides predefined function", WARNING, 341)
            else
                error (context, "Rule/function has been previously defined", FATAL, 342)
            end if
        end if

        rule.setDefined (ruleIndex, true)
        rule.setKind (ruleIndex, ruleKind.functionRule)

        if not r.called then
            % TXL 11.1, optional match/replace part
            if tree.plural_emptyP (txltree.rule_optReplaceOrMatchPartTP (ruleTP)) then
                rule.setIsCondition (ruleIndex, true)
            else
                rule.setIsCondition (ruleIndex, txltree.rule_replaceOrMatchT (ruleTP) = match_T)
            end if
        end if

        enterRuleFormals (ruleIndex, txltree.rule_formalsTP (ruleTP))

        const callscopetype := r.target
        const previouslyCalled := r.called

        enterRuleBody (ruleIndex, ruleTP)

        if r.called and r.isCondition and r.replacementTP not= nilTree then
            error (context, "'replace' rule/function has been previously used as a 'where' condition", FATAL, 343)
        else
            rule.setIsCondition (ruleIndex, r.replacementTP = nilTree)
        end if

        if previouslyCalled and r.target not= callscopetype and r.target not= any_T and callscopetype not= any_T and not r.starred then
            error (context, "Target type of function does not match scope of previous calls", WARNING, 348)
        end if

        if options.option (verbose_p) and
                r.target = any_T and r.postPattern.nparts not= 0 and not r.isCondition then
            error (context, "'replace' rule/function has target type [any] (results may not be well-formed)", WARNING, 344)
        end if

    end processFunction


    procedure processUndefinedRules (var undefinedRules : boolean)

        % Check that all called rules are defined.  If there are any
        % query rule calls [?R], create a copy of the rule table entry
        % for [R] for the query rule.

        undefinedRules := false

        % We use a loop rather than a for loop in case a match rule
        % with an undefined base rule adds the undefined rule to the
        % rule table (see below)

        var r := nPredefinedRules + 1

        loop
            exit when r > rule.nRules

            if not rule.rules (r).defined then
                % First check to see if it is a query rule

                if string@(ident.idents (rule.rules (r).name)) (1) = "?" then
                    % A query rule - link it to the real rule, but as a match rule.
                    % If the real rule is not defined, we will catch that
                    % later in this same checking loop!

                    const realRuleName := ident.install (string@(ident.idents (rule.rules (r).name)) (2..*), kindT.id)

                    % If the base rule is undefined, this may add an entry for it to the rule table!
                    % We catch that in a later iteration of this same loop.
                    var realRuleIndex := rule.enterRule (realRuleName)

                    % ? on predefined rules is undefined
                    if realRuleIndex <= nPredefinedRules then
                        error ("", "[?] is not defined on predefined function [" +
                            string@(ident.idents (rule.rules (realRuleIndex).name)) + "]", DEFERRED, 352)
                        undefinedRules := true
                    end if

                    rule.cloneRule (r, realRuleIndex)
                    rule.setReplacement (r, nilTree)
                    rule.setIsCondition (r, true)

                    if rule.rules (r).defined then

                        if rule.rules (r).kind = ruleKind.normalRule or rule.rules (r).kind = ruleKind.onepassRule then
                            % optimize the new match rule by treating it as a deep function
                            rule.setStarred (r, true)
                            rule.setKind (r, ruleKind.functionRule)
                        end if

                        % If the new match rule has a post construct, it may change a pattern
                        % variable - but match rules are not permitted to change anything.
                        % We correct for this possibility by marking each main pattern variable
                        % (or descendant thereof) that has been changed in a post construct
                        % as having an extra reference.
                        % This accounts for the possibility that its original value will be needed
                        % in the calling scope if the condition calling this match rule succeeds.
                        var hasPostConstruct := false
                        for p : 1 .. rule.rules (r).postPattern.nparts
                            if rule.ruleParts (rule.rules (r).postPattern.partsBase + p).kind = partKind.construct then
                                hasPostConstruct := true
                            end if
                        end for

                        if hasPostConstruct then
                            for i : rule.rules (r).localVars.nformals + 1 .. rule.rules (r).localVars.nlocals
                                if rule.ruleLocals (rule.rules (r).localVars.localBase + i).changed
                                        and rule.ruleLocals (rule.rules (r).localVars.localBase + i).refs = 1 then
                                    rule.incLocalRefs (rule.rules (r).localVars.localBase + i, 1)
                                end if
                            end for
                        end if
                    end if

                else
                    error ("", "Rule/function '" + string@(ident.idents (rule.rules (r).name)) +
                        "' has not been defined", DEFERRED, 353)
                    undefinedRules := true
                end if
            end if

            r += 1
        end loop

    end processUndefinedRules


    procedure processGlobalVariables (var globalErrors : boolean)

        % Find all the global variables imported or exported from rules
        % and enter them in the global scope.  Check global variable type consistency.

        globalErrors := false

        % set up predefined globals
        const repeat_stringlit_T := ident.install ("repeat_0_stringlit", kindT.id)
        var pdindex : int

        % standard new predefined globals
        rule.setLocalBase (globalR, rule.ruleLocalCount)
        bind globalVars to rule.rules (globalR).localVars

        pdindex := rule.enterLocalVar ("", globalVars, TXLargs_T, repeat_stringlit_T)
        assert pdindex = TXLargsG
        pdindex := rule.enterLocalVar ("", globalVars, TXLprogram_T, stringlit_T)
        assert pdindex = TXLprogramG
        pdindex := rule.enterLocalVar ("", globalVars, TXLinput_T, stringlit_T)
        assert pdindex = TXLinputG
        pdindex := rule.enterLocalVar ("", globalVars, TXLexitcode_T, number_T)
        assert pdindex = TXLexitcodeG

        assert pdindex= numGlobalVars

        assert rule.rules (globalR).localVars.nlocals = numGlobalVars

        for ir : nPredefinedRules + 1 .. rule.nRules
            bind r to rule.rules (ir), globals to rule.rules (globalR)

            for p : 1 .. r.prePattern.nparts
                const partIndex := r.prePattern.partsBase + p
                bind part to rule.ruleParts (partIndex)

                if part.kind = partKind.import_ or part.kind = partKind.export_ then

                    const globalVarRef := rule.lookupLocalVar ("", globals.localVars, part.name)

                    if globalVarRef = 0 then
                        const globalIndex := rule.enterLocalVar ("rule/function '" + string@(ident.idents (r.name)), globals.localVars,
                                part.name, part.target)
                        rule.setPartGlobalRef (partIndex, globalIndex)

                    elsif rule.ruleParts (partIndex).target not= rule.ruleLocals (globals.localVars.localBase + globalVarRef).typename then
                        error ("rule/function '" + string@(ident.idents (r.name)) + "'",
                            "Type of imported/exported variable '" + string@(ident.idents (rule.ruleParts (partIndex).name))
                            + "' does not match global variable", DEFERRED, 354)
                        globalErrors := true

                    else
                        rule.setPartGlobalRef (partIndex, globalVarRef)
                    end if
                end if
            end for

            for p : 1 .. r.postPattern.nparts
                const partIndex := r.postPattern.partsBase + p
                bind part to rule.ruleParts (partIndex)

                if part.kind = partKind.import_ or part.kind = partKind.export_ then

                    const globalVarRef := rule.lookupLocalVar ("", globals.localVars, part.name)

                    if globalVarRef = 0 then
                        const globalIndex := rule.enterLocalVar ("rule/function '" + string@(ident.idents (r.name)), globals.localVars,
                                part.name, part.target)
                        rule.setPartGlobalRef (partIndex, globalIndex)

                    elsif part.target not= rule.ruleLocals (globals.localVars.localBase + globalVarRef).typename then
                        error ("rule/function '" + string@(ident.idents (r.name)) + "'",
                            "Type of imported/exported variable '" + string@(ident.idents (part.name))
                            + "' does not match global variable", DEFERRED, 354)
                        globalErrors := true

                    else
                        rule.setPartGlobalRef (partIndex, globalVarRef)
                    end if
                end if
            end for

        end for

    end processGlobalVariables


    var reachList : array 1 .. maxSymbols of treePT
    var reachLength := 0

    function real_reachable (defineTP, targetTP : treePT, depth : int) : boolean
        % reachable (X,Y) = true if X is of type Y,
        %                 = true if X is of type choose, and reachable (one kid of X,Y)
        %                 = true if X is of type order, and reachable (one kid of X,Y)

        if depth > symbol.nSymbols then
            % give up, don't know, probably no
            result false
        end if

        % Is this the one we're looking for?
        if tree.trees (defineTP).name = tree.trees (targetTP).name
                    and tree.trees (defineTP).kind = tree.trees (targetTP).kind then
            result true
        end if

        % If not, is it worth looking deeper?
        if tree.trees (defineTP).kind >= firstLeafKind then
            result tree.trees (defineTP).kind = kindT.token and tree.trees (targetTP).kind >= firstLiteralKind
        end if

        % Keep track of where we've already looked
        if depth = 0 then
            reachLength := 0
        end if

        for i : 1 .. reachLength
            if tree.trees (reachList (i)).name = tree.trees (defineTP).name
                    and tree.trees (reachList (i)).kind = tree.trees (defineTP).kind then
                % been there, done that
                result false
            end if
        end for

        assert reachLength < symbol.nSymbols
        reachLength += 1
        reachList (reachLength) := defineTP

        % Now look deeper
        if tree.trees (defineTP).kind = kindT.generaterepeat
                or tree.trees (defineTP).kind = kindT.generatelist then
            result tree.trees (targetTP).kind = kindT.empty
                    or real_reachable (tree.kid1TP (defineTP), targetTP, depth + 1)
        elsif tree.trees (defineTP).kind = kindT.lookahead then
            result tree.trees (targetTP).kind = kindT.empty
        elsif tree.trees (defineTP).kind = kindT.choose or tree.trees (defineTP).kind = kindT.leftchoose
                or tree.trees (defineTP).kind = kindT.order then
            for i : 1 .. tree.trees (defineTP).count
                if real_reachable (tree.kidTP (i, defineTP), targetTP, depth + 1) then
                    result true
                end if
            end for
            result false
        elsif tree.trees (defineTP).kind = kindT.repeat or tree.trees (defineTP).kind = kindT.list then
            assert tree.trees (defineTP).count = 2
            result real_reachable (tree.kid2TP (defineTP), targetTP, depth + 1)
                or real_reachable (tree.kid1TP (defineTP), targetTP, depth + 1)
        else
            result false
        end if
    end real_reachable


    const reachableCacheSize := 30
    var reachableCache : array 1 .. reachableCacheSize of
        record
            defineTP, targetTP : treePT
            yes : boolean
        end record
    var reachableCacheTop := 0

    function reachable (defineTP, targetTP : treePT) : boolean
        for i : 1 .. reachableCacheTop
            if reachableCache (i).targetTP = targetTP and reachableCache (i).defineTP = defineTP then
                result reachableCache (i).yes
            end if
        end for
        if reachableCacheTop < reachableCacheSize then
            reachableCacheTop += 1
            bind var rc to reachableCache (reachableCacheTop)
            rc.defineTP := defineTP
            rc.targetTP := targetTP
            rc.yes := real_reachable (defineTP, targetTP, 0)
            result rc.yes
        else
            result real_reachable (defineTP, targetTP, 0)
        end if
    end reachable


    function possiblyEmpty (r : ruleT, replacementTP : treePT, depth : int) : boolean
        % possiblyEmpty (X) = true if X is of type empty, generaterepeat or generatelist,
        %                   = true if X is of type choose, and possiblyEmpty (kid of X)
        %                   = true if X is of type order, repeat or list, and possiblyEmpty (all kids of X)

        if depth > symbol.nSymbols then
            % give up, don't know, probably yes
            result true
        end if

        if tree.trees (replacementTP).kind = kindT.empty
                or tree.trees (replacementTP).kind = kindT.generaterepeat
                or tree.trees (replacementTP).kind = kindT.generatelist
                or tree.trees (replacementTP).kind = kindT.lookahead then
            result true

        elsif tree.trees (replacementTP).kind = kindT.choose
                or  tree.trees (replacementTP).kind = kindT.leftchoose then
            result possiblyEmpty (r, tree.kid1TP (replacementTP), depth + 1)

        elsif tree.trees (replacementTP).kind = kindT.order
                or tree.trees (replacementTP).kind = kindT.repeat
                or tree.trees (replacementTP).kind = kindT.list then
            for i : 1 .. tree.trees (replacementTP).count
                if not possiblyEmpty (r, tree.kidTP (i, replacementTP), depth + 1) then
                    result false
                end if
            end for
            result true

        elsif tree.trees (replacementTP).kind = kindT.expression or  tree.trees (replacementTP).kind = kindT.lastExpression then
            % the count field tells us the ruleLocals index!
            const localIndex := tree.trees (replacementTP).count
            const symbolIndex := symbol.findSymbol (rule.ruleLocals (r.localVars.localBase + localIndex).typename)

            result possiblyEmpty (r, symbol.symbols (symbolIndex), depth + 1)

        else
            result false
        end if
    end possiblyEmpty


    procedure unreachable_target_warning (ruleName, calledRuleName, localName, localTypeName : tokenT)
        error ("rule/function '" + string@(ident.idents (ruleName)) + "'",
            "Scope '" + string@(ident.idents (localName))
            + " [" + externalType (string@(ident.idents (localTypeName)))
            + "]' of call to rule/function '" + string@(ident.idents (calledRuleName))
            + "' can never contain a match", WARNING, 356)
    end unreachable_target_warning


    procedure empty_result_warning (ruleName, calledRuleName, localName, localTypeName, repeat1TypeName : tokenT)
        error ("rule/function '" + string@(ident.idents (ruleName)) + "'",
            "Call to rule/function '" + string@(ident.idents (calledRuleName))
            + "' with scope '" + string@(ident.idents (localName))
            + " [" + externalType (string@(ident.idents (localTypeName)))
            + "]' may yield an empty result for embedded [" + externalType (string@(ident.idents (repeat1TypeName)))
            + "]", WARNING, 357)
    end empty_result_warning


    procedure checkRuleCallScopes (replacementTP : treePT, r : ruleT, var scopeErrors : boolean)

        % Find every rule call in the replacement tree and check that its scope type
        % is reasonable

        if replacementTP = nilTree then
            return
        end if


        case tree.trees (replacementTP).kind of

            label kindT.order, kindT.repeat, kindT.list :
                var replacementKidsKP := tree.trees (replacementTP).kidsKP
                const endKP := replacementKidsKP + tree.trees (replacementTP).count
                assert replacementKidsKP not= nilKid
                loop
                    checkRuleCallScopes (tree.kids (replacementKidsKP), r, scopeErrors)
                    replacementKidsKP += 1
                    exit when replacementKidsKP >= endKP
                end loop

            label kindT.choose :
                const replacementKidKP := tree.trees (replacementTP).kidsKP
                assert replacementKidKP not= nilKid

                checkRuleCallScopes (tree.kids (replacementKidKP), r, scopeErrors)

            label kindT.literal, kindT.stringlit, kindT.charlit, kindT.number, kindT.id, kindT.comment,
                    kindT.usertoken1, kindT.usertoken2, kindT.usertoken3, kindT.usertoken4, kindT.usertoken5,
                    kindT.usertoken6, kindT.usertoken7, kindT.usertoken8, kindT.usertoken9, kindT.usertoken10,
                    kindT.usertoken11, kindT.usertoken12, kindT.usertoken13, kindT.usertoken14, kindT.usertoken15,
                    kindT.usertoken16, kindT.usertoken17, kindT.usertoken18, kindT.usertoken19, kindT.usertoken20,
                    kindT.usertoken21, kindT.usertoken22, kindT.usertoken23, kindT.usertoken24, kindT.usertoken25,
                    kindT.usertoken26, kindT.usertoken27, kindT.usertoken28, kindT.usertoken29, kindT.usertoken30,
                    kindT.empty, kindT.token, kindT.key, kindT.upperlowerid, kindT.upperid,
                    kindT.lowerupperid, kindT.lowerid, kindT.floatnumber,
                    kindT.decimalnumber, kindT.integernumber,
                    kindT.newline, kindT.space,                 % JRC 31.3.08
                    kindT.srclinenumber, kindT.srcfilename:     % JRC 14.12.07
                return

            label kindT.expression, kindT.lastExpression :
                % the count field tells us the ruleLocals index!
                const localIndex := tree.trees (replacementTP).count
                var ruleCallsKP : kidPT := tree.trees (replacementTP).kidsKP
                var scopeSymbolIndex := symbol.findSymbol (rule.ruleLocals (r.localVars.localBase + localIndex).typename)
                const scopeTypeTP := symbol.symbols (scopeSymbolIndex)

                if ruleCallsKP not= nilKid
                        and index (string@(ident.idents (rule.ruleLocals (r.localVars.localBase + localIndex).name)), "_anonymous_") not= 1 then
                    % Process each rule called, and check target is reachable from the scope
                    loop
                        assert tree.trees (tree.kids (ruleCallsKP)).kind = kindT.ruleCall

                        % rule index encoded in the name field of the call!
                        const calledRuleIndex := tree.trees (tree.kids (ruleCallsKP)).name

                        if calledRuleIndex > nPredefinedRules then
                            % Check scope for anomalies
                            var targetIndex := symbol.findSymbol (rule.rules (calledRuleIndex).target)
                            const targetTypeTP := symbol.symbols (targetIndex)

                            % First check: can we ever match, with this scope?
                            var targetType0TP := targetTypeTP
                            if (index (string@(ident.idents (rule.rules (calledRuleIndex).target)), "repeat_1_") = 1
                                        or index (string@(ident.idents (rule.rules (calledRuleIndex).target)), "list_1_") = 1) then
                                targetType0TP := symbol.symbols (targetIndex - 1)
                            end if

                            if tree.trees (targetType0TP).name not= any_T
                                    and tree.trees (scopeTypeTP).name not= any_T
                                    and tree.trees (targetType0TP).name not= key_T
                                    and not reachable (scopeTypeTP, targetType0TP) then
                                if not polymorphicProgram then
                                    unreachable_target_warning (r.name, rule.rules (calledRuleIndex).name,
                                        rule.ruleLocals (r.localVars.localBase + localIndex).name, rule.ruleLocals (r.localVars.localBase + localIndex).typename)
                                end if
                            end if

                            % Second check: can we ever make an empty [repeat] in a scope containing [repeat+] ?
                            if options.option (analyze_p) then
                                if (index (string@(ident.idents (rule.rules (calledRuleIndex).target)), "repeat_0_") = 1
                                            or index (string@(ident.idents (rule.rules (calledRuleIndex).target)), "list_0_") = 1)
                                    and (rule.rules (calledRuleIndex).kind = ruleKind.normalRule or rule.rules (calledRuleIndex).kind = ruleKind.onepassRule
                                        or (rule.rules (calledRuleIndex).kind = ruleKind.functionRule and rule.rules (calledRuleIndex).starred))
                                    and rule.rules (calledRuleIndex).replacementTP not= nilTree
                                        and possiblyEmpty (rule.rules (calledRuleIndex), rule.rules (calledRuleIndex).replacementTP, 0) then
                                    % The corresponding [repeat_1_X] or [list_1_X] follows the original in the symbol table
                                    const targetType1TP := symbol.symbols (targetIndex + 1)
                                    if reachable (scopeTypeTP, targetType1TP) then
                                        empty_result_warning (r.name, rule.rules (calledRuleIndex).name,
                                            rule.ruleLocals (r.localVars.localBase + localIndex).name, rule.ruleLocals (r.localVars.localBase + localIndex).typename,
                                            tree.trees (targetType1TP).name)
                                    end if
                                end if
                            end if

                            % Third check: is an optimizable skipping [X] ever called with a scope that is not [repeat X] for the skipped [X]?
                            if rule.rules (calledRuleIndex).skipRepeat then
                                if tree_ops.isListOrRepeatType (tree.trees (scopeTypeTP).name)
                                        and tree.trees (targetTypeTP).name = tree_ops.listOrRepeatBaseType (tree.trees (scopeTypeTP).name) then
                                    % skipping [X] match/replace * [X] in [repeat/list X]
                                else
                                    % this call can't be optimized, so we give up on the optimization
                                    rule.setSkipRepeat (calledRuleIndex, false)
                                end if
                            end if
                        end if

                        ruleCallsKP += 1
                        exit when tree.kids (ruleCallsKP) = nilTree
                    end loop
                end if

            label :
                error ("", "Fatal TXL error in checkRuleCallScopes", INTERNAL_FATAL, 359)
        end case

    end checkRuleCallScopes


    procedure processRuleCalls (var scopeErrors : boolean)

        % Find all rule calls and check that their targets are reachable from their scopes.

        scopeErrors := false

        for r : nPredefinedRules + 1 .. rule.nRules
            checkRuleCallScopes (rule.rules (r).replacementTP, rule.rules (r), scopeErrors)

            for p : 1 .. rule.rules (r).prePattern.nparts
                bind part to rule.ruleParts (rule.rules (r).prePattern.partsBase + p)
                if part.kind = partKind.construct or part.kind = partKind.export_
                        or part.kind = partKind.cond or part.kind = partKind.assert_ then
                    checkRuleCallScopes (part.replacementTP, rule.rules (r), scopeErrors)
                end if
            end for

            for p : 1 .. rule.rules (r).postPattern.nparts
                bind part to rule.ruleParts (rule.rules (r).postPattern.partsBase + p)
                if part.kind = partKind.construct or part.kind = partKind.export_
                        or part.kind = partKind.cond or part.kind = partKind.assert_ then
                    checkRuleCallScopes (part.replacementTP, rule.rules (r), scopeErrors)
                end if
            end for
        end for

        % Skipping main rule target is never optimizable - JRC 10.4d
        rule.setSkipRepeat (mainRule, false)

    end processRuleCalls


    function callsRule (ruleIndex : int, replacementTP : treePT) : boolean

        if replacementTP = nilTree then
            result false
        end if

        case tree.trees (replacementTP).kind of

            label kindT.order, kindT.repeat, kindT.list :
                var replacementKidsKP := tree.trees (replacementTP).kidsKP
                const endKP := replacementKidsKP + tree.trees (replacementTP).count
                assert replacementKidsKP not= nilKid
                var kidsCallRule := false
                loop
                    kidsCallRule := kidsCallRule or callsRule (ruleIndex, tree.kids (replacementKidsKP))
                    replacementKidsKP += 1
                    exit when replacementKidsKP >= endKP
                end loop
                result kidsCallRule

            label kindT.choose :
                const replacementKidKP := tree.trees (replacementTP).kidsKP
                assert replacementKidKP not= nilKid

                result callsRule (ruleIndex, tree.kids (replacementKidKP))

            label kindT.literal, kindT.stringlit, kindT.charlit, kindT.number, kindT.id, kindT.comment,
                    kindT.usertoken1, kindT.usertoken2, kindT.usertoken3, kindT.usertoken4, kindT.usertoken5,
                    kindT.usertoken6, kindT.usertoken7, kindT.usertoken8, kindT.usertoken9, kindT.usertoken10,
                    kindT.usertoken11, kindT.usertoken12, kindT.usertoken13, kindT.usertoken14, kindT.usertoken15,
                    kindT.usertoken16, kindT.usertoken17, kindT.usertoken18, kindT.usertoken19, kindT.usertoken20,
                    kindT.usertoken21, kindT.usertoken22, kindT.usertoken23, kindT.usertoken24, kindT.usertoken25,
                    kindT.usertoken26, kindT.usertoken27, kindT.usertoken28, kindT.usertoken29, kindT.usertoken30,
                    kindT.empty, kindT.token, kindT.key, kindT.upperlowerid, kindT.upperid,
                    kindT.lowerupperid, kindT.lowerid, kindT.floatnumber,
                    kindT.decimalnumber, kindT.integernumber,
                    kindT.srclinenumber, kindT.srcfilename:     % JRC 14.12.07

                result false

            label kindT.expression, kindT.lastExpression :
                % the count field tells us the ruleLocals index!
                var ruleCallsKP : kidPT := tree.trees (replacementTP).kidsKP

                if ruleCallsKP not= nilKid then
                    % Process each rule called, and check target is reachable from the scope
                    loop
                        assert tree.trees (tree.kids (ruleCallsKP)).kind = kindT.ruleCall

                        % rule index encoded in the name field of the call!
                        if tree.trees (tree.kids (ruleCallsKP)).name = ruleIndex then
                            result true
                        end if

                        ruleCallsKP += 1
                        exit when tree.kids (ruleCallsKP) = nilTree
                    end loop
                end if

                result false

            label :
                error ("", "Fatal TXL error in callsRule", INTERNAL_FATAL, 360)
        end case

    end callsRule


    var callerIndex : array 1 .. maxRules of nat2       % 1 .. maxRules
    var callerDepth := 0

    function callersPreImportGlobal (ruleIndex : int, globalName : tokenT) : boolean
        if callerDepth = rule.nRules then
            result false
        end if
        for c : 1 .. callerDepth
            if callerIndex (c) = ruleIndex then
                result false
            end if
        end for

        callerDepth += 1
        callerIndex (callerDepth) := ruleIndex

        for rindex : nPredefinedRules + 1 .. rule.nRules
            bind r to rule.rules (rindex)
            for c : 1 .. r.calledRules.ncalls

                if rule.ruleCalls (r.calledRules.callBase + c) = ruleIndex then
                    const localIndex := rule.lookupLocalVar (context, r.localVars, globalName)
                    if localIndex not= 0 and rule.ruleLocals (r.localVars.localBase + localIndex).global then
                        for p : 1 .. r.prePattern.nparts
                            if rule.ruleParts (r.prePattern.partsBase + p).kind = partKind.import_
                                    and rule.ruleParts (r.prePattern.partsBase + p).name = globalName then
                                for pp : p + 1 .. r.prePattern.nparts
                                    exit when rule.ruleParts (r.prePattern.partsBase + pp).name = globalName
                                    if (rule.ruleParts (r.prePattern.partsBase + pp).kind = partKind.construct
                                            or rule.ruleParts (r.prePattern.partsBase + pp).kind = partKind.export_)
                                            and callsRule (ruleIndex, rule.ruleParts (r.prePattern.partsBase + pp).replacementTP) then
                                        callerDepth -= 1
                                        result true
                                    end if
                                end for
                                for pp : 1 .. r.postPattern.nparts
                                    exit when rule.ruleParts (r.postPattern.partsBase + pp).name = globalName
                                    if (rule.ruleParts (r.postPattern.partsBase + pp).kind = partKind.construct
                                            or rule.ruleParts (r.postPattern.partsBase + pp).kind = partKind.export_)
                                            and callsRule (ruleIndex, rule.ruleParts (r.postPattern.partsBase + pp).replacementTP) then
                                        callerDepth -= 1
                                        result true
                                    end if
                                end for
                            end if
                        end for
                        for p : 1 .. r.postPattern.nparts
                            if rule.ruleParts (r.postPattern.partsBase + p).kind = partKind.import_
                                    and rule.ruleParts (r.postPattern.partsBase + p).name = globalName then
                                for pp : p + 1 .. r.postPattern.nparts
                                    exit when rule.ruleParts (r.postPattern.partsBase + pp).name = globalName
                                    if (rule.ruleParts (r.postPattern.partsBase + pp).kind = partKind.construct
                                            or rule.ruleParts (r.postPattern.partsBase + pp).kind = partKind.export_)
                                            and callsRule (ruleIndex, rule.ruleParts (r.postPattern.partsBase + pp).replacementTP) then
                                        callerDepth -= 1
                                        result true
                                    end if
                                end for
                            end if
                        end for
                    end if
                    if callersPreImportGlobal (rindex, globalName) then
                        callerDepth -= 1
                        result true
                    end if
                end if
            end for
        end for
        callerDepth -= 1
        result false
    end callersPreImportGlobal


    procedure optimizeGlobalVariables

        % Find all global variable tail-recursive updates
        % and optimize to avoid copying

        for rindex : nPredefinedRules + 1 .. rule.nRules
            bind r to rule.rules (rindex)
            % If the last thing in the postpattern is a recursive export,
            % and it is not referred to in the replacement (or following postexports),
            % then we can optimize it
            for decreasing i : r.postPattern.nparts .. 1
                exit when rule.ruleParts (r.postPattern.partsBase + i).kind not= partKind.export_

                var lastRecursiveRefTP := nilTree
                lastRecursiveRefTP := findLastRef (rule.ruleParts (r.postPattern.partsBase + i).name, rule.ruleParts (r.postPattern.partsBase + i).replacementTP)

                if lastRecursiveRefTP not= nilTree then

                    var lastPostExportRefTP := nilTree
                    for j : i + 1 .. r.postPattern.nparts
                        lastPostExportRefTP := findLastRef (rule.ruleParts (r.postPattern.partsBase + i).name, rule.ruleParts (r.postPattern.partsBase + j).replacementTP)
                        exit when lastPostExportRefTP not= nilTree
                    end for

                    const lastReplacementRefTP := findLastRef (rule.ruleParts (r.postPattern.partsBase + i).name, r.replacementTP)

                    if lastPostExportRefTP = nilTree and lastReplacementRefTP = nilTree
                            and not callersPreImportGlobal (rindex, rule.ruleParts (r.postPattern.partsBase + i).name) then
                        tree.setKind (lastRecursiveRefTP, kindT.lastExpression)
                    end if
                end if
            end for
        end for

    end optimizeGlobalVariables


    body procedure makeRuleTable %(txlParseTreeTP : treePT)

        % predefined rules must be initialized
        assert rule.nRules = nPredefinedRules

        % now process rule definitions
        var statementsLeftTP := txltree.program_statementsTP (txlParseTreeTP)
        polymorphicProgram := false

        loop
            exit when tree.plural_emptyP (statementsLeftTP)

            const statementTP := txltree.statement_keyDefRuleTP (tree.plural_firstTP (statementsLeftTP))
            const statementKind := string@(ident.idents (tree.trees (statementTP).name))

            if statementKind = "TXL_ruleStatement_" then
                processRule (statementTP)
            elsif statementKind = "TXL_functionStatement_" then
                processFunction (statementTP)
            else
                assert statementKind = "TXL_keysStatement_" or
                    statementKind = "TXL_defineStatement_"
                % handled previously when creating the object language
                % grammar tree, so ignore now
            end if

            statementsLeftTP := tree.plural_restTP (statementsLeftTP)
        end loop

        % check that all rules have been defined, and process query rule conversions
        var undefinedRules := false

        processUndefinedRules (undefinedRules)

        if undefinedRules then
            quit
        end if

        % identify main rule
        var mainRuleName := ident.install ("main", kindT.id)

        for mr : 1 .. rule.nRules
            if rule.rules (mr).name = mainRuleName then
                mainRule := mr
                exit
            end if
        end for

        if rule.nRules = nPredefinedRules then
            error ("", "No rules/functions defined, assuming parse only", INFORMATION, 364)
            mainRule := rule.enterRule (mainRuleName)
            rule.setDefined (mainRule, false)
            return

        elsif mainRule = 0 then
            error ("", "Rule/function 'main' has not been defined", FATAL, 361)

        else
            bind main to rule.rules (mainRule)
            if main.kind = ruleKind.functionRule and not main.starred then
                const programT := ident.lookup ("program")
                if main.target not= programT and main.target not= any_T then
                    error ("", "Function 'main' can never match input type [program]" +
                        " (use rule, searching function, or target type [program] instead)", FATAL, 362)
                end if
            end if
        end if

        % Process global variables and check that import/export types are consistent
        var globalErrors := false

        processGlobalVariables (globalErrors)

        if globalErrors then
            quit
        end if

        % Check that rule call scope types are reasonable
        if options.option (analyze_p) then
            error ("", "Analyzing the transformation rule set", INFORMATION, 363)
        end if

        var scopeErrors := false

        processRuleCalls (scopeErrors)

        if scopeErrors then
            quit
        end if

        % Optimize global variable updates
        optimizeGlobalVariables

    end makeRuleTable

end ruleCompiler
