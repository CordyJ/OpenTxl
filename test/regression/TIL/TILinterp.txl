% Tiny Imperative Language interpreter

% Tell TXL that the string literal escape character is backslash
#pragma -esc '\'

% Begin with the TIL base grammar
include "TIL.grm"

% Marker for executed statements
redefine statement
        ...
     |  'null;
end redefine

% VM memory cells
define memory_cell
        [id] [literal]
end define

% Execute the program statement by statement
function main
        % The VM memory
        export Memory [memory_cell*]
                _ % Initially empty
        replace [program]
                Statements [statement*]
        by
                Statements [executeStatements]
end function

rule executeStatements
        replace * [statement*]
                S [statement]
                Rest [statement*]
        construct Execution [statement]
                S %% [print]
                  [executeStatement]
        by
                Rest [executeStatements]
end rule

function executeStatement
        replace [statement]
                S [statement]
        by
                S [executeDeclaration]
                  [executeAssignment]
                  [executeIf]
                  [executeWhile]
                  [executeFor]
                  [executeRead]
                  [executeWrite]
                  [failure]
end function

function failure
        match [statement]
                S [statement]
        deconstruct not S
                'null;
        construct ErrorMessage [stringlit]
                _ [+ "*** Error: unable to interpret statement: '"]
                  [quote S] [+ "'"] 
                  [print] 
                  [quit 101]
end function

function executeDeclaration
        replace [statement]
                'var Id [id] ;
        import Memory [memory_cell*]
        export Memory
                Id "--UNDEFINED--"
                Memory
        by
                'null;
end function

function executeAssignment
        replace [statement]
                Id [id] := Expn [expression] ;
        construct ExpnValue [expression]
                Expn [evaluateExpression]
        deconstruct ExpnValue
                Value [literal]
        import Memory [memory_cell*]
        export Memory
                Memory [checkDefined Id]
                       [setValue Id Value]
        by
                'null;
 end function

function executeIf
        replace [statement]
                'if Expn [expression] 'then
                        S [statement*]
                OptElse [opt else_statement]
                'end
        construct ExpnValue [expression]
                Expn [evaluateExpression]
        deconstruct ExpnValue
                Value [literal]
        construct TruePart [statement*]
                S [executeThen Value]
        construct FalsePart [opt else_statement]
                OptElse [executeElse Value]
        by
                'null;
end function

function executeThen Value [literal]
        deconstruct not Value
                0
        replace [statement*]
                S [statement*]
        by
                S [executeStatements]
end function

function executeElse Value [literal]
        deconstruct Value
                0
        replace [opt else_statement]
                'else
                        S [statement*]
        by
                'else
                        S [executeStatements]
end function

function executeWhile
        replace [statement]
                WhileStatement [statement]
        deconstruct WhileStatement
                'while Expn [expression] 'do
                        S [statement*]
                'end
        construct IfStatement [statement]
                'if Expn 'then
                        S [. WhileStatement]
                'end
        by
                IfStatement [executeStatement]
end function

function executeFor
        replace [statement]
                'for Id [id] := E1 [expression] 'to E2 [expression] 'do
                        S [statement*]
                'end
        construct InitialStatements [statement*]
                'var Id;
                Id := E1;
                'var 'Upper;
                'Upper := (E2) + 1;
        construct IterateStatement [statement]
                Id := Id + 1;
        construct WhileStatement [statement]
                'while Id - Upper 'do
                        S [. IterateStatement]
                'end
        construct Initialize [statement*]
                InitialStatements [executeStatements]
        by
                WhileStatement [executeStatement]
end function

function executeRead
        replace [statement]
                'read Id [id] ;
        construct Input [opt literal]
                _ [getp "read: "]
        deconstruct Input 
                Value [literal]
        import Memory [memory_cell*]
        export Memory
                Memory [checkDefined Id]
                       [setValue Id Value]
        by
                'null;
end function

function executeWrite
        replace [statement]
                'write Expn [expression] ;
        construct ExpnValue [expression]
                Expn [evaluateExpression]
                     [print]
        by
                'null;
end function

function checkDefined Id [id]
        match [memory_cell*]
                Memory [memory_cell*]
        deconstruct not * [id] Memory
                Id %% _ [primary]
        construct ErrorMessage [stringlit]
                _ [+ "*** Error: undeclared variable : '"]
                  [quote Id] [+ "'"] 
                  [print] 
                  [quit 102]
end function

function setValue Id [id] Value [literal]
        replace * [memory_cell]
                Id _ [literal]
        by
                Id Value
end function

rule evaluateExpression
        replace [expression]
                E [expression]
        construct NewE [expression]
                E [evaluateParens]
                  [evaluatePrimaries]
                  [evaluateEquals]
                  [evaluateNotEquals]
                  [evaluateAdditions]
                  [evaluateSubtractions]
                  [evaluateMultiplications]
                  [evaluateDivisions]
        deconstruct not NewE
                E
        by
                NewE
end rule

rule evaluateParens
        replace [primary]
                ( Expn [expression] )
        construct ExpnValue [expression]
                Expn [evaluateExpression]
        deconstruct Expn
                Value [literal]
        by
                Value
end rule

rule evaluatePrimaries
        replace [primary]
                Id [id]
        import Memory [memory_cell*]
        construct Check [memory_cell*]
                Memory [checkDefined Id]
        deconstruct * [memory_cell] Memory
                Id Value [literal]
        by
                Value
end rule

rule evaluateEquals
        replace [expression]
                I1 [integernumber] = I2 [integernumber]
        by
                I1 [- I2] [toBoolean] [+ 1] [rem 2]
end rule

rule evaluateNotEquals
        replace [expression]
                I1 [integernumber] != I2 [integernumber]
        by
                I1 [- I2] [toBoolean]
end rule

function toBoolean
        replace [integernumber]
                N [integernumber]
        deconstruct not N
                0
        by
                1
end function

rule evaluateAdditions
        replace [expression]
                I1 [integernumber] + I2 [integernumber]
        by
                I1 [+ I2]
end rule

rule evaluateSubtractions
        replace [expression]
                I1 [integernumber] - I2 [integernumber]
        by
                I1 [- I2]
end rule

rule evaluateMultiplications
        replace [expression]
                I1 [integernumber] * I2 [integernumber]
        by
                I1 [* I2]
end rule

rule evaluateDivisions
        replace [expression]
                I1 [integernumber] / I2 [integernumber]
        by
                I1 [div I2]
end rule
