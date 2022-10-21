%% From melges%athena@[199.117.41.108] Thu Jun 15 11:28 EDT 1995
%% From: melges@advancedsw.com (Mike Elges)
%% Subject: Re: Possible Bug
%% To: cordy@qucis.queensu.ca (James R. Cordy)
%% In-Reply-To: <9506151456.AA03187@forelle.qucis.queensu.ca> from "James R. Cordy" at Jun 15, 95 10:56:41 am
%% 
%% Dr Cordy,
%% > 
%% > Just send me your entire ruleset and input if you can.
%% > I'll see if we still have the bug.  If we do, I will fix it
%% Thank you
%% > before you (if ever) get TXL Pro. 
%% I hope you where just kidding or you know something I do not???
%% 
%% I have "%%MARKER to mark the spot for the " where not" statement.  
%% My test was to run it with the "where not" not commented and then
%% commented the two lines and ran it again.  You can then diff the
%% two output files and you will see 
%% 
%% <                 isInline: FALSE
%% <                 isVirtual: FALSE
%% ---
%% >                 isInline: TRUE
%% >                 isVirtual: TRUE
%% 
%% which indicates that the a0 parse tree was modified when the 
%% "when not" is commented out.
%% 
%% --------------------START of C++.TXL---------------------------
include "Cpp2.0.grm"

% external function message M [any]
% external function quote X [any]
% external function unquote X [stringlit]
% external function print
% external function debug

function main
	replace [program]
	   P [repeat declaration]
	by
	   P [message "Breaking out Typedefs Structs and Classes"]
             [BreakUpTypedef]
             [BreakUpTypedef1]
             [message "Extracting Class and Inline Functions"]
             [ExtractClassDefAndInlineFunctionDef]
             [message "DoneClass and Inline Functions"]
             [message "Processing Classes"]
             [ProcClass]
             [message "Done Processing Classes"]
end function

rule BreakUpTypedef
   replace [repeat declaration]
      b0 [declaration] b1 [repeat declaration]
   deconstruct b0
      a0 [opt decl_specifiers] a1 [opt declarator_list] ;
   deconstruct * a0
     'typedef a2 [class_specifier] a3 [identifier]
   deconstruct a2
     a4 [class_head] {
          a5 [repeat member_list]
     }
   deconstruct a4
     a6 [class_key] a7 [identifier] a8 [opt base_spec]
   by
     a2 ;
     typedef a6 a7 a3 a1;
     b1
end rule

