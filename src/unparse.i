% OpenTxl Version 11 predefined built-in functions
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

% TXL unparsing and output printing 

% Modification Log

% v11.0 Initial revision, revised from FreeTXL 10.8b (c) 1988-2022 Queen's University at Kingston


% Turing standard output stream codes
const * stdout := -1
const * stderr := 0

module unparser

   import
        tree, 
        var charset, var ident, var options, var scanner,
        rule,
        var inputTokens, var lastTokenIndex, 
        kindType,
        error, externalType, stackBase

    export 
        printLeaves, extractLeaves, quoteLeaves, printMatch, printParse, printPatternParse, printGrammar

    % Global limits
    if options.outputLineLength > maxLineLength then
        options.setOutputLineLength (maxLineLength)
    end if
    var maxIndent := min (1024, options.outputLineLength div 2)

    % Preformatted blanks, for tabs and such
    var BLANKS : char (maxIndent+1) 
    for i : 1 .. maxIndent
        BLANKS (i) := ' '
    end for
    type (string, BLANKS (maxIndent+1)) := "" 


    % Routines for printing parse and grammar trees

    var nparselines := 0
    var localVarsAddress : addressint := 0
    forward procedure realPrintParse (parseTP : treePT, outstream : int, indentation : int)

    #if not STANDALONE then
    function emptyTree (parseTP: treePT) : boolean
        result tree.trees (parseTP).kind = kindT.empty or 
            ((tree.trees (parseTP).kind = kindT.repeat or tree.trees (parseTP).kind = kindT.list or tree.trees (parseTP).kind = kindT.choose)
                and tree.trees (tree.kids (tree.trees (parseTP).kidsKP)).kind = kindT.empty)
    end emptyTree

    procedure printKids (kidCount : int, kidsKP: kidPT, outstream : int, indentation: int, internalTree : boolean)
        for k : 0 .. kidCount - 1
            const kidTP := tree.kids (kidsKP + k)
            % Elide formatting cues when printing trees
            if (not emptyTree (kidTP)) or (outstream >= 0 and (tree.trees (kidTP).name = empty_T or options.option (verbose_p))) then
                if (kidCount > 1 or indentation = 1) and tree.trees (kidTP).kind not= kindT.literal then
                    if outstream >= 0 then
                        put : outstream, ""
                        if not options.option (darren_p) then
                            put : outstream, type (string, BLANKS) (1 .. indentation) ..
                        end if
                    else
                        put ""
                        if not options.option (darren_p) then
                            put type (string, BLANKS) (1 .. indentation) ..
                        end if
                    end if
                    nparselines += 1
                elsif (kidCount > 1 or indentation = 1) then
                    if outstream >= 0 then
                        put : outstream, " " ..
                    else
                        put " " ..
                    end if
                end if
                realPrintParse (kidTP, outstream, indentation)
            end if
        end for
    end printKids

    procedure printRepeatKids (originalKidsKP: kidPT, outstream : int, indentation: int, internalTree : boolean)
        var kidsKP := originalKidsKP
        loop
            const kidTP := tree.kids (kidsKP)
            const moreKidsTP := tree.kids (kidsKP + 1)
            
            % Elide formatting cues when printing trees
            if (not emptyTree (kidTP)) or (outstream >= 0 and (tree.trees (kidTP).name = empty_T or options.option (verbose_p))) then
                if (tree.kidCount > 1 or indentation = 1) and tree.trees (kidTP).kind not= kindT.literal then
                    if outstream >= 0 then
                        put : outstream, ""
                        if not options.option (darren_p) then
                            put : outstream, type (string, BLANKS) (1 .. indentation) ..
                        end if
                    else
                        put ""
                        if not options.option (darren_p) then
                            put type (string, BLANKS) (1 .. indentation) ..
                        end if
                    end if
                    nparselines += 1
                end if

                realPrintParse (kidTP, outstream, indentation)
            end if
            
            exit when tree.trees (moreKidsTP).kind = kindT.empty
            
            kidsKP := tree.trees (moreKidsTP).kidsKP
        end loop
    end printRepeatKids

    function underscore (s : string) : string
        loop
            const spindex := index (s, " ")
            exit when spindex = 0
            % Dangerous operation!
            type char4095 : char (4095)
            char4095@(addr(s)) (spindex) := '_'
        end loop
        if index (s, "opt_'") = 1 then
            result "opt_literal"
        end if
        if index (s, "lit_'") = 1 then
            result "literal"
        end if
        result s
    end underscore

    procedure printTypedTree (parseTP : treePT, outstream : int, grammar_p : boolean, end_p : boolean)

        if tree.trees (parseTP).kind = kindT.empty and outstream < 0 then
            % elide empty in XML output
            return
        end if
        
        var treeT := tree.trees (parseTP).rawname
        
        if tree.trees (parseTP).kind = kindT.ruleCall then
            % name field actually encodes rule index
            treeT := rule.rules (treeT).name
        end if
        
        bind treeName to string@(ident.idents (treeT))
        
        if tree.trees (parseTP).kind = kindT.literal then
            if end_p then
                return
            end if
        else
            if not end_p then
                if outstream >= 0 then
                    put : outstream, "<" ..
                else
                    put "<" ..
                end if
            else
                if tree.trees (parseTP).kind = kindT.empty or (tree.trees (parseTP).kind >= kindT.firstTime 
                        and tree.trees (parseTP).kind not= kindT.ruleCall) then
                    return
                end if
                if outstream >= 0 then
                    put : outstream, "</" ..
                else
                    put "</" ..
                end if
            end if
        end if

        case tree.trees (parseTP).kind of
            label kindT.order, kindT.choose, kindT.repeat, kindT.list, 
                    kindT.leftchoose, kindT.generaterepeat, kindT.generatelist, kindT.lookahead :
                if outstream >= 0 then
                    put : outstream, underscore (externalType (treeName)) ..
                else
                    put underscore (externalType (treeName)) ..
                end if
            label kindT.empty :
                if outstream >= 0 then
                    put : outstream, treeName ..
                else
                    put treeName ..
                end if
            label kindT.firstTime :
                if outstream >= 0 then
                    put : outstream, "varbind" ..
                else
                    put "varbind" ..
                end if
                if not end_p then
                    if outstream >= 0 then
                        put : outstream, " name=\"", treeName, "\"" ..
                    else
                        put " name=\"", treeName, "\"" ..
                    end if
                    assert localVarsAddress not= 0
                    bind localVars to localsListT@(localVarsAddress)
                    assert tree.trees (parseTP).count > 0 and tree.trees (parseTP).count <= localVars.nlocals
                    if outstream >= 0 then
                        put : outstream, " type=\"", underscore (externalType (string@(ident.idents (rule.ruleLocals (localVars.localBase + tree.trees (parseTP).count).typename)))), "\"" ..
                    else
                        put " type=\"", underscore (externalType (string@(ident.idents (rule.ruleLocals (localVars.localBase + tree.trees (parseTP).count).typename)))), "\"" ..
                    end if
                end if
            label kindT.subsequentUse, kindT.expression, kindT.lastExpression :
                if outstream >= 0 then
                    put : outstream, "varref" ..
                else
                    put "varref" ..
                end if
                if not end_p then
                    if tree.trees (parseTP).kind = kindT.lastExpression and options.option (verbose_p) then
                        if outstream >= 0 then
                            put : outstream, " last=\"true\"" ..
                        else
                            put " last=\"true\"" ..
                        end if
                    end if
                    if outstream >= 0 then
                        put : outstream, " name=\"", treeName, "\"" ..
                    else
                        put " name=\"", treeName, "\"" ..
                    end if
                    assert localVarsAddress not= 0
                    bind localVars to localsListT@(localVarsAddress)
                    assert tree.trees (parseTP).count > 0 and tree.trees (parseTP).count <= localVars.nlocals
                    if outstream >= 0 then
                        put : outstream, " type=\"", underscore (externalType (string@(ident.idents (rule.ruleLocals (localVars.localBase + tree.trees (parseTP).count).typename)))), "\"" ..
                    else
                        put " type=\"", underscore (externalType (string@(ident.idents (rule.ruleLocals (localVars.localBase + tree.trees (parseTP).count).typename)))), "\"" ..
                    end if
                end if
            label kindT.ruleCall :
                if outstream >= 0 then
                    put : outstream, "rulecall" ..
                    if not end_p then
                        put : outstream, " name=\"", treeName, "\"" ..
                    end if
                else
                    put "rulecall" ..
                    if not end_p then
                        put " name=\"", treeName, "\"" ..
                    end if
                end if
            label kindT.literal :
                if outstream >= 0 then
                    charset.putXmlCode (outstream, treeName)
                else
                    charset.putXmlCode (outstream, treeName)
                end if
            label :
                if tree.trees (parseTP).kind > kindT.literal and tree.trees (parseTP).kind <= lastUserTokenKind then
                    if outstream >= 0 then
                        put : outstream, string@(ident.idents (kindType (ord (tree.trees (parseTP).kind)))) ..
                        if (not grammar_p) and (not end_p) then
                            put : outstream, ">" ..
                            charset.putXmlCode (outstream, treeName)
                        end if
                    else
                        put string@(ident.idents (kindType (ord (tree.trees (parseTP).kind)))) ..
                        if (not grammar_p) and (not end_p) then
                            put : outstream, ">" ..
                            charset.putXmlCode (outstream, treeName)
                        end if
                    end if
                else
                    if outstream >= 0 then
                        put : outstream, "ILLEGAL" ..
                        if not end_p then
                            put : outstream, " kind=\"", ord (tree.trees (parseTP).kind), "\">", treeName ..
                        end if
                    else
                        put "ILLEGAL" ..
                        if not end_p then
                            put " kind=\"", ord (tree.trees (parseTP).kind), "\">", treeName ..
                        end if
                    end if
                end if
        end case
        
        if tree.trees (parseTP).kind not= kindT.literal then
            if not end_p then
                if tree.trees (parseTP).kind = kindT.empty or (tree.trees (parseTP).kind >= kindT.firstTime 
                        and tree.trees (parseTP).kind not= kindT.ruleCall) then
                    if outstream >= 0 then
                        put : outstream, "/" ..
                    else
                        put "/" ..
                    end if
                end if
                if (tree.trees (parseTP).kind <= kindT.literal or tree.trees (parseTP).kind > lastUserTokenKind) and not grammar_p then
                    if outstream >= 0 then
                        put : outstream, ">" ..
                    else
                        put ">" ..
                    end if
                end if
            else
                if outstream >= 0 then
                    put : outstream, ">" ..
                else
                    put ">" ..
                end if
            end if
        end if
    end printTypedTree
    #end if


    body procedure realPrintParse % (parseTP : treePT, outstream : int, indentation: int)

    #if not STANDALONE then
        if parseTP = nilTree then
            return
        end if

        % New style tree output -- JRC 16.9.95
        var treeT := tree.trees (parseTP).rawname
        
        if tree.trees (parseTP).kind = kindT.ruleCall then
            % name field actually encodes rule index
            treeT := rule.rules (treeT).name
        end if
        
        bind treeName to string@(ident.idents (treeT))
        
        % Dangerous operation!
        type char4095 : char (4095)
        const internalTree := tree.trees (parseTP).kind < firstLiteralKind
            and ((type (char4095, treeName) (1) = '_' and type (char4095, treeName) (2) = '_') 
                or (tree.trees (parseTP).kind = kindT.lookahead))
        
        var indent := 0
        var nKids := 0
        
        if indentation = 0 then
            nparselines := 0
        end if
        
        if not internalTree then
            if indentation < maxIndent then
                indent := 1
            end if
            printTypedTree (parseTP, outstream, false, false)
        end if
        
        const oldparselines := nparselines

        case tree.trees (parseTP).kind of
            label kindT.repeat, kindT.list :
                assert tree.trees (parseTP).count = 2
                if localVarsAddress not= 0 then
                    % Printing a pattern
                    printKids (2, tree.trees (parseTP).kidsKP, outstream, indentation + indent, internalTree)
                else
                    printRepeatKids (tree.trees (parseTP).kidsKP, outstream, indentation + indent, internalTree)
                end if
            label kindT.order, kindT.generatelist, kindT.lookahead :
                nKids := tree.trees (parseTP).count
                printKids (nKids, tree.trees (parseTP).kidsKP, outstream, indentation + indent, internalTree)
            label kindT.choose, kindT.leftchoose, kindT.generaterepeat :
                nKids := 1
                printKids (1, tree.trees (parseTP).kidsKP, outstream, indentation + indent, internalTree)
            label kindT.expression, kindT.lastExpression, kindT.ruleCall :
                if tree.trees (parseTP).kidsKP not= nilKid then
                    nKids := 0
                    for c : tree.trees (parseTP).kidsKP .. maxKids
                        exit when tree.kids (c) = nilTree
                        nKids += 1
                    end for
                    printKids (nKids, tree.trees (parseTP).kidsKP, outstream, indentation + indent, internalTree)
                end if
            label :
        end case

        if not internalTree then
            if nKids > 1 or nparselines > oldparselines then
                if outstream >= 0 then
                    put : outstream, ""
                else
                    put ""
                end if
                nparselines += 1
                if indentation > 0 and not options.option (darren_p) then
                    if outstream >= 0 then
                        put : outstream, type (string, BLANKS) (1 .. indentation) ..
                    else
                        put type (string, BLANKS) (1 .. indentation) ..
                    end if
                end if
            end if
            if indentation > 0 then
                printTypedTree (parseTP, outstream, false, true)
            else
                printTypedTree (parseTP, outstream, false, true)
                if outstream >= 0 then
                    put : outstream, ""
                else
                    put ""
                end if
            end if
        end if

    #else
        error ("", "XML output disabled in standalone applications", FATAL, 951)
    #end if
    end realPrintParse


    procedure printParse (parseTP : treePT, outstream : int, indentation: int)
        localVarsAddress := 0
        realPrintParse (parseTP, outstream, indentation)
    end printParse


    procedure printPatternParse (parseTP : treePT, localVars : localsListT, indentation: int)
        localVarsAddress := addr (localVars)
        realPrintParse (parseTP, 0, indentation)
    end printPatternParse


    #if not NOCOMPILE then
        var grammarLength := 0
        var grammarList : array 1 .. maxSymbols of treePT
    #end if

    forward procedure real_printGrammar (grammarTP : treePT, indentation : int)

    #if not NOCOMPILE then
    procedure printGrammarKids (kidCount : int, kidsKP: kidPT, indentation: int, kind: kindT, internalTree : boolean)
        for k : 0 .. kidCount - 1
            if kidCount > 1 then
                put : stderr, ""
                put : stderr, type (string, BLANKS) (1 .. indentation ) ..
            else
                const kidKind := tree.trees (tree.kids (kidsKP + k)).kind
                if kidKind < kindT.literal then
                    put : stderr, ""
                    put : stderr, type (string, BLANKS) (1 .. indentation ) ..
                end if
            end if
            real_printGrammar (tree.kids (kidsKP + k), indentation)
        end for
    end printGrammarKids
    #end if


    body procedure real_printGrammar % (grammarTP : treePT, indentation: int)

    #if not NOCOMPILE then
        if grammarTP = nilTree then
            return
        end if

        % New style tree output -- JRC 16.9.95
        var treeT := tree.trees (grammarTP).rawname
        
        if tree.trees (grammarTP).kind = kindT.ruleCall then
            % name field actually encodes rule index
            treeT := rule.rules (treeT).name
        end if
        
        bind treeName to string@(ident.idents (treeT))

        % Dangerous operation!
        type char4095 : char (4095)
        const internalTree := tree.trees (grammarTP).kind < firstLiteralKind
            and ((type (char4095, treeName) (1) = '_' and type (char4095, treeName) (2) = '_') 
                or (type (char4095, treeName) (4) = '_' and type (char4095, treeName) (5) = '_'))
            
        var indent := 0
        var nKids := 0
        
        if indentation < maxIndent then
            indent := 2
        end if
        
        printTypedTree (grammarTP, stderr, true, false)

        if tree.trees (grammarTP).kind = kindT.choose or
                tree.trees (grammarTP).kind = kindT.order or 
                tree.trees (grammarTP).kind = kindT.repeat or 
                tree.trees (grammarTP).kind = kindT.list or 
                tree.trees (grammarTP).kind = kindT.leftchoose or
                tree.trees (grammarTP).kind = kindT.generaterepeat or
                tree.trees (grammarTP).kind = kindT.generatelist or
                tree.trees (grammarTP).kind = kindT.lookahead then

            % if we've already printed it once, then reference the original nonterminal label
            for decreasing g : grammarLength .. 1
                if grammarTP = grammarList (g) then
                    put : stderr, " ref=\"", g, "\"/>" ..
                    return
                end if
            end for

            grammarLength += 1
            grammarList (grammarLength) := grammarTP

            % make the kind of the new nonterminal clear
            var kind := tree.trees (grammarTP).kind
            if not options.option (verbose_p) then
                if kind = kindT.leftchoose then 
                    kind := kindT.choose
                elsif kind = kindT.generaterepeat then
                    kind := kindT.repeat
                elsif kind = kindT.generatelist then
                    kind := kindT.list
                end if
            end if
            assert char@(ident.idents (kindType (ord (kind)))) = '*'
            put : stderr, " kind=\"", string@(ident.idents (kindType (ord (kind))) + 1), "\"" ..
            
            % label the new nonterminal for future reference
            if not internalTree then
                put : stderr, " label=\"", grammarLength, "\"" ..
            end if
        end if
        
        if tree.trees (grammarTP).kind not= kindT.literal then
            put : stderr, ">" ..
        end if

        case tree.trees (grammarTP).kind of
            label kindT.order, kindT.repeat, kindT.list :
                nKids := tree.trees (grammarTP).count
                printGrammarKids (nKids, tree.trees (grammarTP).kidsKP, indentation + indent, kindT.order, internalTree)
            label kindT.choose, kindT.leftchoose, kindT.generaterepeat, kindT.generatelist, kindT.lookahead :
                nKids := tree.trees (grammarTP).count
                printGrammarKids (nKids, tree.trees (grammarTP).kidsKP, indentation + indent, kindT.choose, internalTree)
            label kindT.expression, kindT.lastExpression, kindT.ruleCall :
                if tree.trees (grammarTP).kidsKP not= nilKid then
                    nKids := 0
                    for c : tree.trees (grammarTP).kidsKP .. maxKids
                        exit when tree.kids (c) = nilTree
                        nKids += 1
                    end for
                    printGrammarKids (nKids, tree.trees (grammarTP).kidsKP, indentation + indent, kindT.expression, internalTree)
                end if
            label :
        end case

        if nKids > 1 then
            put : stderr, ""
            put : stderr, type (string, BLANKS) (1 .. indentation) ..
            printTypedTree (grammarTP, stderr, true, true)
        elsif indentation > 0 then
            printTypedTree (grammarTP, stderr, true, true)
        else
            put : stderr, ""
            printTypedTree (grammarTP, stderr, true, true)
            put : stderr, ""
        end if

    #end if
    end real_printGrammar


    procedure printGrammar (grammarTP : treePT, indentation: int)
    #if not NOCOMPILE then
        grammarLength := 0
        real_printGrammar (grammarTP, indentation)
    #end if
    end printGrammar


    % Routines for deparsing output

    % Output paragraphing parameters
    const tempIndent := max (1, options.indentIncrement div 2)
    var indent := 0

    % Output line buffer
    % the + maxTuringStringLength + 1 is necessary for type cheats
    % use variable buffer size to force dynamic allocation for efficiency
    var outputLineBufferSize := maxLineLength + maxTuringStringLength + 1
    var outputline, savedoutputline : array 1 .. outputLineBufferSize of char   
    var lineLength := 0

    % Output state
    var emptyLine, blankLine, spacing := true
    var lastLeafNameEnd : char := ' '


    procedure outputindent (n : int)
        % N.B. Cannot use Turing substrings here since maxIndent can be > 4095
        if n <= maxIndent then
            for i : 1 .. n
                outputline (i) := ' '
            end for
            outputline (n + 1) := chr (0)
            lineLength := n
        else
            for i : 1 .. maxIndent
                outputline (i) := ' '
            end for
            outputline (maxIndent + 1) := chr (0)
            lineLength := maxIndent
        end if
    end outputindent

    procedure substr (var target : string, source : string, first, last : int)
        % substring procedure to avoid string temps in recursive routines
        % N.B. Cannot use Turing substrings here since maxLineLength can be > 4095
        type char4096 : char (maxLineLength + maxTuringStringLength + 1)
        var len := last - first + 1
        for i : 1 .. len
            type (char4096, target) (i) := type (char4096, source) (first + i - 1)
        end for
        type (char4096, target) (len + 1) := chr (0)
    end substr

    procedure printLeavesTraversal (subtreeTP : treePT, outstream : int)

        % Stack use limitation - to avoid crashes
        var dummy : int
        if stackBase - addr (dummy) > maxStackUse then 
            quit : stackLimitReached
        end if

        case tree.trees (subtreeTP).kind of

            label kindT.choose :
                % optimize by skipping choose chains -- JRC 4.1.94
                var register chainTP := tree.kids (tree.trees (subtreeTP).kidsKP)
                loop
                    exit when tree.trees (chainTP).kind not= kindT.choose 
                    chainTP := tree.kids (tree.trees (chainTP).kidsKP)
                end loop
                printLeavesTraversal (chainTP, outstream)

            label kindT.order :
                % print out the kids
                var register subtreeKidsKP := tree.trees (subtreeTP).kidsKP
                for : 1 .. tree.trees (subtreeTP).count 
                    exit when tree.trees (tree.kids (subtreeKidsKP)).name = ATTR_T and not options.option (attr_p)
                    printLeavesTraversal (tree.kids (subtreeKidsKP), outstream)
                    subtreeKidsKP += 1
                end for

            label kindT.repeat :
                var register subtreeKidsKP := tree.trees (subtreeTP).kidsKP
                assert subtreeKidsKP not= nilKid
                loop
                    printLeavesTraversal (tree.kids (subtreeKidsKP), outstream)
                    exit when tree.trees (tree.kids (subtreeKidsKP + 1)).kind = kindT.empty
                    subtreeKidsKP := tree.trees (tree.kids (subtreeKidsKP + 1)).kidsKP
                end loop

            label kindT.list :
                var register subtreeKidsKP := tree.trees (subtreeTP).kidsKP
                assert subtreeKidsKP not= nilKid
                if tree.trees (tree.kids (subtreeKidsKP + 1)).kind not= kindT.empty then
                    loop
                        printLeavesTraversal (tree.kids (subtreeKidsKP), outstream)
                        subtreeKidsKP := tree.trees (tree.kids (subtreeKidsKP + 1)).kidsKP
                        exit when tree.trees (tree.kids (subtreeKidsKP + 1)).kind = kindT.empty
                        printLeavesTraversal (commaTP, outstream)
                    end loop
                end if

            label kindT.empty :
                bind name to tree.trees (subtreeTP).name

                if name not= empty_T and name not= ATTR_T then
                    % might be a paragraphing symbol!
                    if name = NL_T then
                        if (not emptyLine) or (not blankLine) then
                            
                            if outstream >= 0 then
                                put : outstream, type (string, outputline)
                            else
                                put type (string, outputline)
                            end if
                            type (string, outputline) := ""
                            blankLine := emptyLine
                            emptyLine := true
                            lineLength := 0
                        end if
                    elsif name = FL_T then
                        if not emptyLine then
                            if outstream >= 0 then
                                put : outstream, type (string, outputline)
                            else
                                put type (string, outputline)
                            end if
                            type (string, outputline) := ""
                            blankLine := emptyLine
                            emptyLine := true
                            lineLength := 0
                        end if
                    elsif name = IN_T then
                        indent += options.indentIncrement
                    elsif name = EX_T then
                        if indent >= options.indentIncrement then
                            indent -= options.indentIncrement
                        else
                            indent := 0
                        end if
                    elsif name = SP_T then
                        if lineLength < options.outputLineLength then
                            type (string, outputline (lineLength + 1)) := " "
                            lineLength += 1
                        else
                            % this line is full, and will force a new line at the next token anyway
                        end if
                    elsif name = TAB_T then
                        const newLineLength := lineLength + (8 - lineLength mod 8)
                        if newLineLength > options.outputLineLength then
                            % just make it a full line, to force a new line at the next token
                            substr (type (string, outputline (lineLength + 1)), type (string, BLANKS), 1, options.outputLineLength - lineLength)
                            lineLength := options.outputLineLength
                        else
                            substr (type (string, outputline (lineLength + 1)), type (string, BLANKS), 1, 8 - lineLength mod 8)
                            lineLength := newLineLength
                        end if
                    elsif name = SPOFF_T then
                        spacing := false
                    elsif name = SPON_T then
                        spacing := true
                    elsif name = KEEP_T or name = FENCE_T or name = SEE_T or name = NOT_T then
                        % Nothing to do
                    else
                        % custom TAB_, IN_ or EX_ formatting symbol
                        bind subtreeName to string@(ident.idents(name))
                        assert length (subtreeName) >= 4 
                            and (subtreeName (1..4) = "TAB_" or subtreeName (1..3) = "IN_" 
                                or subtreeName (1..3) = "EX_")
                        % get custom value
                        type char4095 : char (4095)
                        const subtreeName1 : char := type (char4095, subtreeName) (1)
                        var numindex := 4
                        if subtreeName1 = 'T' then
                            numindex += 1
                        end if
                        var value := 0
                        for i : numindex .. length (subtreeName)
                            const d : char := subtreeName (i)
                            exit when not charset.digitP (d)
                            value := value * 10 + (ord (d) - ord ('0'))
                        end for
                        if value > maxIndent then
                            value := maxIndent
                        end if
                        % implement action
                        if value not= 0 then
                            if subtreeName1 = 'T' then
                                % custom tabstop
                                if lineLength < value - 1 then
                                    substr (type (string, outputline (lineLength + 1)), type (string, BLANKS), 1, value - lineLength - 1)
                                    lineLength := value - 1
                                elsif options.option (notabnl_p) then
                                    if lineLength = value - 1 then
                                        % Already exactly where we should be
                                    elsif lineLength < options.outputLineLength then
                                        type (string, outputline (lineLength + 1)) := " "
                                        lineLength += 1
                                    else
                                        % this line is full, and will force a new line at the next token anyway
                                    end if
                                else
                                    if not emptyLine then
                                        if outstream >= 0 then
                                            put : outstream, type (string, outputline)
                                        else
                                            put type (string, outputline)
                                        end if
                                        blankLine := false
                                    end if
                                    substr (type (string, outputline), type (string, BLANKS), 1, value - 1)
                                    lineLength := value - 1
                                end if
                                emptyLine := false
                                lastLeafNameEnd := ' '
                            elsif subtreeName1 = 'I' then
                                % custom indent
                                indent += value
                            elsif subtreeName1 = 'E' then
                                % custom exdent
                                if indent > value then
                                    indent -= value
                                else
                                    indent := 0
                                end if
                            end if
                        end if
                    end if
                end if

            label kindT.newline :
                % New line, when in -char mode

                if outstream >= 0 then
                    put : outstream, type (string, outputline)
                else
                    put type (string, outputline)
                end if
                
                type (string, outputline) := ""
                blankLine := emptyLine
                emptyLine := true
                lineLength := 0

            label :
                % it's a leaf - print it out
                bind leafName to string@(ident.idents (tree.trees (subtreeTP).rawname))
                const lengthLeaf := length (leafName)
                type char4095 : char (4095)
                const leafName1 : char := type (char4095, leafName) (1)
                
                if emptyLine then
                    outputindent (indent)
                else
                    if lineLength + 1 + lengthLeaf > options.outputLineLength then
                        % must split the output line here
                        if options.option (raw_p) or options.option (newline_p) then
                            % raw output must have no new lines unless explicitly asked for!
                            
                            if outstream >= 0 then
                                put : outstream, type (string, outputline) ..
                            else
                                put type (string, outputline) ..
                            end if

                            outputindent (0)
                            blankLine := false
                            
                            % since this line is continuing, need usual intra-line spacing - JRC 14.1.05
                            if spacing then
                                if not options.option (raw_p) then
                                    if charset.spaceAfterP (lastLeafNameEnd) 
                                            and (charset.spaceBeforeP (leafName1) or tree.trees (subtreeTP).kind = kindT.number) then
                                        type (string, outputline (lineLength + 1)) := " "
                                        lineLength += 1
                                    end if
                                elsif charset.idP (lastLeafNameEnd) and charset.idP (leafName1) 
                                        and not options.option (charinput_p) then
                                    type (string, outputline (lineLength + 1)) := " "
                                    lineLength += 1
                                end if
                            end if
                            
                        elsif not spacing then
                            % not supposed to break at the moment - must choose an appropriate previous place to break
                            var i := lineLength
                            loop
                                exit when i = 0 or outputline (i) = ' '
                                i -= 1
                            end loop
                            if i < options.outputLineLength div 2 then
                                error ("", "Forced to split [SPOFF] output at line boundary", WARNING, 952)
                                i := lineLength
                            end if
                            
                            % substring in place - don't try this at home, kids!
                            const savedoutputlineip1 := outputline (i + 1)
                            outputline (i + 1) := chr (0)       % EOS

                            if outstream >= 0 then
                                put : outstream, type (string, outputline)
                            else
                                put type (string, outputline)
                            end if
                            
                            outputline (i + 1) := savedoutputlineip1 

                            substr (type (string, savedoutputline), type (string, outputline), i + 1, lineLength)

                            outputindent (indent + tempIndent)
                            blankLine := false
                            
                            type (string, outputline (lineLength + 1)) := type (string, savedoutputline)
                            lineLength := length (type (string, outputline))
                            
                        else
                            if outstream >= 0 then
                                put : outstream, type (string, outputline)
                            else
                                put type (string, outputline)
                            end if
                            outputindent (indent + tempIndent)
                            blankLine := false
                        end if

                    else
                        if spacing then
                            if not options.option (raw_p) then
                                if charset.spaceAfterP (lastLeafNameEnd) 
                                        and (charset.spaceBeforeP (leafName1) or tree.trees (subtreeTP).kind = kindT.number) then
                                    type (string, outputline (lineLength + 1)) := " "
                                    lineLength += 1
                                end if
                            elsif charset.idP (lastLeafNameEnd) and charset.idP (leafName1) 
                                    and not options.option (charinput_p) then
                                type (string, outputline (lineLength + 1)) := " "
                                lineLength += 1
                            end if
                        end if
                    end if
                end if

                if lengthLeaf > options.outputLineLength then
                    if (not options.option (raw_p)) and (not options.option (quiet_p)) then
                        error ("", "Output token too long for output width", WARNING, 953)
                    end if
                    if outstream >= 0 then
                        put : outstream, leafName
                    else
                        put leafName
                    end if
                    blankLine := false
                    outputindent (indent)
                else
                    if lineLength + lengthLeaf > options.outputLineLength then
                        % Since we already handled line overflow above, this can only mean
                        % that the indent plus the leaf is too long
                        assert lengthLeaf <= options.outputLineLength
                        outputindent (options.outputLineLength - lengthLeaf)
                    end if
                    type (string, outputline (lineLength + 1)) := leafName 
                    lineLength += lengthLeaf
                    emptyLine := false
                    if lineLength > 0 then 
                        lastLeafNameEnd := outputline (lineLength) 
                    else
                        % an empty leaf on an empty line!
                        lastLeafNameEnd := '\0' 
                    end if
                    % If the leaf ends in a newline, we may as well output it now
                    if lastLeafNameEnd = '\r' or lastLeafNameEnd = '\n' then
                        if outstream >= 0 then
                            put : outstream, type (string, outputline) ..
                        else
                            put  type (string, outputline) ..
                        end if
                        blankLine := false
                        outputindent (indent)
                    end if
                end if
        end case

        assert lineLength = length (type (string, outputline)) and lineLength <= options.outputLineLength

    end printLeavesTraversal


    procedure printMatchTraversal (subtreeTP : treePT, matchtreeTP : treePT, outstream : int)

        if subtreeTP = matchtreeTP then

            if lineLength + 6 > options.outputLineLength then
                if outstream >= 0 then
                    put : outstream, type (string, outputline)
                else
                    put type (string, outputline)
                end if
                blankLine := false
                outputindent (indent + tempIndent)
            end if
            
            if charset.spaceAfterP (lastLeafNameEnd) and not blankLine then
                type (string, outputline (lineLength + 1)) := " "
                lineLength += 1
                lastLeafNameEnd := ' '
            end if
            
            type (string, outputline (lineLength + 1)) := "|>>>|"
            emptyLine := false
            lineLength += 5
            
            printLeavesTraversal (subtreeTP, outstream)
            
            if lineLength + 5 > options.outputLineLength then
                if outstream >= 0 then
                    put : outstream, type (string, outputline)
                else
                    put type (string, outputline)
                end if
                blankLine := false
                outputindent (indent + tempIndent)
            end if
            
            type (string, outputline (lineLength + 1)) := "|<<<|"
            lineLength += 5
            emptyLine := false
            
        else

            case tree.trees (subtreeTP).kind of

                label kindT.choose :
                    printMatchTraversal (tree.kids (tree.trees (subtreeTP).kidsKP), matchtreeTP, outstream)

                label kindT.order :
                    % print out the kids
                    var register subtreeKidsKP := tree.trees (subtreeTP).kidsKP
                    for : 1 .. tree.trees (subtreeTP).count 
                        exit when tree.trees (tree.kids (subtreeKidsKP)).name = ATTR_T and not options.option (attr_p)
                        printMatchTraversal (tree.kids (subtreeKidsKP), matchtreeTP, outstream)
                        subtreeKidsKP += 1
                    end for

                label kindT.repeat :
                    var register subtreeKidsKP := tree.trees (subtreeTP).kidsKP
                    assert subtreeKidsKP not= nilKid
                    loop
                        printMatchTraversal (tree.kids (subtreeKidsKP), matchtreeTP, outstream)
                        exit when tree.trees (tree.kids (subtreeKidsKP + 1)).kind = kindT.empty
                        subtreeKidsKP := tree.trees (tree.kids (subtreeKidsKP + 1)).kidsKP
                    end loop

                label kindT.list :
                    var register subtreeKidsKP := tree.trees (subtreeTP).kidsKP
                    assert subtreeKidsKP not= nilKid
                    if tree.trees (tree.kids (subtreeKidsKP + 1)).kind not= kindT.empty then
                        loop
                            printMatchTraversal (tree.kids (subtreeKidsKP), matchtreeTP, outstream)
                            subtreeKidsKP := tree.trees (tree.kids (subtreeKidsKP + 1)).kidsKP
                            exit when tree.trees (tree.kids (subtreeKidsKP + 1)).kind = kindT.empty
                            printMatchTraversal (commaTP, matchtreeTP, outstream)
                        end loop
                    end if

                label kindT.empty :
                    bind name to tree.trees (subtreeTP).name

                    if name not= empty_T and name not= ATTR_T then
                        % might be a paragraphing symbol!
                        if name = NL_T then
                            if (not emptyLine) or (not blankLine) then
                                if outstream >= 0 then
                                    put : outstream, type (string, outputline)
                                else
                                    put type (string, outputline)
                                end if
                                type (string, outputline) := ""
                                blankLine := emptyLine
                                emptyLine := true
                                lineLength := 0
                            end if
                        elsif name = FL_T then
                            if not emptyLine then
                                if outstream >= 0 then
                                    put : outstream, type (string, outputline)
                                else
                                    put type (string, outputline)
                                end if
                                type (string, outputline) := ""
                                blankLine := emptyLine
                                emptyLine := true
                                lineLength := 0
                            end if
                        elsif name = IN_T then
                            indent += options.indentIncrement
                        elsif name = EX_T then
                            if indent >= options.indentIncrement then
                                indent -= options.indentIncrement
                            else
                                indent := 0
                            end if
                        elsif name = SP_T then
                            if lineLength < options.outputLineLength then
                                type (string, outputline (lineLength + 1)) := " "
                                lineLength += 1
                            else
                                % this line is full, and will force a new line at the next token anyway
                            end if
                        elsif name = TAB_T then
                            lineLength += 8 - lineLength mod 8
                            if lineLength > options.outputLineLength then
                                % just make it a full line, to force a new line at the next token
                                type (string, outputline (options.outputLineLength + 1)) := ""
                                lineLength := options.outputLineLength
                            else
                                substr (type (string, outputline (lineLength + 1)), type (string, BLANKS), 1, 8 - lineLength mod 8)
                            end if
                        elsif name = SPOFF_T then
                            spacing := false
                        elsif name = SPON_T then
                            spacing := true
                        elsif name = KEEP_T or name = FENCE_T or name = SEE_T or name = NOT_T then
                            % Nothing to do
                        else
                            % custom TAB_, IN_ or EX_ formatting symbol
                            bind subtreeName to string@(ident.idents(name))
                            assert length (subtreeName) >= 4 
                                and (subtreeName (1..4) = "TAB_" or subtreeName (1..3) = "IN_" 
                                    or subtreeName (1..3) = "EX_")
                            % get custom value
                            type char4095 : char (4095)
                            const subtreeName1 : char := type (char4095, subtreeName) (1)
                            var numindex := 4
                            if subtreeName1 = 'T' then
                                numindex += 1
                            end if
                            var value := 0
                            for i : numindex .. length (subtreeName)
                                const d : char := subtreeName (i)
                                exit when not charset.digitP (d)
                                value := value * 10 + (ord (d) - ord ('0'))
                            end for
                            if value > maxIndent then
                                value := maxIndent
                            end if
                            % implement action
                            if value not= 0 then
                                if subtreeName1 = 'T' then
                                    % custom tabstop
                                    if lineLength < value - 1 then
                                        substr (type (string, outputline (lineLength + 1)), type (string, BLANKS), 1, value - lineLength - 1)
                                        lineLength := value - 1
                                    elsif options.option (notabnl_p) then
                                        if lineLength = value - 1 then
                                            % Already exactly where we should be
                                        elsif lineLength < options.outputLineLength then
                                            type (string, outputline (lineLength + 1)) := " "
                                            lineLength += 1
                                        else
                                            % this line is full, and will force a new line at the next token anyway
                                        end if
                                    else
                                        if not emptyLine then
                                            if outstream >= 0 then
                                                put : outstream, type (string, outputline)
                                            else
                                                put type (string, outputline)
                                            end if
                                            blankLine := false
                                        end if
                                        substr (type (string, outputline), type (string, BLANKS), 1, value - 1)
                                        lineLength := value - 1
                                    end if
                                    emptyLine := false
                                    lastLeafNameEnd := ' '
                                elsif subtreeName1 = 'I' then
                                    % custom indent
                                    indent += value
                                elsif subtreeName1 = 'E' then
                                    % custom exdent
                                    if indent > value then
                                        indent -= value
                                    else
                                        indent := 0
                                    end if
                                end if
                            end if
                        end if
                    end if

                label kindT.newline :
                    % New line, when in -char mode
                    if outstream >= 0 then
                        put : outstream, type (string, outputline)
                    else
                        put type (string, outputline)
                    end if
                    
                    type (string, outputline) := ""
                    blankLine := emptyLine
                    emptyLine := true
                    lineLength := 0

                label :
                    % it's a leaf - print it out
                    bind leafName to string@(ident.idents (tree.trees (subtreeTP).rawname))
                    const lengthLeaf := length (leafName)
                    type char4095 : char (4095)
                    const leafName1 : char := type (char4095, leafName) (1)

                    if emptyLine then
                        outputindent (indent)

                    else
                        if lineLength + 1 + lengthLeaf > options.outputLineLength then
                            % must split the output line here
                            if options.option (raw_p) or options.option (newline_p) then
                                % raw output must have no new lines unless explicitly asked for!
                                if outstream >= 0 then
                                    put : outstream, type (string, outputline) ..
                                else
                                    put type (string, outputline) ..
                                end if
                                
                                outputindent (0)
                                blankLine := false
                                
                                % since this line is continuing, need usual intra-line spacing - JRC 14.1.05
                                if spacing then
                                    if not options.option (raw_p) then
                                        if charset.spaceAfterP (lastLeafNameEnd) 
                                                and (charset.spaceBeforeP (leafName1) or tree.trees (subtreeTP).kind = kindT.number) then
                                            type (string, outputline (lineLength + 1)) := " "
                                            lineLength += 1
                                        end if
                                    elsif charset.idP (lastLeafNameEnd) and charset.idP (leafName1) 
                                            and not options.option (charinput_p) then
                                        type (string, outputline (lineLength + 1)) := " "
                                        lineLength += 1
                                    end if
                                end if
                                
                            elsif not spacing then
                                % not supposed to break at the moment - must choose an appropriate previous place to break
                                var i := lineLength
                                loop
                                    exit when i = 0 or outputline (i) = ' '
                                    i -= 1
                                end loop
                                if i < options.outputLineLength div 2 then
                                    error ("", "Forced to split [SPOFF] output at line boundary", WARNING, 952)
                                    i := lineLength
                                end if
                                
                                % substring in place - don't try this at home, kids!
                                const savedoutputlineip1 := outputline (i + 1)
                                outputline (i + 1) := chr (0)   % EOS
                                
                                if outstream >= 0 then
                                    put : outstream, type (string, outputline)
                                else
                                    put type (string, outputline)
                                end if

                                outputline (i + 1) := savedoutputlineip1 
                                
                                substr (type (string, savedoutputline), type (string, outputline), i + 1, lineLength)
                                
                                outputindent (indent + tempIndent)
                                blankLine := false
                                
                                type (string, outputline (lineLength + 1)) := type (string, savedoutputline)
                                lineLength := length (type (string, outputline))
                                                        
                            else
                                if outstream >= 0 then
                                    put : outstream, type (string, outputline)
                                else
                                    put type (string, outputline)
                                end if
                                outputindent (indent + tempIndent)
                                blankLine := false
                            end if

                        else
                            if spacing then
                                if not options.option (raw_p) then
                                    if charset.spaceAfterP (lastLeafNameEnd) 
                                            and (charset.spaceBeforeP (leafName1) or tree.trees (subtreeTP).kind = kindT.number) then
                                        type (string, outputline (lineLength + 1)) := " "
                                        lineLength += 1
                                    end if
                                elsif charset.idP (lastLeafNameEnd) and charset.idP (leafName1) 
                                        and not options.option (charinput_p) then
                                    type (string, outputline (lineLength + 1)) := " "
                                    lineLength += 1
                                end if
                            end if
                        end if
                    end if

                    if lengthLeaf > options.outputLineLength then
                        if (not options.option (raw_p)) and (not options.option (quiet_p)) then
                            error ("", "Output token too long for output width", WARNING, 953)
                        end if
                        if outstream >= 0 then
                            put : outstream, leafName
                        else
                            put leafName
                        end if
                        blankLine := false
                        outputindent (indent)
                    else
                        if lineLength + lengthLeaf > options.outputLineLength then
                            % Since we already handled line overflow above, this can only mean
                            % that the indent plus the leaf is too long
                            assert lengthLeaf <= options.outputLineLength
                            outputindent (options.outputLineLength - lengthLeaf)
                        end if
                        type (string, outputline (lineLength + 1)) := leafName 
                        lineLength += lengthLeaf
                        emptyLine := false
                        lastLeafNameEnd := outputline (lineLength)
                    end if
            end case
        end if

    end printMatchTraversal


    procedure printLeaves (subtreeTP : treePT, outstream : int, nl : boolean)
        handler (code)
            if code = stackLimitReached then
                error ("", "Output recursion limit exceeded (probable cause: small size or stack limit)", LIMIT_FATAL, 959)
            end if
            quit > : code
        end handler

        indent := 0
        type (string, outputline) := ""
        lineLength := 0
        emptyLine := true
        blankLine := true
        spacing := true
        lastLeafNameEnd := ' '

        if options.outputLineLength > maxLineLength then
            options.setOutputLineLength (maxLineLength)
        end if
            
        maxIndent := min (1024, options.outputLineLength div 2)
        
        printLeavesTraversal (subtreeTP, outstream)

        if outstream >= 0 then
            if not emptyLine then
                put : outstream, type (string, outputline) ..
                if nl then
                    put : outstream, ""
                end if
            end if
        else
            if not emptyLine then
                put type (string, outputline) ..
                if nl then
                    put ""
                end if
            end if
        end if
    end printLeaves 


    procedure printMatch (subtreeTP : treePT, matchTreeTP : treePT, outstream : int, nl : boolean)
        indent := 0
        type (string, outputline) := ""
        lineLength := 0
        emptyLine := true
        blankLine := true
        spacing := true
        lastLeafNameEnd := ' '

        if options.outputLineLength > maxLineLength then
            options.setOutputLineLength (maxLineLength)
        end if
            
        maxIndent := min (1024, options.outputLineLength div 2)
            
        printMatchTraversal (subtreeTP, matchTreeTP, outstream)

        if outstream >= 0 then
            if not emptyLine then
                put : outstream, type (string, outputline) ..
                if nl then
                    put : outstream, ""
                end if
            end if
        else
            if not emptyLine then
                put type (string, outputline) ..
                if nl then
                    put ""
                end if
            end if
        end if
    end printMatch 


    % Function to implement the [quote] and [unparse] predefined externals

    var quotedText : char (maxLineLength + maxTuringStringLength + 1)   % for string type cheats
    var lengthQT := 0

    procedure quoteLeavesTraversal (subtreeTP : treePT)

        % Stack use limitation - to avoid crashes
        var dummy : int
        if stackBase - addr (dummy) > maxStackUse then 
            quit : stackLimitReached
        end if

        case tree.trees (subtreeTP).kind of
            label kindT.choose :
                % optimize by skipping choose chains -- JRC 4.1.94
                var register chainTP := tree.kids (tree.trees (subtreeTP).kidsKP)
                loop
                    exit when tree.trees (chainTP).kind not= kindT.choose 
                    chainTP := tree.kids (tree.trees (chainTP).kidsKP)
                end loop
                quoteLeavesTraversal (chainTP)

            label kindT.order :
                % quote the kids
                var register subtreeKidsKP := tree.trees (subtreeTP).kidsKP
                for : 1 .. tree.trees (subtreeTP).count 
                    exit when tree.trees (tree.kids (subtreeKidsKP)).name = ATTR_T and not options.option (attr_p)
                    quoteLeavesTraversal (tree.kids (subtreeKidsKP))
                    exit when lengthQT = maxLineLength
                    subtreeKidsKP += 1
                end for

            label kindT.repeat :
                var register subtreeKidsKP := tree.trees (subtreeTP).kidsKP
                assert subtreeKidsKP not= nilKid
                loop
                    quoteLeavesTraversal (tree.kids (subtreeKidsKP))
                    exit when tree.trees (tree.kids (subtreeKidsKP + 1)).kind = kindT.empty
                    subtreeKidsKP := tree.trees (tree.kids (subtreeKidsKP + 1)).kidsKP
                end loop

            label kindT.list :
                var register subtreeKidsKP := tree.trees (subtreeTP).kidsKP
                assert subtreeKidsKP not= nilKid
                if tree.trees (tree.kids (subtreeKidsKP + 1)).kind not= kindT.empty then
                    loop
                        quoteLeavesTraversal (tree.kids (subtreeKidsKP))
                        subtreeKidsKP := tree.trees (tree.kids (subtreeKidsKP + 1)).kidsKP
                        exit when tree.trees (tree.kids (subtreeKidsKP + 1)).kind = kindT.empty
                        quoteLeavesTraversal (commaTP)
                    end loop
                end if

            label kindT.empty :
                if tree.trees (subtreeTP).name = SP_T then
                    assert lengthQT < maxLineLength
                    type (string, quotedText (lengthQT + 1)) := " "
                    lengthQT += 1
                elsif tree.trees (subtreeTP).name = SPOFF_T then
                    spacing := false
                elsif tree.trees (subtreeTP).name = SPON_T then
                    spacing := true
                end if

            label :
                % it's a leaf - print it out
                bind leafName to string@(ident.idents (tree.trees (subtreeTP).rawname))
                const lengthLeaf := length (leafName)
                type char4095 : char (4095)
                const leafName1 : char := type (char4095, leafName) (1)

                if spacing and not emptyLine then
                    if not options.option (raw_p) then
                        if charset.spaceAfterP (lastLeafNameEnd) 
                                and (charset.spaceBeforeP (leafName1) or tree.trees (subtreeTP).kind = kindT.number) then
                            if lengthQT < maxLineLength then
                                type (string, quotedText (lengthQT + 1)) := " "
                                lengthQT += 1
                            end if
                        end if
                    elsif charset.idP (lastLeafNameEnd) and charset.idP (leafName1) and not options.option (charinput_p) then
                        if lengthQT < maxLineLength then
                            type (string, quotedText (lengthQT + 1)) := " "
                            lengthQT += 1
                        end if
                    end if
                end if

                if lengthQT + lengthLeaf > maxLineLength then
                    error ("", "Result of [quote] predefined function exceeds maximum line length (1048575 characters)", LIMIT_FATAL, 960)
                else
                    type (string, quotedText (lengthQT + 1)) := leafName
                    lengthQT += lengthLeaf
                end if

                lastLeafNameEnd := quotedText (lengthQT)
                emptyLine := false
        end case

    end quoteLeavesTraversal


    procedure quoteLeaves (subtreeTP : treePT, var resultText : string)
        emptyLine := true
        spacing := true
        lastLeafNameEnd := ' '
        type (string, quotedText) := ""
        lengthQT := 0
        quoteLeavesTraversal (subtreeTP)
        resultText := type (string, quotedText)
    end quoteLeaves 


    % Procedure to extract the leaves from a tree to implement the [reparse] predefined external

    procedure extractLeavesTraversal (subtreeTP : treePT)

        % Stack use limitation - to avoid crashes
        var dummy : int
        if stackBase - addr (dummy) > maxStackUse then 
            quit : stackLimitReached
        end if

        case tree.trees (subtreeTP).kind of

            label kindT.choose :
                % optimize by skipping choose chains -- JRC 4.1.94
                var register chainTP := tree.kids (tree.trees (subtreeTP).kidsKP)
                loop
                    exit when tree.trees (chainTP).kind not= kindT.choose 
                    chainTP := tree.kids (tree.trees (chainTP).kidsKP)
                end loop
                extractLeavesTraversal (chainTP)

            label kindT.order :
                % reparse the kids
                var register subtreeKidsKP := tree.trees (subtreeTP).kidsKP
                for : 1 .. tree.trees (subtreeTP).count 
                    exit when tree.trees (tree.kids (subtreeKidsKP)).name = ATTR_T and not options.option (attr_p)
                    extractLeavesTraversal (tree.kids (subtreeKidsKP))
                    subtreeKidsKP += 1
                end for

            label kindT.repeat :
                var register subtreeKidsKP := tree.trees (subtreeTP).kidsKP
                assert subtreeKidsKP not= nilKid
                loop
                    extractLeavesTraversal (tree.kids (subtreeKidsKP))
                    exit when tree.trees (tree.kids (subtreeKidsKP + 1)).kind = kindT.empty
                    subtreeKidsKP := tree.trees (tree.kids (subtreeKidsKP + 1)).kidsKP
                end loop

            label kindT.list :
                var register subtreeKidsKP := tree.trees (subtreeTP).kidsKP
                assert subtreeKidsKP not= nilKid
                if tree.trees (tree.kids (subtreeKidsKP + 1)).kind not= kindT.empty then
                    loop
                        extractLeavesTraversal (tree.kids (subtreeKidsKP))
                        subtreeKidsKP := tree.trees (tree.kids (subtreeKidsKP + 1)).kidsKP
                        exit when tree.trees (tree.kids (subtreeKidsKP + 1)).kind = kindT.empty
                        extractLeavesTraversal (commaTP)
                    end loop
                end if

            label kindT.empty :
                % do nothing

            label kindT.id, kindT.upperlowerid, kindT.upperid,
                    kindT.lowerupperid, kindT.lowerid :
                % typed id's become untyped on reparse 
                lastTokenIndex += 1
                bind var inputToken to inputTokens (lastTokenIndex)
                inputToken.token := tree.trees (subtreeTP).name
                inputToken.rawtoken := tree.trees (subtreeTP).rawname
                inputToken.kind := kindT.id

            label kindT.number, kindT.floatnumber, kindT.decimalnumber, kindT.integernumber :
                % typed numbers become untyped on reparse 
                lastTokenIndex += 1
                bind var inputToken to inputTokens (lastTokenIndex)
                inputToken.token := tree.trees (subtreeTP).name
                inputToken.rawtoken := tree.trees (subtreeTP).rawname
                inputToken.kind := kindT.number
                    
            label kindT.literal :
                % literals revert to their scan type on reparse -JRC 2.6d6
                lastTokenIndex += 1
                bind var inputToken to inputTokens (lastTokenIndex)
                inputToken.token := tree.trees (subtreeTP).name
                inputToken.rawtoken := tree.trees (subtreeTP).rawname
                inputToken.kind := ident.identKind (tree.trees (subtreeTP).name)
                
                % correct for residual TXL keyword bug - in the long run, 
                % perhaps this can be fixed by un-keying TXL keywords in the ident table - JRC 10.5e
                if inputTokens (lastTokenIndex).kind = kindT.key and not scanner.keyP (tree.trees (subtreeTP).name) then
                    inputTokens (lastTokenIndex).kind := kindT.id
                end if
                    
            label :
                % it's some other kind of leaf - add it to the tokens array 
                lastTokenIndex += 1
                bind var inputToken to inputTokens (lastTokenIndex)
                inputToken.token := tree.trees (subtreeTP).name
                inputToken.rawtoken := tree.trees (subtreeTP).rawname
                inputToken.kind := tree.trees (subtreeTP).kind
        end case

    end extractLeavesTraversal


    procedure extractLeaves (subtreeTP : treePT) 
        lastTokenIndex := 0

        extractLeavesTraversal (subtreeTP)

        lastTokenIndex += 1
        inputTokens (lastTokenIndex).token := empty_T  
        inputTokens (lastTokenIndex).kind := kindT.empty  

        if options.option (tokens_p) then
            put skip, "[reparse] tokens:"
            for i : 1 .. lastTokenIndex - 1
                put string@(ident.idents (kindType (ord (inputTokens (i).kind)))), " '", string@(ident.idents (inputTokens (i).token)), "'"
            end for
        end if
    end extractLeaves 

end unparser
