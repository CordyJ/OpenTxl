%-----------------------------------------------------------
% Production rule grammars  (nov 1994)
%-----------------------------------------------------------

compounds
  '::=
end compounds

keys 
 EMPTY
end keys

define program
 [production]
end define

define production
  [id] '::=        [NL][IN]             % BNF
            [body]
             ';          [NL][EX]
end define

define body  
 [SP] [terms] [NL]
      [repeat Alternative] 
end define

define terms
  [repeat term]
 | [list   term]
end define

define Alternative
  '|  [terms]      [NL]
 | ';  [list term]    [NL]
 | 'EMPTY           [NL]
end define

define term
          [id]
        | [charlit]
end define

%  Now for a MAIN RULE

function main
 replace [program]
  ID [id] '::=  Body [body] ';   
 construct ID2 [id]
  ID [!]
 construct PR [production]
  ID '::= ID2 '|  'EMPTY ';
 construct PR2 [production]
  ID '::= rouge '|  noir ';

 by
  PR  
end function
