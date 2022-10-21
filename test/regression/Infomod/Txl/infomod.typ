% typing file

define informationModelName_51                        % 51
           [opt 'InfModName_] [entityVariableName_80]
end define

define entityVariableName_80                           % 80  
            'Entity
      |     'Class
      |     'EntVar_ [entityId][repeat  '#]
      |     'PrimeEntVar_ [entityId][repeat  '#]   
      |     'Class_ [entityId][repeat  '#]
      |      [entityId][repeat  '#]
end define

define attributeVariableDeclarator_81              % 81 
            [opt 'MultAttVar_] '{ [attributeVariableName_85] '}
      |     [associationName_94]
      |     [attributeVariableName_85] 
end define  
  
define entityDeclarator_87                 % 87 
             [opt 'MultEntVar_ ]
            '{ [list entityVariableDeclarator_87] '}
      |     [opt 'OrdEntVar_ ]
             '<< [list entityVariableDeclarator_87] '>>
      |     [entityVariableName_80]          
end define 
 
define associationName_94                          % 94
            [opt 'AssName_][verbWord_95] [repeat compoundVerbWord_96]
end define

define roleNames_98                                 % 98
            [opt 'RoleName_ ] [repeat roleId_98]
end define

define logicalPrimary_118                       % 118 
            '( [opt domainsClause_216]
                 [assertionStatement_106] ')           
      |     [entityTypeSentence_123]   
      |     [attributeIdentitySentence_128]
      |     [opt 'AtomicSent_] [atomicSentence_119]
end define

define classPrimary_145                 % 145
           '( [classExpression_137] ')
      |    [opt 'AtomicClass_] [atomicClass_146]
end define

%_______________________________________________
define domainClause_217                          % 217
            [opt 'DomainCl_] [quantifierIndication_224][entitySelection_217] 
end define

define quantifierIndication_224                    % 224
            [opt 'UnivQ_] [universalQuantifier_647]
      |     [opt 'ExisQ_] [existentialQuantifier_650]
      |     [opt 'UniqQ_] [uniquenessQuantifier_652]
      |     [opt 'SpecQ_] [specificExistenceQuantifier_654]
      |     [opt 'EnumQ_] [enumeratedQuantifier_655]
end define







