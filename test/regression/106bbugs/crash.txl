define program
   [repeat number]
end define

rule removeNonProtected
  replace [ClassMember*
    CM [ClassMember] Rest [ClassMember*]
  by 
    Rest
end rule

