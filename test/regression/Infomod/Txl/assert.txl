function typeAssertionStatement
            Statement [informationModelStatement_48]

    % This function is the beginning of a suite of rules that type-check
    % assertion statements.  It handles exactly one assertion statement
    % at a time.

    deconstruct Statement
        SId [opt statementIdentifier_3]
        aS [assertionStatement_106]
        sT [statementTerminator_22]

    match [repeat informationModelStatement_48]
        patterns [repeat informationModelStatement_48]

    construct dummy [assertionStatement_106]
        aS [check_solitary_Entity_Sentence patterns Statement]

    % If we got this far then it's an assertionStatement. Apply the rules
    % to type the assertion statement.

    construct dummy2 [assertionStatement_106]
        aS [check_solitary_Entity_Sentence patterns Statement]
            [removeSimpleSelExpr]
            [findDomainsClause Statement] % check for shared quant variable
            [type_such_that_Clause patterns Statement]
            [find_that_Clause patterns Statement]
            [find_atomicSentence patterns Statement]
            [type_optSelectedEntity patterns Statement]
end function

% =======================================================

rule check_solitary_Entity_Sentence
            patterns [repeat informationModelStatement_48]
            Statement [informationModelStatement_48]

    % Check to see that no atomic sentence consists of only an entity-variable
    % This must be checked in a rule because the syntax has to allow it 
    % for application of the declaration checking rules.  These rules reduce all
    % atomic sentences to a single variable to prevent indefinite rematch of
    % TXL pattern matches.  It's easier and faster  to reduce the item to an
    % 'illegal' syntactic form than to mark it.

    match[atomicSentence_119]
        eVN [entityVariableName_80]

    construct string1 [repeat tokenOrKey]
        '** ERROR***The solitary entity variable

    construct string2 [repeat tokenOrKey]
        occurs as an atomic sentence in the statement

    construct eM [errorMessage_S01]
        string1 eVN string2 Statement

    construct dummy1 [errorMessage_S01]
        eM [print]
end rule

% ===========================================================

function findDomainsClause
            Statement [informationModelStatement_48]

    % This function ensures that the quantification Variable also occurs in 
    % the assertion Statement governed by the quantifier.
    % aS is the scope of the quantification, which need not be the whole
    % Statement.  Statement is carried along for the error message.

    match [assertionStatement_106]
        ldc [list domainClause_217]
        ': cS [conditionalStatement_108]

    where
        cS [sharesQuantVariable Statement each ldc][not]
end function

% ===========================================================

function sharesQuantVariable
            Statement [informationModelStatement_48]
            dC [domainClause_217]

% Checks to see that the following scope contains the variable governed
% by the quantifier

    match [conditionalStatement_108]
        cS [conditionalStatement_108]

    deconstruct dC
        qI [quantifierIndication_229]
        eVN [entityVariableName_80]
        oSE [opt selectionExpression_224]

    where
        cS [containsSharedVariable eVN][not]

    % issues error message and returns if the test fails.

    construct string1 [repeat tokenOrKey]
        **WARNING**The quantification variable' ' 

    construct string2 [repeat tokenOrKey]
        ' ' does not occur in the part

    construct string3 [repeat tokenOrKey]
        occurring'in the statement

    construct eM [errorMessage_Q01]
        string1 eVN string2 cS string3 Statement

    construct output [errorMessage_Q01]
        eM [print]
end function

    % ==============================================================
rule type_such_that_Clause
            patterns [repeat informationModelStatement_48]
            Statement [informationModelStatement_48]

    % This rule types assertion statements inside 'such that' clauses
    % The 'such that' clause is then deleted.
    % Statement is carried along for the error message. . 

    replace[associatedEntityReference_416]
        rN [roleNames_98]
        eVN [entityVariableName_80]
        cI [criterionIndicator_662]
        qAS [assertionStatement_106]

    construct copy [assertionStatement_106]
        qAS 
        [checkSharedSelectVariable eVN Statement]
            [find_that_Clause patterns Statement]
            [find_atomicSentence patterns Statement]


    by
        rN eVN
end rule

% ===========================================================

