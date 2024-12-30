% OpenTxl Version 11
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

% The main TXL process, used to run the stages of a TXL program -
% bootstrap of the TXL language grammar to a grammar tree, scan and parse of the TXL program source,
% compile of the input language grammar to a grammar tree, compile of the user rules to a rule table,
% scan and parse of the input source, application of the transformation rules.

% Modification Log

% v11.0 Initial revision, revised from FreeTXL 10.8b (c) 1988-2022 Queen's University at Kingston
%       Reprogrammed and remodularized to improve maintainability

% v11.1 Added anonymous conditions, e.g., where _ [test]
%       Added optional match/replace rules, implicit match [any]
%       Added new predefined function [faccess FILE MODE] 
%       Added NBSP (ASCII 160) as space character and separator
%       Fixed local variable binding bug issue #1

% v11.2 Corrected Unicode conflict with Latin-1 character set
%       Added shallow extract [^/]
%       Changed default message level to quiet
%       Changed stack limit message to when verbose only

% v11.3 Fixed bug in output of zero-length tokens
%       Added multiple skipping criteria
%       Fixed lookahead source line number bug
%       Fixed multiple nl-comments source line number bug
%       Fixed compatibility of [srclinenumber] with [number]
%       Updated default size to 128
%       Fixed minor memory leaks
%       Fixed serious bug in skipping rules
%       Fixed problems with single user installation
%       Fixed handling of escape chars in predefined functions
%       Added nolimit parse time option -t
%       Add scripts, makefiles and build support for Windows command line

% Global symbols granted to child modules
include "globals.i"

% TXL version
const * version := "OpenTxl v11.3.6 (20.12.24) (c) 2024 James R. Cordy and others"

% Phase
const * INITIALIZE := 0
const * COMPILE := 1
const * TRANSFORM := 2
var phase := INITIALIZE

% Localization, character set, options and limits
include "locale.i"
include "charset.i"
include "errors.i"
include "options.i"
include "limits.i"      % requires options, for txlSize

% Global tables and operations
include "tokens.i"
include "trees.i"
include "ident.i"
include "shared.i"
include "treeops.i"
include "txltree.i"
include "errormsg.i"
include "symbols.i"
include "rules.i"

% Phases of the TXL processor
#if not NOCOMPILE then
    include "boot.i"
#end if

include "scan.i"
include "unparse.i"     % requires scanner, for keyP

child "parse.ch"

#if not NOCOMPILE then
    child "compdef.ch"
    child "comprul.ch"
#end if

child "xform.ch"

% User grammar tree
var inputGrammarTreeTP : treePT

#if not NOLOADSTORE then
    child "loadstor.ch"
#end if


% Main TXL Processor

if not options.option (quiet_p) then
    put : 0, version
end if

% Keep track of tree space use by each phase
var oldTreeCount, oldKidCount := 0

% Phase 1: Compile the TXL program

phase := COMPILE

#if not NOLOADSTORE then
if options.option (load_p) then
    % Already previously compiled - simply load the compiled file
    if not options.option (quiet_p) then
        put : 0, "Loading ", options.txlCompiledFileName, " ... "
    end if

    LoadStore.Restore (options.txlCompiledFileName)

    if options.option (verbose_p) then
        put : 0, "  ... used ", tree.treeCount, " trees and ", tree.kidCount, " kids."
    end if

