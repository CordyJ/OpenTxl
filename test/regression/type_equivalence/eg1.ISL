types Jim;
	c == 5;
	% Test 1.  Type generic, one parameter
	J [T] = ( x : T;);
	T =  J [int];
	S = J [string];
	% Test 2. Value generic, one parameter
	K (V) = [ V ]char;
	TV = K (c);
	% Test 3.  Type and value generic, one each
	L[T](V) = ( x : T; y : [V] char;);
	LTV = L[TV](5);
	d == 12;
	LTVE = L[TV](c);  % struct. equiv. LTV
	% Test 4.  Mixed bag
	M[T1,T2,T3](V1) = ( x:T1; y:T2; z:T3; a:[V1]char;);
	e == 65;
	MT = M[int, LTV,boolean](e);
end Jim.
