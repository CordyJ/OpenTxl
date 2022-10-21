% OpenTxl Version 11 error messages
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

% TXL error message printing routines

% Modification Log

% v11.0	Initial revision, revised from FreeTXL 10.8b (c) 1988-2022 Queen's University at Kingston


body procedure error % (context : string, message : string, severity : int, code : int)

    var kind := "E"
    if severity = WARNING then
    	kind := "W"
    elsif severity = INFORMATION then
    	kind := "I"
    end if
    
    var qualifier := ""
    if severity = INFORMATION then
    	qualifier := "(Information) "
    elsif severity = WARNING then
    	qualifier := "(Warning) "
    elsif severity = LIMIT_WARNING or severity = LIMIT_FATAL then
    	qualifier := "(TXL implementation limit) "
    elsif severity = INTERNAL_FATAL then
    	qualifier := "(TXL internal error) "
    end if
    
    var TXL := "TXL"
    assert code >= 100 and code <= 9999
    if code < 1000 then
    	TXL := "TXL0"
    end if
    
    var comma := ""
    var inputFileName := ""
    if phase = TRANSFORM and options.inputSourceFileName not= "" then
    	comma := ", "
	inputFileName := options.inputSourceFileName
    end if
    
    var space := ""
    if context not= "" then
    	space := " "
    end if
    
    put : 0, "[", inputFileName, comma, options.txlSourceFileName, "] : ", TXL, code, kind, space, context, " - ", qualifier, message
    
    if severity >= FATAL then
	quit 
    end if
end error


% Syntax error handling

procedure printInputTokens (failTokenIndex : int)
    % Find the ten (or fewer) tokens around the failure
    const startTokenIndex := max (1, failTokenIndex - 5)
    const endTokenIndex := min (failTokenIndex + 5, lastTokenIndex - 1)

    % Now show them
    put : 0, "\t" ..

    if startTokenIndex > endTokenIndex then
    	    put : 0, "EOF" ..
    else	    
    	for tokenIndex : startTokenIndex .. endTokenIndex
	    if tokenIndex = failTokenIndex then
		put : 0, ">>> ", string@(ident.idents (inputTokens (tokenIndex).rawtoken)), " <<< " ..
	    else
		put : 0, string@(ident.idents (inputTokens (tokenIndex).rawtoken)), " " ..
	    end if
	end for
    end if

    put : 0, ""
end printInputTokens


procedure syntaxError (failTokenIndex : tokenIndexT)
    % give source coordinates
    if failTokenIndex >= lastTokenIndex then
	error ("at end of " + fileNames (1), "Syntax error at end of:", DEFERRED, 191)
    else
	error ("line " + intstr (inputTokens (failTokenIndex).linenum mod maxLines, 1) + 
	    " of " + fileNames (inputTokens (failTokenIndex).linenum div maxLines), 
	    "Syntax error at or near:", DEFERRED, 192)
    end if

    printInputTokens (failTokenIndex)
    quit 
end syntaxError


function externalType (internalType : string) : string
    if index (internalType, "list_1_") = 1 then
	result "list " + internalType (8..*) + "+"
    elsif index (internalType, "list_0_") = 1 then
	result "list " + internalType (8..*) 
    elsif index (internalType, "repeat_1_") = 1 then
	result "repeat " + internalType (10..*) + "+"
    elsif index (internalType, "repeat_0_") = 1 then
	result "repeat " + internalType (10..*) 
    elsif index (internalType, "opt__") = 1 or index (internalType, "attr__") = 1 then
	var targetType := internalType (6..*)
	var optattr := "opt "
	if internalType (1) = 'a' then
	    optattr := "attr "
	    targetType := targetType (2..*)
	end if
	if index (targetType, "lit__") = 1 then
	    result optattr + "'" + targetType (6..*) 
	else
	    result optattr + targetType
	end if
    elsif index (internalType, "lit__") = 1 then
	result "lit " + "'" + internalType (6..*) 
    elsif index (internalType, "__") = 1 then
    	% __if_statement_2__
	assert length (internalType) > 4 and internalType (*-1 .. *) = "__"
	var targetType := internalType (3 .. *-2)
	var i := length (targetType)
	loop
	    exit when targetType (i) = "_"
	    i -= 1
	end loop
	targetType := targetType (1 .. i-1)
	result targetType
    else
	result internalType
    end if
end externalType


procedure predefinedParseError (failTokenIndex : tokenIndexT, 
	rulename, callername, typename : tokenT, source : string)
    var place := "at or near:"
    if failTokenIndex >= lastTokenIndex then
	place := "at end of:"
    end if

    error ("predefined function [" + string@(ident.idents(rulename)) 
	+ "], called from [" + string@(ident.idents(callername)) +"]",
	"Syntax error parsing " + source 
	+ " as a [" + externalType (string@(ident.idents(typename))) + "], " 
	+ place, DEFERRED, 193)

    printInputTokens (failTokenIndex)
    quit 
