IMPLEMENTATION MODULE MergeSort;

FROM list IMPORT concatenate;

VAR
  direction: INTEGER;
END;
/* direction determines whether the elements should be
   sorted monotonically increasing or decreasing.
   direction = 0 : increasing
   direction = 1 : decreasing
*/

PROCEDURE MakeBitonic(INOUT V: VIEW; IN blength, n: INTEGER);
VAR
  W: VIEW;
  i: INTEGER;
END;

BEGIN
i := 0;
direction := 0;
WHILE i < n DO
  W {t: blength} <- V [t + i];
  SortUpDown(W, blength);
  direction := 1 - direction;
  i := i + blength;
END;
END MakeBitonic;

PROCEDURE SortUpDown(INOUT V: VIEW; IN blength: INTEGER);
VAR
  rows: INTEGER;
END;

BEGIN
rows := 1;
WHILE rows <= blength/2 DO
  SplitSort(V, blength, rows);
  rows := rows * 2;
END;
END SortUpDown;

PROCEDURE SplitSort(INOUT V: VIEW; IN blength, rows: INTEGER);
VAR
  V1, V2: VIEW;
END;

BEGIN
IF rows = 1
THEN
  CondSwitch(V, blength);
ELSE
  V1 {i: blength} <- V [i];
  V2 {i: blength} <- V [i + blength];
  SplitSort(V1, blength/2, rows/2);
  SplitSort(V2, blength/2, rows/2);
  V := concatenate(V1, V2);
END;
END SplitSort;

PROCEDURE CondSwitch(INOUT V: VIEW; IN blength: INTEGER);
VAR
  i, bside: INTEGER;
  temp: ElmType;
END;

BEGIN
bside := blength/2;
ITER i OVER bside DO
  IF (V [i] > V [i + bside]) AND (direction = 0)
  THEN
    temp := V [i];
    V [i] := V [i + bside];
    V [i + bside] := temp;
  ELSEIF (V [i] < V [i + bside]) AND (direction = 1)
  THEN
    temp := V [i];
    V [i] := V [i + bside];
    V [i + bside] := temp;
  END;
END;
END CondSwitch;

END MergeSort.
