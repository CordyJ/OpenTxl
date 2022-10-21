% TXL 7.7a4
% Andy Maloney, Queen's University, January 1995
%	[part of 499 project]


define declaration
	'typedef [type_specifier] [opt pointer] [identifier] [opt array_part] ';	[NL]
  |
	'const [type_specifier] [identifier] [initialisation]';		[NL]
  |
	[type_specifier] [list decl_id_part+] ';	[NL]
end define

define decl_id_part
	[opt pointer] [decl_identifier] [opt array_part] [opt initialisation]
end define

define decl_identifier
	[identifier]
end define

define type_specifier
%% C
	'void
  | 'char
  | 'short
  | 'int
  | 'long
  | 'float
  | 'double
%% Turing
  | [t_array_spec]
  | 'string [opt string_len_part]
  |	'real
end define

define t_array_spec
	'array [constant] .. [constant] 'of [type_specifier]
end define

define string_len_part
	'( [constant] ')
end define

define pointer
	'*
end define

define array_part
	'[ [constant] ']
end define

define initialisation
	'= [expression]
end define