end predefinedParseError


#if not NOCOMPILE then

procedure printPatternToken (patternTP : treePT)
    if patternTP = emptyTP then
	% nothing to print

    elsif string@(ident.idents (tree.trees (patternTP).name)) = "TXL_literal_" then
	put : 0, string@(ident.idents (txltree.literal_tokenT (patternTP))) ..

    elsif string@(ident.idents (tree.trees (patternTP).name)) = "TXL_firstTime_" then
	put : 0, string@(ident.idents (txltree.firstTime_nameT (patternTP))) ..
	put : 0, " [", externalType (string@(ident.idents (txltree.firstTime_typeT (patternTP)))), "]" ..

    elsif string@(ident.idents (tree.trees (patternTP).name)) = "TXL_expression_" then
	put : 0, string@(ident.idents (txltree.expression_baseT (patternTP))) ..
	var ruleCallsTP := txltree.expression_ruleCallsTP (patternTP)
	var ruleCallTP, literalsTP : treePT

	loop
	    exit when tree.plural_emptyP (ruleCallsTP)
	    ruleCallTP := tree.plural_firstTP (ruleCallsTP)
	    put : 0, " [", string@(ident.idents (txltree.ruleCall_nameT (ruleCallTP)))  ..
	    literalsTP := txltree.ruleCall_literalsTP (ruleCallTP)

	    loop
		exit when tree.plural_emptyP (literalsTP)
		put : 0, " ", string@(ident.idents (txltree.literal_tokenT (tree.plural_firstTP (literalsTP)))) ..
		literalsTP := tree.plural_restTP (literalsTP)
	    end loop

	    put : 0, "]" ..
	    ruleCallsTP := tree.plural_restTP (ruleCallsTP)
	end loop

    else
	error ("", "Fatal TXL error in printPatternToken", INTERNAL_FATAL, 194)
    end if
end printPatternToken


procedure printPatternTokens (failTokenIndex : int)
    % Find the ten (or fewer) tokens around the failure
    const startTokenIndex := max (1, failTokenIndex - 5)
    const endTokenIndex := min (failTokenIndex + 5, lastTokenIndex - 1)

    % Now show them
    put : 0, "\t" ..

    if startTokenIndex > endTokenIndex then
    	    put : 0, "EOF" ..
    else	    
    	for tokenIndex : startTokenIndex .. endTokenIndex
	    if tokenIndex = failTokenIndex then
		put : 0, ">>> " ..
		printPatternToken (inputTokens (tokenIndex).tree)
		put : 0, " <<< " ..
	    else
		printPatternToken (inputTokens (tokenIndex).tree)
		put : 0, " " ..
	    end if
	end for
    end if

    put : 0, ""
end printPatternTokens

#end if


procedure patternError (failTokenIndex : tokenIndexT, context : string, productionTP : treePT)
    #if not NOCOMPILE then
	var place := "at or near:"
	if failTokenIndex >= lastTokenIndex then
	    place := "at end of:"
	end if

        error (context, "[" + externalType (string@(ident.idents (tree.trees (productionTP).name))) + 
            "] syntax error, " + place, DEFERRED, 195)

	printPatternTokens (failTokenIndex)
	quit 
    #end if
end patternError


procedure parseInterruptError (failTokenIndex : tokenIndexT, 
			       patternParse : boolean, context : string)
    var place := "at or near:"
    if failTokenIndex >= lastTokenIndex then
	place := "at end of:"
    end if

    #if not NOCOMPILE then
	if patternParse then
	    error (context, "Parse interrupted, " + place, DEFERRED, 196)
	    printPatternTokens (failTokenIndex)
	    quit
	end if
    #end if

    assert not patternParse

    % Give source coordinates
    error ("line " + intstr (inputTokens (failTokenIndex).linenum mod maxLines, 1) 
	+ " of " + fileNames (inputTokens (failTokenIndex).linenum div maxLines),
	"Parse interrupted, " + place, DEFERRED, 197)

    printInputTokens (failTokenIndex)
    quit 
end parseInterruptError


procedure parseStackError (failTokenIndex : tokenIndexT, 
			       patternParse : boolean, context : string)
    var place := "at or near:"
    if failTokenIndex >= lastTokenIndex then
	place := "at end of:"
    end if

    #if not NOCOMPILE then
	if patternParse then
	    error (context, "Stack use limit (" + intstr (maxStackUse div 1024) + "k) reached, " + place, DEFERRED, 198)
	    printPatternTokens (failTokenIndex)
	    quit
	end if
    #end if

    assert not patternParse

    % Give source coordinates
	error ("line " + intstr (inputTokens (failTokenIndex).linenum mod maxLines, 1) 
	    + " of " + fileNames (inputTokens (failTokenIndex).linenum div maxLines), 
	    "Stack use limit (" + intstr (maxStackUse div 1024) + "k) reached, " + place, DEFERRED, 199)

    printInputTokens (failTokenIndex)
    quit 
end parseStackError
