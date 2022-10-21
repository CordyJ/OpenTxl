% TXL 7.7a4
% Andy Maloney, Queen's University, March 1995
%	[part of 499 project]



function changeArrayBrackets
	replace * [unary_expression]
		PE [primary_expression] '[ E [expression] ']
		
	by
		PE '( E ')
end function


define binary_operator
%% C
    	 +  | -  | *  | / | '% 
    |	==  | != | <  | > | <= | >=
    |	'|| | && | '| | ^ | & 
    |	<<  | >> 
    |	 .* | ->*
    |
%% Turing
		'=
	|
		'not=
	|
		'and
	|
		'or
	|
		'mod
end define


rule changeExpression
	replace [expression]
		E [expression]
		
	construct newE [expression]
		E
			[changeEquals]
			[changeNotEquals]
			[changeBooleanAnd]
			[changeBooleanOr]
			[changeMod]
			
			[changeArrayBrackets]
			
	where not
		E [= newE]
	
	by
		newE 
end rule

function changeEquals
	replace [expression]
		UE1 [unary_expression] '== UE2 [unary_expression]
		
	by
		UE1 '= UE2
end function

function changeNotEquals
	replace [expression]
		UE1 [unary_expression] '!= UE2 [unary_expression]
		
	by
		UE1 'not= UE2
end function

function changeBooleanAnd
	replace [expression]
		UE1 [unary_expression] '&& UE2 [unary_expression]
		
	by
		UE1 'and UE2
end function

function changeBooleanOr
	replace [expression]
		UE1 [unary_expression] '|| UE2 [unary_expression]
		
	by
		UE1 'or UE2
end function

function changeMod
	replace [expression]
		UE1 [unary_expression] '% UE2 [unary_expression]
		
	by
		UE1 'mod UE2
end function