rule BreakUpTypedef1
   replace [repeat declaration]
      b0 [declaration] b1 [repeat declaration]
   deconstruct b0
      a0 [opt decl_specifiers] a1 [opt declarator_list] ;
   deconstruct * a0
     'typedef a2 [class_specifier] a3 [identifier]
   deconstruct a2
     a4 [class_head] {
          a5 [repeat member_list]
     }
   deconstruct a4
     a6 [class_key]  a8 [opt base_spec]
   deconstruct a3
     uns [repeat '_] nme [id]
   construct tmp [id]
    nme [_ 'XXYY]    [!] 
   construct tmp1 [identifier]
     uns tmp
   construct classSpec [class_specifier]
     a6 tmp1 a8 { a5 }
   by
     classSpec;
     typedef a6 tmp1 a3 a1;
     b1
end rule

rule ProcClass
   replace [class_definition]
        x1 [repeat sc_specifier]
        a [class_key] a1 [opt identifier] a2 [opt base_spec] {
         a3 [repeat member_list] 
        }
        x2 [opt declarator_list] ;
   by
     (CreateSymbol Class SymbolID a1) 
       a3 [RemoveMultipleDeclaration]
          [GetClassAttributes a1]
          [GetClassAttributes1 a1]
          [DecomposeFctDefinitions a1 a]
          [DecomposeFctDefinitions1 a1 a]
          [DecomposeFctDefinitions2 a1]
          [GetDataAttributes a1 a]
          [GetDataAttributes0 a1 a]
          [GetDataAttributes1 a1]
	  [RemoveAccessSpecifier]
%%
%%  After the last function all should be translated from within a class.
%%  if Not we have a problem and will loose data needed to forward.
%%
end rule

rule RemoveAccessSpecifier
  replace [member_list]
    a0 [member_decl2]
  deconstruct a0
    Type [access_specifier] : b1 [repeat member_declaration]
  by
   b1 
end rule

rule RemoveMultipleDeclaration
   replace [repeat member_declaration]
     a0 [member_declaration] d0 [repeat member_declaration]
   deconstruct a0
     a1 [opt my_decl_specifiers]
     a2 [opt member_declarator_list] ;
   deconstruct a2 
     a3 [member_declarator] , a4 [member_declarator] a5 [repeat followingID] 
   by      
     a1  a3; a1 a4 a5; d0
end rule

%%
%%
%%                START OF FUNCTION DEFINITION SECTION.
%%
%%
rule DecomposeFctDefinitions ClassName [opt identifier] ClassKey [class_key]
  replace [member_list]
    a0 [member_decl1]	
  deconstruct * [fct_definition] a0
    a1 [opt my_decl_specifiers] a2 [declarator] 
    a3 [opt ctor_initializer] a4 [fct_body]
  where 
    ClassKey [isClassKeyP]
  construct Type [access_specifier]
    'private
  by
    a0 [DecomposeFctDefinition ClassName Type] 
end rule

rule DecomposeFctDefinitions1 ClassName [opt identifier] ClassKey [class_key]
  replace [member_list]
    a0 [member_decl1]
  deconstruct * [member_declaration] a0
    a1 [opt my_decl_specifiers] a2 [declarator] 
    a3 [opt ctor_initializer] a4 [fct_body]
  where 
    ClassKey [isStructKeyP]
  construct Type [access_specifier]
    'public
  by
    a0 [DecomposeFctDefinition ClassName Type] 
end rule

rule DecomposeFctDefinitions2 ClassName [opt identifier]
  replace [member_list]
    a0 [member_decl2]
  deconstruct a0
    Type [access_specifier] : b1 [repeat member_declaration]
  deconstruct * [member_declaration] a0
    a1 [opt my_decl_specifiers] a2 [declarator] 
    a3 [opt ctor_initializer] a4 [fct_body]
  by
    Type : b1 [DecomposeFctDefinition ClassName Type]
end rule
%%
%%  Above two function collapse here.  This routine first fixes the
%%  missparsed functions and data.
%%
rule DecomposeFctDefinition ClassName [opt identifier] Type [access_specifier]
   replace [member_declaration]
     a0 [member_declaration] 
   deconstruct * [member_declaration] a0
     a1 [opt my_decl_specifiers] a2 [declarator] 
     a3 [opt ctor_initializer] a4 [fct_body]
   where not
     a0 [AllDone]
   by
     a0 [DFDCommon ClassName Type]
end rule
%%
%%  Create a Common Point of Passage.
%%
function DFDCommon ClassName [opt identifier] Type [access_specifier]
   replace [member_declaration]
      a0 [member_declaration]
   deconstruct a0
      a1 [opt my_decl_specifiers] a2 [declarator] 
      a3 [opt ctor_initializer] a4 [fct_body]
   where not
      a0 [AllDone]
   by
      a0 [DFDGetPersistance ClassName Type]
         [DFDGetPersistance1 ClassName Type]
end function

function DFDGetPersistance ClassName [opt identifier] Type [access_specifier]
   replace [member_declaration]
      a0 [member_declaration]
   deconstruct a0
      a1 [opt my_decl_specifiers] a2 [declarator] 
      a3 [opt ctor_initializer] a4 [fct_body]
   deconstruct * [my_decl_specifier] a1
      b0 [persistance]
   by
      a0 [DFDCommon1 ClassName Type b0]
end function

function DFDGetPersistance1 ClassName [opt identifier] Type [access_specifier]
   replace [member_declaration]
      a0 [member_declaration]
   deconstruct a0
      a1 [opt my_decl_specifiers] a2 [declarator] 
      a3 [opt ctor_initializer] a4 [fct_body]
   where not
      a1 [isPersistance]
   construct b0 [persistance]
      'NONE
   by
      a0 [DFDCommon1 ClassName Type b0]
end function

function DFDCommon1 ClassName [opt identifier] Type [access_specifier]
                 Persistance [persistance]
   replace [member_declaration]
      a0 [member_declaration]
   where not
     a0 [AllDone]
   by
      a0 [DFDGetFreind ClassName Type Persistance]
         [DFDGetFreind1 ClassName Type Persistance]
end function
%%
%%  Determine if this function is a freind or not.  In this function
%% friend is true.
%%
function DFDGetFreind ClassName [opt identifier] Type [access_specifier]
                      Persistance [persistance]
   replace [member_declaration]
      a0 [member_declaration]
   deconstruct a0
      a1 [opt my_decl_specifiers] a2 [declarator] 
      a3 [opt ctor_initializer] a4 [fct_body]
   deconstruct * [my_decl_specifier] a1
      'friend
   construct b0 [id]
      'TRUE
   by
      a0 [DFDCommon2 ClassName Type Persistance b0]
end function
%%
%%  Determine if this function is a freind or not.  In this function
%% friend is false.
%%
function DFDGetFreind1 ClassName [opt identifier] Type [access_specifier]
                       Persistance [persistance]
   replace [member_declaration]
      a0 [member_declaration]
   deconstruct a0
      a1 [opt my_decl_specifiers] a2 [declarator] 
      a3 [opt ctor_initializer] a4 [fct_body]
   where not
      a1 [isFreind]
   construct b0 [id]
      'FALSE
   by
      a0 [DFDCommon2 ClassName Type Persistance b0]
end function

%%
%%  Next Collection point, Continues the decomposition of the 
%%  member funtion/data.
%%
function DFDCommon2 ClassName [opt identifier] Type [access_specifier]
                 Persistance [persistance] Friend [id]
   replace [member_declaration]
      a0 [member_declaration]
   where not
     a0 [AllDone]
   by
      a0 [DFDGetSCSpec ClassName Type Persistance Friend]
         [DFDGetSCSpec1 ClassName Type Persistance Friend]
end function
%%
%%  determine the scope specifier for the data or function the value can
%%  be none.  This function gets the sc_Specifier when one exists.
%%
function DFDGetSCSpec ClassName [opt identifier] Type [access_specifier]
                      Persistance [persistance] Friend [id]
   replace [member_declaration]
      a0 [member_declaration]
   deconstruct a0
      a1 [opt my_decl_specifiers] a2 [declarator] 
      a3 [opt ctor_initializer] a4 [fct_body]
   deconstruct * [my_decl_specifier] a1
      b0 [sc_specifier]
   by
      a0 [DFDCommon3 ClassName Type Persistance Friend b0]
end function
%%
%%  determine the scope specifier for the data or function the value can
%%  be none.  This function gets the sc_Specifier ehrn it does not exist.
%%
function DFDGetSCSpec1 ClassName [opt identifier] Type [access_specifier]
                       Persistance [persistance] Friend [id]
   replace [member_declaration]
      a0 [member_declaration]
   deconstruct a0
      a1 [opt my_decl_specifiers] a2 [declarator] 
      a3 [opt ctor_initializer] a4 [fct_body]
   where not
      a1 [isSCSpec]
   construct b0 [sc_specifier]
      'NONE
   by
      a0 [DFDCommon3 ClassName Type Persistance Friend b0]
end function

%%
%%  Next Collection point, Continues the decomposition of the 
%%  member funtion/data.
%%
function DFDCommon3 ClassName [opt identifier] Type [access_specifier]
                    Persistance [persistance] Friend [id] SCSpec [sc_specifier]
   replace [member_declaration]
      a0 [member_declaration]
   where not
     a0 [AllDone]
   by
      a0 [DFDGetType ClassName Type Persistance Friend SCSpec]
         [DFDGetType3 ClassName Type Persistance Friend SCSpec]
end function
%%
%%  The next four function determin the Type of the variable
%%
function DFDGetType ClassName [opt identifier] Type [access_specifier]
                    Persistance [persistance] Friend [id] SCSpec [sc_specifier]
   replace [member_declaration]
      a0 [member_declaration]
   deconstruct a0
      a1 [my_decl_specifiers] a2 [declarator] 
      a3 [opt ctor_initializer] a4 [fct_body]
   construct b1 [my_decl_specifiers]
      a1 [RemoveExtra]
   where not
      a0 [AllDone]
   by
      a0 [DFDCommon4 ClassName Type Persistance Friend SCSpec b1]
end function

function DFDGetType3 ClassName [opt identifier] Type [access_specifier]
                     Persistance [persistance] Friend [id] 
                     SCSpec [sc_specifier]
   replace [member_declaration]
      a0 [member_declaration]
   deconstruct a0
      a1 [opt my_decl_specifiers] a2 [declarator] 
      a3 [opt ctor_initializer] a4 [fct_body]
   where not
      a1 [isTheType]
   construct b0 [my_decl_specifiers]
      'int
   by
      a0 [DFDCommon4 ClassName Type Persistance Friend SCSpec b0]
end function

function DFDCommon4 ClassName [opt identifier] Type [access_specifier]
                    Persistance [persistance] Friend [id] SCSpec [sc_specifier]
                    VarFuncType [my_decl_specifiers]
   replace [member_declaration]
      a0 [member_declaration]
   where not
     a0 [AllDone]
   by
      a0 [DFDGetInline ClassName Type Persistance Friend SCSpec VarFuncType]
         [DFDGetInline1 ClassName Type Persistance Friend SCSpec VarFuncType]
end function

function DFDGetInline ClassName [opt identifier] Type [access_specifier]
                      Persistance [persistance] Friend [id] 
                      SCSpec [sc_specifier] VarFuncType [my_decl_specifiers]
   replace [member_declaration]
      a0 [member_declaration]
   deconstruct a0
      a1 [opt my_decl_specifiers] a2 [declarator] 
      a3 [opt ctor_initializer] a4 [fct_body]
   deconstruct * [fct_specifier] a1
      'inline
   construct b1 [id]
      'TRUE
   by
      a0 [DFDCommon5 ClassName Type Persistance Friend SCSpec VarFuncType b1]
         [DFDCommon5 ClassName Type Persistance Friend SCSpec VarFuncType b1]
end function

function DFDGetInline1 ClassName [opt identifier] Type [access_specifier]
                       Persistance [persistance] Friend [id] 
                       SCSpec [sc_specifier] VarFuncType [my_decl_specifiers]
   replace [member_declaration]
      a0 [member_declaration]
   deconstruct a0
      a1 [opt my_decl_specifiers] a2 [declarator] 
      a3 [opt ctor_initializer] a4 [fct_body]
   where not
      a1 [isInline]
   construct b1 [id]
      'FALSE
   by
      a0 [DFDCommon5 ClassName Type Persistance Friend SCSpec VarFuncType b1]
         [DFDCommon5 ClassName Type Persistance Friend SCSpec VarFuncType b1]
end function

function DFDCommon5 ClassName [opt identifier] Type [access_specifier]
                    Persistance [persistance] Friend [id] SCSpec [sc_specifier]
                    VarFuncType [my_decl_specifiers] isInline [id]
   replace [member_declaration]
      a0 [member_declaration]
   where not
     a0 [AllDone]
   by
      a0 [DFDGetVirtual ClassName Type Persistance Friend SCSpec VarFuncType
                        isInline]
         [DFDGetVirtual1 ClassName Type Persistance Friend SCSpec VarFuncType
                         isInline]
end function

function DFDGetVirtual ClassName [opt identifier] Type1 [access_specifier]
                       Per [persistance] Frnd [id] 
                       SCSpec [sc_specifier] VarFuncType [my_decl_specifiers] 
                       BoolInline [id]
   replace [member_declaration]
      a0 [member_declaration]
   deconstruct a0
      a1 [opt my_decl_specifiers] a2 [declarator] 
      a3 [opt ctor_initializer] a4 [fct_body]
   deconstruct a2
      a5 [repeat ptr_operator] a6 [dname] '( a7 [repeat '(]
      a8 [argument_declaration_list] a9 [repeat ')] ') 
      a10 [opt cv_qualifier_list]
   deconstruct * [my_decl_specifier] a1
      'virtual
   construct b2 [id]
      'FUNCTION_ATT
   construct b3 [id]
      b2 [!]
   by
      (Found a Function Decl: a1 Name: a2 Type: Type1 Persistance: Per
       Friend: Frnd SC Specifier: SCSpec Return Type: VarFuncType a5
       isInline: BoolInline isVirtual: 'TRUE
       Function Name: a6
       Function Args: a8)
     (CreateAttribute "Class.Operation" AttributeID b3 For SymbolID ClassName)
     (AddAttribute Name "Class.Operation.Name" Value ^F a6 ^U AttributeID b3
      SymbolID ClassName)
     (AddAttribute Name "Class.Operation.ReturnType" Value ^F VarFuncType a5 ^U
      AttributeID b3 SymbolID ClassName)
     (AddAttribute Name "Class.Operation.Args" Value ^F a8 ^U
      AttributeID b3 SymbolID ClassName)
     (AddAttribute Name "Class.Operation.Visibility" Value ^F Type1 ^U
      AttributeID b3 SymbolID ClassName)
     (AddAttribute Name "Class.Operation.FunctionDef" Value ^F a3 a4 ^U 
      AttributeID b3 SymbolID ClassName)
     (AddAttribute Name "Class.Operation.Virtual" Value ^F 'TRUE ^U
      AttributeID b3 SymbolID ClassName)
     (AddAttribute Name "Class.Operation.Inline" Value ^F BoolInline ^U
      AttributeID b3 SymbolID ClassName)
end function

function DFDGetVirtual1 ClassName [opt identifier] Type1 [access_specifier]
                        Per [persistance] Frnd [id] 
                        SCSpec [sc_specifier] VarFuncType [my_decl_specifiers] 
                        BoolInline [id]
   replace [member_declaration]
      a0 [member_declaration]
   deconstruct * [fct_definition] a0
      a1 [opt my_decl_specifiers] a2 [declarator] 
      a3 [opt ctor_initializer] a4 [fct_body]
   deconstruct a2
      a5 [repeat ptr_operator] a6 [dname] '( a7 [repeat '(]
      a8 [argument_declaration_list] a9 [repeat ')] ') 
      a10 [opt cv_qualifier_list]
   where not
      a1 [isVirtual]
   construct b2 [id]
      'FUNCTION_ATT
   construct b3 [id]
      b2 [!]
   by
      (Found a Function Decl: a1 Name: a2 Type: Type1 Persistance: Per
       Friend: Frnd SC Specifier: SCSpec Return Type: VarFuncType a5
       isInline: BoolInline isVirtual: 'FALSE
       Function Name: a6
       Function Args: a8)
     (CreateAttribute "Class.Operation" AttributeID b3 For SymbolID ClassName)
     (AddAttribute Name "Class.Operation.Name" Value ^F a6 ^U AttributeID b3
      SymbolID ClassName)
     (AddAttribute Name "Class.Operation.ReturnType" Value ^F VarFuncType a5 ^U
      AttributeID b3 SymbolID ClassName)
     (AddAttribute Name "Class.Operation.Args" Value ^F a8 ^U
      AttributeID b3 SymbolID ClassName)
     (AddAttribute Name "Class.Operation.Visibility" Value ^F Type1 ^U
      AttributeID b3 SymbolID ClassName)
     (AddAttribute Name "Class.Operation.FunctionDef" Value ^F a3 a4 ^U
      AttributeID b3 SymbolID ClassName)
     (AddAttribute Name "Class.Operation.Virtual" Value ^F 'FALSE ^U
      AttributeID b3 SymbolID ClassName)
     (AddAttribute Name "Class.Operation.Inline" Value ^F BoolInline ^U
      AttributeID b3 SymbolID ClassName)
end function
%%
%%
%%                END OF FUNCTION DEFINITION SECTION.
%%
%%

%%
%%
%%                START OF DATA ATTRIBUTES SECTION.
%%
%%

%%
%%  Lets start collecting the Data Attrubutes.
%%  First detrmine the Scope of the Attribute or Operation.
%%  In this case no scope is defined do defualt to private in
%%  class definitions.
%%
rule GetDataAttributes ClassName [opt identifier] ClassKey [class_key]
  replace [member_list]
    a0 [member_decl1]
  deconstruct * [member_declaration] a0
    a1 [opt my_decl_specifiers] a2 [opt member_declarator_list] ;
  where 
    ClassKey [isClassKeyP]
  construct Type [access_specifier]
    'private
  by
    a0 [GetDataAttribute ClassName Type] 
end rule

function isClassKeyP
   match [class_key]
     'class
end function

rule GetDataAttributes0 ClassName [opt identifier] ClassKey [class_key]
  replace [member_list]
    a0 [member_decl1]
  deconstruct * [member_declaration] a0
    a1 [opt my_decl_specifiers] a2 [opt member_declarator_list] ;
  where 
    ClassKey [isStructKeyP]
  construct Type [access_specifier]
    'public
  by
    a0 [GetDataAttribute ClassName Type] 
end rule

function isStructKeyP
   match [class_key]
     'struct
end function

%%
%%  Lets start collecting the Data Attrubutes.
%%  First detrmine the Scope of the Attribute or Operation.
%%  In this case scope is defined so grabe it and continue.
%%
rule GetDataAttributes1 ClassName [opt identifier]
  replace [member_list]
    a0 [member_decl2]
  deconstruct a0
    Type [access_specifier] : b1 [repeat member_declaration]
  deconstruct * [member_declaration] a0
    a1 [opt my_decl_specifiers] a2 [opt member_declarator_list] ;
  by
    Type : b1 [GetDataAttribute ClassName Type]
end rule
%%
%%  Above two function collapse here.  This routine first fixes the
%%  missparsed functions and data.
%%
rule GetDataAttribute ClassName [opt identifier] Type [access_specifier]
   replace [member_declaration]
     a0 [member_declaration] 
   deconstruct * [member_declaration] a0
     a1 [opt my_decl_specifiers] a2 [opt member_declarator_list] ;
   where not
     a0 [AllDone]
   by
     a0 [FixMisparsedFunction]
        [FixMisparsedFunction1]
        [FixMisparsedData]
        [Common ClassName Type]
end rule
%%
%%  Continues the decomposition of the member funtion/data.
%%
function Common ClassName [opt identifier] Type [access_specifier]
   replace [member_declaration]
      a0 [member_declaration]
   where not
     a0 [AllDone]
   by
      a0 [GetPersistance ClassName Type]
         [GetPersistance1 ClassName Type]
end function
%%
%%  This function determine the persistance of the data item.  There are
%%  three types CONST, VOLITALE and NONE.  This function cover the first two.
%%
function GetPersistance ClassName [opt identifier] Type [access_specifier]
   replace [member_declaration]
      a0 [member_declaration]
   deconstruct a0
      a1 [opt my_decl_specifiers] a2 [opt member_declarator_list] ;
   deconstruct * [my_decl_specifier] a1
      b0 [persistance]
   by
      a0 [Common1 ClassName Type b0]
end function
%%
%%  This function determine the persistance of the data item.  There are
%%  three types CONST, VOLITALE and NONE.  This function covers the NONE
%%  case.
%%
function GetPersistance1 ClassName [opt identifier] Type [access_specifier]
   replace [member_declaration]
      a0 [member_declaration]
   deconstruct a0
      a1 [opt my_decl_specifiers] a2 [opt member_declarator_list] ;
   where not
      a1 [isPersistance]
   construct b0 [persistance]
     'NONE
   by
      a0 [Common1 ClassName Type b0]
end function
     
function isPersistance
   match [opt my_decl_specifiers]
      a0 [persistance]
end function
%%
%%  Next Collection point, Continues the decomposition of the 
%%  member funtion/data.
%%
function Common1 ClassName [opt identifier] Type [access_specifier]
                 Persistance [persistance]
   replace [member_declaration]
      a0 [member_declaration]
   where not
     a0 [AllDone]
   by
      a0 [GetFreind ClassName Type Persistance]
         [GetFreind1 ClassName Type Persistance]
end function
%%
%%  Determine if this function is a freind or not.  In this function
%% friend is true.
%%
function GetFreind ClassName [opt identifier] Type [access_specifier]
                   Persistance [persistance]
   replace [member_declaration]
      a0 [member_declaration]
   deconstruct a0
      a1 [opt my_decl_specifiers] a2 [opt member_declarator_list] ;
   deconstruct * [my_decl_specifier] a1
      'friend
   construct b0 [id]
      'TRUE
   by
      a0 [Common2 ClassName Type Persistance b0]
end function
%%
%%  Determine if this function is a freind or not.  In this function
%% friend is false.
%%
function GetFreind1 ClassName [opt identifier] Type [access_specifier]
                    Persistance [persistance]
   replace [member_declaration]
      a0 [member_declaration]
   deconstruct a0
      a1 [opt my_decl_specifiers] a2 [opt member_declarator_list] ;
   where not
      a1 [isFreind]
   construct b0 [id]
      'FALSE
   by
      a0 [Common2 ClassName Type Persistance b0]
end function
     
function isFreind
   match [opt my_decl_specifiers]
      'friend
end function
%%
%%  Next Collection point, Continues the decomposition of the 
%%  member funtion/data.
%%
function Common2 ClassName [opt identifier] Type [access_specifier]
                 Persistance [persistance] Friend [id]
   replace [member_declaration]
      a0 [member_declaration]
   where not
     a0 [AllDone]
   by
      a0 [GetSCSpec ClassName Type Persistance Friend]
         [GetSCSpec1 ClassName Type Persistance Friend]
end function
%%
%%  determine the scope specifier for the data or function the value can
%%  be none.  This function gets the sc_Specifier when one exists.
%%
function GetSCSpec ClassName [opt identifier] Type [access_specifier]
                   Persistance [persistance] Friend [id]
   replace [member_declaration]
      a0 [member_declaration]
   deconstruct a0
      a1 [opt my_decl_specifiers] a2 [opt member_declarator_list] ;
   deconstruct * [my_decl_specifier] a1
      b0 [sc_specifier]
   by
      a0 [Common3 ClassName Type Persistance Friend b0]
end function
%%
%%  determine the scope specifier for the data or function the value can
%%  be none.  This function gets the sc_Specifier ehrn it does not exist.
%%
function GetSCSpec1 ClassName [opt identifier] Type [access_specifier]
                    Persistance [persistance] Friend [id]
   replace [member_declaration]
      a0 [member_declaration]
   deconstruct a0
      a1 [opt my_decl_specifiers] a2 [opt member_declarator_list] ;
   where not
      a1 [isSCSpec]
   construct b0 [sc_specifier]
      'NONE
   by
      a0 [Common3 ClassName Type Persistance Friend b0]
end function
     
function isSCSpec
   match [opt my_decl_specifiers]
      a0 [sc_specifier]
end function
%%
%%  Next Collection point, Continues the decomposition of the 
%%  member funtion/data.
%%
function Common3 ClassName [opt identifier] Type [access_specifier]
                 Persistance [persistance] Friend [id] SCSpec [sc_specifier]
   replace [member_declaration]
      a0 [member_declaration]
   where not
     a0 [AllDone]
   by
      a0 [GetType ClassName Type Persistance Friend SCSpec]
         [GetType3 ClassName Type Persistance Friend SCSpec]
end function
%%
%%  The next two function determin the Type of the variable
%%
function GetType ClassName [opt identifier] Type [access_specifier]
                 Persistance [persistance] Friend [id] SCSpec [sc_specifier]
   replace [member_declaration]
      a0 [member_declaration]
   deconstruct a0
      a1 [my_decl_specifiers] a2 [opt member_declarator_list] ;
   construct b1 [my_decl_specifiers]
      a1 [RemoveExtra]
%%MARKER Comment out the next two line to generate the problem
   where not
      a0 [AllDone]
   by
      a0 [Common4 ClassName Type Persistance Friend SCSpec b1]
end function

rule RemoveExtra
   replace [repeat my_decl_specifier]
     a0 [my_decl_specifier] Rest [repeat my_decl_specifier]
   where 
     a0 [isVirtual1]
        [isInline1]
        [isFriend1]
        [isSCSpecifier1]
   by
     Rest
end rule

function isVirtual1
   match [my_decl_specifier]
      'virtual
end function

function isInline1
   match [my_decl_specifier]
      'inline
end function

function isFriend1
   match [my_decl_specifier]
      'friend
end function

function isSCSpecifier1
   match [my_decl_specifier]
      a0 [sc_specifier]
end function

function GetType3 ClassName [opt identifier] Type [access_specifier]
                  Persistance [persistance] Friend [id] SCSpec [sc_specifier]
   replace [member_declaration]
      a0 [member_declaration]
   deconstruct a0
      a1 [opt my_decl_specifiers] a2 [opt member_declarator_list] ;
   where not
      a1 [isTheType]
   construct b0 [my_decl_specifiers]
      'int
   by
      a0 [Common4 ClassName Type Persistance Friend SCSpec b0]
end function
     
function isTheType
   match [opt my_decl_specifiers]
      a0 [the_type]
end function

function Common4 ClassName [opt identifier] Type [access_specifier]
                 Persistance [persistance] Friend [id] SCSpec [sc_specifier]
                 VarFuncType [my_decl_specifiers]
   replace [member_declaration]
      a0 [member_declaration]
   where not
     a0 [AllDone]
   by
      a0 [GetInline ClassName Type Persistance Friend SCSpec VarFuncType]
         [GetInline1 ClassName Type Persistance Friend SCSpec VarFuncType]
end function

function GetInline ClassName [opt identifier] Type [access_specifier]
                   Persistance [persistance] Friend [id] SCSpec [sc_specifier]
                   VarFuncType [my_decl_specifiers]
   replace [member_declaration]
      a0 [member_declaration]
   deconstruct a0
      a1 [opt my_decl_specifiers] a2 [opt member_declarator_list] ;
   deconstruct * [my_decl_specifier] a1
      'inline
   construct b1 [id]
      'TRUE
   by
      a0 [Common5 ClassName Type Persistance Friend SCSpec VarFuncType b1]
         [Common5 ClassName Type Persistance Friend SCSpec VarFuncType b1]
end function

function GetInline1 ClassName [opt identifier] Type [access_specifier]
                   Persistance [persistance] Friend [id] SCSpec [sc_specifier]
                   VarFuncType [my_decl_specifiers]
   replace [member_declaration]
      a0 [member_declaration]
   deconstruct a0
      a1 [opt my_decl_specifiers] a2 [opt member_declarator_list] ;
   where not
      a1 [isInline]
   construct b1 [id]
      'FALSE
   by
      a0 [Common5 ClassName Type Persistance Friend SCSpec VarFuncType b1]
         [Common5 ClassName Type Persistance Friend SCSpec VarFuncType b1]
end function

function isInline
   match [opt my_decl_specifiers]
      'inline
end function

function Common5 ClassName [opt identifier] Type [access_specifier]
                 Persistance [persistance] Friend [id] SCSpec [sc_specifier]
                 VarFuncType [my_decl_specifiers] isInline [id]
   replace [member_declaration]
      a0 [member_declaration]
   where not
     a0 [AllDone]
   by
      a0 [GetVirtual ClassName Type Persistance Friend SCSpec VarFuncType
                     isInline]
         [GetVirtual1 ClassName Type Persistance Friend SCSpec VarFuncType
                      isInline]
end function

function GetVirtual ClassName [opt identifier] Type [access_specifier]
                   Persistance [persistance] Friend [id] SCSpec [sc_specifier]
                   VarFuncType [my_decl_specifiers] isInline [id]
   replace [member_declaration]
      a0 [member_declaration]
   deconstruct a0
      a1 [opt my_decl_specifiers] a2 [opt member_declarator_list] ;
   deconstruct * [my_decl_specifier] a1
      'virtual
   construct b1 [id]
      'TRUE
   by
      a0 
         [ProcFct0 ClassName Type Persistance Friend SCSpec 
          VarFuncType isInline b1]
         [ProcFct1 ClassName Type Persistance Friend SCSpec VarFuncType
          isInline b1]
         [ProcFct2 ClassName Type Persistance Friend SCSpec VarFuncType
          isInline b1]
         [FindTheData1 ClassName Type Persistance Friend SCSpec VarFuncType 
         isInline b1]
         [FindTheData ClassName Type Persistance Friend SCSpec VarFuncType 
          isInline b1]
end function

function GetVirtual1 ClassName [opt identifier] Type [access_specifier]
                     Persistance [persistance] Friend [id] 
                     SCSpec [sc_specifier] VarFuncType [my_decl_specifiers] 
                     isInline [id]
   replace [member_declaration]
      a0 [member_declaration]
   deconstruct a0
      a1 [opt my_decl_specifiers] a2 [opt member_declarator_list] ;
   where not
      a1 [isVirtual]
   construct b1 [id]
      'FALSE
   by
      a0 
         [ProcFct0 ClassName Type Persistance Friend SCSpec VarFuncType 
          isInline b1]
         [ProcFct1 ClassName Type Persistance Friend SCSpec VarFuncType
          isInline b1]
         [ProcFct2 ClassName Type Persistance Friend SCSpec VarFuncType
          isInline b1]
         [FindTheData1 ClassName Type Persistance Friend SCSpec VarFuncType 
         isInline b1]
         [FindTheData ClassName Type Persistance Friend SCSpec VarFuncType 
         isInline b1]
end function

function isVirtual
   match [opt my_decl_specifiers]
      'virtual
end function

function ProcFct0 ClassName [opt identifier] Type1 [access_specifier]
                  Per [persistance] Frnd [id] SCSpec [sc_specifier] 
                  VarFuncType [my_decl_specifiers] BoolInline [id] 
                  BoolVirtual [id]
   replace [member_declaration]
      a0 [member_declaration]
   deconstruct a0
      a1 [opt my_decl_specifiers] a2 [opt member_declarator_list] ;
   deconstruct * [member_declarator_list] a2
     a4 [repeat ptr_operator] a5 [dname] '( a6 [repeat '(] 
     a7 [argument_declaration_list] a8 [repeat ')] ') 
     a9 [opt cv_qualifier_list] a11 [opt pure_specifier]
   deconstruct * a7
     q1 [argument_declaration]
   deconstruct a7
     "FOO*" a12 [decl_specifiers] a13 [opt abstract_declarator]
   where not
      a0 [AllDone]
   construct a14 [argument_declaration_list] 
      a12 a13
   construct b2 [id]
      'FUNCTION_ATT
   construct b3 [id]
      b2 [!]
   by
      (Found a Function Decl: a1 Name: a2 Type: Type1 Persistance: Per
       Friend: Frnd SC Specifier: SCSpec Return Type: VarFuncType a4
       isInline: BoolInline isVirtual: BoolVirtual
       Function Name: a5
       Function Args: a14)
     (CreateAttribute "Class.Operation" AttributeID b3 For SymbolID ClassName)
     (AddAttribute Name "Class.Operation.Name" Value ^F a5 ^U AttributeID b3
      SymbolID ClassName)
     (AddAttribute Name "Class.Operation.ReturnType" Value ^F VarFuncType a4 ^U
      AttributeID b3 SymbolID ClassName)
     (AddAttribute Name "Class.Operation.Args" Value ^F a14 ^U
      AttributeID b3 SymbolID ClassName)
     (AddAttribute Name "Class.Operation.Visibility" Value ^F Type1 ^U
      AttributeID b3 SymbolID ClassName)
     (AddAttribute Name "Class.Operation.Virtual" Value ^F BoolVitual ^U
      AttributeID b3 SymbolID ClassName)
     (AddAttribute Name "Class.Operation.Inline" Value ^F BoolInline ^U
      AttributeID b3 SymbolID ClassName)
end function

function ProcFct1 ClassName [opt identifier] Type1 [access_specifier]
                  Per [persistance] Frnd [id] SCSpec [sc_specifier]
                  VarFuncType [my_decl_specifiers] BoolInline [id] 
                  BoolVirtual [id]
   replace [member_declaration]
      a0 [member_declaration]
   deconstruct a0
      a1 [opt my_decl_specifiers] a2 [opt member_declarator_list] ;
   deconstruct * [member_declarator] a2
     a4 [repeat ptr_operator] a5 [dname] '( a6 [repeat '(] 
     a7 [argument_declaration_list] a8 [repeat ')] ') 
     a9 [opt cv_qualifier_list] a11 [opt pure_specifier]
   where not
      a0 [AllDone]
   construct b2 [id]
      'FUNCTION_ATT
   construct b3 [id]
      b2 [!]
   by
      (Found a Function Decl: a1 Name: a2 Type: Type1 Persistance: Per
       Friend: Frnd SC Specifier: SCSpec Return Type: VarFuncType a4
       isInline: BoolInline isVirtual: BoolVirtual
       Function Name: a5
       Function Args: a7)
     (CreateAttribute "Class.Operation" AttributeID b3 For SymbolID ClassName)
     (AddAttribute Name "Class.Operation.Name" Value ^F a5 ^U AttributeID b3
      SymbolID ClassName)
     (AddAttribute Name "Class.Operation.ReturnType" Value ^F VarFuncType a4 ^U
      AttributeID b3 SymbolID ClassName)
     (AddAttribute Name "Class.Operation.Args" Value ^F a7 ^U
      AttributeID b3 SymbolID ClassName)
     (AddAttribute Name "Class.Operation.Visibility" Value ^F Type1 ^U
      AttributeID b3 SymbolID ClassName)
     (AddAttribute Name "Class.Operation.Virtual" Value ^F BoolVitual ^U
      AttributeID b3 SymbolID ClassName)
     (AddAttribute Name "Class.Operation.Inline" Value ^F BoolInline ^U
      AttributeID b3 SymbolID ClassName)
end function

%%
%%  This case is needed to catch the case of extra parens around the function
%%  name and/or the declarations.
%%
function ProcFct2 ClassName [opt identifier] Type1 [access_specifier]
                  Per [persistance] Frnd [id] SCSpec [sc_specifier]
                  VarFuncType [my_decl_specifiers] BoolInline [id] 
                  BoolVirtual [id]
   replace [member_declaration]
      a0 [member_declaration]
   deconstruct a0
      a1 [opt my_decl_specifiers] a2 [opt member_declarator_list] ;
   deconstruct * [member_declarator] a2
     q1 [declarator] a11 [opt pure_specifier]
   deconstruct * [declarator] a2
     a4 [repeat ptr_operator] a5 [dname] 
   deconstruct * [declarator_extension] a2 
     '( a6 [repeat '(] a7 [argument_declaration_list] a8 [repeat ')] ') 
     a9 [opt cv_qualifier_list] 
   where not
      a0 [AllDone]
   construct b2 [id]
     'FUNCTION_ATT 
   construct b3 [id]
      b2 [!]
   by
      (Found a Function Decl: a1 Name: a2 Type: Type1 Persistance: Per
       Friend: Frnd SC Specifier: SCSpec Return Type: VarFuncType a4
       isInline: BoolInline isVirtual: BoolVirtual
       Function Name: a5
       Function Args: a7)
     (CreateAttribute "Class.Operation" AttributeID b3 For SymbolID ClassName)
     (AddAttribute Name "Class.Operation.Name" Value ^F a5 ^U AttributeID b3
      SymbolID ClassName)
     (AddAttribute Name "Class.Operation.ReturnType" Value ^F VarFuncType a4 ^U
      AttributeID b3 SymbolID ClassName)
     (AddAttribute Name "Class.Operation.Args" Value ^F a7 ^U
      AttributeID b3 SymbolID ClassName)
     (AddAttribute Name "Class.Operation.Visibility" Value ^F Type1 ^U
      AttributeID b3 SymbolID ClassName)
     (AddAttribute Name "Class.Operation.Virtual" Value ^F BoolVitual ^U
      AttributeID b3 SymbolID ClassName)
     (AddAttribute Name "Class.Operation.Inline" Value ^F BoolInline ^U
      AttributeID b3 SymbolID ClassName)
end function

function FindTheData1 ClassName [opt identifier] Type1 [access_specifier]
                      Per [persistance] Frnd [id] SCSpec [sc_specifier]
                      VarFuncType [my_decl_specifiers] BoolInline [id]
                      BoolVirtual [id]
   replace [member_declaration]
      a0 [member_declaration]
   deconstruct a0
      a1 [opt my_decl_specifiers] a2 [opt member_declarator_list] ;
   deconstruct a2 
      b1 [repeat ptr_operator] b2 [dname] b3 [repeat declarator_extension]
   where not
      a0 [AllDone]
   by
      (Found a Data Decl: a1 Name: a2 Type: Type1 Persistance: Per
       Friend: Frnd SC Specifier: SCSpec Variable Type: VarFuncType b1
       isInline: N/A isVirtual: N/A
       Variable Name: b2 b3)
end function

%% 
%%  This is the catch all for the: 
%%    [opt my_decl_specifiers] [opt member_declarator_list]
%%  case.
%%
function FindTheData ClassName [opt identifier] Type1 [access_specifier]
                     Per [persistance] Frnd [id] SCSpec [sc_specifier]
                     VarFuncType [my_decl_specifiers] BoolInline [id]
                     BoolVirtual [id]
   replace [member_declaration]
      a0 [member_declaration]
   deconstruct a0
      a1 [opt my_decl_specifiers] a2 [opt member_declarator_list] ;
   where not
      a0 [AllDone]
   by
      (Found a Data Decl: a1 Name: a2 Type: Type1 Persistance: Per
       Friend: Frnd SC Specifier: SCSpec Variable Type: VarFuncType
       isInline: N/A isVirtual: N/A
       BAD DATA)
end function
%%
%%
%%                END OF DATA ATTRIBUTES SECTION.
%%
%%

function FixMisparsedData
   replace [member_declaration]
      a0 [opt my_decl_specifiers] ;
   deconstruct * [repeat my_decl_specifier] a0
      d0 [my_decl_specifier]
   deconstruct * [my_decl_specifier] d0
      b0 [identifier]
   construct c0 [member_declarator]
      "DATA*" b0
   by 
      a0 [remove_last1 d0] c0 ;
end function

function FixMisparsedFunction 
   replace [member_declaration]
      a0 [opt my_decl_specifiers] a1 [opt member_declarator_list] ;
   deconstruct * [repeat my_decl_specifier] a0
      d0 [my_decl_specifier]
   deconstruct * [my_decl_specifier] d0
      b0 [identifier] 
   deconstruct * [member_declarator] a1
     '( b1 [identifier] ')
   construct b2 [decl_specifiers]
       b1
   construct q1 [argument_declaration]
      "FOO*" b2
   construct q0 [dname]
      b0
   construct c0 [opt member_declarator_list] 
     q0  '( q1 ') %%'( b1 ')
   by
     a0 [remove_last1 d0] c0 ;
