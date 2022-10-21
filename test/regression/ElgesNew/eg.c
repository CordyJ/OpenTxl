/*
From melges%athena@[199.117.41.108] Fri Mar 24 17:33 EST 1995
From: melges%athena@[199.117.41.108] (Mike Elges)
Subject: Possible bug in TXL.
To: cordy@qucis.queensu.ca

Prof Cordy,

   I have come across something that may be a bug in txl.  The following
statement caused txl to go into an infinite loop.  I say infinite because
I let the process run (by accident) for 48 hours of cpu time. The
statement was:
*/

main() {
    array[i] = 
	XmStringCreateLtoR (
	    (
		(char **)
		    (
			ap = (char *) 
			    (
				(__builtin_alignof (char *) ==  8) ? 
				    (
					(long)((long) ap + sizeof(char* ) +  8 - 1) & -8L
				    ) 
				: 
				    1
			    ) 
		    )
	    ) [-1] 
	    ,
	    (
		(char *) _XmStrings[0]
	    )
	    ,1
       );
}

/*
By playing with the statement I was able to get it to parse by swaping
the following lines in the c grammer.

OLD c Grammer:

define expression
	   [constant]		%% JRC optimization
    |	[assignment_expression]	%% JRC optimization
    |	[list assignment_expression+]
end define

My Change:

define expression
	   [constant]		%% JRC optimization
    |	[list assignment_expression+]
    |	[assignment_expression]	%% JRC optimization
end define

How can swapping the position of the two statements fix the problem.

Any ideas???

Cheers

Mike Elges
*/
