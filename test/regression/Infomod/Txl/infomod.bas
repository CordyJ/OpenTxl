%_______________________________________________  
  
%Start Section 2.1  INFORMATION MODEL FORMAT  
% 
%_______________________________________________  
  
%%comments
%%    	'%
%%end comments

keys  
 
  
'a 'about 'above  'after 'all 'an 'and 'approximately 'approx 'are 'as
'ascending 'Assert_ 'Assume 'Assumed 'Assumption 
'at 'Attribute_ 
'AtomicSentence_
'before 'behind 'below 'beside 
'between 'but 'by
'cartesian 'class 'Class_ 'ClassName_  'CollPatt_ 'Comment 'complement
'contains 'corresponding 'corresponds 'CorrAP_ 
 'Default 'Defaults 
'depending 'depends 'Desired 'denoted 'denotes 'descending 'difference 
'each 'eight 'else 'end 'End 'entity 'Entity 'equal 'every 'exactly 
'exist 'exists 'export
'five 'four 'false 'first 'for  'from
'greater 
'Identifier 'Identifiers 'Ident_ 'if 'iff 'Ignore 'Ignored
'implied 'implies 'immediately 'import  'in
'includes 'Information  'intersection  'is
'last 'least 'less 
'model 'Model 'most 'member 'Ment_
'nd 'nine 'no 'not   
'one 'only 'or  'of 'on  'over
'Pattern 'percent 'Possible 'precedes 'proper 'properly 
'product 
'rd 'Required   
'second 'seven 'six 'smaller 'some 'st 'Statement_
'submodel 'Submodel  'subset 'succeeds 'such 
'th 'than 'that 'the 'there 'third 'three 'true 'two 'then 'to 
'under 'Unique 'union 'until 'Unment_
'xor
'where 'which 'who 'whose  'with 
'yes  
 
%The following verbs and prepositions are keywords so that the parser can  
%diagnose ill-formed statements within reasonable time. 
 
 'references 'reference 'owns 'registers 'holds

'owes 'pays 'consists 'consist 'lives 'dwells 'possess
'possesses  
'travel 'travelled 'travels 'manage 'manages 'go 'goes  'lie
'lies 'lay 'lays  
'hold 'holds 'buy 'buys 'sell 'sells 'run 'runs 'provide
'provides 
'controls 'control 'has 'have 'marry 'marries 'married 'die
'dies 
'born 'work 'works 'employ 'employs 'make 'makes 'made
'allow 'allows 'permit 
'permits 'has 'have 'been  
 
end keys  
%==================== END KEYWORDS ========================= 

compounds 
    <<  >> <->  -> <- <= >= =< => /= =/ // {0} *** ** .. <K_> <k_>
end compounds 
 
define preposition 
 
         'of | 'to  | 'from | 'after | 'before 
     | 'until | 'behind |'in     
        | 'at | 'above | 'below | 'beside 
        | 'between | 'over | 'under | 'about 
     | 'with | 'for | 'as |'on | 'by  
 
end define 
 
define verb 
 
'is |'are |'contains |'references |'reference |'owns |'registers
|'holds 
|'owes |'pays |'consists |'consist |'lives |'dwells |'possess
|'possesses  
|'travel |'travelled |'travels |'manage |'manages |'go |'goes  |'lie
|'lies 
|'lay |'lays  
|'hold |'holds |'buy |'buys |'sell |'sells |'run |'runs |'provide
|'provides 
|'controls |'control |'has |'have |'marry |'marries |'married |'die
|'dies 
|'born |'work |'works |'employ |'employs |'make |'makes
|'made |'allow 
|'allows |'permit 
|'permits |'has |'have |'been 
 
end define 
 
define statementIdentifier_3                       %3  
            '[ [tokenOrNumber_5] ']  
end define   

define tokenOrNumber_5                              %5
     [token] | [number] 
end define

define statementTerminator_22                      %22  
            '.    
end define  
  
%_______________________________________________  
%Required by TXL  
  
define program                                     %0  
            [informationModel_44]  
     [opt informationBase_20]
end define  
%_______________________________________________  
  
comments  
            /*   */ 
     ***
           
end comments
 
define informationBase_20                   % 20
          [NL][NL][informationBaseDeclaration_22][NL][NL] 
            [repeat factStatement_24]  
           [NL] [endBaseDeclaration_23]  
end define  

define informationBaseDeclaration_22         % 22
            [informationBaseIndicator_673a]  
            [informationModelName_51]  
            [statementTerminator_22]  
end define  

define endBaseDeclaration_23               % 23
     [endIndicator_674]     
     [opt informationBaseIndicator_673a]  
            [statementTerminator_22]  
end define  
  

define factStatement_24           % 24
                 [opt statementIdentifier_3]
                 [commentStatement_41] 

% A TXL rule should check to see that fact statements are fully instantiated.
% A fact statement is just an assertion rule without quantifiers,
% so that fact statements must have all variables explicitly bound.
     
      |     [opt statementIdentifier_3]
                 [assertionStatement_106 ]
                 [statementTerminator_22] [KEEP][NL][NL]   
end define 

     
define commentStatement_41                        %41
      'Comment ': [stringlit]
      [statementTerminator_22][KEEP]  [NL][NL]

end define
 
