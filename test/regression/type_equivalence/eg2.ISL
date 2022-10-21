types PhoneBookService;
	nmnt == 65;

	CustEnt [InfoType] = ( info : InfoType; name : string;);
	ICust =  CustEnt [int];
	SCust = CustEnt [string];

	Klist (V) = [V] SCust;
	KLent = Klist (ntvs);

	LineEnt [InfoType](V) = ( info : InfoType; y : [V] int;);
	LKLent = LineEnt [KLent](5);
	LEKlist = LineEnt [KLent](ntvs);

	M [T1,T2,T3](V1) = ( x : T1; y : T2; z : T3; a : [V1] LEKlist;);
	MT = M [int, LKLent, boolean](nmnt);

	ntvs == 5;
end PhoneBookService.
