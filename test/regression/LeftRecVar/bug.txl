%%+
%%	File:		zed.Txl
%%
%%	Purpose:	This txl program implements an extended Z checker.
%%			Spivey is too cautious, and goes for something
%%			that he guarantees that he can check.  Other things
%%			may not be provable in theory, but may be provable
%%			in practice.
%%-

% include "compkeys"
compounds
    /_\    '|->   ->     -+->   >+->    >->    -+>>    ->>
    >->>   -++>   >++>   =>     <=>     =/=    @@      '(|
    '|)    '<|    '|>    <+     +>      <->    ..      /\
    \/     @!     '[|    '|]    '<[      ']>   >>      >=
    <=     =^     ::=    @<^    @>^     \\     @~      @el
    @O/    @O	  @O+    @Ox	@i	@id    @E=     @P
end compounds

keys
    true   false      if       then     else    div
    mod    disjoint   prefix   suffix   in      bag
    id     partition  seq      seq1     iseq    inrel
    schema axdef
end keys

% include "fuzz.grammar"
%%+
%%	File:		fuzz.grammar
%%
%%	Purpose:	This file provides the grammar definitions
%%			for a mofified version of the fuzz form of
%%			the Z language.  Latex Clutter have been
%%			replaced by ascii symbols that look something
%%			like the symbols they are supposed to represent.
%%			This is done by the sed script z2.sed.
%%-


define program
      [repeat z_unit]
end define

%% doesn't exatly match the reference becase we are tied
%% to fuzz syntax, which groups all global constructs that
%% are not schemas, axioms or generics into a single type of
%% unit.  Covered in the def part.

define z_unit
      [schema]						[NL]
    | [axiom]						[NL]
    | [generic]						[NL]
    | [def]						[NL]
end define

%%
%% High Level building Blocs
%%

define schema
    '\ begin '{ schema '} '{ [id] '} [opt genFormals]	[NL] [IN]
	[declPart]					[NL] [EX]

    [opt wherePart]

    '\ 'end '{ schema '}				[NL]
end define

define axiom
    '\ begin '{ axdef '}				[NL] [IN]
	[declPart]					[NL] [EX]

    [opt wherePart]

    '\ 'end '{ axdef '} 				[NL]
end define

define generic
    '\ begin '{ gendef '} [opt genFormals]		[NL] [IN]
	[declPart]					[NL] [EX]

    [opt wherePart]

    '\ 'end '{ gendef '}				[NL]
end define

define wherePart
    '\ 'where						[NL] [IN]
	[axiomPart]					[NL] [EX]
end define

    % This type of block includes al gobal statments not
    % covered by the boxes

define def
      '\ begin '{ zed '}				[NL]
	  [definitions]
      '\ 'end '{ zed '}					[NL]
end define

define definitions
    							[IN]
	  [definition] 					[NL] [EX]
      [repeat rest_definitions]
end define

define rest_definitions
      [sep]						[NL] [IN]
	  [definition]					[NL] [EX]
end define

define definition
      [named_set]
    | [schema_def]
    | [abbreviation]
    | [branch_def]
    | [predicate]
end define

%%
%% top level defs nested within definition (except predicate)
%%

define named_set
    '[ [list ident] ']
end define

define schema_def
    [schemaName] [opt genFormals]			[SP]
    '=^							[SP]
    [schemaExp]
end define

define abbreviation
    [defLhs]						[SP]
    '==							[SP]
    [expression]
end define

define branch_def
    [ident]						[SP]
    '::=						[SP]
    [branch] [repeat rest_branch]
end define

define rest_branch
       							[SP]
       '|						[SP]
       [branch]
end define

%%
%% Now deal with each subpart in turn
%%

define declPart
    [bas_decl] [repeat rest_decls]
end define

define rest_decls
      							[SP]
      [sep]						[NL]
      [bas_decl]
end define

define axiomPart
    [predicate] [repeat rest_axioms]
end define

define rest_axioms
      							[SP]
      [sep]						[NL]
      [predicate]
end define

define sep
     ';
   | \\ 			[NL] %% grammar says NL, but fuzz uses \\
   | [EX] '\ also 		[NL][IN]	
end define

define defLhs
      [var_name] [opt genFormals]
    | [preGen] [decoration] [ident]
    | [ident] [inGen] [decoration] [ident]
end define

define branch
      [ident]
    | [var_name] '<[ [expression] ']>
end define

define schemaExp
      '@A  [schemaText] '@@ [schemaExp]
    | '@E  [schemaText] '@@ [schemaExp]
    | '@E1 [schemaText] '@@ [schemaExp]
    | [schemaExp1x1]
end define

define schemaExp1x1				%% Pipe
      [schemaExp1x2]
    | [schemaExp1x1] '>>  [schemaExp1x2]	%% L
end define

define schemaExp1x2				%% semi
      [schemaExp1x3]
    | [schemaExp1x2]  ';  [schemaExp1x3]	%% L
end define

define schemaExp1x3				%% hide
      [schemaExp1x4]
    | [schemaExp1x3]  '\  [schemaExp1x4]	%% L
end define

define schemaExp1x4				%% project
      [schemaExp1x5]
    | [schemaExp1x4]  '^  [schemaExp1x5]	%% L
end define

define schemaExp1x5				%% iff
      [schemaExp1x6]
    | [schemaExp1x5] '<=> [schemaExp1x6]	%% L
end define

define schemaExp1x6				%% implies
      [schemaExp1x7] [opt schem1x6Rest]		%% R
end define

define schem1x6Rest
    '=> [schemaExp1x6]
end define

define schemaExp1x7				%% lor
      [schemaExp1x8]
    | [schemaExp1x7] '\/  [schemaExp1x8]	%% L
end define

define schemaExp1x8				%% land
      [schemaExp1x9]
    | [schemaExp1x8] '/\  [schemaExp1x9]	%% L
end define

define schemaExp1x9
      '[ [schemaText] ']
    | [schemaRef]
    | '@! [schemaExp1x9]
    | pre [schemaExp1x9]
    | '( [schemaExp] ')