define specialChar_43                      %43
           '+ | '- | '* | '/ | '**
      |    '< | '> | '= | '<= | '>=
      |    '<< |  '>> |  '-> | '<- | '<-> 
      |    '=< | '=> | '/= | '=/ | '// | '{0}
      |    '.. | '{  | '} | '[ | '] | '( | ') | ': | ', 
end define

define informationModel_44                         %44  
            [informationModelDeclaration_45]    [NL][NL] 
            [repeat informationModelStatement_48]  
            [endModelDeclaration_45]  
end define  
  
define informationSubModel_44                         %44  
            [informationSubModelDeclaration_45]    [NL][NL] 
            [repeat informationSubModelStatement_48]  
            [endModelDeclaration_45]  
end define  
  
  
define informationModelDeclaration_45              %45  
            [informationModelIndicator_673]  
            [informationModelName_51]  
            [statementTerminator_22] [KEEP] 
end define  
  
define informationSubModelDeclaration_45              %45  
            [informationSubModelIndicator_675]  
            [informationModelName_51]  
            [statementTerminator_22]  
end define  
 
 
define endModelDeclaration_45                      %45  
            [endIndicator_674]  
            [opt informationModelIndicator_673]  
            [opt informationModelName_51]   
            [statementTerminator_22] [KEEP] 
end define  
  
define informationModelStatement_48                %48
           
           [opt statementIdentifier_3]
                 [commentStatement_41] 

      |         [opt typePrefix_48] 
                [opt statementIdentifier_3] 
                 [entityVectorPatternSpecification_75]
 
      |     [opt statementIdentifier_3]
                 [informationRule_105]


     |     [opt statementIdentifier_3]
          [informationSubModel_44]  [NL][NL] 
end define  
  
define typePrefix_48                                 % 48
      'Ment_ | 'Unment_ | 'AtomPatt_ | 'CollPatt_
    | 'Assert_ | 'Ident_ | 'Reqd_ | 'Corr_
end define

define informationSubModelStatement_48                %48  
            [opt statementIdentifier_3]
          [commentStatement_41]
 
      |     [opt statementIdentifier_3] 
            [entityVectorPatternSpecification_75]       
          
 
      |     [opt statementIdentifier_3]
            [informationRule_105] [NL][NL]
 
      |     [opt statementIdentifier_3] 
                 [exportStatement_60]       
          [NL][NL] 
end define  
 
define informationModelName_51                     %51  
            [entityId]
     |   '<MN_> [entityId] '<mn>
end define  
 
define entityId                                     %52  
            [upperlowerid] %**** This is a capitalized Id  
end define  
%__________________________________________________
% Import and Export Statements, used in submodels
%__________________________________________________

define exportStatement_60                    %60 
     [exportWords_680][informationModelName_51]
     '{
     [list entityVectorPattern_76]
     '}
     [statementTerminator_22]
end define

define importStatement_60                    %60 
     [importWords_681][informationModelName_51]
     '{
     [list entityVectorPattern_76]
     '}
     [statementTerminator_22]

end define

%_______________________________________________  
% Entity Vector Pattern  Specification
%_______________________________________________  
  
define entityVectorPatternSpecification_75         %75  
        [IN][opt domainsClause_216]
            [patternWords_666]  
            ':  
           [NL][IN] [entityVectorPattern_76]
           [statementTerminator_22][KEEP]  [NL][NL]
        [EX][EX]
end define  
  

define entityVectorPattern_76                      %76  
            [primeEntityVariable_79][attributeVector_76]
end define  
  
define attributeVector_76                          %76  
          [NL] [IN]
      '( [list attributePhraseDeclaration_81]
      [NL][EX]  ')  
      |     [attributePhraseDeclaration_81]  
end define  
  
define primeEntityVariable_79                      %79
             'Entity
      |    'Class
      |    [informationModelName_51] '.
           [entityVariableName_80]
      |    [entityVariableName_80]

      |    '<PEV_>  [entityVariableName_80]'<pev_>
end define  
  
define entityVariableName_80                           %80  
             [entityId][repeat  '#]
       |     '<PEV_>  [entityId][repeat  '#] '<pev_>
       |     '<EV_>  [entityId][repeat  '#] '<ev_>
end define
   
define attributePhraseDeclaration_81              %81  
           [NL]  '{ [singleAttributePhraseDeclaration_82] '} 
       |   [NL] [singleAttributePhraseDeclaration_82] 
end define

define singleAttributePhraseDeclaration_82               %82
            [associationName_94]   
                [repeat roleNameEntityVariableDeclarator_86]  
      |     [entityVariableDeclarator_87]  
                [repeat roleNameEntityVariableDeclarator_86]
      |         [simpleAttributePhrase_129]
end define   
  
define roleNameEntityVariableDeclarator_86     %86            
       [roleNames_98]  [entityVariableDeclarator_87] 
end define 

 
define entityVariableDeclarator_87                   %87  
            '{ [entityVariableName_80] '}  
      |     '<< [entityVariableName_80]  '>> 

end define  
  
define associationName_94                          %94
            [verbWord_95] [repeat compoundVerbWord_96]
end define
 
define verbWord_95                                     %95 
            [verb] | [lowerid]
end define 
 
  
define compoundVerbWord_96 
            '_ [verbWord_95] 
       |    '- [verbWord_95] 
end define 

define roleNames_98                                 %98
            [opt 'RoleName_ ] [repeat roleId_98]
end define

 
define roleId_98  
            [prepWord_99] [repeat compoundPrepWord_100] 
end define 
 
define prepWord_99                                    %99 
            [preposition] 
       |    [lowerid]    
end define  
 
define compoundPrepWord_100                     %100 
            '_ [prepWord_99] 
       |    '- [prepWord_99] 
end define 
  
%_______________________________________________  
%End Section 3.4  
%***********************************************  
%Chapter 4         INFORMATION RULES  
%************************************************  
  
%_________________________________________________  
%Start Section     4.1 Information Rules  
%_______________________________________________  
  
define informationRule_105                                %105
                 
            [opt domainsClause_216]             
           [desiredRule_201]  
           [statementTerminator_22] [KEEP]   [NL][NL]
 
       |   [opt domainsClause_216]             
	   [possibleRule_203]  
           [statementTerminator_22] [KEEP]   [NL][NL]
 
       |   [opt domainsClause_216]             
	   [defaultRule_204] 
           [statementTerminator_22] [KEEP]   [NL][NL]
 
       | [opt domainsClause_216]             
	 [assumedRule_204] 
         [statementTerminator_22] [KEEP]   [NL][NL]
 
       |   [opt domainsClause_216]             
	    [ignoredRule_204] 
            [statementTerminator_22] [KEEP]   [NL][NL]
 
       |  [opt domainsClause_216]             
	  [entityIdentifiersRule_205]  
          [statementTerminator_22] [KEEP]   [NL][NL]
 
       |      [opt domainsClause_216]             
	      [uniqueAttributesRule_209]  
              [statementTerminator_22] [KEEP]   [NL][NL]
 
       |   [opt domainsClause_216]             
	[requiredAttributesRule_212]  
        [statementTerminator_22] [KEEP]   [NL][NL]
 
       |    [opt universalDomainsClause_216]  
              [ruleOfCorrespondence_191]  
              [statementTerminator_22] [KEEP]   [NL][NL]
 
       |     [classDefinition_137]  
             [statementTerminator_22] [KEEP]   [NL][NL]
 
       |     [assertionStatement_106]  
             [statementTerminator_22] [KEEP]   [NL][NL]
 

%      |     [functionDefinition_170]


end define  
  
%_______________________________________________  
%End Section 4.1  
%Start Section    4.2 Rule Sentences  
%_______________________________________________   
% 
define assertionStatement_106                       %106
         [opt domainsClause_216]                   
         [conditionalStatement_108]         
end define

define conditionalStatement_108
         [IN][sentence_110]    
         [repeat condOpSentence_109][EX] 
end define 
 
define condOpSentence_109               %109
           [EX][NL] [conditionalOp_516] [NL][IN]
            [sentence_110]  
end define 
 
define sentence_110                                %110  
        [logicalExpression_113]
      [repeat transOpLogExpr_111] 
end define  
  
define transOpLogExpr_111                          %111  
           [NL] [transitionOp_511][NL][logicalExpression_113]  
end define  
  
define logicalExpression_113                       %113  
           [IN] [logicalTerm_115] [repeat orOpLogicalTerm_113] [EX] 
end define  
  
define orOpLogicalTerm_113  
           [NL] [EX][alternativeOrOp_522][IN][NL][logicalTerm_115]  
end define  
  
define logicalTerm_115                  %115  
            [IN][logicalFactor_116]
          [repeat andOpLogicalFactor_115] [EX]
end define  
  
define andOpLogicalFactor_115  
           [NL][EX] [andOp_525][IN][NL][logicalFactor_116]  
end define  
  
define logicalFactor_116                           %116  
            [opt notOp_526][logicalPrimary_118]  
end define  
  
define logicalPrimary_118                       %118  
            '( [assertionStatement_106] ')            
      |      [entityTypeSentence_123]    
      |      [attributeIdentitySentence_124] 
      |      [atomicSentence_119]
end define 
 
define atomicSentence_119                          %119 

          [optSelectedEntity_120][opt situationIndication_122]
      |    [entityLogicalExpression_419] 
end define 

define optSelectedEntity_120                           %120
          [entityVariableName_80][opt entitySelector_121]

end define
        
define  entitySelector_121                       % 121
          ', [selectionClause_234] ',
      |    [simpleEntitySelection_225]
end define 

% Don't collapse this next non-terminal.  It's here for the 
% layout codes [NL] etc.

define situationIndication_122                      %122 
            [IN] [NL][attributeLogicalExpression_402][NL][EX]  
end define  
 
define entityTypeSentence_123                     %123  
            [optSelectedEntity_120]
            [typeIndicator_644]  
            [primeEntityVariable_79]  
 end define  

define attributeIdentitySentence_124                     %124  
            '( [primeEntityVariable_79] 
            [simpleAttributePhrase_129]  ') 
            [equalOp_544]  
            '( [primeEntityVariable_79] 
            [simpleAttributePhrase_129]  ') 
end define  

define entityAttributePhrase_125                       %125
            [primeEntityVariable_79]
      '( [list simpleAttributePhrase_129+] ') 
      |     [primeEntityVariable_79]
          [simpleAttributePhrase_129] 
end define

define simpleAttributePhrase_129                        %129
            [associationName_94]   
                [repeat roleNameEntityVariableName_130]  
      |     [entityVariableName_80]  
                [repeat roleNameEntityVariableName_130]  
end define  
  
define roleNameEntityVariableName_130               %130 
           [roleNames_98] [entityVariableName_80] 
end define 
%__________________________________________________
%Class Definition 
%__________________________________________________

define classDefinition_137                       %137  
            [entityVariableName_80]  
            [equalOp_544]  
            [classExpression_137]
       |    'Class_ [entityVariableName_80] %type rules   
end define  
 
define classSpecification_137                     %137 
            [entityVariableName_80] [classSpecificationOp_527]

               [classExpression_137] 
end define 
 
define classExpression_137                  %137 
            [classTerm_140] 
            [repeat unionDiffOpClassTerm_138] 
end define 
 
define unionDiffOpClassTerm_138               %138 
            [unionDiffOp_139] [classTerm_140] 
end define 
 
define unionDiffOp_139                          %139 
            [unionOp_534] 
      |     [differenceOp_533] 
end define 
define classTerm_140                   %140 
            [classFactor_142] 
            [repeat intersectOpClassFactor_141] 
end define 
 
 
define intersectOpClassFactor_141              %141 
            [intersectionOp_535][classFactor_142] 
end define 
 
define classFactor_142                %142 
            [complementOp_536][classExpon_143] 
      |     [classExpon_143] 
end define 
 
define classExpon_143                %143 
            [classPrimary_145] [repeat cartEntPrim_144] 
end define 
 
define cartEntPrim_144               %144 
            [cartesianOp_532][classPrimary_145] 
end define 
 
define classPrimary_145                 %145
           '( [classExpression_137] ')
      |    [opt 'AtomicClass_] [atomicClass_146]
end define

define atomicClass_146                           %146 
            [emptyClassConstant_636] 
      |     [classEnumeration_147] 
      |     [entityVariableName_80]
end define 
 
define classEnumeration_147            %147 
            '{ [list memberIndication_151] '}

      |     '<< [list memberIndication_151+] '>>   
 
      |      '<< [orderingIndication_563] 
             [optSelectedEntity_120]
            ': [list memberIndication_151+] '>>

