include "stringutils.rul"

define program
    [stringlits*]
end define

define stringlits
    [stringlit] [stringlit] [stringlit]
end define

rule main
    match $ [stringlits]
        Stringlits [stringlits]
    construct _ [stringlits]
        Stringlits [putp "String, Pattern, Replacement = "]
    deconstruct Stringlits
        String [stringlit] Pattern [stringlit] Replacement [stringlit]
    construct _ [stringlit]
        String [subst Pattern Replacement] [putp "subst = "] 
    construct _ [stringlit]
        String [substglobal Pattern Replacement] [putp "substglobal = "] 
    construct _ [stringlit]
        String [substleft Pattern Replacement] [putp "substleft = "] 
    construct _ [stringlit]
        String [substright Pattern Replacement] [putp "substright = "] 
    construct _ [number]
        _ [count String Pattern] [putp "count = "] 
    construct _ [number]
        _ [lastindex String Pattern] [putp "lastindex = "] 
end rule
