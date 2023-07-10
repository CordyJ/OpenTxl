% Project REX - ISL Transformer - Part 1, Target Independent Transforms, ISL -> ISL
% J.R. Cordy, GMD Karlsruhe, 5.11.90

% This rule set performs several target-language independent transforms that
% simplify an ISL spec by:
%
%    - resolving all generics
%    - eliminating declaration-before-use problems by expanding all types and constants
%    - eliminating structural-type-equivalence problems by uniquely naming all equivalent types
%
% The complete transformation of an ISL spec must proceed from this point with language-
% dependent transforms to the target language.


include "ISL.Grammar"

function main
    replace [program]
        P [FileSpec]
    by
        P [expandGenerics]
            [expandTypes]
            [expandConstants]
            [nameStructurallyEquivalentTypes]
            [cleanup]
end function


% Part A.  Resolve Generic Types

rule expandGenerics
    replace [TypeUnitSpec]
        types T [Ident] ;
            TUB [StatementList]
        'end OT [opt Ident] .
    construct NewTUB [StatementList]
        TUB     [normalizeGenerics]
                [genericsFirst]
                [resolveGenerics]
    where not
        NewTUB [= TUB]
    by
        types T ;
            NewTUB
        'end OT .
end rule

% % % external rule print
% % % external rule message S [stringlit]


% Step 1.  Normalize all generics to have both value and type parameters
function normalizeGenerics
    replace [StatementList]
        SL [StatementList]
    by
        SL [addMissingGenericTypeParameters] 
            [addMissingGenericValueParameters]
end function

rule addMissingGenericTypeParameters
    replace [repeat Statement+]
        G [Ident] FP [FormalParamPart] = GB [Type] ;
        MoreS [repeat Statement]
    deconstruct G 
        Gid [id]
    construct NewParmId [Ident]
        Gid [!]
    by
        G '[ NewParmId '] FP = GB ;
        MoreS  [addDummyTypeParam G]
end rule

rule addDummyTypeParam G [Ident]
    replace [SimpleType]
        G ( GVP [ExprList] )
    by
        G '[ int '] ( GVP )
end rule

rule addMissingGenericValueParameters
    replace [repeat Statement+]
        G [Ident] GP [GenericPart] = GB [Type] ;
        MoreS [repeat Statement] 
    deconstruct G 
        Gid [id]
    construct NewParmId [Ident]
        Gid [!]
    by
        G GP ( NewParmId ) = GB ;
        MoreS  [addDummyValueParam G]
end rule

rule addDummyValueParam G [Ident]
    replace [SimpleType]
        G '[ GTP [SimpleTypeList] ']
    by
        G '[ GTP '] ( 1 )
end rule


% Step 2.  Sort all generics to top of scopes
rule genericsFirst
    % put all generics first, regardless of present position
    replace [repeat Statement+]
        S [Statement]
        T [TypeClause] ;
        MoreS [repeat Statement]
    where
        T [isGeneric]
    where not
        S [isGeneric]
    by
        T ;
        S
        MoreS
end rule

rule isGeneric
    match [TypeClause]
        G [Ident] GP [GenericPart] GFP [FormalParamPart] = GB [Type] 
end rule


% Step 3.  Resolve generic types
rule resolveGenerics
    replace [repeat Statement+]
        G [Ident] '[ TP [list IdentDefaultType+] '] ( VP [list IdentDefaultExpr+] ) = GB [Type] ;
        MoreS [repeat Statement]
    by
        ; MoreS [resolveGeneric G TP VP GB]
end rule

rule resolveGeneric     G [Ident] TPL [list IdentDefaultType+] VPL [list IdentDefaultExpr+] GB [Type]
    replace [Type]
        G '[ ITPL [list SimpleType+] '] ( IVPL [list Expr+] )
    by
        GB [substituteTypeParameters each TPL ITPL] 
             [substituteValueParameters each VPL IVPL]
