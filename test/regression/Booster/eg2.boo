/* 
Fast Fourier Transformation 
*/

MODULE FFT ;
 

FUNCTION Filter (IN U : VIEW {n};
    	    	 IN k : NAT) RESULT F : VIEW {n DIV k};


BEGIN
    F <- U[k*i];
END Filter;

PROCEDURE Unzip (IN  Seq  : VIEW {n};
    	    	 OUT Even : VIEW {n DIV 2};
    	    	 OUT Odd  : VIEW {n DIV 2 + n MOD 2});

BEGIN
    Even <- Filter(Seq, 2);
    Odd  <- Filter(Seq[1..UPB], 2);
END Unzip;

FUNCTION Omega (IN j,
    	    	   n   : INT) RESULT OmegaJ : COMPLEX ;
VAR
    pi  :  REAL;
END;
BEGIN
    pi := 4.0*ARCTAN(1.0);
    OmegaJ := EXP(2*pi*(0, -1)*j/POWER(2,n));
 
END Omega;

FUNCTION Combine (IN Even,
    	    	     Odd : SHAPE {n} OF COMPLEX) 
    	    	RESULT C : SHAPE {2*n} OF COMPLEX;


BEGIN
    C[j] := Even[j MOD (n DIV 2)] + Omega(j, n)*Odd[j MOD (n DIV 2)];
END Combine;

FUNCTION FFTMAIN (IN S : SHAPE {n} OF COMPLEX ) RESULT T : 
    	    SHAPE {n} OF COMPLEX;
VAR
    S,
    T      : VIEW {n};
END;
BEGIN
    Unzip(S, Even, Odd);
    T := Combine(FFT(Even),  FFT(Odd));
END FFT;

END FFT.
