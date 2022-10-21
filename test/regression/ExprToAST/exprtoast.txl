% Example polymorphic program to print out
% prefix-form AST of input expressions

include "expr.grm"

function main
    % Seed AST conversion 
    construct NullId [id] 
        NULL
    deconstruct * [any] NullId
	Null [any]
	
    replace [program]
        P [program]
    by
        P [toAST Null]
	  [filterLiterals]
	  [filterTypes]
end function

% Form of a prefix AST node
define astnode 
       ( [id] [any] )
   |   [any]
end define

% Convert every parse node to its prefix AST form
rule toAST Here [any]
   % Don't convert AST nodes themselves
   skipping [astnode]
   % Do every node exactly once
   replace $ [any]
      A [any]
   % Make sure it's not the one we just did
   deconstruct not A
      Here
   % Get the abstract type name of this node
   construct AType [id]
   	_ [typeof A]
   % Make the AST node for it, and recursively convert nodes inside it
   construct ANode [astnode]
      ( AType A [toAST A] )
   deconstruct * [any] ANode
       AnyANode [any]
   % Replace the original with the AST form
   by 
       AnyANode 
end rule

% Remove all concrete syntactic sugar
rule filterLiterals
    % If the type name of an AST node is "*literal", it's concrete syntax
    replace [astnode]
        ( TypeId [id] Contents [any] )
    where 
    	TypeId [grep "literal"]
    % So replace it with nothing
    construct Empty [empty]
    deconstruct * [any] Empty
        AnyEmpty [any]
    by
        AnyEmpty
end rule

% Only show interesting abstract types in AST
rule filterTypes
    % List of abstract types we are interested in
    construct AbstractTypes [repeat id] 
        'addition 'subtraction 'multiplication 'division
    % If it's not one of those, don't show its AST, just its contents
    replace [astnode]
        ( TypeId [id] Contents [any] )
    deconstruct not * [id] AbstractTypes
        TypeId
    by
        Contents
end rule
