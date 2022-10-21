%% Example of some kind of bug in TXL 7.7
%% Look for %% for info.

define program
        [ifStatement] 
end define

define declarationOrStatement
        'FRED 
end define

define expn
        1 
end define

define ifStatement
        'if [expn] 'then [NL] [IN] 
        [subScope] [EX] 
        [repeat elsif] [opt else] 'end 'if 
end define

define elsif
        'elsif [expn] 'then [NL] [IN] 
        [subScope] [EX] 
end define

define else
        'else [NL] [IN] 
        [subScope] [EX] 
end define

define subScope
        [repeat declarationOrStatement] 
    |   'begin [NL] [IN] 
        [subScope] 'end [EX] [NL] 
end define

define ifStatement
        'if [expn] 'then [subScope] [repeat elsif] 
        [opt else] 'end 'if 
    |   'if [expn] 'then [NL] [IN] 
        [subScope] [EX] 
        [repeat elsif] [opt else] 
end define

%% This define causes problems since the define name and the literal 'elsif
%% are the same.  Seems to be a literal/nointerminal clash.

define elsif
        'else [NL] [IN] 
        'if [expn] 'then [NL] [IN] 
        [subScope] [EX] 
    |   'elsif [expn] 'then [NL] [IN] 
        [subScope] [EX] 
end define

%********************************

function main
    replace [program]
        P [program]
    by
        P [replaceElsifs]
end function

rule replaceElsifs
    replace [ifStatement]
        'if 
        E [expn]
        'then 
        SS [subScope]
        RE [repeat elsif]
        OE [opt else]
        'end 'if 
    by
        'if E 'then 'begin SS 'end 
        RE [changeElsif]
        OE [changeElse]
end rule

% Transform each of the elsifs

%% Here is the problem symptom.  We can't parse the pattern!

rule changeElsif
    replace [elsif]
        'elsif 
        E [expn]
        'then 
        SS [subScope]
    by
        'else 'if E 'then 'begin SS 'end 
end rule

% Transform the final else statement [if it exists]

function changeElse
    replace * [else]
        'else 
        ESS [subScope]
    by
        'else 'begin ESS 'end 
end function



