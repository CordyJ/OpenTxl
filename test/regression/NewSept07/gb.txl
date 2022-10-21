

% 
% x.Txl contents... 
% 

keys 
    badBody 
    goodBody 
    betterBody 
end keys 

define program 
    [body_element] 
end define 

define attrib 
    [id] = [stringlit]                  [SP] 
end define 

define body_element 
    <badBody    [repeat attrib] />      [NL] 
  | <goodBody   [repeat attrib] />      [NL] 
  | <betterBody [repeat attrib] />      [NL] 
end define 

rule FixBody 
    replace [body_element] 
        <badBody  Attribs [repeat attrib] /> 
    construct OrigAttrib [attrib] 
        fixParam = "value" 
    construct NewAttribs [repeat attrib] 
        Attribs [. OrigAttrib] 
    by 
        <goodBody NewAttribs /> 
end rule 

rule FixBodySomeMore 
    replace [body_element] 
        <goodBody  Attribs [repeat attrib] /> 
    construct OrigAttrib [attrib] 
        anotherFixParam = "better value" 
    construct NewAttribs [repeat attrib] 
        Attribs [. OrigAttrib] 
    by 
        <betterBody NewAttribs /> 
end rule 

function main 
     replace [program] 
        P [program] 
    by 
        P [FixBody] [FixBodySomeMore] 
end function 

