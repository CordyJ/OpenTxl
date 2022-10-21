IMPLEMENTATION MODULE Matrix;

TYPE
	NATURAL = NAT;
END;

/*
 *	At[i,j] iff A[j,i]
 */
FUNCTION Transpose(IN A: VIEW {n#m})
         RESULT At: VIEW {m#n};

BEGIN
	At{i # j} <- A[j:_, i:_];
END Transpose;

/*
 *	C = A * B
 */
FUNCTION Multiply(IN A: VIEW {n#m};
                  IN B: VIEW {m#k})
         RESULT C: VIEW {n#k};

BEGIN
	C[i:_, j:_] := Reduce('+', A[i, _] * B[_, j]);
END Multiply;

/*
 *	Ai = A^-1
 */
FUNCTION Inverse(IN A: VIEW {n#n})
         RESULT Ai: VIEW {n#n};

BEGIN
	Pivoting(A, Pivot, Row, Column, Ai);
	WHILE Size(Ai) > 1 DO
		Column := - Column / Pivot;
		Ai[i:_, j:_] := Ai[i, j] + Column[i] * Row[j];
		Pivoting(Ai, Pivot, Row, Column, Ai);
	END;
END Inverse;

PROCEDURE Pivoting(IN Matrix: VIEW {n#n};
                   OUT Pivot: NATURAL;
                   OUT Row, Cloumn: VIEW {n};
                   OUT Submatrix: VIEW {n-1#n-1});

VAR 
	p: NATURAL;
END;

BEGIN
	p := Maxindex(Abs(Matrix[_, 0]));
	Pivot <- Matrix[p, 0];
	Row <- Matrix[p, 1 .. UPB];
	Column <- Matrix[\ p, 0];
	Submatrix <- Matrix[\ p, 1 .. UPB];
END Pivoting;

END Matrix.