end define 
  
define memberIndication_151                             %151
            [optSelectedEntity_220]
      |     [classExpression_137] 
end define 
 
 
%__________________________________________________
%Function Invocation
%__________________________________________________

define functionReference_160               %160
             [functionName_165] ':
             '( [list sentence_110] ')
      |    [functionName_165] ':
             '( [list entityExpression_420] ')
      |    [functionName_165] ':
             '( [list classExpression_137] ')
end define

define functionName_165                     %165
             [entityVariableName_80]
end define

%__________________________________________________
%Function Definition
%__________________________________________________

define functionDefinition_170               %170
      'Function:
             [functionName_165] ':
      '( [list functionArguments_185] ')
         '= '{ [functionBody_176] '}
end define

define functionBody_176                        %176
        [repeat functionStatement+]
end define

define functionStatement                 %177
        
        'if [entityLogicalExpression_419] 
         'then [entityExpression_420]
end define

define functionArguments_185                      %185
            [entityVariableName_80] [typeIndicator_186]
end define

define typeIndicator_186                            %186
            'Entity
     |      'Class
     |      'String
     |      'Boolean
     |      'Number
end define
      
%_______________________________________________  
%Rule of Correspondence  
%_______________________________________________  
  
define ruleOfCorrespondence_191          %191  
            [correspondingAttributePhrase_192]  
            [repeat corrOpCorrAttribute_191+]  
end define  
  
define corrOpCorrAttribute_191                     %191  
            [correspondingOp_518]  
            [correspondingAttributePhrase_192]  
end define  
  
define correspondingAttributePhrase_192      %192   
            [primeEntityVariable_79] [corrAttrExpr_193] 
             
end define  

define  corrAttrExpr_193                           %193
           '(  [corrAttrExpr_193 ]  ') 

       |    [simpleAttributePhrase_129] 
           [repeat orOpSimpleAttributePhrase_195]
