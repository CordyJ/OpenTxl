% OpenTxl Version 11 TXL parse tree deconstructing functions
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

% TXL parse tree deconstructing functions
% Functions to deconstruct TXL language parse trees according to the TXL grammar. 
% These functions have intimate knowledge of the TXL bootstrap grammar and require updating when it is changed.

% Modification Log

% v11.0 Initial revision, revised from FreeTXL 10.8b (c) 1988-2022 Queen's University at Kingston

% v11.1 Updated to match TXL 11.1 grammar

module txltree
    import 
        var tree, var ident, error

    export 
        patternOrReplacement_litsAndVarsAndExpsTP, 
        construct_varNameT, construct_targetT, construct_replacementTP,
        construct_bracketedDescriptionTP, construct_isAnonymous,
        construct_anonymousExpressionTP,
        deconstruct_varNameT, deconstruct_patternTP, 
        deconstruct_isStarred, deconstruct_negated, deconstruct_targetT,
        deconstruct_isTyped, deconstruct_optSkippingTP,
        import_export_targetT, import_export_bracketedDescriptionTP, import_patternTP,
        rule_nameT, rule_formalsTP, rule_prePatternTP, rule_postPatternTP, 
        rule_optReplaceOrMatchPartTP, rule_optByPartTP, 
        rule_isStarred, rule_isDollared,
        rule_optSkippingTP, optSkipping_nameT, 
        rule_replaceOrMatchT, rule_patternTP, 
        rule_targetBracketedDescriptionTP, rule_targetT, 
        optByPart_replacementTP, optByPart_isAnonymous, optByPart_anonymousExpressionTP,
        formal_nameT, formal_typeT, formal_bracketedDescriptionTP,
        isQuotedLiteral, literal_tokenT, literal_rawtokenT, literal_kindT, ruleCall_nameT, 
        ruleCall_literalsTP, bracketedDescription_idT,
        bracketedDescription_listRepeatOrOptTargetTP,
        firstTime_nameT, firstTime_typeT,
        expression_baseT, expression_ruleCallsTP,
        program_statementsTP, keys_literalsTP, define_nameT, define_defineOrRedefineT, 
        define_endDefineOrRedefineT, define_optDotDotDotBarTP, define_optBarDotDotDotTP, 
        define_literalsAndBracketedIdsTP, define_barOrdersTP, statement_keyDefRuleTP, 
        condition_is_assert, condition_expressionTP, condition_isAnonymous, condition_negated, condition_anded, 
        literalOrBracketedIdP, bracketedDescriptionP, quotedLiteralP, literalP, 
        listP, list1P, repeatP, repeat1P, optP, attrP, seeP, notP, fenceP, pushP, popP

    % TXL program parse tree deconstructors - used only in compiler

    % WARNING: These operations have intimate knowledge of the structure of TXL program parse trees
    % as defined by the TXL bootstrap grammar!

    function patternOrReplacement_litsAndVarsAndExpsTP (patternOrReplacementTP : treePT) : treePT
        pre string@(ident.idents (tree.trees (patternOrReplacementTP).name)) = "TXL_pattern_" or
             string@(ident.idents (tree.trees (patternOrReplacementTP).name)) = "TXL_replacement_"
        result tree.kids (tree.trees (patternOrReplacementTP).kidsKP)
    end patternOrReplacement_litsAndVarsAndExpsTP

    forward function literalP (treeP : treePT) : boolean
    forward function literal_tokenT (literalTP : treePT) : tokenT

    function listRepeatOrOptTargetName (listRepeatOrOptTP : treePT) : string
        if tree.trees (tree.kid1TP (tree.kid2TP (listRepeatOrOptTP))).kind = kindT.id then
            result string@(ident.idents (tree.trees (tree.kid1TP (tree.kid2TP (listRepeatOrOptTP))).name))
        else
            assert literalP (tree.kid1TP (tree.kid2TP (listRepeatOrOptTP)))
            const literalT : tokenT := literal_tokenT (tree.kid1TP (tree.kid2TP (listRepeatOrOptTP)))
            result "lit__" + string@(ident.idents (literalT))
        end if
    end listRepeatOrOptTargetName

    function descriptionTargetT (descriptionTP : treePT) : tokenT
        % Given a list, repeat, opt or nonterminal description, 
        % return its nonterminal target name
        
        pre string@(ident.idents (tree.trees (descriptionTP).name)) = "TXL_description_"
     
        const descriptionName := string@(ident.idents (tree.trees (tree.kids (tree.trees (descriptionTP).kidsKP)).name))
        
        var identIndex : tokenT

        if descriptionName  = "TXL_listDescription_" or descriptionName = "TXL_newlistDescription_" then
            identIndex := ident.install ("list_0_" + listRepeatOrOptTargetName (tree.kids (tree.trees (descriptionTP).kidsKP)), kindT.id)
        elsif descriptionName = "TXL_repeatDescription_" or descriptionName = "TXL_newrepeatDescription_" then
            identIndex := ident.install ("repeat_0_" + listRepeatOrOptTargetName (tree.kids (tree.trees (descriptionTP).kidsKP)), kindT.id)
        elsif descriptionName = "TXL_list1Description_" or descriptionName = "TXL_newlist1Description_" then
            identIndex := ident.install ("list_1_" + listRepeatOrOptTargetName (tree.kids (tree.trees (descriptionTP).kidsKP)), kindT.id)
        elsif descriptionName = "TXL_repeat1Description_" or descriptionName = "TXL_newrepeat1Description_" then
            identIndex := ident.install ("repeat_1_" + listRepeatOrOptTargetName (tree.kids (tree.trees (descriptionTP).kidsKP)), kindT.id)
        elsif descriptionName = "TXL_optDescription_" or descriptionName = "TXL_newoptDescription_" then
            identIndex := ident.install ("opt__" + listRepeatOrOptTargetName (tree.kids (tree.trees (descriptionTP).kidsKP)), kindT.id)
        elsif descriptionName = "TXL_attrDescription_" then
            identIndex := ident.install ("attr__" + listRepeatOrOptTargetName (tree.kids (tree.trees (descriptionTP).kidsKP)), kindT.id)
        elsif descriptionName = "TXL_pushDescription_" then
            identIndex := ident.install ("push__" + listRepeatOrOptTargetName (tree.kids (tree.trees (descriptionTP).kidsKP)), kindT.id)
        elsif descriptionName = "TXL_popDescription_" then
            identIndex := ident.install ("pop__" + listRepeatOrOptTargetName (tree.kids (tree.trees (descriptionTP).kidsKP)), kindT.id)
        else
            identIndex := tree.trees (tree.kids (tree.trees (descriptionTP).kidsKP)).name
        end if

        result identIndex

    end descriptionTargetT

    function construct_varNameT (constructTP : treePT) : tokenT
        pre string@(ident.idents (tree.trees (constructTP).name)) = "TXL_constructPart_"
            or string@(ident.idents (tree.trees (constructTP).name)) = "TXL_importPart_"
            or string@(ident.idents (tree.trees (constructTP).name)) = "TXL_exportPart_"
        result tree.trees (tree.kid2TP(constructTP)).name
    end construct_varNameT

    function construct_targetT (constructTP : treePT) : tokenT
        pre string@(ident.idents (tree.trees (constructTP).name)) = "TXL_constructPart_"
            or string@(ident.idents (tree.trees (constructTP).name)) = "TXL_importPart_"
        const bracketedDescriptionTP := tree.kid3TP (constructTP)
        assert string@(ident.idents (tree.trees (bracketedDescriptionTP).name)) = "TXL_bracketedDescription_"
        const descriptionTP := tree.kid2TP (bracketedDescriptionTP)
        assert string@(ident.idents (tree.trees (descriptionTP).name)) = "TXL_description_"

        result descriptionTargetT (descriptionTP)
    end construct_targetT

    function construct_bracketedDescriptionTP (constructTP : treePT) : treePT
        pre string@(ident.idents (tree.trees (constructTP).name)) = "TXL_constructPart_"
            or string@(ident.idents (tree.trees (constructTP).name)) = "TXL_importPart_"
        result tree.kid3TP (constructTP)
    end construct_bracketedDescriptionTP

    function construct_replacementTP (constructTP : treePT) : treePT
        pre string@(ident.idents (tree.trees (constructTP).name)) = "TXL_constructPart_"
            or string@(ident.idents (tree.trees (constructTP).name)) = "TXL_exportPart_"
        result tree.kid4TP (constructTP)
    end construct_replacementTP

    function construct_isAnonymous (constructTP : treePT) : boolean
        pre string@(ident.idents (tree.trees (constructTP).name)) = "TXL_constructPart_"
            or string@(ident.idents (tree.trees (constructTP).name)) = "TXL_exportPart_"
        const replacementTP := construct_replacementTP (constructTP)
        if tree.plural_emptyP (tree.kid1TP (replacementTP)) then
            result false
        else
            const indExpsAndLitsTP := tree.kid1TP (tree.kid1TP (replacementTP))
            assert string@(ident.idents (tree.trees (indExpsAndLitsTP).name)) = "TXL_indExpsAndLits_"
            if not tree.plural_emptyP (tree.kid2TP (indExpsAndLitsTP)) then 
                result false
            else
                const expressionTP := tree.kid1TP (tree.kid1TP (indExpsAndLitsTP))
                if string@(ident.idents (tree.trees (expressionTP).name)) not= "TXL_expression_" then
                    result false
                else
                    result tree.trees (tree.kid1TP (expressionTP)).name = anonymous_T
                end if
            end if
        end if
    end construct_isAnonymous

    function construct_anonymousExpressionTP (constructTP : treePT) : treePT
        pre construct_isAnonymous (constructTP)
        const replacementTP := construct_replacementTP (constructTP)
        const indExpsAndLitsTP := tree.kid1TP (tree.kid1TP (replacementTP))
        result tree.kid1TP (tree.kid1TP (indExpsAndLitsTP))
    end construct_anonymousExpressionTP

    function deconstruct_varNameT (deconstructTP : treePT) : tokenT
        pre string@(ident.idents (tree.trees (deconstructTP).name)) = "TXL_deconstructPart_"
        result tree.trees (tree.kid6TP (deconstructTP)).name
    end deconstruct_varNameT

    function deconstruct_patternTP (deconstructTP : treePT) : treePT
        pre string@(ident.idents (tree.trees (deconstructTP).name)) = "TXL_deconstructPart_"
        result tree.kidTP (7, deconstructTP)
    end deconstruct_patternTP

    function deconstruct_isStarred (deconstructTP : treePT) : boolean
        pre string@(ident.idents (tree.trees (deconstructTP).name)) = "TXL_deconstructPart_"
            and string@(ident.idents (tree.trees (tree.kid4TP (deconstructTP)).name)) = "TXL_optStarDollarHash_"
        result tree.trees (tree.kid1TP (tree.kid4TP (deconstructTP))).name = star_T
    end deconstruct_isStarred

    function deconstruct_negated (deconstructTP : treePT) : boolean
        pre string@(ident.idents (tree.trees (deconstructTP).name)) = "TXL_deconstructPart_"
            and string@(ident.idents (tree.trees (tree.kid3TP (deconstructTP)).name)) = "TXL_optNot_"
        result not tree.plural_emptyP (tree.kid3TP (deconstructTP))
    end deconstruct_negated

    function deconstruct_isTyped (deconstructTP : treePT) : boolean
        pre string@(ident.idents (tree.trees (deconstructTP).name)) = "TXL_deconstructPart_"
            and string@(ident.idents (tree.trees (tree.kid5TP (deconstructTP)).name)) = "TXL_optBracketedDescription_"
        result not tree.plural_emptyP (tree.kid5TP(deconstructTP))
    end deconstruct_isTyped

    function deconstruct_targetT (deconstructTP : treePT) : tokenT
        pre string@(ident.idents (tree.trees (deconstructTP).name)) = "TXL_deconstructPart_"
                and deconstruct_isTyped (deconstructTP)

        const bracketedDescriptionTP := tree.kid1TP (tree.kid5TP(deconstructTP))
        assert string@(ident.idents (tree.trees (bracketedDescriptionTP).name)) = "TXL_bracketedDescription_"
        const descriptionTP := tree.kid2TP (bracketedDescriptionTP)
        assert string@(ident.idents (tree.trees (descriptionTP).name)) = "TXL_description_"

        result descriptionTargetT (descriptionTP)
    end deconstruct_targetT

    function deconstruct_optSkippingTP (deconstructTP : treePT) : treePT
        pre string@(ident.idents (tree.trees (deconstructTP).name)) = "TXL_deconstructPart_" and
            string@(ident.idents (tree.trees (tree.kid1TP (deconstructTP)).name)) = "TXL_optSkippingBracketedDescription_"
        result tree.kid1TP (deconstructTP)
    end deconstruct_optSkippingTP

    function import_export_targetT (exportTP : treePT) : tokenT
        pre string@(ident.idents (tree.trees (exportTP).name)) = "TXL_exportPart_"
            or string@(ident.idents (tree.trees (exportTP).name)) = "TXL_importPart_"
        const optBracketedDescriptionTP := tree.kid3TP (exportTP)
        assert string@(ident.idents (tree.trees (optBracketedDescriptionTP).name)) = "TXL_optBracketedDescription_"
        if not tree.plural_emptyP (optBracketedDescriptionTP) then
            const descriptionTP := tree.kid2TP ( tree.kid1TP (optBracketedDescriptionTP))
            assert string@(ident.idents (tree.trees (descriptionTP).name)) = "TXL_description_"
            result descriptionTargetT (descriptionTP)
        else
            result NOT_FOUND
        end if
    end import_export_targetT

    function import_export_bracketedDescriptionTP (exportTP : treePT) : treePT
        pre string@(ident.idents (tree.trees (exportTP).name)) = "TXL_importPart_"
                or string@(ident.idents (tree.trees (exportTP).name)) = "TXL_exportPart_"
            and import_export_targetT (exportTP) not= NOT_FOUND
        result tree.kid1TP (tree.kid3TP(exportTP))
    end import_export_bracketedDescriptionTP

    function import_patternTP (importTP : treePT) : treePT
        pre string@(ident.idents (tree.trees (importTP).name)) = "TXL_importPart_"
        result tree.kid4TP (importTP)
    end import_patternTP

    %    define TXL_ruleStatement_
    %           'rule [id] [TXL_arguments_]
    %               [TXL_parts_]
    %               [TXL_optReplaceOrMatchPart_]
    %               [TXL_parts_]
    %               [TXL_optByPart_]
    %           'end 'rule 
    %    end define

    function rule_nameT (ruleTP : treePT) : tokenT
        pre string@(ident.idents (tree.trees (ruleTP).name)) = "TXL_ruleStatement_"
         or string@(ident.idents (tree.trees (ruleTP).name)) = "TXL_functionStatement_"
        result tree.trees (tree.kid2TP (ruleTP)).name
    end rule_nameT

    function rule_formalsTP (ruleTP : treePT) : treePT
        pre (string@(ident.idents (tree.trees (ruleTP).name)) = "TXL_ruleStatement_" or
             string@(ident.idents (tree.trees (ruleTP).name)) = "TXL_functionStatement_" ) and
            string@(ident.idents (tree.trees (tree.kid3TP (ruleTP)).name)) = "TXL_arguments_"
        result tree.kid3TP (ruleTP)
    end rule_formalsTP

    function rule_prePatternTP (ruleTP : treePT) : treePT
        pre (string@(ident.idents (tree.trees (ruleTP).name)) = "TXL_ruleStatement_" or
             string@(ident.idents (tree.trees (ruleTP).name)) = "TXL_functionStatement_") and
            string@(ident.idents (tree.trees (tree.kid4TP (ruleTP)).name)) = "TXL_parts_"
        result tree.kid4TP (ruleTP)
    end rule_prePatternTP

    function rule_optReplaceOrMatchPartTP (ruleTP : treePT) : treePT
        pre (string@(ident.idents (tree.trees (ruleTP).name)) = "TXL_ruleStatement_" or
             string@(ident.idents (tree.trees (ruleTP).name)) = "TXL_functionStatement_" ) and
            string@(ident.idents (tree.trees (tree.kid5TP (ruleTP)).name)) = "TXL_optReplaceOrMatchPart_"
        result tree.kid5TP (ruleTP)
    end rule_optReplaceOrMatchPartTP

    function rule_postPatternTP (ruleTP : treePT) : treePT
        pre (string@(ident.idents (tree.trees (ruleTP).name)) = "TXL_ruleStatement_" or
             string@(ident.idents (tree.trees (ruleTP).name)) = "TXL_functionStatement_") and
            string@(ident.idents (tree.trees (tree.kid6TP (ruleTP)).name)) = "TXL_parts_"
        result tree.kid6TP (ruleTP)
    end rule_postPatternTP

    function rule_optByPartTP (ruleTP : treePT) : treePT
        pre (string@(ident.idents (tree.trees (ruleTP).name)) = "TXL_ruleStatement_" or
             string@(ident.idents (tree.trees (ruleTP).name)) = "TXL_functionStatement_" ) and
            string@(ident.idents (tree.trees (tree.kid7TP (ruleTP)).name)) = "TXL_optByPart_"
        result tree.kid7TP (ruleTP)
    end rule_optByPartTP

    % define TXL_optReplaceOrMatchPart_
    %           [TXL_replaceOrMatchPart_]
    %     |     [empty]
    % end define
    % 
    % define TXL_replaceOrMatchPart_
    %   [TXL_optSkippingBracketedDescription_] 
    %   [TXL_replaceOrMatch_] [TXL_optStarDollarHash_]
    %           [TXL_bracketedDescription_] 
    %   [TXL_pattern_]
    % end define

    function rule_isStarred (ruleTP : treePT) : boolean
        pre string@(ident.idents (tree.trees (ruleTP).name)) = "TXL_ruleStatement_" or
            string@(ident.idents (tree.trees (ruleTP).name)) = "TXL_functionStatement_" 
        const optReplaceOrMatchPartTP := rule_optReplaceOrMatchPartTP (ruleTP)
        assert string@(ident.idents (tree.trees (optReplaceOrMatchPartTP).name)) = "TXL_optReplaceOrMatchPart_" 
        assert not tree.plural_emptyP (optReplaceOrMatchPartTP) 
        const replaceOrMatchPartTP := tree.kid1TP (optReplaceOrMatchPartTP)
        result tree.trees (tree.kid1TP (tree.kid3TP (replaceOrMatchPartTP))).name = star_T
    end rule_isStarred

    function rule_isDollared (ruleTP : treePT) : boolean
        pre string@(ident.idents (tree.trees (ruleTP).name)) = "TXL_ruleStatement_" or
            string@(ident.idents (tree.trees (ruleTP).name)) = "TXL_functionStatement_" 
        const optReplaceOrMatchPartTP := rule_optReplaceOrMatchPartTP (ruleTP)
        assert string@(ident.idents (tree.trees (optReplaceOrMatchPartTP).name)) = "TXL_optReplaceOrMatchPart_" 
        assert not tree.plural_emptyP (optReplaceOrMatchPartTP) 
        const replaceOrMatchPartTP := tree.kid1TP (optReplaceOrMatchPartTP)
        result tree.trees (tree.kid1TP (tree.kid3TP (replaceOrMatchPartTP))).name = dollar_T
    end rule_isDollared

    function rule_replaceOrMatchT (ruleTP : treePT) : tokenT
        pre string@(ident.idents (tree.trees (ruleTP).name)) = "TXL_ruleStatement_" or
            string@(ident.idents (tree.trees (ruleTP).name)) = "TXL_functionStatement_" 
        const optReplaceOrMatchPartTP := rule_optReplaceOrMatchPartTP (ruleTP)
        assert string@(ident.idents (tree.trees (optReplaceOrMatchPartTP).name)) = "TXL_optReplaceOrMatchPart_" 
        assert not tree.plural_emptyP (optReplaceOrMatchPartTP) 
        const replaceOrMatchPartTP := tree.kid1TP (optReplaceOrMatchPartTP)
        result tree.trees (tree.kid1TP (tree.kid2TP (replaceOrMatchPartTP))).name 
    end rule_replaceOrMatchT

    function rule_optSkippingTP (ruleTP : treePT) : treePT
        pre string@(ident.idents (tree.trees (ruleTP).name)) = "TXL_ruleStatement_" or
            string@(ident.idents (tree.trees (ruleTP).name)) = "TXL_functionStatement_" 
        const optReplaceOrMatchPartTP := rule_optReplaceOrMatchPartTP (ruleTP)
        assert string@(ident.idents (tree.trees (optReplaceOrMatchPartTP).name)) = "TXL_optReplaceOrMatchPart_" 
        assert not tree.plural_emptyP (optReplaceOrMatchPartTP) 
        const replaceOrMatchPartTP := tree.kid1TP (optReplaceOrMatchPartTP)
        assert string@(ident.idents (tree.trees (tree.kid1TP (replaceOrMatchPartTP)).name)) = "TXL_optSkippingBracketedDescription_"
        result tree.kid1TP (replaceOrMatchPartTP)
    end rule_optSkippingTP

    function rule_targetBracketedDescriptionTP (ruleTP : treePT) : treePT
        pre string@(ident.idents (tree.trees (ruleTP).name)) = "TXL_ruleStatement_" or
            string@(ident.idents (tree.trees (ruleTP).name)) = "TXL_functionStatement_" 
        const optReplaceOrMatchPartTP := rule_optReplaceOrMatchPartTP (ruleTP)
        assert string@(ident.idents (tree.trees (optReplaceOrMatchPartTP).name)) = "TXL_optReplaceOrMatchPart_" 
        assert not tree.plural_emptyP (optReplaceOrMatchPartTP) 
        const replaceOrMatchPartTP := tree.kid1TP (optReplaceOrMatchPartTP)
        assert string@(ident.idents (tree.trees (tree.kid4TP (replaceOrMatchPartTP)).name)) = "TXL_bracketedDescription_"
        result tree.kid4TP (replaceOrMatchPartTP)
    end rule_targetBracketedDescriptionTP

    function rule_targetT (ruleTP : treePT) : tokenT
        pre string@(ident.idents (tree.trees (ruleTP).name)) = "TXL_ruleStatement_" or
            string@(ident.idents (tree.trees (ruleTP).name)) = "TXL_functionStatement_" 
        const optReplaceOrMatchPartTP := rule_optReplaceOrMatchPartTP (ruleTP)
        assert string@(ident.idents (tree.trees (optReplaceOrMatchPartTP).name)) = "TXL_optReplaceOrMatchPart_" 
        assert not tree.plural_emptyP (optReplaceOrMatchPartTP) 
        const replaceOrMatchPartTP := tree.kid1TP (optReplaceOrMatchPartTP)
        const bracketedDescriptionTP := tree.kid4TP (replaceOrMatchPartTP)
        assert string@(ident.idents (tree.trees (bracketedDescriptionTP).name)) = "TXL_bracketedDescription_"
        const descriptionTP := tree.kid2TP (bracketedDescriptionTP)
        assert string@(ident.idents (tree.trees (descriptionTP).name)) = "TXL_description_"
        result descriptionTargetT (descriptionTP)
    end rule_targetT

    function rule_patternTP (ruleTP : treePT) : treePT
        pre string@(ident.idents (tree.trees (ruleTP).name)) = "TXL_ruleStatement_" or
            string@(ident.idents (tree.trees (ruleTP).name)) = "TXL_functionStatement_" 
        const optReplaceOrMatchPartTP := rule_optReplaceOrMatchPartTP (ruleTP)
        assert string@(ident.idents (tree.trees (optReplaceOrMatchPartTP).name)) = "TXL_optReplaceOrMatchPart_" 
        assert not tree.plural_emptyP (optReplaceOrMatchPartTP) 
        const replaceOrMatchPartTP := tree.kid1TP (optReplaceOrMatchPartTP)
        assert string@(ident.idents (tree.trees (tree.kid5TP (replaceOrMatchPartTP)).name)) = "TXL_pattern_"
        result tree.kid5TP (replaceOrMatchPartTP)
    end rule_patternTP 

    % define TXL_optByPart_
    %           [TXL_byPart_]
    %     |     [empty]
    % end define
    % 
    % define TXL_byPart_
    %   'by
    %       [TXL_replacement_]
    % end define

    function optByPart_replacementTP (optByPartTP : treePT) : treePT
        pre string@(ident.idents (tree.trees (optByPartTP).name)) = "TXL_optByPart_" and
         (not tree.plural_emptyP (optByPartTP)) and
            string@(ident.idents (tree.trees (tree.kid2TP (tree.kids (tree.trees (optByPartTP).kidsKP))).name)) = "TXL_replacement_"
        result tree.kid2TP (tree.kids (tree.trees (optByPartTP).kidsKP))
    end optByPart_replacementTP 

    function optByPart_isAnonymous (optByPartTP : treePT) : boolean
        pre string@(ident.idents (tree.trees (optByPartTP).name)) = "TXL_optByPart_" and
            not tree.plural_emptyP (optByPartTP)
        const replacementTP := optByPart_replacementTP (optByPartTP)
        assert string@(ident.idents (tree.trees (replacementTP).name)) = "TXL_replacement_"
        if tree.plural_emptyP (tree.kid1TP (replacementTP)) then
            % nothing in replacement
            result false
        else
            const indExpsAndLitsTP := tree.kid1TP (tree.kid1TP (replacementTP))
            assert string@(ident.idents (tree.trees (indExpsAndLitsTP).name)) = "TXL_indExpsAndLits_"
            if not tree.plural_emptyP (tree.kid2TP (indExpsAndLitsTP)) then 
                result false
            else
                const expressionTP := tree.kid1TP (tree.kid1TP (indExpsAndLitsTP))
                if string@(ident.idents (tree.trees (expressionTP).name)) not= "TXL_expression_" then
                    result false
                else
                    result tree.trees (tree.kid1TP (expressionTP)).name = anonymous_T
                end if
            end if
        end if
    end optByPart_isAnonymous

    function optByPart_anonymousExpressionTP (optByPartTP : treePT) : treePT
        pre optByPart_isAnonymous (optByPartTP)
        const replacementTP := optByPart_replacementTP (optByPartTP)
        const indExpsAndLitsTP := tree.kid1TP (tree.kid1TP (replacementTP))
        result tree.kid1TP (tree.kid1TP (indExpsAndLitsTP))
    end optByPart_anonymousExpressionTP

    % define TXL_optSkippingBracketedDescription_
    %           [TXL_skippingBracketedDescription_]
    %     |     [empty]
    % end define
    % 
    % define TXL_skippingBracketedDescription_
    %   'skipping [TXL_bracketedDescription_]
    % end define

    function optSkipping_nameT (optSkippingTP : treePT) : tokenT
        pre string@(ident.idents (tree.trees (optSkippingTP).name)) = "TXL_optSkippingBracketedDescription_"
            and string@(ident.idents (tree.trees (tree.kid1TP(optSkippingTP)).name)) = "TXL_skippingBracketedDescription_"

        const bracketedDescriptionTP := tree.kid2TP (tree.kid1TP(optSkippingTP))
        assert string@(ident.idents (tree.trees (bracketedDescriptionTP).name)) = "TXL_bracketedDescription_"
        const descriptionTP := tree.kid2TP (bracketedDescriptionTP)
        assert string@(ident.idents (tree.trees (descriptionTP).name)) = "TXL_description_"

        result descriptionTargetT (descriptionTP)
    end optSkipping_nameT
        
    % define TXL_argument_
    %   [id] [TXL_bracketedDescription_]
    % end define

    function formal_nameT (argumentTP : treePT) : tokenT
        pre string@(ident.idents (tree.trees (argumentTP).name)) = "TXL_argument_"
        result tree.trees (tree.kids (tree.trees (argumentTP).kidsKP)).name
    end formal_nameT

    function formal_bracketedDescriptionTP (argumentTP : treePT) : treePT
        pre string@(ident.idents (tree.trees (argumentTP).name)) = "TXL_argument_" 
            and string@(ident.idents (tree.trees (tree.kid2TP (argumentTP)).name)) = "TXL_bracketedDescription_"
        result tree.kid2TP (argumentTP)
    end formal_bracketedDescriptionTP

    function formal_typeT (argumentTP : treePT) : tokenT
        pre string@(ident.idents (tree.trees (argumentTP).name)) = "TXL_argument_" 
        const bracketedDescriptionTP := tree.kid2TP (argumentTP)
        assert string@(ident.idents (tree.trees (bracketedDescriptionTP).name)) = "TXL_bracketedDescription_"
        const descriptionTP := tree.kid2TP (bracketedDescriptionTP)
        assert string@(ident.idents (tree.trees (descriptionTP).name)) = "TXL_description_"
        result descriptionTargetT (descriptionTP)
    end formal_typeT

    function isQuotedLiteral (literalTP : treePT) : boolean
        pre string@(ident.idents (tree.trees (literalTP).name)) = "TXL_literal_"
            or string@(ident.idents (tree.trees (literalTP).name)) = "TXL_expression_"
            or string@(ident.idents (tree.trees (literalTP).name)) = "TXL_firstTime_"
        const k1TP : treePT := tree.kids (tree.trees (literalTP).kidsKP)
        result string@(ident.idents (tree.trees (literalTP).name)) = "TXL_literal_"
            and string@(ident.idents (tree.trees (k1TP).name)) = "TXL_quotedLiteral_" 
    end isQuotedLiteral

    body function literal_tokenT % (literalTP : treePT) : tokenT
        pre string@(ident.idents (tree.trees (literalTP).name)) = "TXL_literal_"
            or string@(ident.idents (tree.trees (literalTP).name)) = "TXL_expression_"
            or string@(ident.idents (tree.trees (literalTP).name)) = "TXL_firstTime_"

        const k1TP : treePT := tree.kids (tree.trees (literalTP).kidsKP)

        if tree.trees (k1TP).kind = kindT.order or tree.trees (k1TP).kind = kindT.choose then
            if string@(ident.idents (tree.trees (k1TP).name)) = "TXL_quotedLiteral_" then
                result tree.trees (tree.kid1TP (tree.kid2TP (k1TP))).name
            else
                assert string@(ident.idents (tree.trees (literalTP).name)) = "TXL_expression_"
                    or string@(ident.idents (tree.trees (literalTP).name)) = "TXL_firstTime_"
                result tree.trees (k1TP).name
            end if
        else
            % direct token literal
            result tree.trees (k1TP).name
        end if
    end literal_tokenT

    function literal_rawtokenT (literalTP : treePT) : tokenT
        pre string@(ident.idents (tree.trees (literalTP).name)) = "TXL_literal_"
            or string@(ident.idents (tree.trees (literalTP).name)) = "TXL_expression_"
            or string@(ident.idents (tree.trees (literalTP).name)) = "TXL_firstTime_"

        const k1TP : treePT := tree.kids (tree.trees (literalTP).kidsKP)

        if tree.trees (k1TP).kind = kindT.order or tree.trees (k1TP).kind = kindT.choose then
            if string@(ident.idents (tree.trees (k1TP).name)) = "TXL_quotedLiteral_" then
                result tree.trees (tree.kid1TP (tree.kid2TP (k1TP))).rawname
            else
                assert string@(ident.idents (tree.trees (literalTP).name)) = "TXL_expression_"
                    or string@(ident.idents (tree.trees (literalTP).name)) = "TXL_firstTime_"
                result tree.trees (k1TP).rawname
            end if
        else
            % direct token literal
            result tree.trees (k1TP).rawname
        end if
    end literal_rawtokenT

    function literal_kindT (literalTP : treePT) : kindT
        pre string@(ident.idents (tree.trees (literalTP).name)) = "TXL_literal_"
            or string@(ident.idents (tree.trees (literalTP).name)) = "TXL_expression_"
            or string@(ident.idents (tree.trees (literalTP).name)) = "TXL_firstTime_"

        const k1TP : treePT := tree.kids (tree.trees (literalTP).kidsKP)
        const k1kind : kindT := tree.trees (k1TP).kind

        if k1kind = kindT.order or k1kind = kindT.choose then
            if string@(ident.idents (tree.trees (k1TP).name)) = "TXL_quotedLiteral_" then
                result tree.trees (tree.kid1TP (tree.kid2TP (k1TP))).kind
            else
                assert string@(ident.idents (tree.trees (literalTP).name)) = "TXL_expression_"
                    or string@(ident.idents (tree.trees (literalTP).name)) = "TXL_firstTime_"
                result k1kind
            end if
        else
            % direct token literal
            result k1kind
        end if
    end literal_kindT

    function ruleCall_nameT (ruleCallTP : treePT) : tokenT
        pre string@(ident.idents (tree.trees (ruleCallTP).name)) = "TXL_ruleCall_"
        result tree.trees (tree.kid2TP (ruleCallTP)).name
    end ruleCall_nameT

    function ruleCall_literalsTP (ruleCallTP : treePT) : treePT
        pre string@(ident.idents (tree.trees (tree.kid3TP (ruleCallTP)).name)) = "TXL_literals_"
        result tree.kid3TP (ruleCallTP)
    end ruleCall_literalsTP

    function bracketedDescription_idT (bracketedDescriptionTP : treePT) : tokenT
        pre string@(ident.idents (tree.trees (bracketedDescriptionTP).name)) = "TXL_bracketedDescription_"
            and string@(ident.idents (tree.trees (tree.kid2TP (bracketedDescriptionTP)).name)) = "TXL_description_"
        % const descriptionName := string@(ident.idents (tree.trees (tree.kid1TP(tree.kid2TP(bracketedDescriptionTP))).name))
        % assert descriptionName ~= "TXL_listDescription_" and descriptionName ~= "TXL_repeatDescription_"
        %    and descriptionName ~= "TXL_list1Description_" and descriptionName ~= "TXL_repeat1Description_"
        %    and descriptionName ~= "TXL_optDescription_" 
        % assert descriptionName ~= "TXL_newlistDescription_" and descriptionName ~= "TXL_newrepeatDescription_"
        %    and descriptionName ~= "TXL_newlist1Description_" and descriptionName ~= "TXL_newrepeat1Description_"
        %    and descriptionName ~= "TXL_newoptDescription_"  and descriptionName ~= "TXL_attrDescription_"
        result tree.trees (tree.kid1TP (tree.kid2TP (bracketedDescriptionTP))).name
    end bracketedDescription_idT

    function bracketedDescription_listRepeatOrOptTargetTP (bracketedDescriptionTP : treePT) : treePT
        pre string@(ident.idents (tree.trees (bracketedDescriptionTP).name)) = "TXL_bracketedDescription_"
            and string@(ident.idents (tree.trees (tree.kid2TP (bracketedDescriptionTP)).name)) = "TXL_description_"
        const listRepeatOrOptTP := tree.kid1TP (tree.kid2TP(bracketedDescriptionTP))
        % const listRepeatOrOptName := string@(ident.idents (tree.trees (listRepeatOrOptTP).name))
        % assert listRepeatOrOptName  = "TXL_listDescription_" or listRepeatOrOptName = "TXL_repeatDescription_"
        %    or listRepeatOrOptName  = "TXL_list1Description_" or listRepeatOrOptName  = "TXL_repeat1Description_"
        %    or listRepeatOrOptName  = "TXL_optDescription_" 
        %    or listRepeatOrOptName  = "TXL_newlistDescription_" or listRepeatOrOptName = "TXL_newrepeatDescription_"
        %    or listRepeatOrOptName  = "TXL_newlist1Description_" or listRepeatOrOptName  = "TXL_newrepeat1Description_"
        %    or listRepeatOrOptName  = "TXL_newoptDescription_" or listRepeatOrOptName = "TXL_attrDescription_"
        result tree.kid2TP (listRepeatOrOptTP)
    end bracketedDescription_listRepeatOrOptTargetTP

    function firstTime_nameT (firstTimeTP : treePT) : tokenT
        pre string@(ident.idents (tree.trees (firstTimeTP).name)) = "TXL_firstTime_"
        result tree.trees (tree.kids (tree.trees (firstTimeTP).kidsKP)).name
    end firstTime_nameT

    function firstTime_typeT (firstTimeTP : treePT) : tokenT
        pre string@(ident.idents (tree.trees (firstTimeTP).name)) = "TXL_firstTime_"

        const descriptionTP : treePT := tree.kid3TP (firstTimeTP)
        assert string@(ident.idents (tree.trees (descriptionTP).name)) = "TXL_description_"

        result descriptionTargetT (descriptionTP)
    end firstTime_typeT

    function expression_baseT (expressionTP : treePT) : tokenT
        pre string@(ident.idents (tree.trees (expressionTP).name)) = "TXL_expression_"
        result tree.trees (tree.kids (tree.trees (expressionTP).kidsKP)).name
    end expression_baseT

    function expression_ruleCallsTP (expressionTP : treePT) : treePT
        pre string@(ident.idents (tree.trees (tree.kid2TP (expressionTP)).name)) = "TXL_ruleCalls_"
        result tree.kid2TP (expressionTP)
    end expression_ruleCallsTP

    function program_statementsTP (programTP : treePT) : treePT
        pre string@(ident.idents (tree.trees (tree.kids (tree.trees (programTP).kidsKP)).name)) = "TXL_statements_"
        result tree.kids (tree.trees (programTP).kidsKP)
    end program_statementsTP

    function keys_literalsTP (keyListTP : treePT) : treePT
        pre string@(ident.idents (tree.trees (tree.kid2TP (keyListTP)).name)) = "TXL_literals_"
        result tree.kid2TP (keyListTP)
    end keys_literalsTP

    function define_nameT (defineTP : treePT) : tokenT
        result tree.trees (tree.kid2TP (defineTP)).name
    end define_nameT

    function define_defineOrRedefineT (defineTP : treePT) : tokenT
        result tree.trees (tree.kid1TP (tree.kid1TP (defineTP))).name
    end define_defineOrRedefineT

    function define_endDefineOrRedefineT (defineTP : treePT) : tokenT
        result tree.trees (tree.kid1TP (tree.kidTP (8, defineTP))).name
    end define_endDefineOrRedefineT

    function define_optDotDotDotBarTP (defineTP : treePT) : treePT
        pre string@(ident.idents (tree.trees (defineTP).name)) = "TXL_defineStatement_"
        result tree.kid3TP (defineTP)
    end define_optDotDotDotBarTP

    function define_optBarDotDotDotTP (defineTP : treePT) : treePT
        pre string@(ident.idents (tree.trees (defineTP).name)) = "TXL_defineStatement_"
        result tree.kidTP (6, defineTP)
    end define_optBarDotDotDotTP

    function define_literalsAndBracketedIdsTP (defineTP : treePT) : treePT
        pre string@(ident.idents (tree.trees (defineTP).name)) = "TXL_defineStatement_"
        result tree.kid4TP (defineTP)
    end define_literalsAndBracketedIdsTP

    function define_barOrdersTP (defineTP : treePT) : treePT
        pre string@(ident.idents (tree.trees (defineTP).name)) = "TXL_defineStatement_"
        result tree.kid5TP (defineTP)
    end define_barOrdersTP

    function statement_keyDefRuleTP (statementTP : treePT) : treePT
        pre string@(ident.idents (tree.trees (statementTP).name)) = "TXL_statement_"
        result tree.kids (tree.trees (statementTP).kidsKP)
    end statement_keyDefRuleTP

    function condition_is_assert (conditionTP : treePT) : boolean
        pre string@(ident.idents (tree.trees (conditionTP).name)) = "TXL_conditionPart_"
            and string@(ident.idents (tree.trees (tree.kid1TP (conditionTP)).name)) = "TXL_whereOrAssert_"
        result tree.trees (tree.kid1TP (tree.kid1TP (conditionTP))).name = assert_T
    end condition_is_assert

    function condition_expressionTP (conditionTP : treePT) : treePT
        pre string@(ident.idents (tree.trees (conditionTP).name)) = "TXL_conditionPart_"
            and string@(ident.idents (tree.trees (tree.kid4TP (conditionTP)).name)) = "TXL_expression_"
        result tree.kid4TP (conditionTP)
    end condition_expressionTP

    function condition_isAnonymous (conditionTP : treePT) : boolean
        pre string@(ident.idents (tree.trees (conditionTP).name)) = "TXL_conditionPart_"
        const expressionTP := tree.kid4TP (conditionTP)
        assert string@(ident.idents (tree.trees (expressionTP).name)) = "TXL_expression_"
        result tree.trees (tree.kid1TP (expressionTP)).name = anonymous_T
    end condition_isAnonymous

    function condition_negated (conditionTP : treePT) : boolean
        pre string@(ident.idents (tree.trees (conditionTP).name)) = "TXL_conditionPart_"
            and string@(ident.idents (tree.trees (tree.kid2TP (conditionTP)).name)) = "TXL_optNot_"
        result not tree.plural_emptyP (tree.kid2TP (conditionTP))
    end condition_negated

    function condition_anded (conditionTP : treePT) : boolean
        pre string@(ident.idents (tree.trees (conditionTP).name)) = "TXL_conditionPart_"
            and string@(ident.idents (tree.trees (tree.kid3TP (conditionTP)).name)) = "TXL_optAll_"
        result not tree.plural_emptyP (tree.kid3TP (conditionTP))
    end condition_anded

    function literalOrBracketedIdP (treeP : treePT) : boolean
        result string@(ident.idents (tree.trees (treeP).name)) = "TXL_literalOrBracketedDescription_"
    end literalOrBracketedIdP

    function bracketedDescriptionP (treeP : treePT) : boolean
        result string@(ident.idents (tree.trees (treeP).name)) = "TXL_bracketedDescription_"
    end bracketedDescriptionP

    function quotedLiteralP (treeP : treePT) : boolean
        result string@(ident.idents (tree.trees (treeP).name)) = "TXL_quotedLiteral_"
    end quotedLiteralP

    body function literalP % (treeP : treePT) : boolean
        result string@(ident.idents (tree.trees (treeP).name)) = "TXL_literal_"
    end literalP

    function listP (bracketedDescriptionTP : treePT) : boolean
        result string@(ident.idents (tree.trees (tree.kid1TP (tree.kid2TP (bracketedDescriptionTP))).name))
                = "TXL_listDescription_"
            or string@(ident.idents (tree.trees (tree.kid1TP (tree.kid2TP (bracketedDescriptionTP))).name))
                = "TXL_newlistDescription_"
    end listP

    function repeatP (bracketedDescriptionTP : treePT) : boolean
        result string@(ident.idents (tree.trees (tree.kid1TP (tree.kid2TP (bracketedDescriptionTP))).name))
                = "TXL_repeatDescription_"
            or string@(ident.idents (tree.trees (tree.kid1TP (tree.kid2TP (bracketedDescriptionTP))).name))
                = "TXL_newrepeatDescription_"
    end repeatP

    function list1P (bracketedDescriptionTP : treePT) : boolean
        result string@(ident.idents (tree.trees (tree.kid1TP (tree.kid2TP (bracketedDescriptionTP))).name))
                = "TXL_list1Description_"
            or string@(ident.idents (tree.trees (tree.kid1TP (tree.kid2TP (bracketedDescriptionTP))).name))
                = "TXL_newlist1Description_"
    end list1P

    function repeat1P (bracketedDescriptionTP : treePT) : boolean
        result string@(ident.idents (tree.trees (tree.kid1TP (tree.kid2TP (bracketedDescriptionTP))).name))
                = "TXL_repeat1Description_"
            or string@(ident.idents (tree.trees (tree.kid1TP (tree.kid2TP (bracketedDescriptionTP))).name))
                = "TXL_newrepeat1Description_"
    end repeat1P

    function optP (bracketedDescriptionTP : treePT) : boolean
        result string@(ident.idents (tree.trees (tree.kid1TP (tree.kid2TP (bracketedDescriptionTP))).name))
                = "TXL_optDescription_"
            or string@(ident.idents (tree.trees (tree.kid1TP (tree.kid2TP (bracketedDescriptionTP))).name))
                = "TXL_newoptDescription_"
    end optP

    function attrP (bracketedDescriptionTP : treePT) : boolean
        result string@(ident.idents (tree.trees (tree.kid1TP (tree.kid2TP (bracketedDescriptionTP))).name))
                = "TXL_attrDescription_"
    end attrP

    function seeP (bracketedDescriptionTP : treePT) : boolean
        result string@(ident.idents (tree.trees (tree.kid1TP (tree.kid2TP (bracketedDescriptionTP))).name))
                = "TXL_seeDescription_"
    end seeP

    function notP (bracketedDescriptionTP : treePT) : boolean
        result string@(ident.idents (tree.trees (tree.kid1TP (tree.kid2TP (bracketedDescriptionTP))).name))
                = "TXL_notDescription_"
    end notP

    function fenceP (bracketedDescriptionTP : treePT) : boolean
        result string@(ident.idents (tree.trees (tree.kid1TP (tree.kid2TP (bracketedDescriptionTP))).name))
                = "TXL_fenceDescription_"
    end fenceP

    function pushP (bracketedDescriptionTP : treePT) : boolean
        result string@(ident.idents (tree.trees (tree.kid1TP (tree.kid2TP (bracketedDescriptionTP))).name))
                = "TXL_pushDescription_"
    end pushP

    function popP (bracketedDescriptionTP : treePT) : boolean
        result string@(ident.idents (tree.trees (tree.kid1TP (tree.kid2TP (bracketedDescriptionTP))).name))
                = "TXL_popDescription_"
    end popP

end txltree