end function

function FixMisparsedFunction1
   replace [member_declaration] 
      a0 [opt my_decl_specifiers] a1 [opt member_declarator_list] ;
   deconstruct * a0
      a2 [identifier] 
   deconstruct * [declarator] a1
      '( a3 [identifier] ')
   construct b2 [decl_specifiers]
       a3
   construct q1 [argument_declaration]
      "FOO*" b2
   construct q0 [dname]
      a2
   construct c0 [opt member_declarator_list] 
     q0  '( q1 ') %%'( b1 ')
   by
     c0 ;
end function

%%
%% This rule is suppose to remove the last entry in a 
%% [repeat my_decl_specifier] but it leaves the first and last and
%% deletes the middle.  (WHO KNOWS WHY!!!!!!!!!!!!!!!!)
%%
rule remove_last
   replace [repeat my_decl_specifier]
       Last [my_decl_specifier]
   by 
     % nada
end rule
%%
%%  This rule removes a user supplied element from the list.
%%
rule remove_last1 d0 [my_decl_specifier]
   replace [repeat my_decl_specifier]
       Value [my_decl_specifier] Rest [repeat my_decl_specifier]
   where
       Value [isDO d0]
   by 
       Rest
end rule

function isDO d0 [my_decl_specifier]
   match [my_decl_specifier]
      d0
