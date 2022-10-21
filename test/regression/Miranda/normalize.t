% Use 'expand' to replace tabs by spaces


procedure Count_Spaces(var spcs: int, line: string, var flag: int)
	var c: string(1)
	var a : int := 1

	spcs := 0
	loop
		c := line(a)
		spcs += 1
		exit when c not= ' '
		exit when spcs = length(line)
		a += 1
	end loop
	if (spcs = length(line)) then
		flag := 2
	elsif index(line, "where") = 0 then
		flag := 1
	end if
end Count_Spaces
		
var line : string
var flag, spcs : int
var Indent_Array : array 1..100 of int
var Array_Index: int := 1


if nargs not= 2 then
    put "USAGE:  normalize Input_FileName Output_FileName"
end if

Indent_Array(Array_Index) := 0

loop
    var templine : string := ""
    exit when eof(1)
    get : 1, line : *
    if length(line) > 1 then
    	if (line(1) not= ' ') and (Array_Index>1) then
		for decreasing i:Array_Index-1..1
			Array_Index := i
			for j:1..Indent_Array(Array_Index)-1 
				templine += ' '
			end for
			templine += '}'
			put :2, templine
			templine := ""
		end for
    	end if
	if (line(1) not= ' ') and (line(1) not= '|') 
			and (line(2) not= '|') then
		put :2, ';'
	end if
    end if
    put Array_Index
    if length(line) > 1 then
   	if (line(1) = ' ') then
  		flag := 0
		spcs := 0
		Count_Spaces(spcs, line, flag)
		if (spcs > Indent_Array(Array_Index)) and (flag = 0) then
			for i:1..Indent_Array(Array_Index)-1
				templine += ' '
			end for
			templine += '{'
			put : 2, templine
			Array_Index += 1
			Indent_Array(Array_Index) := spcs
		elsif (spcs < Indent_Array(Array_Index)) and (flag = 0) then
			Array_Index -= 1
			for i:1..Indent_Array(Array_Index)-1
				templine += ' '
			end for
			templine += '}'
			put : 2, templine
		end if
    	end if
       	put : 2, line
    end if
end loop