function checkSharedSelectVariable
            eVN [entityVariableName_80]
            Statement [informationModelStatement_48]

    % This function ensures that the selection Variable also occurs in 
    % the assertion Statement governed by the selection 
    % (Entity such that ..).

    match [assertionStatement_106]
        qAS [assertionStatement_106]

    where
        qAS [containsSharedVariable eVN][not]

    % issues error message and returns if the test fails.

    construct string1 [repeat tokenOrKey]
        **WARNING**The variable

    construct string2 [repeat tokenOrKey]
        does not occur in the selection clause

    construct string3 [repeat tokenOrKey]
        'in the statement

    construct eM [errorMessage_C01]
        string1 eVN string2 qAS string3 Statement

    construct output [errorMessage_C01]
        eM [print]
end function

% ============================================================

rule find_atomicSentence
            patterns [repeat informationModelStatement_48]
            Statement [informationModelStatement_48]

    % This rule finds all the atomic sentences that match the syntax of the
    % rules invoked by the 'where' clause. These do all the type checking.
    % They act effectively as a case statement, since the various syntactic 
    % forms matched by the invoked rules are mutually exclusive. Since the 
    % 'where' rules act as logical 'or' one of them will succeed 
    % unless they are given as their scope the sentence 'AtomicSentence_ ,
    % which is the marker for the 'deleted' atomic sentence. When all such 
    % subrules fail for all sentences in the scope of this rule, this rule quits.
    replace[atomicSentence_119]
        aS [atomicSentence_119]

    where
        aS [type_eVN_aLP patterns Statement]
            [type_eVN_aLE patterns Statement]


    construct done [atomicSentence_119]
        'AtomicSentence_ 
    by
        done
% get rid of the atomic Sentence
end rule

% ============================================================

function type_eVN_aLP
            patterns [repeat informationModelStatement_48]
            Statement [informationModelStatement_48]

    % types atomic sentences of the form 
    % [optSelectedEntity_220][attributeLogicalPrimary_412]
    % since by now the only thing that's left of attributeLogicalPrimary_412
    % is attributeReference_414  

    match [atomicSentence_119]
        eVN [entityVariableName_80]
        aR [attributeReference_414]

    construct aR1 [attributeReference_414]
        aR [type_attributeReference eVN patterns Statement]
end function

% ============================================================

function type_eVN_aLE
            patterns [repeat informationModelStatement_48]
            Statement [informationModelStatement_48]

% Type-checks sentences of the form matched (i.e. with parens).

    match [atomicSentence_119]
        eVN [entityVariableName_80]
        '( aLE [attributeLogicalExpression_402]
        ') 

    construct aLE_1 [attributeLogicalExpression_402]
        aLE [type_aLE eVN patterns Statement]


end function

% ======================================================

rule type_aLE
            eVN [entityVariableName_80]
            patterns [repeat informationModelStatement_48]
            Statement [informationModelStatement_48]

    % This rule handles phrases of the form 
    %  [attributeLogicalExpression]  
    % The scope of this rule is the aLE associated with eVN

    replace[attributeReference_414]
        aR [attributeReference_414]

    where
        aR [rebuildAttribRef_1 eVN patterns Statement]
            [rebuildAttribRef_2 eVN patterns Statement]

% get rid of the aR

    by
        'Attribute_ 
end rule

% ============================================================

rule type_optSelectedEntity
            patterns [repeat informationModelStatement_48]
            Statement [informationModelStatement_48]

    % After everything else has been typechecked, there can be a residue of 
    % [optSelectedEntity_220] clauses. These can be of any of the forms that	
    % selectionExpression_224 can take.  Check them all.

    replace[optSelectedEntity_220]
        eVN [entityVariableName_80]
        sE [selectionExpression_224]

    where
        sE [type_selectionClause eVN patterns Statement]
            [type_identificationClause eVN patterns Statement]
            [type_classSelection eVN patterns Statement]
            [type_relExpression eVN patterns Statement]
    by
        eVN
end rule

% ============================================================

function type_selectionClause
            eVN [entityVariableName_80]
            patterns [repeat informationModelStatement_48]
            Statement [informationModelStatement_48]

    match [selectionExpression_224]
        sC [selectionClause_234]

    where
        sC [type_that_clause eVN patterns Statement]