end define

define schemaText
    [declaration] [opt sFilter]
end define

define sFilter
    '| [predicate]
end define

define schemaRef
   [schemaName] [decoration] [opt genActuals] [opt renaming]
end define

define renaming
    '[ [list renamePair] ']
end define

define renamePair
    [declName] '/ [declName]
end define

define declaration
    [bas_decl] [repeat rest_decl]
end define

define rest_decl
      '; [bas_decl]
end define

define bas_decl
      [list declName] [SP] ': [SP] [expression]
    | [schemaRef]
end define

define predicate
      '@A   [schemaText] '@@ [predicate]
    | '@E   [schemaText] '@@ [predicate]
    | '@E1  [schemaText] '@@ [predicate]
    | '@let [letDefList] '@@ [predicate]
    | [predicate1x1]
end define

define letDefList
    [letDef] [repeat restLet]
end define

define restLet
      '; [letDef]
end define

define predicate1x1
      [predicate1x2]
    | [predicate1x1] '<=> [predicate1x2]		%%L
end define

define predicate1x2
      [predicate1x3] [opt pred1x2Rest]			%%R
end define

define pred1x2Rest
    '=> [predicate1x2]
end define

define predicate1x3
      [predicate1x4]
    | [predicate1x3] '\/  [predicate1x4]		%%L
end define

define predicate1x4
      [predicate1x5]
    | [predicate1x4] '/\  [predicate1x5]		%%L
end define

define predicate1x5
      [expression] [repeat restPExpr]
    | [preRel] [decoration] [expression]
    | [schemaRef]
    | pre [schemaRef]
    | true
    | false
    | '@! [predicate1x5]
    | '( [predicate] ')
end define

define restPExpr
      [rel] [expression]
end define

define rel
      '=
    | '@el
    | [inRel] [decoration]
    %%| \inrel{ident}		%% for fuzz
end define

define letDef
    [var_name] == [expression]
end define

define expression0
      '@l [schemaText] '@@ [expression]
    | '@mu [schemaText] [opt bulExpr]
    | '@let [letDefList] '@@ [expression]
    | [expression]
end define

define bulExpr
    '@@ [expression]
end define

define expression
      '@if [predicate] '@then [expression] '@else [expression]
    | [expression1]
end define

define expression1
     [expression1] [inGen] [expression1]			%% Right assoc
  |  [expression2] [repeat cross_prod]
end define

define cross_prod
    '@x [expression2]
end define

define expression2
      [expression2] [inFun] [decoration] [expression2]		%% Left Assoc
    | '@P [expression4]
    | [preGen] [decoration] [expression4]
    | '- [decoration] [expression4]
    | [expression4] '(| [expression0]  '|) [decoration]
    | [expression3]
end define

define expression3
      [expression4]
    | [expression3] [expression4]
end define