end define 

define  orOpSimpleAttributePhrase_195                   %195 
            [alternativeOrOp_522]  
            [simpleAttributePhrase_129] 
end define  
  
%______9________________________________________  
%End Section   4.6  
%Start Section     4.8   Desired Rule  
%_______________________________________________  
define desiredRule_201                  %201  
            [desiredIndicator_668] ':   
            [sentence_110]  
end define  
  
%_______________________________________________  
%End Section   4.8  
%Start Section     4.9   Possible Rule  
%_______________________________________________  
  
define possibleRule_203                  %203  
            [possibleIndicator_667] ':  
            [sentence_110]  
end define  
  
%_______________________________________________  

%Section 5.6  Default Rule

define defaultRule_204                               %204
           [defaultIndicator_678] ': 
           [sentence_110][statementTerminator_22]
end define

define assumedRule_204                         %204  
            [assumeIndicator_642] ': [sentence_110]  
end define  
  
define ignoredRule_204                         204  
            [ignoreIndicator_643] ':[sentence_110]  
end define  
 

%______________________________________________
%Start Section 4.10 Entity Identifier  
%_______________________________________________  
  
define entityIdentifiersRule_205                  %205  
            [entityIdentifierIndicator_669] ':  
            [list entityAttributePhrase_125+]  
end define  
  
%_______________________________________________  
  %End Section   4.10  
  %Start Section 4.11 Unique Attributes  
%_______________________________________________  
  define uniqueAttributesRule_209                  %209  
            [uniqueIndicator_670] ':  
            [list entityAttributePhrase_125+]  
end define  
  
%_______________________________________________  
%End Section   4.11  
%Start Section 4.12 Required Attributes  
%_______________________________________________  
  
define requiredAttributesRule_212                  %212  
            [IN][requiredIndicator_671] ':  
            [list requiredAttributesSpecification_212+] 
          [EX]
end define 
 
define requiredAttributesSpecification_212         %212 
            [NL][IN][primeEntityVariable_79]  
         '( [list requiredAttributeExpression_213+][NL]') [EX] 
      |       [NL][IN][primeEntityVariable_79]  
          [ requiredAttributeExpression_213][NL] [EX] 
 
end define  
  
define requiredAttributeExpression_213              %213  
            [requiredAttributeTerm_214]  
          [repeat orOpRequiredAttributeTerm_213]
end define  
  
define orOpRequiredAttributeTerm_213                  %213  
           [NL] [alternativeOrOp_522]  
           [NL] [requiredAttributeTerm_214]  
end define  
  
define requiredAttributeTerm_214                      %214  
           [IN] [requiredAttributeFactor_215][EX]
            [repeat andOpRequiredAttributeFactor_214]  
end define  
  
define andOpRequiredAttributeFactor_214                %214 
           [NL] [IN][andOp_525]  
           [NL] [requiredAttributeFactor_215][EX]  
end define  
  
define requiredAttributeFactor_215                    %215  
            'Attribute_
      |     '( [NL] 
          [requiredAttributeExpression_213][NL] ')  
      |     [simpleAttributePhrase_129]  
end define  

  
%**************************************************

 
  
%Start Chapter 5 ENTITY SELECTIONS  
  
%**************************************************
 
  
  
%_______________________________________________  
%Section     5.1 Domain Clauses  
%_______________________________________________  
  
define domainsClause_216                           %216  
            [list domainClause_217] ': [NL][NL][EX] 
end define
  
define universalDomainsClause_216                   %216  
            [list universalDomainClause_218] ': [NL]  
end define  
  
define domainClause_217                          %217
           [NL] [quantifierIndication_229]
          [optSelectedEntity_220]
end define

define universalDomainClause_218                   %218  
           [universalQuantifier_647]
        [optSelectedEntity_220]
end define  

  
define optSelectedEntity_220                           %220
          [entityVariableName_80][opt selectionExpression_224]
end define
        
define selectionExpression_224                %224 
          ', [selectionClause_234]
       |    [simpleEntitySelection_225]
end define 

define simpleEntitySelection_225                            %225 
           [atomicIdentification_302] 
      |    [classSelectionOp_236] [classExpression_137]  
      |    [relationalOp_541] [entityExpression_420]
end define  
  
define quantifierIndication_229                    %229
             [universalQuantifier_647]
      |      [existentialQuantifier_650]
      |      [uniquenessQuantifier_652]
      |      [specificExistenceQuantifier_654]
      |      [enumeratedQuantifier_655]
end define
 
%============================================
%
%          Entity Selection and Identification 
 
 
define selectionClause_234                         %234  
          [IN][NL]  [criterionIndicator_662]
          [IN][assertionStatement_106][EX][EX]
      |    [NL][IN] [pronounCriterionIndicator_662] 
                    [attributeLogicalExpression_402]
end define
 
define classSelectionOp_236 
            [membershipOp_537] 
      |     [subsetOp_528]     
      |     [properSubsetOp_530] 
      |     [reverseSubsetOp_529] 
end define 
 
define precisionSpecification_237                  %237  
            [approximatelyIndicator_657]  
               [equalOp_544][percentageIndication_569]  
      |     [approximatelyIndicator_657][numericIndication_564] 

end define  
 
define identificationClause_301                   %301 
            [atomicIdentification_302]
      |     [compoundIdentification_303]
end define

define atomicIdentification_302                     %302
           [entityConstant_318]    
      |    [denotationOp_510][stringlit]  
      |    [subscript_302]
end define
 
define subscript_302                                 %302
           '[ [list entityExpression_420+] '] %must be integer
end define       


define compoundIdentification_303             %303
           [classEnumeration_147] 
      |    [specificIndicator_653][identifierSelectionClause_304]
      |    [identifierSelectionClause_304]
end define 

