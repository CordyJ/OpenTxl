% Example using TXL 10.5a source coordinate extensions to extract
% a table of all function definitions with source coordinates

% Jim Cordy, January 2008

% Requires TXL 10.5a or later

% Using standard C grammar
include "C.grm"

% Uncomment this line to allow Gnu gcc extensions
% include "CGnuOverrides.Grm"

% Redefinitions to collect source coordinates for function definitions as parsed input,
% and to allow for XML markup of function definitions as output

redefine function_definition
	% Input form 
	[srcfilename] [srclinenumber] 		% Keep track of starting file and line number
	[function_header]
	'{ 				[IN][NL]
	    [compound_statement_body]	[EX]
	    [srcfilename] [srclinenumber] 	% Keep track of ending file and line number
	'}
    |
	% Output form 
	[xml_source_coordinate]
	[function_header]
	'{ 				[IN][NL]
	    [compound_statement_body] 	[EX]
	'}
	[end_xml_source_coordinate]
end redefine

define function_header
    [decl_specifiers] [declarator] [opt KR_parameter_decls]
end define

define xml_source_coordinate
    '< [SPOFF] 'source [SP] 'file=[stringlit] [SP] 'startline=[stringlit] [SP] 'endline=[stringlit] '> [SPON] [NL]
end define

define end_xml_source_coordinate
    [NL] '< [SPOFF] '/ 'source '> [SPON] [NL]
end define

redefine program
	...
    | 	[repeat function_definition]
end redefine


% Main function - extract and mark up function definitions from parsed input program
function main
    replace [program]
	P [program]
    construct Functions [repeat function_definition]
    	_ [^ P] 			% Extract all functions from program
	  [convertFunctionDefinitions] 	% Mark up with XML
    by 
    	Functions
end function

rule convertFunctionDefinitions
    % Find each function definition and match its input source coordinates
    replace [function_definition]
	FileName [srcfilename] LineNumber [srclinenumber]
	FunctionHeader [function_header]
	'{
	    FunctionBody [compound_statement_body]
	    EndFileName [srcfilename] EndLineNumber [srclinenumber]
	'}

    % Convert file name and line numbers to strings for XML
    construct FileNameString [stringlit]
	_ [quote FileName]
    construct LineNumberString [stringlit]
	_ [quote LineNumber]
    construct EndLineNumberString [stringlit]
	_ [quote EndLineNumber]

    % Output is XML form with attributes indicating input source coordinates
    by
	<source file=FileNameString startline=LineNumberString endline=EndLineNumberString>
	FunctionHeader 
	'{
	    FunctionBody 
	'}
	</source>
end rule
