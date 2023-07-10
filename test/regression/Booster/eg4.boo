IMPLEMENTATION MODULE LinearRegression;

FROM Matrix IMPORT Multiply, Transpose, Inverse;

/*
 *      x = LR(A, y) iff A^T A x = A^T y
 */
FUNCTION LR(IN A: VIEW {n#m};
            IN y: VIEW {n#k})
         RESULT x: VIEW {m#k};

BEGIN
        /*
         * Not really the way to do it, but what the hack...
         */
        x := Multiply(Inverse(Multiply(Transpose(A), A)),
                      Multiply(Transpose(A), y));
END LR;
END LinearRegression.