define identifierSelectionClause_304                %304
           [selectionClause_234]      %must be type checked 
end define

define entityConstant_318                          %318 
            [stringlit] 
      |     [numericConstant_563] 
end define 
 
%_______________________________________________  
%End Section 5.1  
%________________________________________________  
%***********************************************  
  
%Chapter 6 EXPRESSIONS  
  
%***********************************************  
  
  
%_______________________________________________  
% 
%Start Section 6.5 Attribute  Expressions  
%_______________________________________________  
  
define attributeLogicalExpression_402                     %402  
            [attributeLogicalTerm_406]  
            [repeat orOpAttributeLogicalTerm_404]  
end define  
  
define orOpAttributeLogicalTerm_404               %404 
 
           [NL] [alternativeOrOp_522] [NL][attributeLogicalTerm_406]  
end define  
  
define attributeLogicalTerm_406                  %406  
            [attributeLogicalFactor_410]  
            [repeat andOpAttributeLogicalFactor_408]  
end define  
  
define  andOpAttributeLogicalFactor_408                %408 
           [NL] [andOp_525][NL] [attributeLogicalFactor_410]  
end define  
  
define attributeLogicalFactor_410                %410  
            [opt notOp_526] [attributeLogicalPrimary_412]  
end define  
  
define attributeLogicalPrimary_412                     %412  
          [IN]'( [NL][attributeLogicalExpression_402][NL] ')[EX]
      |      [attributeReference_414][opt knownUnk_418]  
end define  

define attributeReference_414                         %414
           [associationName_94]
           [repeat  associatedEntityReference_416]
           [opt finalAssociatedEntityReference_416]

      |    [entityVariableName_80]
          [opt assocEntitySelection_417]
          [repeat associatedEntityReference_416]
          [opt finalAssociatedEntityReference_416]

end define  

define associatedEntityReference_416                       %416 
           [roleNames_98] [entityVariableName_80] 
          [opt assocEntitySelection_417] 
end define 

define  finalAssociatedEntityReference_416
           [roleNames_98] [entityVariableName_80] 
          [opt finalAssocEntitySelection_417] 
end define 

define  assocEntitySelection_417 
          ',  [selectionClause_234] ',  % Two commas
      |    [simpleEntitySelection_225]
end define

define  finalAssocEntitySelection_417              %417 
          ',  [selectionClause_234]     % one comma
      |    [simpleEntitySelection_225]
end define

 
define knownUnk_418                               %418 
             [knownIndicator_640] 
      |      [unknownIndicator_641] 
end define 
 
%_______________________________________________ 
%Start Section 5.2 Entity Expressions 
%_______________________________________________ 

define entityLogicalExpression_419                %419
           [entityExpression_420]
            [relationalOp_541] 
            [entityExpression_420]
      |    [classExpression_137]  
            [classSelectionOp_236]       
            [classExpression_137]  
end define

define entityExpression_420               %420 
            [entityTerm_426] 
            [repeat additionOpEntityTerm_422] 
end define 
 
define additionOpEntityTerm_422               %422 
            [additionOp_424] [entityTerm_426] 
end define 
 
define additionOp_424                          %424 
            [addSubtOp_554_555] 
      |     [concatenationOp_562] 
end define 
 
define entityTerm_426                   %426 
            [entityFactor_430] 
            [repeat multOpEntityFactor_428] 
end define 
 
 
define multOpEntityFactor_428              %428 
            [multDivOp_556_557] 
            [entityFactor_430] 
end define 
 
define entityFactor_430                %430 
            [opt negationOp_430] [entityExpon_432] 
end define 
 
define negationOp_430                  %430 
            [negativeSign_561] 
end define 
 
define entityExpon_432                %432 
            [entityPrimary_434] [repeat exponEntPrim_432] 
end define 
 
define exponEntPrim_432               %432 
            [exponentiationOp_558] 
            [entityPrimary_434] 
end define 
 
define entityPrimary_434                 %434 
          '( [entityExpression_420] ') 
      |    [entityTerminal_435]
      |    '( [entityVariableName_80]
          [selectionExpression_224]
') 
end define 

define entityTerminal_435                   %435
           [entityConstant_318] 
      |    [subrange_661] 
      |    [functionReference_160]
      |    [entityVariableName_80] 
      
end define 
%_______________________________________________ 
%End Section 5.3 
 
%End Section 6.5 
%_______________________________________________ 
%********************************************** 
 
%Chapter 7  Keywords, Constants and Operators 
 
%********************************************** 
 
%______________________________________________ 
%Start Section    7.3 Operators 
%_______________________________________________ 
 
define denotationOp_510                            %510 
         [denotationOp_510a ]
       | '<K_>[denotationOp_510a ]'<k_>
end define 

define denotationOp_510a                            %510a 
          'denoted  'by       
end define 
 
define transitionOp_511         %511 
             [transitionOp_511a]
      |      '<K_>[transitionOp_511a]'<k_>
end define 

define transitionOp_511a         %511a 
            [precedingOp_512] 
      |     [predecessorOp_513] 
      |     [succeedingOp_514] 
      |     [successorOp_515] 
end define 
 
define precedingOp_512           %512 
             'precedes
end define 
 
define predecessorOp_513             %513 
            'immediately [precedingOp_512] 
end define 
 
define succeedingOp_514           %514 
             'succeeds  
end define 
 
define successorOp_515           %515 
             'immediately [succeedingOp_514] 
end define 
 
define conditionalOp_516            %516 
                 [conditionalOp_516a]
           |     '<K_>[conditionalOp_516a] '<k_>
     end define 

define conditionalOp_516a            %516a
            [biconditionalOp_517] 
      |     [implicationOp_520] 
      |     [reverseImplicationOp_521] 
      |     [dependingOp_519]  
end define 
 
define biconditionalOp_517           %517 
              'if 'and  'only  'if  
      |      'iff 
      |      '<-> 
end define 
 
define correspondingOp_518            %518 
            [correspondingOp_518a]
      |    '<K_>  [correspondingOp_518a] '<k_> 
      |     [biconditionalOp_517] 
end define 

define correspondingOp_518a            %518a 
           'corresponds  
      |    'corresponds 'to
end define 

define dependingOp_519            %519 
            [dependingOp_519a]
      |    '<K_>  [dependingOp_519a] '<k_>
      |     [biconditionalOp_517] 
end define 

define dependingOp_519a            %519a 
           'depends  'on 
end define 
 