end function

% ============================================================

function type_identificationClause
            eVN [entityVariableName_80]
            patterns [repeat informationModelStatement_48]
            Statement [informationModelStatement_48]

    match [selectionExpression_224]
        iC [identificationClause_301]
end function

% ============================================================

function type_classSelection
            eVN [entityVariableName_80]
            patterns [repeat informationModelStatement_48]
            Statement [informationModelStatement_48]

    match [selectionExpression_224]
        cSO [classSelectionOp_236]
        cE [classExpression_137]
end function

% ============================================================

function type_relExpression
            eVN [entityVariableName_80]
            patterns [repeat informationModelStatement_48]
            Statement [informationModelStatement_48]

    match [selectionExpression_224]
        rO [relationalOp_541]
        eE [entityExpression_420]
end function

% ============================================================

rule find_that_Clause
            patterns [repeat informationModelStatement_48]
            Statement [informationModelStatement_48]

    % This rule finds Entity Selections of the kind 
    % entityVariableName 'that (etc) attributeReference 
    % and sends them off to another rule
    % for checking against declarations, and then deletes the selection clause

    replace[associatedEntityReference_416]
        rN [roleNames_98]
        eVN [entityVariableName_80]
        sC [selectionClause_234]

    where
        sC [type_that_clause eVN patterns Statement]

    by
        rN eVN
end rule

% =======================================================

function type_that_clause
            eVN [entityVariableName_80]
            patterns [repeat informationModelStatement_48]
            Statement [informationModelStatement_48]

    match [selectionClause_234]
        pCI [pronounCriterionIndicator_662]
        aN [associationName_94]
        raER [repeat associatedEntityReference_416]

    where
        raER [contains_aES][not]

    construct dummy [attributeReference_414]
        aN raER

    where
        dummy [rebuildAttribRef_1 eVN patterns Statement]

end function

% ==============================================================

rule contains_aES

    % Checks for presence of [assocEntitySelection_417]
    % in the [repeat associatedEntityReference_416]
    % scope supplied in the where clause. Fails if there is 
    % no [associatedEntityReference_416] in the scope or if no 
    % [associatedEntityReference_416] has a [assocEntitySelection_417]
    % in it.

    match[associatedEntityReference_416]
        rN [roleNames_98]
        eVN [entityVariableName_80]
        aES [assocEntitySelection_417]
end rule

% ============================================================

function type_attributeReference
            eVN [entityVariableName_80]
            patterns [repeat informationModelStatement_48]
            Statement [informationModelStatement_48]

    match [attributeReference_414]
        aR [attributeReference_414]

    where
        aR [rebuildAttribRef_1 eVN patterns Statement]
            [rebuildAttribRef_2 eVN patterns Statement]
end function

% ===========================================================

function rebuildAttribRef_1
            eVN [entityVariableName_80]
            patterns [repeat informationModelStatement_48]
            Statement [informationModelStatement_48]

    % This rule changes the type [repeat associatedEntityReference_416]
    % to [repeat roleNameEntityVariableDeclarator_86]
    % This function handles attributes with an association name in them
    % The function picks up the roleName entityVariableName sets that belong
    % to the attribute and rebuilds them into an attribute of the type that
    % appears in a Pattern statement. At this point all the information
    % for the entity attribute combination is available, so this function 
    % invokes [buildSelectAtomicPattern ] to check the presence of an atomic
    % pattern that matches this combination.

    match [attributeReference_414]
        aN [associationName_94]
        raER [repeat associatedEntityReference_416]

    construct pEV [primeEntityVariable_79]
        eVN

    construct nul_rNEVN [repeat roleNameEntityVariableDeclarator_86]
        % (empty)

    construct new_rNEVN [repeat roleNameEntityVariableDeclarator_86]
        nul_rNEVN [buildRNEVN patterns Statement each raER]

    % Build the new format of the attribute and go see if we have an atomic
    % declaration that exactly matches it.

    construct sAPD [singleAttributePhraseDeclaration_82]
        aN new_rNEVN

    construct sAPD_1 [singleAttributePhraseDeclaration_82]
        sAPD [buildSelectAtomicPattern Statement pEV patterns sAPD]
