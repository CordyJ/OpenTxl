MODULE TravSalesmanMod;
                    // Approximation of the optimal solution for a Travelling
                    // Salesman problem on a parallel machine

FROM TravSalesmanAnnotMod IMPORT stInitialize, stNext;
                    // gives first and subsequent values for S and T

FROM MathMod IMPORT Exp;

VAR
    V       :   VIEW { n#n };
    R       :   VIEW { n };
END;

FUNCTION Distance
            (  IN       a,
                        b   :   NATURAL)
                    RESULT G : REAL;

BEGIN
    G := (  V[R[(a+n-1) MOD n],R[b]] + V[R[b],R[(a+1) MOD n]] + 
            V[R[(b+n-1) MOD n],R[a]] + V[R[a],R[(b+1) MOD n]] ) -
         (  V[R[(a+n-1) MOD n],R[a]] + V[R[a],R[(a+1) MOD n]] + 
            V[R[(b+n-1) MOD n],R[b]] + V[R[b],R[(b+1) MOD n]]);
END Distance;


PROCEDURE ConditionalSwap
            (   IN      a,
                        b   :   NATURAL;
                IN      T   :   REAL);
VAR
    dump        :   NATURAL;
END;

BEGIN
    IF Distance(a,b) < T THEN
        dump := R[a];
        R[a] := R[b];
        R[b] := dump;
    END;
END ConditionalSwap;
        
            


FUNCTION TravSalesman
            (   IN  D   :   SHAPE { n#n } OF REAL)
                                    // The distances between the cities
                RESULT Route :  SHAPE { n } OF NATURAL;


VAR
    S       :   NATURAL; 
                    // Distance in route order between cities
                    // over which to swap
    T       :   REAL;   // 'Temperature' of the system, my be varied in
                    // order to improve the performance
    Route   :   SHAPE { n } OF NATURAL;
    i       :   NATURAL;

END;    

BEGIN
    Route [i:_] := i;
    R <- Route;
    stInitialTemperature(S,T);
    V <- D;     
    WHILE T > 0 DO
        ITER i OVER n DO
            ConditionalSwap(i,(i+T) MOD n,T);
        END;
        stNext(S,T);
    END;
END TravSalesman;

END TravSalesmanMod.
