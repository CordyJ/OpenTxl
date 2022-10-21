DEFINITION MODULE Matrix;

/*
 *	At[i,j] iff A[j,i]
 */
FUNCTION Transpose(IN A: VIEW {n#m})
         RESULT At: VIEW {m#n};

/*
 *	C = A * B
 */
FUNCTION Multiply(IN A: VIEW {n#m};
                  IN B: VIEW {m#k})
         RESULT C: VIEW {n#k};

/*
 *	Ai = A^-1
 */
FUNCTION Inverse(IN A: VIEW {n#n})
         RESULT Ai: VIEW {n#n};

END Matrix.
