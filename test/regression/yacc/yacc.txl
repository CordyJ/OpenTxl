% Yacc to TXL grammar converter
% C. Xie, Software Technology Laboratory, Queen's University
% April 1994

#pragma -raw

compounds
    '%% '%{ '%} /* */
end compounds

comments
    /* */
    '%{ '%}
    { }
end comments

% TXL predefined external helper function
% external function unquote ch [charlit]


% Yacc grammar syntax

compounds
    '%% 
end compounds

define yac_tokenDefinition
        '%token [SP] [charlit] [NL]
    |   '%token [upperlowerid] [NL]
end define

define endTokens
        '%% [NL] [NL]
end define

define yac_literal
          [upperlowerid]
        | [lowerupperid]
        | [charlit]
end define

define bar_yac_literals
        '| [SP] [repeat yac_literal] [NL]
end define


define productionDefinition
        [lowerupperid] ': [NL] [IN]
            [SP] [SP] [repeat literalOrType] 
                      [repeat barLiteralsAndTypes] [NL] [EX]
        | 'define [lowerupperid] [NL] [IN]
             [SP] [SP] [repeat literalOrType] [NL]
                       [repeat barLiteralsAndTypes] [EX]
          'end 'define [NL] [NL]
end define


% TXL subset syntax

define barLiteralsAndTypes
        '| [SP] [repeat literalOrType] [NL] 
        | [SP] [bar_yac_literals] [NL] 
end define

define literalOrType
        [literal] | [type] | [yac_literal]
end define

define type
          [SP] '[ [lowerupperid] ']
        | [SP] '[ [upperlowerid] ']
        | [SP] '[ 'opt [lowerupperidOrQuotedLiteral] ']
        | [SP] '[ 'repeat [lowerupperidOrQuotedLiteral] [opt plusOrStar] ']
        | [SP] '[ 'list [lowerupperidOrQuotedLiteral] [opt plusOrStar] ']
end define

define plusOrStar
        '+ | '*
end define

define lowerupperidOrQuotedLiteral
        [lowerupperid]
        | [quotedLiteral]
end define

define literal
        [quotedLiteral] | [unquotedLiteral]
end define

define quotedLiteral
        [SP] '' [unquotedLiteral] [SP]
end define

define unquotedLiteral
          [lowerupperid]
        | [upperlowerid]
        | [charlit]
        | [stringlit]
        | [number]
        | [key]
end define

define program
        [Yacc_Txl_Grammar]
end define


% Transformation grammar

define Yacc_Txl_Grammar
        [opt tokenDefinitions] 
        [productionDefinitions]
end define

define tokenDefinitions
        [repeat tokenDefinition]
        [opt endTokens]
end define

define tokenDefinition
        [yac_tokenDefinition]
    |   'define [upperlowerid] [NL] [IN]
            [yac_tokenDefinition] [EX]
        'end 'define [NL] [NL]
end define

define productionDefinitions 
        [repeat productionDefinition]
end define


% YACC productions are converted to TXL defines, with three optimizations:
% sequences, lists and direct left recursions.

function main
   replace [program]
        P [program]
   by 
        P [convertTokenDefinitions]
          [convertListProductions]
          [convertSequenceProductions]
          [convertDirectLeftRecursions]
          [convertOtherProductions] 
end function


% We don't know for certain what the text of Lex tokens might be,
% so we just make nonterminals for the user to fill in.

rule convertTokenDefinitions
    replace [tokenDefinition]
        '%token LexToken [upperlowerid]
    by
        'define LexToken 
            '%token LexToken
        'end 'define
end rule


rule convertDirectLeftRecursions
   replace [repeat productionDefinition]
        ProdId [lowerupperid] ': 
            FirstAlternative [repeat literalOrType]
            RestOfAlternatives [repeat barLiteralsAndTypes]
        RestOfProductions [repeat productionDefinition]
   deconstruct RestOfAlternatives
        '| ProdId TailOfSecondAlternative [repeat literalOrType]
   construct NewId [lowerupperid]
        ProdId [_ ProdId]
   construct NewIdType [literalOrType]
        NewId
    by
        ProdId ': 
            FirstAlternative [. NewIdType]
        NewId ': 
            TailOfSecondAlternative [. NewIdType]
            '| '[ 'empty ']
        RestOfProductions 
end rule


rule convertListProductions
   replace [productionDefinition]
        ProdId [lowerupperid] ': 
            FirstAlternative [repeat literalOrType]
            RestOfAlternatives [repeat barLiteralsAndTypes]
  deconstruct FirstAlternative
        ElementId [lowerupperid]
  deconstruct RestOfAlternatives
        '| ProdId '',' ElementId
  by
        'define ProdId 
            '[ 'list ElementId '] 
        'end 'define
end rule 


rule convertSequenceProductions
   replace [productionDefinition]
        ProdId [lowerupperid] ': 
                ElementId [lowerupperid]
            '|  ProdId ElementId 
  by
        'define ProdId 
            '[ 'repeat ElementId '] 
        'end 'define
end rule  


rule convertOtherProductions
   replace [productionDefinition]
        ProdId [lowerupperid] ': FirstAlternative [repeat literalOrType] 
        RestOfAlternatives [repeat barLiteralsAndTypes]
   by 
        'define ProdId  
            FirstAlternative [convert_charlit] [convert_type] [convert_key] 
            RestOfAlternatives [convert_charlit] [convert_type] [convert_key] 
        'end 'define
end rule

rule convert_charlit
   replace [literalOrType]
        CharLit [charlit]
   construct Dummy [upperlowerid]
        'UpperLower
   construct CharLitAsId [upperlowerid]
        Dummy [unquote CharLit]
   by
        '' CharLitAsId
end rule 

rule convert_type
   replace [literalOrType]
        ProdId [lowerupperid]
   by
        '[ ProdId ']
end rule

rule convert_key
   replace [literalOrType]
        Token [upperlowerid]
   by
         '[ Token ']
end rule