define expression4
      [var_name] [opt genActuals]
    | [preDef]
    | [number]
    | [schemaRef]
    | [setExpr]
    | '< [list expression] '>
    | '[| [list expression] '|]
    | '( [list expression] ')
    | '@O [schemaName] [decoration] [opt renaming]
    | [expression4] '. [var_name]
    | [expression4] [postFun] [decoration]
    | [expression4] '\bsup [expression] '\esup
    | '( [expression0] ')
end define

define setExpr
      '{ [schemaText] [opt bulExpr] '}
    | '{ [list expression] '}
end define

define ident
   [Word] [decoration]
end define

define declName
      [ident]
    | [opName]
end define

define var_name
      [ident]
    | '( [opName] ')
end define

define opName
      '_ [inSym] [decoration] '_
    | [preSym] [decoration] '_
    | '_ [postSym] [decoration]
    | '_ '(| '_ '|) [decoration]
    | - [decoration]
end define

define inSym
    [inFun] | [inGen] | [inRel]
end define

define preSym
    [preGen] | [preRel]
end define

define postSym
	[postFun]
end define

define decoration
    [repeat stroke]
end define

define genFormals
    '[ [list ident] ']
end define

define genActuals
    '[ [list expression] ']
end define

% include "classes"
%%+
%%      File:           classes
%%
%%      Purpose:        This file provides the grammar definitions
%%			for the classes of symbols for fuzz.
%%
%%	Author: 	Thomas R. Dean
%%-

%% The classes In-Fun, Pre-Rel, etc. stand for members of the class
%% Word that have been announced as infix function symbols, prefix
%% relation symbols, etc., either in the prelude or by an explicit
%% directive.

%% infun will be split into six productions to model the six levels
%% of precedence available.

define inFun
      '|->                                              %% priority 1
    | '..                                               %% priority 2
    | '+                                                %% priority 3
    | '-
    | '@u
    | '\
    | '@^
    | '@U+
    | '@U-                                              %% priority 3
    | '*                                                %% priority 4
    | 'div
    | 'mod
    | '@i
    | '@<^
    | '@>^
    | ';
    | '@o
    | '@Ox                                              %% priority 4
    | '@O+                                              %% priority 5
    | '#                                                %% priority 5
    | '<|                                               %% priority 6
    | '|>
    | '<+
    | '+>                                               %% priority 6
end define

define inGen
      '<->
    | '-+->
    | '->
    | '>+->
    | '>->
    | '-+>>
    | '->>
    | '>->>
    | '-++>
    | '>++>
end define

define inRel
      '=/=
    | '@nel
    | '\ subseteq
    | '\ subset
    | '<
    | '>
    | '<=
    | '>=
    | prefix
    | suffix
    | in
    | '@EE
    | '@Eeq
    | partition
    | \inrel { [Word] }
end define

define preGen
      '@P1
    | '@id
    | '@F
    | '@F1
    | seq
    | seq1
    | iseq
    | bag
end define

define preRel
    disjoint
end define

define postFun
    '@~
  | '*
  | '+
  | '^ { [number] }
end define

define preDef
    '#
    | @O/
end define

% include "terminals"
%%+
%%      File:           terminals
%%
%%      Purpose:        This file provides the definitions of some
%%			of the terminal symbols for fuzz.
%%
%%	Author:		Thomas R. Dean
%%-


%% A Word is an undecorated name or special symbol, it may be
%% a non-empty sequence of letters, digits and underscores that
%% starts with a letter (an id), or a non-empty sequence
%% of characters drawn from +-*.=<> or a latex command (not implemented)

define Word
      [id]
    | [repeat wordEl+]
end define

define wordEl
      '+
    | '-
    | '*
    | '.
    | '=
    | '<
    | '>
end define

%% A schema name is a Word that has been defined as a schema, or one
%% of the greek leeters \Delta or \Xi followed by a single space
%% and a Word

define schemaName
    [opt greek] [SP] [Word]
end define

define greek
      /_\		%% Delta
    | @E=		%% Xi
end define

%% A stroke is a single decoration: one of ', ?, ! or a subscript
%% digit entered as _0, _1, and so on.

define stroke
      ''
    | '?
    | '!
    | '_ [number]		%% subscript
end define

%% aux definitions

%% Type Entry is an entry in the type table (repeat TypeEntry)
%% it is a definition, or the keyword schema, and id and a subtable.

define TypeEntry
     [definition] [NL]
   | [bas_decl]   [NL]
   | schema [Word]  [NL] [IN] [repeat TypeEntry] [EX]
