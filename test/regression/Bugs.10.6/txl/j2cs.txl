% TXL 103a3 Translation, Java to C#
% Rihab Eltayeb, Sudan University, March 2005
% [part of master thesis project]
% CS refers to C#

% The base Java grammar and grammar overrides
include "Java.grm"
include "JavaCommentOverrides.grm"
% Translation rule sets
include "DataStructures.grm"
include "HelperRules.rul"
include "TranslateMembers.rul"
include "TranslateInitializers.rul"
include "TranslateFieldDeclaration.rul"
include "TranslateBlockStatements.rul"

% Main translation rule 
function main
	    %aid mapping of modifiers as java -> C#
	    %Note that protected and internal protected modifiers in C# has no
	    %equivalent modifiers in java
	    export ClassInterfaceMapping [Mapper]
		'protected -> 'internal
		'final 	   -> 'sealed 
	    export PrimDataTypesMapping [DataMapper]
		'byte -> 'sbyte
		'boolean -> 'bool 
	    %Statements 
	    export StatementMapping [StmtMapper]
		'System.out.println -> 'Console.WriteLine
		'System.out.print -> 'Console.Write
	    %and Runtime and checked Exception Subclasses 
	    export RunTimeExceptionsMapper[ExceptionMapper]	
	    	'ArrayIndexOutOfBoundsException -> 'IndexOutOfRangeException
	    	'ArrayStoreException -> 'ArrayTypeMismatchException
	    	'ClassCastException  ->	'InvalidCastException
	    	'IllegalArgumentException -> 'FormatException
	    	'IllegalMonitorStateException -> 'Threading.SynchronizationLockException
	    	'IllegalStateException -> 'ExecutionEngineException
	    	'IllegalThreadStateException ->	'Threading.ThreadStateException
	    	'IndexOutOfBoundsException -> 'IndexOutOfRangeException
	    	'NullPointerException -> 'NullReferenceException
	    	'NumberFormatException -> 'System.Exception
	    	'SecurityException -> 'Security.SecurityException
	    	'StringIndexOutOfBounds	-> 'IndexOutOfRangeException
	    	'UnsupportedOperationException -> 'NotSupportedException
	    	'ClassNotFoundException -> 'System.Exception
	    	'CloneNotSupportedException -> 'System.NotSupportedException
	    	'IllegalAccessException	-> 'System.UnauthorizedAccessException
	    	'InstantiationException -> 'System.Exception
	    	'InterruptedException -> 'System.Threading.ThreadInterruptedException
	    	'NoSuchFieldException -> 'System.MissingFieldException
	    	'NoSuchMethodException -> 'System.MissingMethodException	    
	replace [program] 
            PHeader[opt package_header]
	    ImportDeclaration[repeat import_declaration] 
	    TypeDeclr[repeat type_declaration]
	    
	    %include the System namespace
	    construct DefaultImportDeclaration[repeat import_declaration] 
   	       	'using 'System ;
	    %change each import 
	    construct NewImportDeclaration[repeat import_declaration] 
   	       DefaultImportDeclaration[changeImportToUsing each ImportDeclaration]
   	    % before adding braces
   	    construct NewProgram[program]
   	    	NewImportDeclaration
	        PHeader[changePackageToNamespace]
	                 TypeDeclr[changeClassHeader]
	                       	  [changeInterfaceHeader]
   	by
            NewProgram[addBraces]
end function
% add the optional braces when required
function addBraces %
replace [program] 
	NewImportDeclaration[repeat import_declaration]
	PHeader[package_header]	    
	TypeDeclr[repeat type_declaration]
	%construct Length[number]
	%	 _[length NewImportDeclaration]
	%where Length[> 0]
	by
	NewImportDeclaration
	PHeader	    
	'{
	    TypeDeclr
	'}