define implicationOp_520            %520 
           [implicationOp_520a] 
      |     '<K_> [implicationOp_520a] '<k_> 
end define  

define implicationOp_520a            %520a 
            'implies 
      |     '-> 
end define 

define reverseImplicationOp_521             %521 
             [reverseImplicationOp_521a] 
      |     '<K_> [reverseImplicationOp_521a]  '<k_> 
end define 

 
define reverseImplicationOp_521a             %521a 
            'implied 'by 
      |     '<- 
end define 

define alternativeOrOp_522           %522
              [alternativeOrOp_522a]
       |      [orOp_524] 
       |      '<K_>[alternativeOrOp_522a]'<k_>
end define 

define alternativeOrOp_522a          %522a 
            'or 'else 
       |    'xor
end define 
 
define orOp_524        %524 
          [orOp_524a]
     |    '<K_> [orOp_524a] '<k_>
end define
 
define orOp_524a       %524a
            'or
      |     '| 
end define 

define  andOp_525        %525 
               [ andOp_525a]
       |      '<K_>[andOp_525a ]'<k_>

end define

 
define andOp_525a        %525a 
            'and 
      |     '& 
end define 

define  notOp_526        %526 
               [notOp_526a ]
       |      '<K_>[ notOp_526a]'<k_>

end define

 
define notOp_526a        %526a 
            'not
      |     '~ 
end define 

define classSentenceOp_527            %527 
           [classSentenceOp_527a] 
       |   '<K_>[classSentenceOp_527a] '<k_> 
end define 
 
define classSentenceOp_527a            %527a 
            [subsetOp_528] 
      |     [reverseSubsetOp_529] 
      |     [properSubsetOp_530] 
      |     [reverseProperSubsetOp_531] 
end define 

define classSpecificationOp_527         %527
               [classSpecificationOp_527a ]
       |      '<K_>[classSpecificationOp_527a ]'<k_>

end define

 
define classSpecificationOp_527a         %527a 
            [classSentenceOp_527] 
      |     [membershipOp_537] 
      |     [reverseMembershipOp_540] 
end define 
 
define subsetOp_528           %528 
%    |     [subsetSign]    not defined in ASCII 
             'subset   
end define 
 
define reverseSubsetOp_529            %529 
            'includes 
%   |     [reverse SubsetOpSign] 
end define 
 
define properSubsetOp_530             %530 
          'proper  'subset  
 %   |     [properSubsetOpSign] 
end define 
 
define reverseProperSubsetOp_531               %531 
             'properly  'includes  
end define 

define  cartesianOp_532          %532 
               [ cartesianOp_532a]
       |      '<K_>[ cartesianOp_532a]'<k_>

end define

 
define cartesianOp_532a          %532a 
             'cartesian  'product
%    |      [cartesianProductSign] 
end define 
 
 
define differenceOp_533          %533 
            '- 
end define 

define unionOp_534         %534 
               [unionOp_534a ]
       |      '<K_>[unionOp_534a ]'<k_>

end define

 
define unionOp_534a         %534a 
             'union  
%    |     [unionSign] 
end define 

define intersectionOp_535           %535
               [intersectionOp_535a ]
       |      '<K_>[ intersectionOp_535a]'<k_>

end define

 
define intersectionOp_535a           %535a 
            'intersection 
%    |     [intersectionSign] 
end define 

define complementOp_536             %536 
               [complementOp_536a ]
       |      '<K_>[complementOp_536a ]'<k_>

end define

 
define complementOp_536a             %536a 
            [notOp_526] 
      |     'complement
end define 
 
define  membershipOp_537             %537                        
               [membershipOp_537a ]
       |      '<K_>[membershipOp_537a ]'<k_>
end define

define membershipOp_537a             %537a 
            [belongsOp_538] 
      |     [notOp_526] [belongsOp_538] 
end define 
 
define belongsOp_538           %538 
             'member   
%    |      [membershipSign] 
end define 
 
define  reverseMembershipOp_540               %540
               [reverseMembershipOp_540a ]
       |      '<K_>[ reverseMembershipOp_540a]'<k_>
end define

 
define reverseMembershipOp_540a                %540a 
            'contains 
end define 

define  classSelectionOp_540                   %540 
               [classSelectionOp_540a ]
       |      '<K_>[ classSelectionOp_540a]'<k_>

end define

 
define classSelectionOp_540a                   %540a 
             'member 
end define 

define relationalOp_541                      %541 
               [ relationalOp_541a]
       |      '<K_>[ relationalOp_541a]'<k_>
end define

 
define relationalOp_541a                      %541a 
            [equalOp_544] 
      |     [notEqualOp_545] 
      |     [greaterOp_546] 
      |     [greaterEqualOp_547] 
      |     [lessOp_548] 
      |     [lessEqualOp_549]
end define 

define  equalOp_544         %544                      
               [equalOp_544a ]
       |      '<K_>[ equalOp_544a]'<k_>
end define


define equalOp_544a         %544a 
            '= 
      |      'equal  
end define 
 
define notEqualOp_545          %545 
             'not  'equal  
      |      'not  '= 
%    |     [notEqualSign] 
end define 
 
define greaterOp_546          %546 
            '> 
      |     'greater  'than 
      |      'after  
end define 
 
define greaterEqualOp_547            %547 
            '>= 
      |      'greater  'or 'equal  
end define 
 
define lessOp_548         %548 
            '< 
      |      'before 
      |      'less 'than  
end define 
 
define lessEqualOp_549           %549 
            '<= 
      |      'until  
      |      'less  'or  'equal 
end define 
 

define  nextHigherOp_552           %552                      
               [ nextHigherOp_552a]
       |      '<K_>[nextHigherOp_552a ]'<k_>
end define

define nextHigherOp_552a           %552a 
             'next  'greater   
      |      'immediately  'after
end define 

define   nextLowerOp_553             %553                     
               [nextLowerOp_553a ]
       |      '<K_>[nextLowerOp_553a ]'<k_>
end define
 
define nextLowerOp_553a             %553a 
             'next 'smaller  
      |      'immediately  'before 
end define 
 
define addSubtOp_554_555               %554_555 
            '+ 
      |     '- 
end define 
 
define multDivOp_556_557               %556_557 
            '* 
      |     '/ 
end define 
 
define exponentiationOp_558             %558 
            '** 
end define 
 
define posNegIndication_559             %559 
            '+ 
      |     '- 
