program FahrenheitToCelsius(output);

var
	count : integer;
	fahren : real;


function tempVert ( in_temp : real ) : real;
begin
	tempVert := (5.0/9.0) * (in_temp - 32.0 );
end;

begin
	for count := 1 to 4 do
	begin
		write( 'Enter a Fahrenheit temp: ' );
		read( fahren );
		writeln( 'The Celsius equivalent is: ', tempVert( fahren ) );
	end
end.