else
#end if

    #if not NOCOMPILE then

        % Step 1. Make the TXL language grammar tree
        var txlGrammarTreeTP : treePT

        bootstrap.makeGrammarTree (txlGrammarTreeTP)

        if options.option (verbose_p) then
            put : 0, "Bootstrapping TXL ... "
            put : 0, "  ... used ", tree.treeCount, " trees and ", tree.kidCount, " kids."
        end if

        oldTreeCount := tree.treeCount
        oldKidCount := tree.kidCount


        % Step 2. Parse the input language TXL program using the TXL grammar tree
        var txlSourceParseTreeTP := nilTree

        if options.option (verbose_p) then
            put : 0, "Scanning the TXL program ", options.txlSourceFileName
        elsif not options.option (quiet_p) then
            put : 0, "Compiling ", options.txlSourceFileName, " ... "
        end if

        scanner.tokenize (options.txlSourceFileName, true, true)

        if options.option (verbose_p) then
            put : 0, "Parsing the TXL program"
        end if

        const save_tree_print_p := options.option (tree_print_p)
        options.setOption (tree_print_p, false)

        parser.initializeParse ("", false, false, true, 0, type (parser.parseVarOrExpProc, 0))
        parser.parse (txlGrammarTreeTP, txlSourceParseTreeTP)

        options.setOption (tree_print_p, save_tree_print_p)

        if txlSourceParseTreeTP = nilTree then
            % unsuccessful parse
            syntaxError (failTokenIndex)
        end if

        if options.option (boot_parse_p) then
            put : 0, skip, "----- TXL Program Parse Tree -----"
            unparser.printParse (txlSourceParseTreeTP, stderr, 0)
            put : 0, "----- End TXL Program Parse Tree -----", skip
        end if

        if options.option (verbose_p) then
            put : 0, "  ... used ", tree.treeCount - oldTreeCount, " trees and ",
                tree.kidCount - oldKidCount, " kids."
        end if

        oldTreeCount := tree.treeCount
        oldKidCount := tree.kidCount


        % Mark beginning of user program tree space for load/store facilty
        tree.beginUserTreeSpace


        % Step 3. Make the input language grammar tree

        % We save the symbol table from the input language grammar, which contains all the 
        % definitions of the nonterminals (defined by the TXL program) of the input language.
        % These are not needed right away: when the input language source is parsed, 
        % only the top level pattern is needed.  

        % Later (in phase two) when the rules are being compiled into a rule table, 
        % the patterns and replacements are converted from strings of tokens to "parse" trees
        % including variables and expressions as appropriate.

        if options.option (verbose_p) then
            put : 0, "Making the input language grammar tree"
        end if

        defineCompiler.makeGrammarTree (txlSourceParseTreeTP, inputGrammarTreeTP)

        if options.option (verbose_p) then
            put : 0, "  ... used ", tree.treeCount - oldTreeCount, " trees and ",
                tree.kidCount - oldKidCount, " kids."
        end if

        if options.option (grammar_print_p) then
            put : 0, skip, "----- Grammar Tree -----"
            unparser.printGrammar (inputGrammarTreeTP, 0)
            put : 0, "----- End Grammar Tree -----", skip
        end if

        oldTreeCount := tree.treeCount
        oldKidCount := tree.kidCount


        % Step 4. Make the rule table from the rules in the TXL program
        if options.option (verbose_p) then
            put : 0, "Making the rule table"
        end if

        ruleCompiler.makeRuleTable (txlSourceParseTreeTP)

        if options.option (verbose_p) then
            put : 0, "  ... used ", tree.treeCount - oldTreeCount, " trees and ",
                tree.kidCount - oldKidCount, " kids."
        end if
    #end if

#if not NOLOADSTORE then
end if
#end if


#if not NOLOADSTORE then
if options.option (compile_p) then

    #if not NOCOMPILE then
        % Store the compiled result
        if not options.option (quiet_p) then
            put : 0, "Storing ", options.txlCompiledFileName, " ... "
        end if

        LoadStore.Save (options.txlCompiledFileName)

        if options.option (verbose_p) then
            put : 0, "  ... a total of ", tree.treeCount, " trees and ", tree.kidCount, " kids."
        end if

        if not options.option (quiet_p) then
            put : 0, "Done."
        end if
    #end if