end define 
 
define negativeSign_561          %561 
            '- 
end define 
 
define posSign_562        %562 
            '+ 
end define 
 
define concatenationOp_562            %562 
            '// 
end define 
 
define    orderingIndication_563                %563                     
               [orderingIndication_563a ]
       |      '<K_>[orderingIndication_563a ]'<k_>
end define

define orderingIndication_563a               %563a 
           'ascending  
     |     'descending 
end define 
 
%_______________________________________________ 
%End Section 7.3 
%Start Section 7.4 Constants 
%_______________________________________________ 
 
define numericConstant_563            %563 
            [numericIndication_564] 
      |     [percentageIndication_569] 
      |     [numericHexadecimalString_573] 
      |     [numericBinaryString_570] 
%     |     [numericString_576]       %change for true numbers 
end define 
 
define numericIndication_564           %564 
            [integerIndication_578] 
      |     [rational_565] 
end define 
 
define rational_565         %565 
            [rationalFixed_566] 
end define 
 
define rationalFixed_566           %566 
            [integer_579] [decimalPoint_568] [integer_579] 
end define 
 
define decimalPoint_568          %568 
            '. 
end define 
 
define percentageIndication_569            %569 
            [number][percentSign_569] 
end define 

define   percentSign_569          %569 
                      
               [percentSign_569a ]
       |      '<K_>[percentSign_569a ]'<k_>
end define

 
define percentSign_569a          %569a 
            '%
      |      'percent 
end define 
 
define numericBinaryString_570              %570 
            [binaryString_571] 
end define 
 
define binaryString_571         %571 
            [stringlit] 'B 
end define 
 
define numericHexadecimalString_573                 %573 
            [hexadecimalString_574] 
end define 
 
define hexadecimalString_574            %574 
            [stringlit] 'X 
end define 
 
define numericString_576            %576 
            [stringlit] 
end define 
 
define integerIndication_578          %578 
            [integer_579] 
end define 
 
define integer_579       %579 
            [number] 
end define 

define   ordinal_583                  %583                      
               [ordinal_583a ]
       |      '<K_>[ ordinal_583a]'<k_>
end define

 
define ordinal_583a                  %583a 
             'first 
      |      'second 
      |      'third
      |      [integerIndication_578]  [ordinalSuffix_584]  
      |      'last  'but  [integerIndication_578] 
      |      'last  
  end define 

define  ordinalSuffix_584                  % 584
             'th  
      |      'st  
      |      'nd  
      |      'rd  
end define
 
define emptyClassConstant_636               %636 
            '{0} 
end define 
 
define stringMask_637         %637 
            [repeat questionMark_637] 
          [stringlit] [repeat questionMark_637] 
end define 
 
define questionMark_637                  %637 
            '? 
end define 

define    knownIndicator_640                          %640                   
               [ knownIndicator_640a ]
       |      '<K_>[ knownIndicator_640a] '<k_>
end define

 
define knownIndicator_640a                         %640a
             'is  'known 
      |      'are  'known  
end define 

define  unknownIndicator_641                        %641                      
               [unknownIndicator_641a ]
       |      '<K_>[unknownIndicator_641a ]'<k_>
end define

 
define unknownIndicator_641a                        %641a 
             'is  'unknown  
      |      'are  'unknown  
end define 

define assumeIndicator_642                             %642 
                     
               [ assumeIndicator_642a]
       |      '<K_>[assumeIndicator_642a ]'<k_>
end define

  
define assumeIndicator_642a                             %642a 
            'Assume 
      |     'Assumed 
      |     'Assumption  
end define 

define   ignoreIndicator_643                          %643                   
               [ignoreIndicator_643a ]
       |      '<K_>[ ignoreIndicator_643a]'<k_>
end define

 
define ignoreIndicator_643a                          %643a 
             'Ignore
      |      'Ignored  
end define 

define  typeIndicator_644                             %644                    
               [ typeIndicator_644a]
       |      '<K_>[typeIndicator_644a ]'<k_>
end define

 
define typeIndicator_644a                             %644a 
            'is  'a  
      |      'is  'an  
end define

define   universalQuantifier_647                          %647                     
               [universalQuantifier_647a ]
       |      '<K_>[universalQuantifier_647a ]'<k_>
end define
 
define universalQuantifier_647a                          %647a
             'for  'every
      |     'for  'all  
      |     'for 'every  
      |      'for 'all
end define 

define   existentialQuantifier_650                            %650                    
               [ existentialQuantifier_650a]
       |      '<K_>[existentialQuantifier_650a ]'<k_>
end define

 
define existentialQuantifier_650a                           %650a 
             'there  'is 'a 
      |      'there  'is  'an  
      |      'there  'exists   
      |      'there  'exists   'a
      |      'there  'exists 'an  
      |      'for  'some 
      |      'for  'at  'least  'one 
      |     'there  'is  'at  'least 'one
end define 

define   uniquenessQuantifier_652                         %652                    
               [ uniquenessQuantifier_652a]
       |      '<K_>[uniquenessQuantifier_652a ]'<k_>
end define

define uniquenessQuantifier_652a                         %652a 
             'for  'exactly  'one  
      |      'for  'the  'one  
      |      'for  'the 
      |      'for  'the [ordinal_583]  
end define 

define specificIndicator_653                           %653                     
               [specificIndicator_653a ]
       |      '<K_>[specificIndicator_653a ]'<k_>
end define

define specificIndicator_653a                           %653a 
              'the  'one 
end define 
 

define     specificExistenceQuantifier_654              %654                  
               [specificExistenceQuantifier_654a ]
       |      '<K_>[specificExistenceQuantifier_654a ]'<k_>
end define

define specificExistenceQuantifier_654a             %654a 
             'there  'is  [precisionIndicator_656] 
      |      'there  'exists  [precisionIndicator_656] 
%    |     symbol 
end define 

define  enumeratedQuantifier_655                         %655                   
               [ enumeratedQuantifier_655a]
       |      '<K_>[enumeratedQuantifier_655a ]'<k_>
end define

define enumeratedQuantifier_655a                         %655a 
             'for  [integerIndication_578] 
      |      'for  [precisionIndicator_656] [integerIndication_578] 
      |      'for  [limit_659][precisionIndicator_656] 
                 [integerIndication_578] 
      |      'for  [limit_659][integerIndication_578] 
      |      'for [lowLimit_660] [precisionIndicator_656] 
                 [integerIndication_578] 
                 [highLimit_661][precisionIndicator_656] 
                 [integerIndication_578] 
      |      'for  [intSubrange_661] 