end function



rule GetClassAttributes ClassName [opt identifier]
  replace [member_decl1]
    a0 [member_decl1]
  deconstruct * [member_declaration] a0
    a4 [my_class_specifier] ;
  construct Type [access_specifier]
    'private
  by
    a0 [GetClassAttribute ClassName Type]
end rule

rule GetClassAttributes1 ClassName [opt identifier]
  replace [member_list]
    a0 [member_decl2]
  deconstruct a0
    Type [access_specifier] : b1 [repeat member_declaration]
  deconstruct * [member_declaration] a0
    a1 [my_class_specifier] ;
  by
    Type : b1 [GetClassAttribute ClassName Type]
end rule


rule GetClassAttribute ClassName [opt identifier] Type [access_specifier]
   replace [member_declaration]
     a0 [member_declaration] 
   deconstruct a0 
     a1 [my_class_specifier] ;
   where not
     a0 [AllDone]
   by
     a0 [FindStructerClass ClassName Type] 
end rule 

function FindStructerClass ClassName [opt identifier] 
                           Type1 [access_specifier]
   replace [member_declaration]
      b0 [member_declaration] 
   deconstruct b0 
      a0 [my_class_specifier] ;
   where 
      a0 [isClassP] [isStructerP] 
   where not
      b0 [AllDone]
   by
      b0 [CreateStructerAttribute ClassName Type1 a0]
