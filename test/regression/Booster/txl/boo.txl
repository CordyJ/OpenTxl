% Booster Language Definition -------------------------------------------------
%
% File:         boo.Txl
% Contents:     The canonical Booster grammar in Txl format.
% Comments:     The grammar is LALR and not well suited for Txl!
% Comments:     Well, two lines of it weren't ...  :-)  JRC 1.3.94
%
% Organization: Delft University of Technology
% Section:      Computational Physics
% Author:       Hans de Vreught
% Date:         March 1, 1994
%
% -----------------------------------------------------------------------------

% Grammar tuned and pretty-printing added - JRC 2.3.94

function main
        match [program]
            dummy [program]
end function

comments
        //
        /* */
end comments

compounds
        // /* */ >= <> <= <- := ..
end compounds

keys
        AND BEGIN CONST DEFINITION DIV DO ELSE ELSEIF END FROM FUNCTION
        IMPORT IF IMPLEMENTATION IN INOUT ITER MOD MODULE NOT OF OUT OR
        OVER PROCEDURE RECORD RESULT SHAPE THEN TIMES TYPE VAR VIEW WHILE
end keys

define program
                [Booster]
end define

% Modules ---------------------------------------------------------------------

define Booster
                [DefinitionModule]
        |       [ImplementationModule]
% Not yet implemented:
%       |       [AnnotationModule]
%       |       [ScheduleModule]
end define

define DefinitionModule
                [DefinitionHeader] 
                [DefinitionBody]
end define

define DefinitionHeader
                DEFINITION MODULE [id] ';       [NL][IN]
end define

define DefinitionBody
                [repeat DefinitionUnit]         [EX]
                END [id] '.                     [NL]
end define

define ImplementationModule
                [ImplementationHeader] 
                [ImplementationBody]
end define

define ImplementationHeader
                [opt 'IMPLEMENTATION] MODULE [id] ';            [NL][IN]
end define

define ImplementationBody
                [repeat ImplementationUnit]
                [opt BEGINStatementList]                        [EX]
                END [id] '.                                     
end define

define BEGINStatementList
                BEGIN                   [NL]
                [StatementList]
end define

% Units -----------------------------------------------------------------------

define DefinitionUnit
                [ImportDefinition]      [NL]
        |       [ConstDefinition]       [NL]
        |       [TypeDefinition]        [NL]
        |       [VarDeclaration]        [NL]
        |       [ProcedureHeader]       [NL]
        |       [FunctionHeader]        [NL]
end define

define ImplementationUnit
                [ImportDefinition]      [NL]
        |       [ConstDefinition]       [NL]
        |       [TypeDefinition]        [NL]
        |       [VarDeclaration]        [NL]
        |       [Procedure]             [NL]
        |       [Function]              [NL]
end define

define ImportDefinition
                [opt FROMIdentifier] IMPORT [IdentifierList] ';
end define

define FROMIdentifier
                FROM [id]
end define

define IdentifierList
                [list id+]
end define

define ConstDefinition
                CONST                   [NL][IN]
                    [ConstList]         [EX]
                END ';
end define

define TypeDefinition
                TYPE                    [NL][IN]
                    [TypeList]          [EX]
                END ';
end define

define VarDeclaration
                VAR                     [NL][IN]
                    [DeclarationList]   [EX]
                END ';
end define

define Procedure
                                        [NL]
                [ProcedureHeader] 
                [Body]
end define

define ProcedureHeader
                PROCEDURE [id] '( [opt ArgumentList] ') ';      [NL]
end define

define Function
                                        [NL]
                [FunctionHeader] 
                [Body]
end define

define FunctionHeader
                FUNCTION [id] '( [opt ArgumentList] ')          [NL][IN]
                        RESULT [SingleDeclaration] ';           [EX]
end define

define Body
                [opt VarDeclaration]                            [NL]
                BEGIN                                           [NL][IN]
                        [StatementList]                         [EX]
                END [id] ';                                     
end define

% Declarations ----------------------------------------------------------------

define ConstList
                [repeat ConstListAtom+]
end define

define ConstListAtom
                [id] '= [Expression] ';                 [NL]
end define

define TypeList
                [repeat TypeListAtom+]                  [NL]
end define

define TypeListAtom
                [id] '= [Type] ';
end define

define DeclarationList
                [repeat DeclarationListAtom+]
end define

define DeclarationListAtom
                [IdentifierList] ': [Type] ';           [NL]
end define

define SingleDeclaration
                [id] ': [Type]
end define

define ArgumentList
                [Argument] [repeat ArgumentListTail]