end function	 
% *********	DATA STRUCTURES SECTION	*********
% contains data structures and types that I defined
% *********	DEFINE SECTION		*********
% contains the newly added parts that does not exist
% in Java grammar and I need them to transform to C#
define namespace_member_declaration
	[opt package_header] [IN]
	[opt '{][NL][IN]
		[repeat type_declaration][EX]
	[opt '}][NL][IN]
end define
% *********	REDEFINE SECTION	*********
% contains the parts that need modifications so as to 
% include C# notation that differs in syntax from Java
redefine package_declaration
     ...%Java
    |
    [repeat import_declaration]%C#
    [namespace_member_declaration]
end redefine

redefine import_declaration
      ...%Java
    |
    'using [imported_name] '; [NL]%C#
end redefine

redefine package_header
    ...%Java
    |
    'namespace [package_name] [NL]%C# 
end define

redefine extends_clause
    ...%Java
    |
    ': [list qualified_name+]%C#
end redefine
redefine implements_clause
    ...%Java
    |
    ': [list qualified_name+]%C#
end redefine

% *********	PACKAGE and IMPORTS SECTION	*********
% [1]------------------------------------------------------------------------------- 
% To change library access from import to using clause
function changeImportToUsing importDec[import_declaration]
	deconstruct importDec
	    'import Name[package_or_type_name] DotStar[opt dot_star] '; 
	replace *[repeat import_declaration]
	by
	    'using Name ';%remove DotStar
	    %decide how to change for proper C# equivelant API
end function
% [2]-------------------------------------------------------------------------------
% To change the method of grouping from package to namespace
function changePackageToNamespace
	replace [opt package_header]
	    'package Name[package_name] '; 
	by
	    'namespace Name 
end function	
% ------------------------------------------------------------------------------- 
% *********	CLASSES and INTERFACES SECTION	*********
% [1]---------------------------------------------------------------------------- 
% To change the class header which includes changing
% of the modifiers,extends and implements clauses
function changeClassHeader
% Java: [repeat modifier] 'class [class_name] [opt extends_clause] [opt implements_clause]
% C#:   class-modifiersopt   class   identifier   class-base opt   class-body   ;opt 
% Note attributesopt is not used in Java
	replace [repeat type_declaration]
		ClassHead[class_header]ClassBody[class_body]
		Remaining [repeat type_declaration]
		deconstruct ClassHead
			modifiers[repeat modifier] 'class Name[class_name] ExtendClause[opt extends_clause] ImplmntClause[opt implements_clause]
		construct NewModifiers [repeat modifier]		
			modifiers[changeModifiers ]
		construct NewImplement[opt implements_clause]
			ImplmntClause[changeImplement ExtendClause]
		construct NewExtend [opt extends_clause ]		
			ExtendClause[changeExtend]
		construct NewClassHead[class_header]
		NewModifiers 'class Name NewExtend NewImplement
		%to set a constructor if needed
		export ClassName[class_name]
			Name	
	by
		NewClassHead[addClassExtendToImplmt]
		ClassBody [translateEmptyBody][changeClassBody]   
		Remaining[changeClassHeader][changeInterfaceHeader]
end function
% [2]-------------------------------------------------------------------------------
% To change the interface header which includes changing
% of the modifiers,extends and implements clauses
function changeInterfaceHeader
% Java: [repeat modifier] 'interface [interface_name] [opt extends_clause] [opt implements_clause]
% C#:   attributesopt interface-modifiersopt interface identifier interface-baseopt interface-body ;opt 
% Note attributesopt is not used in Java
	replace [repeat type_declaration]
		InterfaceHead[interface_header] InterfaceBody[interface_body]
		Remaining [repeat type_declaration]
		deconstruct InterfaceHead
			modifiers[repeat modifier] 'interface Name[interface_name] ExtendClause[opt extends_clause] ImplmntClause[opt implements_clause]
		construct NewModifiers [repeat modifier]		
			modifiers[changeModifiers ]
		construct NewImplement[opt implements_clause]
			ImplmntClause[changeImplement ExtendClause]
		construct NewExtend [opt extends_clause]		
			ExtendClause[changeExtend]
		construct NewInterfaceHead[interface_header]
		NewModifiers 'interface Name NewExtend NewImplement
	by
		NewInterfaceHead[addInterfaceExtendToImplmt]
		InterfaceBody [translateEmptyBody][changeInterfaceBody] 
		Remaining[changeClassHeader][changeInterfaceHeader]
end function
% [3]-------------------------------------------------------------------------------
% To change class or interface access modifiers
function changeModifiers
	replace [repeat modifier]
		Modifiers[modifier]
		import ClassInterfaceMapping [Mapper]
		deconstruct * [table_entry] ClassInterfaceMapping
			Modifiers -> CSModifier [modifier]
	by
		CSModifier
end function
% [4]-------------------------------------------------------------------------------
% To change the inheritance syntax from extends to colon representation
function changeExtend 
	replace [opt extends_clause]
		'extends Enames[list type_name+] 
		construct AllNames[repeat qualified_name]
			 _[^ Enames]
		construct NewListEnames[list qualified_name]
			 _[toQualifiedName each AllNames]
	by
		': NewListEnames
end function
% [5]-------------------------------------------------------------------------------
% To change the implementation syntax from implements to colon representation
function changeImplement ExtendClause[opt extends_clause]
	%check if no extend clause then base class will be Object
	deconstruct not ExtendClause
		'extends Enames[list type_name+] 
	replace [opt implements_clause]
		'implements Inames[list qualified_name+]
	construct BaseAll [list qualified_name]
		Object
	construct NewNames[list qualified_name+]
		BaseAll[, Inames]
	by
		': NewNames
end function
% [6]-------------------------------------------------------------------------------
% applied if both extends and implements exist in class header
% the implements will not be changed before
function addClassExtendToImplmt 
	replace [class_header]
		modifiers[repeat modifier] 'class Name[class_name] ExtendClause[opt extends_clause] ImplmntClause[opt implements_clause]
		deconstruct ExtendClause
		': Enames[list qualified_name+] 
		deconstruct ImplmntClause
		'implements Inames[list qualified_name+] 
		construct NewAddedClause[list qualified_name+]
			Enames[, Inames]
		construct NewExtend [opt extends_clause]
			': NewAddedClause
	by
		modifiers 'class Name NewExtend
end function
% [7]-------------------------------------------------------------------------------
% applied if both extends and implements exist in interface header
% but the implements will not be changed before
function addInterfaceExtendToImplmt 
	replace [interface_header]
		modifiers[repeat modifier] 'interface Name[interface_name] ExtendClause[opt extends_clause] ImplmntClause[opt implements_clause]
		deconstruct ExtendClause
		': Enames[list qualified_name+] 
		deconstruct ImplmntClause
		'implements Inames[list qualified_name+] 
		construct NewAddedClause[list qualified_name+]
			Enames[, Inames]
		construct NewExtend [opt extends_clause]
			': NewAddedClause
	by
		modifiers 'interface Name NewExtend
end function
% [8]-------------------------------------------------------------------------------
% to treat an empty body  
function translateEmptyBody
replace [class_body]
	'{
		;
	'}
	by
	'{
	'}
end function
% [9]-------------------------------------------------------------------------------
% to treat the body of a class 
function changeClassBody
replace [class_body]
	'{                                   
		ClassBodyDecls[repeat class_body_declaration]    
   	'} optSemiColon[opt ';]          
	export InitCalls[repeat declaration_or_statement]
		_%empty one
	by
	'{	
		 ClassBodyDecls[translateFieldDeclaration]
		 	       [translateInstanceInit]
		 	       [translateStaticInit]
		 	       [translateBodyMembers]
		 	        	
	'}optSemiColon
end function
% [10]-------------------------------------------------------------------------------
% inside the body
function translateBodyMembers
	replace [repeat class_body_declaration]                               
		ClassBodyDecl[class_body_declaration] 
		RemainingRepeatBodyDecl[repeat class_body_declaration]    
   	by
	 	ClassBodyDecl[translateMemberDeclaration]%type declaration
	 		     [translateMethodConstructor]   
    		RemainingRepeatBodyDecl[translateBodyMembers]
end function

% [11]-------------------------------------------------------------------------------
% to treat the body of an interface,the members of it are fields and methods.
function changeInterfaceBody
	replace[interface_body]
		'{                                   
			InterfaceBodyDecls[repeat class_body_declaration]    
		'} optSemiColon[opt ';]          
		by
		'{	
			 InterfaceBodyDecls[translateIntFieldDeclaration]
			 	           [translateIntMethods]
			 	           %[translateBodyMembers]
	'}optSemiColon
end function
% [12]-------------------------------------------------------------------------------
% to convert a list of type_name to list of qualified_name
function toQualifiedName Name[qualified_name]
replace[list qualified_name]
	TypeName[list qualified_name]
by
	TypeName[,Name]
end function
% function 
%
% end function

