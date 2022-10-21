%  BNF Grammar
%

comments
  /*  */
end comments

compounds
  '::=
end compounds

keys
   'define 'end
end keys

define program
   [repeat regle]
end define

define regle
    [bnfRule]
 |  [txlRule]
end define

define bnfRule
   [id] ::= [elements]    
      [repeat alternative]
end define

define txlRule
   'define [id]               [NL][IN]
       [elements]
       [repeat alternative]   [EX]
   'end 'define               [NL][NL]
end define

define alternative
  '|  [elements]     
end define

define elements
  [element] [repeat element]  
end define

define element
    [terminal]
 |  [nonTerminal]
end define

define terminal
   [charlit]
end define

define nonTerminal
   [id]
end define

% transformation rules

function main
   replace [program]
      P [program]
   by
     P
end function

