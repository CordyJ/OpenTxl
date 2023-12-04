program Stack (input, output);

const 
    maxDepth = 6;
type 
    elementType = integer;
var 
    stack : array [1 .. maxDepth] of elementType;
    stackTop : 0 .. maxDepth;

procedure Push (value : elementType);
begin
    if stackTop < maxDepth then
	begin
	    stackTop := stackTop + 1;
	    stack [stackTop] := value
	end
    else
	writeln ('ERROR: Push');
end;

procedure Pop;
begin
    if stackTop > 0 then
	stackTop := stackTop - 1
    else
	writeln ('ERROR: Pop');
end;

function Top : elementType;
begin
    Top := stack [stackTop]
end;

procedure Pause;
var x : char;
begin
    writeln ('Hit return to continue');
    read (x)
end;


begin
    stackTop := 0;
    Push (10);
    Push (5);
    Push (-6);
    Push (14); Pause;
    Pop;
    Pop;
    Push (99); Pause;
end.