end function

% ==============================================================

function rebuildAttribRef_2
            eVN [entityVariableName_80]
            patterns [repeat informationModelStatement_48]
            Statement [informationModelStatement_48]

    % This is just like rebuildAttribRef_1 except that there is no
    % association name in this format.

    match [attributeReference_414]
        aEVN [entityVariableName_80]
        raER [repeat associatedEntityReference_416]

    construct pEV [primeEntityVariable_79]
        eVN

    construct nul_rNEVN [repeat roleNameEntityVariableDeclarator_86]
        % (empty)

    construct new_rNEVN [repeat roleNameEntityVariableDeclarator_86]
        nul_rNEVN [buildRNEVN patterns Statement each raER]

    construct sAPD [singleAttributePhraseDeclaration_82]
        aEVN new_rNEVN

    construct sAPD_1 [singleAttributePhraseDeclaration_82]
        sAPD [buildSelectAtomicPattern Statement pEV patterns sAPD]
end function

% ==============================================================

function buildRNEVN
            patterns [repeat informationModelStatement_48]
            Statement [informationModelStatement_48]
            aER [associatedEntityReference_416]

    % This function extracts the roleName entityVariable name
    % pairs and appends them to the previous collection

    deconstruct aER
        rN [roleNames_98]
        eVN [entityVariableName_80]
        oAES [opt assocEntitySelection_417]

    construct rNEVN [roleNameEntityVariableDeclarator_86]
        rN eVN

    replace [repeat roleNameEntityVariableDeclarator_86]
        previous [repeat roleNameEntityVariableDeclarator_86]
    by
        previous [. rNEVN]
end function

% ===============================================================

function buildSelectAtomicPattern
            Statement [informationModelStatement_48]
            pEV [primeEntityVariable_79]
            patterns [repeat informationModelStatement_48]
            sAPD [singleAttributePhraseDeclaration_82]

    % Now build new atomic patterns from the pEV and sAP
    % and see if in the parse tree there is an atomic Pattern built by 
    % the function 'decomposePatterns' that matches it.
    % If therre is no such atomic Pattern, an error message is issued
    % to indicate that pEV sAP has not been declared in a Pattern.

    construct desiredPattern [informationModelStatement_48]
        'AtomPatt_ 'Pattern ': pEV '( sAPD ') '. 

    match [singleAttributePhraseDeclaration_82]
        sAPDummy [singleAttributePhraseDeclaration_82]

    where
        patterns [contains desiredPattern][not]

    construct undeclaredPhrase [entityVectorPattern_76]
        pEV sAPD

    construct string1 [repeat tokenOrKey]
        '** 'ERROR '** 'No 'pattern 'defined 'for 'phrase 

    construct string2 [repeat tokenOrKey]
        in the statement

    construct eM [errorMessage_P01]
        string1 undeclaredPhrase string2 Statement

    construct dummy1 [errorMessage_P01]
        eM [print]
end function

% ==============================================================

define errorMessage_S01
        [repeat tokenOrKey] [entityVariableName_80] [NL] [repeat tokenOrKey] [NL] [IN] [informationModelStatement_48] [EX]
end define

% ===========================================================

define errorMessage_Q01
        [repeat tokenOrKey] [entityVariableName_80] [repeat tokenOrKey] [NL] [IN] [conditionalStatement_108] [EX] [NL]
        [repeat tokenOrKey] [NL] [IN] [informationModelStatement_48] [EX] 
end define

define quote
        ' '  
end define

% ==========================================================

define errorMessage_C01
        [repeat tokenOrKey] [entityVariableName_80] [repeat tokenOrKey] [NL] [IN] [assertionStatement_106] [EX] [NL]
        [repeat tokenOrKey] [NL] [IN] [informationModelStatement_48] [EX] [NL] 
end define

% ==================================================================

define errorMessage_P01
        [repeat tokenOrKey] [entityVectorPattern_76] [repeat tokenOrKey] [NL] [IN] [informationModelStatement_48] [EX] 
end define

% ===============================================================


