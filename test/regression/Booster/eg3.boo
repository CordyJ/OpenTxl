DEFINITION MODULE LinearRegression;

/*
 *      x = LR(A, y) iff A^T A x = A^T y
 */
FUNCTION LR(IN A: VIEW {n#m};
            IN y: VIEW {n#m})
         RESULT x: VIEW {m#k};

END LinearRegression.