end define

%% % % % external rules we might need

% external function print
% external function message M [any]

%%
%% Rules
%%

%% main rule.  Start with an empty type table.  Call the function to 
%% traverse the list building the type table and checking each
%% z_unit it encounters.

%%function main
%%  match [program]
%%      P [repeat z_unit]
%%  construct T [repeat TypeEntry]
%%      _
%%  where
%%     P [typeTraverse T] [emptyTraverse] %% Just incase it's empty
%%end function
%%
%%%% catch case for empty program
%%
%%function emptyTraverse
%%    match [repeat z_unit]
%%	E [empty]
%%    where
%%	E [message "empty program"]
%%end function
%%
%%%% This is the function that traverses the Z program.  For each z_unit
%%%% it constructs the new table and passes the augmented type
%%%% table to the recursion on the rest of the list
%%
%%function typeTraverse T [repeat TypeEntry]
%%
%%    match [repeat z_unit]
%%       Z1 [z_unit] Rest [repeat z_unit]
%%
%%    construct N [repeat TypeEntry]	%% build the new table entries
%%       _ [addAndCheckType Z1 T]
%%
%%    construct T1 [repeat TypeEntry]	%% splice on to the end of the table
%%       T [. N]
%%
%%    where
%%       Rest [typeTraverse T1] [endTraverse T1]	%% recursive step
%%
%%end function
%%
%%%% Function endTraverse prints out the type table.  Only applied on
%%%% the last entry of the list.  This function is used to debug
%%%% the type entry table.
%%
%%function endTraverse T [repeat TypeEntry]
%%    match [repeat z_unit]
%%	E [empty]
%%    where
%%	T [message "type table is:"] [print]
%%end function
%%
%%%% The scope of this rule is the list of items added by this Z unit.
%%%% We must first find out what Z unit this is.
%%
%%function addAndCheckType Z [z_unit] T [repeat TypeEntry]
%%    replace [repeat TypeEntry]
%%       T1 [repeat TypeEntry]
%%    by
%%       T1 [addAndCheckDef Z T]
%%	  %[addAndCheckGen Z T]
%%	  [addAndCheckAxe Z T]
%%	  [addAndCheckSchem Z T]
%%end function
%%
%%
%%%% **************************
%%%%     Global Definition
%%%% **************************
%%
%%%% The scope of this rule is the (initialy empty) items added by this Z unit.
%%%% This rule only applies if the z unit is a definition unit. Parameter
%%%% T is the table of everything before this unit.
%%
%%function addAndCheckDef Z [z_unit] T [repeat TypeEntry]
%%   deconstruct Z
%%	'\ begin '{ zed '} D [definitions] '\ 'end '{ zed '}
%%   replace [repeat TypeEntry]
%%      T1 [repeat TypeEntry]
%%   by
%%      T1 [processDefs D T]
%%end function
%%
%%%% The scope of this function is the items added by a z_unit made
%%%% up of definitions.  Handles initial case.
%%
%%function processDefs D [definitions] T [repeat TypeEntry]
%%    deconstruct D
%%       D1 [definition] R1 [repeat rest_definitions]
%%    replace [repeat TypeEntry]
%%       T1 [repeat TypeEntry]
%%    construct N [TypeEntry]
%%	D1 %[processADef T T1]
%%    by
%%       T1 [. N] [processDefs2 R1 T]
%%end function
%%
%%%% The scope of this function is the items added by the z_unit made
%%%% up of definitions. handles recursive case
%%
%%function processDefs2 D [repeat rest_definitions] T [repeat TypeEntry]
%%    deconstruct D
%%	S [sep] D1 [definition] R1 [repeat rest_definitions]
%%    replace [repeat TypeEntry]
%%       T1 [repeat TypeEntry]
%%    construct N [TypeEntry]
%%	D1 %[processADef T T1]
%%    by
%%       T1 [. N] [processDefs2 R1 T]
%%end function
%%
%%%% Fix and check the definition. 
%%function processADef T [repeat TypeEntry] T1 [repeat TypeEntry]
%%    replace [TypeEntry]
%%       D [definition]
%%    by
%%       D %[fixDef T T1] [checkDef T T1]
%%end function
%%
%%%% **************************
%%%%     Global Axioms
%%%% **************************
%%
%%%% The scope of this rule is the (initialy empty) items added by this Z unit.
%%%% This rule only applies if the z unit is a axiomatic unit. Parameter
%%%% T is the table of everything before this unit.
%%
%%function addAndCheckAxe Z [z_unit] T [repeat TypeEntry]
%%   deconstruct Z
%%	'\ begin '{ axdef '} D [declPart] W [opt wherePart] '\ 'end '{ axdef '}
%%   replace [repeat TypeEntry]
%%      T1 [repeat TypeEntry]
%%   by
%%      T1 [processDecls D T]
%%end function
%%
%%%% The scope of this function is the items added by a axiom z_unit.
%%%% Handles initial case.
%%
%%function processDecls D [declPart] T [repeat TypeEntry]
%%    deconstruct D
%%       D1 [bas_decl] R1 [repeat rest_decls]
%%    replace [repeat TypeEntry]
%%       T1 [repeat TypeEntry]
%%    construct N [TypeEntry]
%%	D1 [processADecl T T1]
%%    by
%%       T1 [. N] [processDecls2 R1 T]
%%end function
%%
%%function processDecls2 D [repeat rest_decls] T [repeat TypeEntry]
%%    deconstruct D
%%       S [sep] D1 [bas_decl] R1 [repeat rest_decls]
%%    replace [repeat TypeEntry]
%%       T1 [repeat TypeEntry]
%%    construct N [TypeEntry]
%%	D1 [processADecl T T1]
%%    by
%%       T1 [. N] [processDecls2 R1 T]
%%end function
%%
%%function processADecl T [repeat TypeEntry] TL [repeat TypeEntry]
%%    replace [bas_decl]
%%	D [bas_decl]
%%    by
%%	D %[fixPartFunc T TL] %...
%%end function
%%
%%%% **************************
%%%%     Schema
%%%% **************************
%%
%%%% The scope of this rule is the (initialy empty) items added by this Z unit.
%%%% This rule only applies if the z unit is a axiomatic unit. Parameter
%%%% T is the table of everything before this unit.
%%
%%function addAndCheckSchem Z [z_unit] T [repeat TypeEntry]
%%   deconstruct Z
%%	'\ begin '{ schema '} '{ Sname [id] '} G [opt genFormals]
%%	D [declPart] W [opt wherePart] '\ 'end '{ schema '}
%%   replace [repeat TypeEntry]
%%      T1 [repeat TypeEntry]
%%   by
%%      schema Sname T1 [processSchem D T]
%%end function
%%
%%%% The scope of this function is the items added by a schmea z_unit.
%%%% Handles initial case.
%%
%%function processSchem D [declPart] T [repeat TypeEntry]
%%    deconstruct D
%%       D1 [bas_decl] R1 [repeat rest_decls]
%%    replace [repeat TypeEntry]
%%       T1 [repeat TypeEntry]
%%    construct N [repeat TypeEntry]
%%	D1
%%    construct N2 [repeat TypeEntry]
%%	N [processASchem T T1]
%%    by
%%       T1 [. N2] [processSchem2 R1 T]
%%end function
%%
%%function processSchem2 D [repeat rest_decls] T [repeat TypeEntry]
%%    deconstruct D
%%       S [sep] D1 [bas_decl] R1 [repeat rest_decls]
%%    replace [repeat TypeEntry]
%%       T1 [repeat TypeEntry]
%%    construct N [repeat TypeEntry]
%%	D1
%%    construct N2 [repeat TypeEntry]
%%	N [processASchem T T1]
%%    by
%%       T1 [. N] [processSchem2 R1 T]
%%end function
%%
%%function processASchem T [repeat TypeEntry] TL [repeat TypeEntry]
%%    replace [repeat TypeEntry]
%%	D [repeat TypeEntry]
%%    by
%%	D [fixXieSchem T TL] [fixDeltSchem T TL]
%%	  %[fixPfun]
%%end function
%%
%%%% Function fixXieSchem replaces @E= (Xie) SchemaName with
%%%% the variables the schema, and a second copy with the extra decoration
%%%% marks. Doesn't understand genacutals or renaming yet
%%
%%rule fixXieSchem T [repeat TypeEntry] TL [repeat TypeEntry]
%%    replace [repeat TypeEntry]
%%	T1 [TypeEntry] Rest [repeat TypeEntry]
%%    deconstruct * [schemaRef] T1
%%	D [schemaName] L [decoration] G [opt genActuals] R [opt renaming]
%%    deconstruct D
%%	@E= W [Word]
%%    construct T2 [repeat TypeEntry]
%%	_ [extractScope T W]
%%    by
%%	T2 
%%end rule
%%
%%%% scope is an empty repeat TypeEntry
%%function extractScope T [repeat TypeEntry] L [Word]
%%    replace [repeat TypeEntry]
%%	P [repeat TypeEntry]
%%    deconstruct * [TypeEntry] T
%%	schema L R [repeat TypeEntry]
%%    by
%%	R
%%end function
%%
%%%% Function fixDeltSchem replaces /_\ (Delta) SchemaName with
%%%% the variables the schema, and a second copy with the extra decoration
%%%% marks. Doesn't understand genacutals or renaming yet
%%
%%rule fixDeltSchem T [repeat TypeEntry] TL [repeat TypeEntry]
%%    replace [repeat TypeEntry]
%%	T1 [TypeEntry] Rest [repeat TypeEntry]
%%    deconstruct * [schemaRef] T1
%%	D [schemaName] L [decoration] G [opt genActuals] R [opt renaming]
%%    deconstruct D
%%	/_\ W [Word]
%%    construct T2 [repeat TypeEntry]
%%	_ [extractScope T W]
%%    construct T3 [repeat TypeEntry]
%%	T2 [addQuoteDecoration]
%%    by
%%	T2  [. T3]
%%end rule
%%
%%function addQuoteDecoration
%%    replace [repeat TypeEntry]
%%	T1 [TypeEntry] Rest [repeat TypeEntry]
%%    by
%%	T1 [addQuote] Rest [addQuoteDecoration]
%%end function
%%
%%function addQuote
%%    replace [TypeEntry]
%%       LD [list declName] ': E [expression]
%%    deconstruct LD
%%       LE [list_1_declName]
%%    by
%%       LE [listAddQuote] ': E 
%%end function
%%
%%function listAddQuote
%%    replace [list_1_declName]
%%	D [declName] R [list_opt_rest_declName]
%%    by
%%	D [declIDAddQuote] [declOPAddQuote] R [listAddQuoteRest]
%%end function
%%
%%function listAddQuoteRest
%%    replace [list_opt_rest_declName]
%%	, R [list_1_declName]
%%    by
%%	, R [listAddQuote]
%%end function
%%
%%function declIDAddQuote
%%    replace [declName]
%%	 R [Word] D [decoration]
%%    deconstruct D
%%	 P [repeat stroke]
%%    construct S [stroke]
%%	''
%%    construct D2 [decoration]
%%	 P [. S]
%%    by
%%	 R D2
%%end function
%%
%%function declOPAddQuote
%%    replace [declName]
%%	 O [opName] 
%%    by
%%	 O [inSymAddQuote] [preSymAddQuote]
%%	   [postSymAddQuote] [BRAddQuote] [minAddQuote]
%%end function
%%
%%function inSymAddQuote
%%    replace [opName]
%%	'_ I [inSym] D [decoration] '_
%%    deconstruct D
%%	 P [repeat stroke]
%%    construct S [stroke]
%%	''
%%    construct D2 [decoration]
%%	 P [. S]
%%    by
%%	'_ I D2 '_
%%end function
%%
%%function preSymAddQuote
%%    replace [opName]
%%	P [preSym] D [decoration] '_
%%    deconstruct D
%%	 P1 [repeat stroke]
%%    construct S [stroke]
%%	''
%%    construct D2 [decoration]
%%	 P1 [. S]
%%    by
%%	P  D2 '_
%%end function
%%
%%function postSymAddQuote
%%    replace [opName]
%%	'_ P [postSym] D [decoration]
%%    deconstruct D
%%	 P1 [repeat stroke]
%%    construct S [stroke]
%%	''
%%    construct D2 [decoration]
%%	 P1 [. S]
%%    by
%%	'_ P D2
%%end function
%%
%%function BRAddQuote
%%    replace [opName]
%%	'_ '(| '_ '|) D [decoration]
%%    deconstruct D
%%	 P [repeat stroke]
%%    construct S [stroke]
%%	''
%%    construct D2 [decoration]
%%	 P [. S]
%%    by
%%	'_ '(| '_ '|) D2
%%end function
%%
%%function minAddQuote
%%    replace [opName]
%%	- D [decoration]
%%    deconstruct D
%%	 P [repeat stroke]
%%    construct S [stroke]
%%	''
%%    construct D2 [decoration]
%%	 P [. S]
%%    by
%%	- D2
%%end function
%%
%%rule fixPfun
rule main
    match [expression1]
	E1 [expression1] G [inGen] E2 [expression1]
end rule
