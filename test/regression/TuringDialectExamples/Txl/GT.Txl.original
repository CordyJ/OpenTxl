% Generic Turing dialect
% Charlie Halpern, University of Toronto, January 1986
% revised by Jim Cordy, Queen's University, November 1988

include "Turing.Grammar"

% Syntactic forms

define declaration
        [moduleDeclaration]
    |   [constantDeclaration]
    |   [typeDeclaration]
    |   [variableDeclaration]
    |   [variableBinding]
    |   [subprogramDeclaration]
    |   [genericDeclaration]
    |   [instanceDeclaration]
end define

define genericDeclaration
        generic [id] ( [list id] )      [NL][IN]
                [declaration]           [EX]
end define

define instanceDeclaration
        instance [id] : [id] ( [list expnOrTypeSpec] )
end define

define expnOrTypeSpec
        [id]                    % This is the ambiguous case - could be either.
    |   [typeSpec]      % All types
    |   [expn]          % All expressions
end define


% Semantic transforms

rule mainRule
    replace [repeat declarationOrStatement]
        generic Gname [id] ( Formals [list id] )
            Decl [declaration]
        RestOfScope [repeat declarationOrStatement]
    by
        RestOfScope [fixInstantiations Gname Formals Decl]
end rule

rule fixInstantiations Gname [id] Formals [list id] BaseDecl [declaration]
    replace [declaration]
        instance Iname [id] : Gname ( Actuals [list expnOrTypeSpec] )
    by
        BaseDecl
            [substId Gname Iname]
            [substAmbiguousArgs each Formals Actuals]
            [substExpnArgs each Formals Actuals]
            [substTypeArgs each Formals Actuals]
end rule

rule substId Old [id] New [id]
    replace [id]
        Old 
    by
        New
end rule

rule substAmbiguousArgs OldName [id] New [expnOrTypeSpec]
    deconstruct New
        NewName [id]
    replace [id]
        OldName
    by
        NewName
end rule

rule substExpnArgs OldName [id] New [expnOrTypeSpec]
    deconstruct New
        NewExpn [expn]
    replace [primary]
        OldName
    by
        ( NewExpn )
end rule

rule substTypeArgs Old [id] New [expnOrTypeSpec]
    deconstruct New
        NewTypeSpec [typeSpec]
    replace [typeSpec]
        Old
    by
        NewTypeSpec
end rule