end define

define ArgumentListTail
                '; [Argument]
end define

define Argument
                [FlowType] [IdentifierList] ': [Type]
end define

define FlowType
                IN
        |       INOUT
        |       OUT
end define

define Type
                [id]
        |       [TypeConstructor]
end define

define TypeConstructor
                RECORD [DeclarationList] END
        |       SHAPE '{ [CardinalityList] '} OF [id]
        |       VIEW [opt LCBCardinalityListRCB]
end define

define LCBCardinalityListRCB
                '{ [CardinalityList] '}
end define

define CardinalityList
                [opt IdentifierCOLON] [Expression] [repeat CardinalityListTail]
end define

define IdentifierCOLON
                [id] ':
end define

define CardinalityListTail
                '# [opt IdentifierCOLON] [Expression]
end define

% Flow of Control -------------------------------------------------------------

define StatementList
                [repeat StatementListAtom]
end define

define StatementListAtom
                [Statement] ';          [NL]
end define

define Statement
                [ControlFlowStatement]
        |       [ViewStatement]
        |       [ContentStatement]
        |       [ProcedureCall]
end define

define ControlFlowStatement
                [WhileStatement]
        |       [IterStatement]
        |       [IfStatement]
end define

define WhileStatement
                WHILE [Expression] DO   [NL][IN]
                    [StatementList]     [EX]
                END
end define

define IterStatement
                ITER [Expression] TIMES [NL][IN]
                    [StatementList]     [EX]
                END
        |       ITER [Designator] OVER [Expression] DO  [NL][IN]
                    [StatementList]                     [EX]
                END
end define

define IfStatement
                IF [Expression] THEN    [NL][IN]
                    [StatementList]     
                    [opt ElsePart]      [EX]
                END
end define

define ElsePart
                                                [EX]
                ELSE                            [NL][IN]
                    [StatementList]
        |                                       [EX]
                ELSEIF [Expression] THEN        [NL][IN]
                    [StatementList] 
                    [opt ElsePart]
end define

% Statements ------------------------------------------------------------------

define ViewStatement
                [ViewDesignator] '<- [Structure]
end define

define ViewDesignator
                [id] [opt LCBCardinalityListRCB]
end define

define ContentStatement
                [Designator] ':= [Expression]
end define

define Designator
                [id] [opt LBSelectorListRB] [repeat DesignatorTail]
end define

define DesignatorTail
                '. [id] [opt LBSelectorListRB]
end define

define LBSelectorListRB
                '[ [SelectorList] ']
end define

define SelectorList
                [list Selector+]
end define

define Selector
                [Expression]
        |       [opt IdentifierCOLON] [SetExpression]
end define

define SetExpression
                '_
        |       '\ [Expression] [opt DotsExpression] 
        |       [Expression] '.. [Expression]
end define

define DotsExpression
                '.. [Expression]
end define

define ProcedureCall
                [id] '( [opt ExpressionList] ')
end define

% Expressions -----------------------------------------------------------------

define Expression 
                [ArithmeticExpression] [repeat RelOp_ArithmeticExpression]
end define

define RelOp_ArithmeticExpression
                [RelOp] [ArithmeticExpression]
end define

define ArithmeticExpression
                [Term] [repeat AddOp_Term]
end define

define AddOp_Term
                [AddOp] [Term]
end define

define Term
                [Factor] [repeat MulOp_Factor]
end define

define MulOp_Factor
                [MulOp] [Factor]
end define

define Factor
                [stringlit]
        |       [charlit]
        |       [opt UnOp] [number]
        |       [opt UnOp] [Structure]
        |       [opt UnOp] '( [Expression] ')
        |       [opt UnOp] '( [Expression] ', [Expression] ')
        |       [opt UnOp] '{ [ExpressionList] '}
end define

define ExpressionList
                [list Expression+]
end define

define Structure
                [Designator]
        |       [FunctionCall] [opt DotDesignator]
end define

define DotDesignator
                '. [Designator]
end define

define FunctionCall
                [id] '( [opt ExpressionList] ') [opt LBSelectorListRB]
end define

% Tokens-----------------------------------------------------------------------

define RelOp
                '> 
        |       '>= 
        |       '<>
        |       '=
        |       '<= 
        |       '< 
end define 

define AddOp
                OR
        |       '+ 
        |       '- 
end define

define MulOp
                AND
        |       DIV
        |       MOD
        |       '* 
        |       '/
end define

define UnOp
                NOT 
        |       '+ 
        |       '-
end define

% -----------------------------------------------------------------------------
