% TXL 7.7a4
% Andy Maloney, Queen's University, March 1995
%	[part of 499 project]
%
%  This file contains the optimizing functions for Turing.



function optimizeTuring
	replace [repeat externaldefinition]
		Program [repeat externaldefinition]
		
	by
		Program
			[changeToFor]
end function


rule changeToFor
	replace [repeat statement]
		S [repeat statement]
		
	deconstruct S
 		'% due to an error, this comment is required for the program to compile
		ID1 [id] ':= E1 [expression]	
		'loop
			RS2 [repeat statement]
		'end 'loop
		RestOfScope [repeat statement]
	
	where not
		RestOfScope [references ID1]
		
	deconstruct RS2
		S2 [statement]
		RS3 [repeat statement]
	
	deconstruct S2
		'exit 'when 'not '( C [expression] ')
		
	deconstruct C
		ID2 [id] '<= E2 [unary_expression]

	construct N [number]
		_ [length RS3]
	
	construct N2 [number]
		N [- 1]
		
	construct RS4 [repeat statement]	%% NOTE: need to check these statments for assignments and
						%% NOT change to a for loop if any exist
		RS3 [select 1 N2]

	construct S3 [repeat statement]
		RS3 [select N N]
		
	deconstruct S3
		ID3 [id] ':= ID4 [id] BOP [binary_operator] '1	
	
	construct newID [id]
		ID1 [!]
		
	construct newS [repeat statement]
		'for newID : E1 '.. E2
			RS4 [$ ID1 newID]
		'end 'for
		RestOfScope
	
	where not
		newS [= S]
		
	by
		newS
end rule

rule references ID [id]
	match [id]
		ID
end rule
