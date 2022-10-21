MODULE Sor;

FROM Config IMPORT n, size;

VAR
  A: SHAPE {n # n} OF REAL;
  Red, Black: VIEW;
END;

/*******/

FUNCTION relaxation(IN     X: SHAPE {n # n} OF REAL;
                    IN     c: REAL)
		    RESULT Y: SHAPE {n-2 # n-2} OF REAL;

BEGIN

  Y[i-1, j-1] := (X[i-1, j] + X[i+1, j] +
                  X[i, j-1] + X[i, j+1])/(c/4) +
                 (1-c)* X[i:1..UBD-1, j:1..UBD-1];

END relaxation;

/*******/

FUNCTION block(IN X: VIEW {n # n};
               IN overlap, size, blockNbr: NATURAL) 
               RESULT Y: VIEW {size+2*overlap # size+2*overlap};

VAR
  Aux: VIEW;
  rowOffset, colOffset: NATURAL;
END;

BEGIN

  RowOffset := blockNbr DIV (n-2 DIV size);
  ColOffset := blockNbr MOD (n-2 DIV size);
  Aux <- X[RowOffset..RowOffset+size+2*overlap-1];
  Y   <- Aux[_, ColOffset..ColOffset+size+2*overlap-1];

END block;

/*******/

FUNCTION redSlices (IN n, size: NATURAL) RESULT nbrOfRedSlices: NATURAL;

BEGIN

  nbrOfRedSlices := (n-2 DIV size) * (n-2 DIV size) DIV 2;

END redSlices;

/*******/

FUNCTION blackSlices (IN n, size: NATURAL) RESULT nbrOfBlackSlices: NATURAL;

BEGIN

  nbrOfBlackSlices := ((n-2 DIV size) * (n-2 DIV size) DIV 2) +
                      ((n-2 DIV size) * (n-2 DIV size) MOD 2);

END blackSlices;

/*******/

PROCEDURE Slice(IN W: VIEW {n # n};
                IN size: NATURAL;
		OUT Red, Black: VIEW);

BEGIN

  Black {u: blackSlices(n, size) # size+2 # size+2} <- block(W, 1, size, 2*u);
  Red {u: redSlices(n, size) # size+2 # size+2}  <- block(W, 1, size, 2*u+1);

END Slice;

/*******/

BEGIN

  Slice(A, size, Red, Black);
  
  Red[k:_, 1..UBD-1, 1..UBD-1] := relaxation(Red[k],c);
  Black[k:_, 1..UBD-1, 1..UBD-1] := relaxation(Black[k],c);

END Sor.