else
#end if
    
    % Phase 2: Run the compiled TXL program
    
    phase := TRANSFORM

    oldTreeCount := tree.treeCount
    oldKidCount := tree.kidCount


    % Step 5. Parse the input language source using the input language grammar tree
    var inputParseTreeTP := nilTree

    if options.option (verbose_p) then
        put : 0, "Scanning the input file ", options.inputSourceFileName
    elsif not options.option (quiet_p) then
        put : 0, "Parsing ", options.inputSourceFileName, " ..."
    end if

    scanner.tokenize (options.inputSourceFileName, true, false)
    const inputLastTokenIndex := lastTokenIndex

    if options.option (verbose_p) then
        put : 0, "Parsing the input file"
    end if

    parser.initializeParse ("input file '" + options.inputSourceFileName + "'", 
        true, false, false, 0, type (parser.parseVarOrExpProc, 0))
    parser.parse (inputGrammarTreeTP, inputParseTreeTP)

    if inputParseTreeTP = nilTree then
        % unsuccessful parse
        syntaxError (failTokenIndex)
    end if

    if options.option (parse_print_p) then
        put : 0, skip, "----- Input Parse Tree -----"
        unparser.printParse (inputParseTreeTP, stderr, 0)
        put : 0, "----- End Input Parse Tree -----", skip
    end if

    if options.option (verbose_p) then
        put : 0, "  ... used ", tree.treeCount - oldTreeCount, " trees and ",
            tree.kidCount - oldKidCount, " kids."
    end if

    oldTreeCount := tree.treeCount
    oldKidCount := tree.kidCount
    

    % Step 6. Apply the rules to transform the parsed input source

    var transformedInputParseTreeTP : treePT

    if options.option (verbose_p) then
        put : 0, "Applying the transformation rules"
    elsif not options.option (quiet_p) then
        put : 0, "Transforming ..."
    end if

    transformer.applyMainRule (inputParseTreeTP, transformedInputParseTreeTP)

    if options.option (result_tree_print_p) then
        put : 0, skip, "----- Output Parse Tree -----"
        unparser.printParse (transformedInputParseTreeTP, stderr, 0)
        put : 0, "----- End Output Parse Tree -----", skip
    end if

    if options.option (verbose_p) then
        put : 0, "  ... used ", tree.treeCount - oldTreeCount, " trees and ",
            tree.kidCount - oldKidCount, " kids."
    end if

    oldTreeCount := tree.treeCount
    oldKidCount := tree.kidCount


    % Step 7. Generate the transformed input language source
    if options.option (verbose_p) then
        put : 0, "Generating transformed output"
    end if

    if options.outputSourceFileName not= "" then
        var outputStream := 0
        open : outputStream, options.outputSourceFileName, put
        if outputStream = 0 then
            error ("", "Unable to open output file '" + options.outputSourceFileName + "'", FATAL, 991)
        end if
        if options.option (xmlout_p) then
            unparser.printParse (transformedInputParseTreeTP, outputStream, 0)
        else
            unparser.printLeaves (transformedInputParseTreeTP, outputStream, true)
        end if
        close : outputStream
    else
        if options.option (xmlout_p) then
            unparser.printParse (transformedInputParseTreeTP, stdout, 0)
        else
            unparser.printLeaves (transformedInputParseTreeTP, stdout, true)
        end if
    end if

    % Optionally output statistics 

    if options.option (verbose_p) then
        put : 0, "Used a total of ", tree.treeCount, " trees (",
            (tree.treeCount * 100) div maxTrees, "%) and ", tree.kidCount, " kids (",
            (tree.kidCount * 100) div maxKids, "%)."
    end if

    if options.option (usage_p) then
        put : 0, skip, "===== TXL Resource Usage Summary ====="
        put : 0, "Defines             ", symbol.nSymbols, "/", maxSymbols
        put : 0, "Rules/functions     ", rule.nRules, "/", maxRules
        put : 0, "Keywords            ", scanner.nKeys, "/", maxKeys
        put : 0, "Compound tokens     ", scanner.nCompounds, "/", maxCompoundTokens
        put : 0, "Comment tokens      ", scanner.nComments, "/", maxCommentTokens
        put : 0, "Token patterns      ", scanner.nPatterns, "/", maxTokenPatterns
        put : 0, "Ident/string tokens ", ident.nIdents, "/", maxIdents
        put : 0, "Ident/string chars  ", ident.nIdentChars, "/", maxIdentChars
        put : 0, "Input size (tokens) ", inputLastTokenIndex, "/", maxTokens
        put : 0, "Input files         ", nFiles, "/", maxFiles
        put : 0, "Trees               ", tree.treeCount, "/", maxTrees
        put : 0, "Kids                ", tree.kidCount, "/", maxKids
        put : 0, "=== ==="
        put : 0, ""
    end if

    % Detailed stats for use in tuning the TXL processor's memory footprint

    #if SPACETUNING then
        type dummyaddrint : addressint
        type dummyint : int
        const szTrees := upper (trees) * size (parseTreeT)
        const szKids := upper (kids) * size (consKidT)
        const szIdents := upper (ident.identTable) * size (dummyaddrint)
        const szIdtext := upper (ident.identText) 
        const szIdtrees := upper (ident.identTree) * size (treePT)
        const szTokens := upper (inputTokens) * size (tokenT)
        const szTokenkind := upper (inputTokenKind) * size (kindT)
        const szTokenline := upper (inputTokenLineNum) * size (dummyint)
        const szTokentree := upper (inputTokenTP) * size (treePT)
        const szSymbols := upper (symbol.symbolTable) * size (treePT)
        const szRules := upper (rules) * size (ruleT)
        const szStack := maxStackUse

        put : 0, skip, "=== TXL Memory Usage Summary ==="
        put : 0, "Trees      ", szTrees
        put : 0, "Kids       ", szKids
        put : 0, "Idents     ", szIdents
        put : 0, "Idtext     ", szIdtext
        put : 0, "Idtrees    ", szIdtrees
        put : 0, "Tokens     ", szTokens
        put : 0, "Tokenkind  ", szTokenkind
        put : 0, "Tokenline  ", szTokenline
        put : 0, "Tokentree  ", szTokentree
        put : 0, "Symbols    ", szSymbols
        put : 0, "Rules      ", szRules
        put : 0, "Stack      ", szStack
        put : 0, skip, "Total ", szTrees + szKids + szIdents  + szIdtext + szIdtrees 
            + szTokens + szTokenkind + szTokenline + szTokentree + szSymbols 
            + szRules + szStack 
        put : 0, "=== ==="
        put : 0, ""
    #end if
    
    if exitcode not= 0 then
        quit : exitcode
    end if

#if not NOLOADSTORE then
end if
#end if