end define 
 
define precisionIndicator_656                      %656 
             'exactly 
      |     [approximatelyIndicator_657] 
end define 

define approximatelyIndicator_657                  %657                      
               [ approximatelyIndicator_657a]
       |      '<K_>[approximatelyIndicator_657a ]'<k_>
end define
 
define approximatelyIndicator_657a                  %657a 
            'approximately
      |     'approx   
end define 

 
define limit_659                                   %659 
            [lowLimit_660] 
      |     [highLimit_661] 
end define 

define lowLimit_660                                %660        
               [lowLimit_660a ]
       |      '<K_>[lowLimit_660a ]'<k_>
end define

define lowLimit_660a                                %660a 
             'at  'least  
end define 

define highLimit_661                               %661 
              [highLimit_661a ]
       |      '<K_>[highLimit_661a ]'<k_>
end define
 
define highLimit_661a                               %661a 
            'at 'most 
end define 

define intSubrange_661                                  %661 
             [lowLimit_660] [integerIndication_578] 
             [highLimit_661][integerIndication_578] 
      |      [integerIndication_578] '.. [integerIndication_578] 
      |      [numericString_576] '.. [numericString_576] 
end define

define subrange_661                               %661
           [entityConstant_318] '.. [entityConstant_318]
end define 
           
define  criterionIndicator_662                      %662                    
               [ criterionIndicator_662a]
       |      '<K_>[criterionIndicator_662a ]'<k_>
end define

define criterionIndicator_662a                      %662a 
             'for  'which  
      |     'such 'that 
      |     '\ 
      |      'where 
end define 
 
define  pronounCriterionIndicator_662               %662                       
               [pronounCriterionIndicator_662a ]
       |      '<K_>[pronounCriterionIndicator_662a ]'<k_>
end define

define pronounCriterionIndicator_662a               %662a 
             'which
      |      'that 
      |     'who
      |     'whose
end define 
 
define entityIndicator_663                         %663                      
               [ entityIndicator_663a]
       |      '<K_>[entityIndicator_663a ]'<k_>
end define

define entityIndicator_663a                         %663a 
            'entity 
end define 
 
define viewIndicator_664                           %664 
               [ viewIndicator_664a]
       |      '<K_>[viewIndicator_664a ]'<k_>
end define

define viewIndicator_664a                           %664a 
            [subviewIndicator_664] 'of 
      |     [subviewIndicator_664] 
end define 
 
define subviewIndicator_664                        %664 
            'view 
      |     'scope 
      |     'realm 
      |     'domain 
      |     'universe 'of 'discourse 
end define 
 
define  patternWords_666                             %666                    
               [patternWords_666a ]
       |      '<K_>[patternWords_666a ]'<k_>
end define
 
define patternWords_666a                             %666a 
             'Pattern  
end define 

define  possibleIndicator_667                        %667             
               [ possibleIndicator_667a]
       |      '<K_>[ possibleIndicator_667a]'<k_>
end define
 
define possibleIndicator_667a                        %667a 
             'Pattern 
end define
 
define  desiredIndicator_668                        %668                     
               [desiredIndicator_668a ]
       |      '<K_>[desiredIndicator_668a ]'<k_>
end define
 
define desiredIndicator_668a                        %668a 
             'Desired  
end define 

 define  entityIdentifierIndicator_669                %669                    
               [entityIdentifierIndicator_669a ]
       |      '<K_>[entityIdentifierIndicator_669a ]'<k_>
end define

define entityIdentifierIndicator_669a                %669a 
            'Entity '-  'Identifier 
      |     'Entity '- 'Identifiers
      |     'Identifier
      |    'Identifiers
end define 

define  uniqueIndicator_670                          %670                      
               [uniqueIndicator_670a ]
       |      '<K_>[ uniqueIndicator_670a]'<k_>
end define
  
define uniqueIndicator_670a                          %670a 
            'Unique 
end define 

define requiredIndicator_671                        %671                      
               [requiredIndicator_671a ]
       |      '<K_>[requiredIndicator_671a ]'<k_>
end define
 
define requiredIndicator_671a                        %671a 
            'Required  
end define 

define  informationModelIndicator_673                %673                    
               [informationModelIndicator_673a]
       |      '<K_>[ informationModelIndicator_673a]'<k_>
end define

define informationModelIndicator_673a               %673a 
            [informationWords_673]  
            [opt '-] [modelWords_673] 
end define

define informationBaseIndicator_673a               %673a 
            [informationWords_673]  
            [opt '-] [baseWords_673d] 
end define

define informationWords_673 
             'Information  
end define
  
define modelWords_673  
             'model |  'Model 
end define 

define baseWords_673d                        % 673d
     'base | 'Base
end define
       
define   endIndicator_674                        %674                    
               [endIndicator_674a ]
       |      '<K_>[ endIndicator_674a]'<k_>
end define
 
define endIndicator_674a                        %674a 
             'end  |  'End 
end define 

define  informationSubModelIndicator_675                %675                     
               [informationSubModelIndicator_675a ]
       |      '<K_>[informationSubModelIndicator_675a ]'<k_>
end define
 
define informationSubModelIndicator_675a                %675a 
            [informationWords_673]  
            [opt '-] [subModelWords_676] 
end define 

define subModelWords_676                                 %676                       
               [subModelWords_676a ]
       |      '<K_>[subModelWords_676a ]'<k_>
end define

define subModelWords_676a                                 %676a 
             'submodel |  'Submodel 
end define
        
define commentWord_677                                     %677                     
               [ commentWord_677a]
       |      '<K_>[commentWord_677a ]'<k_>
end define

define commentWord_677a                                     %677a
          'Comment 
end define
 
define   defaultIndicator_678                         %678                    
               [ defaultIndicator_678a]
       |      '<K_>[ defaultIndicator_678a]'<k_>
end define

define defaultIndicator_678a                         %678a
             'Default |  'Defaults 
end define

define   exportWords_680                      % 680                   
               [ exportWords_680a]
       |      '<K_>[ exportWords_680a]'<k_>
end define

define exportWords_680a                   % 680a
         'export  'to
end define

define   importWords_681                   
               [ importWords_681a]
       |      '<K_>[importWords_681a ]'<k_>
end define

define importWords_681a
      'import  'from
end define










