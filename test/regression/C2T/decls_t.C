% TXL 7.7a4
% Andy Maloney, Queen's University, January 1995
%	[part of 499 project]


%% *****
%% common to consts, vars, typedefs, and function arguments
%%

rule changeCharToString
	replace [type_specifier]
		'char
	
	by
		'string '( '1 ')
end rule

rule changeLongToInt
	replace [type_specifier]
		'long
	
	by
		'int
end rule

rule changeFloatToReal
	replace [type_specifier]
		'float
	
	by
		'real
end rule

rule changeDoubleToReal
	replace [type_specifier]
		'double
	
	by
		'real
end rule


%% change array of chars to string
function changeToStrings
	replace * [type_specifier]
		'array 0 .. N [number] 'of 'char
	
	construct newN [number]
		N [+ 1]
		
	construct newTuringTypeSpec [type_specifier]
		'string '( newN ')
		
	by
		newTuringTypeSpec
end function


%% *****
%% constants
%%

define t_constDecl
	'const [identifier] ': [type_specifier] ':= [expression]		[NL]
end define


function translateCConst
	replace [externaldefinition]
		'const T [type_specifier] N [identifier] '= E [expression] ';
		
	construct newType [type_specifier]
		T
			[changeCharToString]
			[changeLongToInt]
			[changeFloatToReal]
			[changeDoubleToReal]
		
	by	
		'const N ': newType ':= E
end function

		
%% *****
%% types
%%

define t_typeDecl
	'type [identifier] : [type_specifier]		[NL]
end define

function translateCType
	replace [externaldefinition]
		'typedef T [type_specifier] OP [opt pointer] N [identifier] 
			OAP [opt array_part] ';

	construct newType [type_specifier]
		T
			[changeCharToString]
			[changeLongToInt]
			[changeFloatToReal]
			[changeDoubleToReal]
		
	construct newTuringConst [externaldefinition]
		'type N : newType
		
	by
		newTuringConst
end function


%% *****
%% vars
%%

define t_varDecl
	[t_var]
  |
    [repeat t_var]
end define

define t_var
	'var [decl_identifier] ': [type_specifier]	[opt t_initialisation]	[NL]
end define

define t_initialisation
	':= [expression]
end define

function translateCVar
	replace [externaldefinition]
		T [type_specifier] D [list decl_id_part+] ';
	
	construct newTuringVar [repeat t_var]
		_
			[translatePointerVarDecl T each D]
			[translateVarDecl T each D]
	
	construct newED [externaldefinition]
		newTuringVar
		
	by
		newED
end function

%% translate var declarations NOT returning pointers to types
function translateVarDecl T [type_specifier] D [decl_id_part]
	deconstruct D
		DI [decl_identifier] OAP [opt array_part] OI [opt initialisation]
			
	replace [repeat t_var]
		SoFar [repeat t_var]
	
	construct TuringVar [t_var]
		'var DI ': T
	
	construct newTuringVar [t_var]
		TuringVar
				[addOptArrayPart OAP]
				[addOptInit OI]
				[changeCharToString]
				[changeLongToInt]
				[changeFloatToReal]
				[changeDoubleToReal]
	
	by
		SoFar [. newTuringVar]	
end function

%% translate var declarations returning pointers to types
function translatePointerVarDecl T [type_specifier] D [decl_id_part]
	deconstruct D
		'* DI [decl_identifier] OAP [opt array_part] OI [opt initialisation]
	
	deconstruct T
		'char

	replace [repeat t_var]
		SoFar [repeat t_var]
	
	construct TuringVar [t_var]
		'var DI ': 'string
	
	construct newTuringVar [t_var]
		TuringVar
				[addOptArrayPart OAP]
				[addOptInit OI]
	
	by
		SoFar [. newTuringVar]	
end function

%% add initialisation if it exists
function addOptInit OI [opt initialisation]
	deconstruct OI
		'= E [expression]
		
	replace [t_var]
		'var DI[decl_identifier] ': T[type_specifier]
		
	by
		'var DI ': T ':= E [changeExpression]
end function

%% add array part if it exists
function addOptArrayPart OAP[opt array_part]
	deconstruct OAP
		'[ N [number] ']
			
	replace [t_var]
		'var DI [decl_identifier] ': T [type_specifier]

	construct newN [number]
		N [- 1]
	
	construct TuringArraySpec [type_specifier]
		'array 0 .. newN 'of T
	
	construct newTuringArraySpec [type_specifier]
		TuringArraySpec [changeToStrings]
		
	by
		'var DI ': newTuringArraySpec
end function