end rule

rule substituteTypeParameters GTP [IdentDefaultType] ITP [SimpleType]
    deconstruct GTP
        GTPid [Ident]
    replace [SimpleType]
        GTPid
    by
        ITP
end rule

rule substituteValueParameters GVP [IdentDefaultExpr] IVP [Expr]
    deconstruct GVP
        GVPid [Ident]
    replace [Expr]
        GVPid
    by
        IVP
end rule
        

% Part B.  Expand constants

function expandConstants
    replace * [TypeUnitSpec]
        types T [Ident] ;
            TUB [StatementList]
        'end OT [opt Ident] .
    by
        types T ;
            TUB     [constsFirst] [resolveConsts]
        'end OT .
end function

rule constsFirst
    replace [repeat Statement+]
        S [Statement] 
        CD [ConstDef] ;
        MoreS [repeat Statement]
    where not
        S [isConstDef] 
    by
        CD ;
        S
        MoreS
end rule

function isConstDef
    match [Statement]
        CD [ConstDef] ;
end function

function resolveConsts
    replace * [repeat Statement+]
        CD [ConstDef] ;
        MoreS [repeat Statement]
    deconstruct CD
        Cid [Ident] == Cexpr [Expr]
    by
        CD ;
        MoreS [substituteConstValue Cid Cexpr] [resolveConsts]
end function

rule substituteConstValue  Cid [Ident]  Cvalue [Expr]
    replace [Expr]
        Cid
    by
        Cvalue
end rule


% Part C.  Expand type references

function expandTypes
    replace * [TypeUnitSpec]
        types T [Ident] ;
            TUB [StatementList]
        'end OT [opt Ident] .
    by
        types T ;
            TUB     [typesFirst] [resolveTypes]
        'end OT .
end function

rule typesFirst
    replace [repeat Statement+]
        S [Statement] 
        TD [TypeClause] ;
        MoreS [repeat Statement]
    where not
        S [isTypeClause] 
    by
        TD ;
        S
        MoreS
end rule

function isTypeClause
    match [Statement]
        TD [TypeClause] ;
end function

function resolveTypes
    replace * [repeat Statement+]
        TD [TypeClause] ;
        MoreS [repeat Statement]
    deconstruct TD
        Tid [Ident] = Ttype [Type]
    by
        TD ;
        MoreS [substituteTypeDef Tid Ttype] [resolveTypes]
end function

rule substituteTypeDef  Tid [Ident]  Ttype [Type]
    replace [Type]
        Tid
    by
        Ttype
end rule


% Part D.  Implement structural type equivalence

function nameStructurallyEquivalentTypes
    replace * [TypeUnitSpec]
        types T [Ident] ;
            TUB [StatementList]
        'end OT [opt Ident] .
    by
        types T ;
            TUB     [nameOneStructurallyEquivalentType]
        'end OT .
end function

rule nameOneStructurallyEquivalentType
    replace [repeat Statement+]
        TD [TypeClause] ;
        MoreS [repeat Statement]
    deconstruct TD
        Tid [id] = Ttype [Type]
    where not
        Ttype [isSimpleType] 
    where
        MoreS [hasAnotherTypeDefLike Ttype]
    construct Tprime [id]
        Tid [!]
    by
        Tprime = Ttype ;
        Tid = Tprime ;
        MoreS [substituteTypeId Ttype Tprime]
end rule

function isSimpleType
    match [Type]
        ST [SimpleType]
end function

% % % external rule breakpoint

rule hasAnotherTypeDefLike Ttype [Type]
    match [Type]
        Ttype
end rule

rule substituteTypeId Ttype [Type] Tid [id]
    replace [Type]
        Ttype
    by
        Tid
end rule


% Part E.  Clean up the mess

rule cleanup
    replace [repeat Statement]
        ;
        MoreS [repeat Statement]
    by
        MoreS
end rule
