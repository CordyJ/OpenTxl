
program ObjectPascalExample;
 
type
  THelloWorld = class
    procedure Put;
  end;
 
procedure THelloWorld.Put;
begin
  Writeln('Hello, World!');
end;
 
var
  HelloWorld: THelloWorld;               { this is an implicit pointer }
 
begin
  HelloWorld := THelloWorld.Create;      { constructor returns a pointer to an object of type THelloWorld }
  HelloWorld.Put;                        
  HelloWorld.Free;                       { this line deallocates the THelloWorld object pointed to by HelloWorld }
end.
