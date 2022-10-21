MODULE BitonicSort;

FROM FileIO IMPORT ReadElements, CountElements;  // Assume these exist
IMPORT MergeSort;

TYPE
    ElmType = INTEGER;   // type of the elements to sort
END;

VAR
    blength, n : INTEGER;
    A: SHAPE {n} OF ElmType;
    V: VIEW;
END;
/* In the shape A the concerned elements will be placed.
   The view V will in the end view the sorted sequence of A
*/

BEGIN

n := CountElements;  // require that n=2^k for some k
A := ReadElements;
V <- A;
blength := 2;   // initial length of bitonic sequence
WHILE blength <= n DO
  MakeBitonic(V, blength, n);
  blength := blength * 2;
END;

END BitonicSort.