end function


function CreateStructerAttribute ClassName1 [opt identifier] 
                                 Type1 [access_specifier]
                                 CS [my_class_specifier]
   replace [member_declaration]
      b0 [member_declaration]
   construct type [stringlit]
     _ [+ "CLASS.SUBSUMED.TYPE"]
   construct data [stringlit]
     _ [+ "CLASS.SUBSUMED.DATA"]
   deconstruct b0
      a0 [my_class_specifier] ;
   by
      (AddAttribute Type type Value Type1 To ClassName1)
      (AddAttribute Type data Value ^G CS ^G To ClassName1) 
end function

function isClassP
   match [my_class_specifier]
     'class a1 [opt identifier] a2 [opt base_spec] 
         { a3 [repeat my_member_list] }
end function

function isStructerP
   match [my_class_specifier]
     'struct a1 [opt identifier] a2 [opt base_spec] 
          { a3 [repeat my_member_list] }
end function

function AllDone
   match [member_declaration]
     a1 [Translation]
end function

rule ExtractClassDefAndInlineFunctionDef
	replace [repeat declaration]
	    a [declaration]
	    Rest [repeat declaration]
	where not
	    a [isClassDefinition] %% [isInlineFunction]
	by
	  Rest
end rule

function isClassDefinition
	match [declaration]
	  Class [class_definition]
end function

function isInlineFunction
	match [declaration]
	  InlineFunction [inline_fct_definition]
end function

function isOrigClassSpec
        match [class_specifier]
            CH [class_head] { ML [repeat member_list] }
end function

%% ------------------------END OF FILE C++.Txl-------------------------------
