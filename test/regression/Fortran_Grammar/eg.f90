      SUBROUTINE NOZZLE(TIME, P0, D0, E0, C0, PRES, DENS, VEL, ENER,    &
     &    FLOW, GAMMA)
!
!        DEFINE TIME DEPENDENT FLOW CONDITIONS AT THE NOZZLE EXIT
!
!
!        INPUT:
!
!        TIME      REAL      TIME (S) TO DEFINE CONDITIONS AT
!        P0        REAL      INITIAL CHAMBER PRESSURE (PASCALS)
!        D0        REAL      INITIAL CHAMBER DENSITY (KG/M**3)
!                              NOT REQUIRED IF FLOW NOT SET
!        E0        REAL      INITIAL CHAMBER SPECIFIC INTERNAL ENERGY
!                                  (J/KG)
!        C0        REAL      INITIAL CHAMBER SOUND VELOCITY (M/S)
!                              NOT REQUIRED IF FLOW NOT SET
!        FLOW      REAL      IF NON-NEGATIVE, THIS DEFINES THE MASS
!                              FLOW RATE THROUGH THE NOZZLE.  IF SET,
!                              FLOW WILL BE CONSTANT IN TIME.
!        GAMMA     REAL      INITIAL CHAMBER GAMMA (NOT REQUIRED IF
!                              FLOW IS GIVEN)
!
!        OUTPUT:
!
!        PRES      REAL      PRESSURE (PASCALS)
!        DENS      REAL      DENSITY (KG/M**3)
!        VEL       REAL      VELOCITY (M/S)
!        ENER      REAL      INTERNAL SPECIFIC ENERGY (J/KG)
!
!        IF FLOW IS NOT SET, THEN
!        WE ASSUME CRITICAL FLOW ACROSS THE NOZZLE AND CALCULATE THE
!        DECAY IN THE CHAMBER ASSUMING ISOTHERMAL CONDITIONS.
!
!
!        AREA = NOZZLE AREA (M**2)
!        VOL  = VOLUME OF CHAMBER (M**3)
!
!...Translated by Pacific-Sierra Research VAST-90 1.02A2  13:53:43   1/12/93   -
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE VCIMAGE
      USE VIMAGE
      IMPLICIT NONE
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      REAL TIME, P0, FLOW
      REAL, OPTIONAL :: D0, E0, C0, PRES, DENS, VEL, ENER, GAMMA
!-----------------------------------------------
!   L o c a l   P a r a m e t e r s
!-----------------------------------------------
      REAL, PARAMETER :: AREA = 5.1725E-7
      REAL, PARAMETER :: VOL = 1.24E-5
      INTEGER, PARAMETER :: IMAX = 500
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      INTEGER :: TYPE, ICNT, IJ, IOLD, N, NN, I
      REAL, DIMENSION(IMAX) :: P, T
      REAL :: X1, Y1, X2, Y2, SLOPE, B
      LOGICAL :: FIRST = .TRUE.
      CHARACTER :: INFIL*30
      SAVE FIRST,ICNT,T,P
      INCLUDE 'terror.int'
      INCLUDE 'value.int'
!-----------------------------------------------
!
!        IF FLOW NOT SET, USE INPUTED PRESSURE-TIME HISTORY
!
      IF (FLOW <= 0.0) THEN
          IF (FIRST) THEN
              ICPNT = 999
              ICNT = 1
              WRITE (*, '(//'' ENTER P-T HISTORY FILE NAME: '')')
               READ (*, '(A)') INFIL
              OPEN(UNIT=5, FILE=INFIL, STATUS='UNKNOWN')
              REWIND 5
    3         CONTINUE
              CALL VALUE (T(ICNT), TYPE)
              IF (.NOT.EOFF) THEN
                  IF (TYPE /= 1) THEN
                      CALL TERROR (1, FIELD, TYPE)
                      WRITE (6, '('' ABORT IN NOZZLE'')')
                       STOP 
                  ENDIF
                  CALL VALUE (P(ICNT), TYPE)
                  IF (EOFF) THEN
                      WRITE (6, '('' UNEXPECTED EOF IN NOZZLE, ABORT'')'&
     &                    )
                       STOP 
                  ELSE IF (TYPE /= 1) THEN
                      CALL TERROR (1, FIELD, TYPE)
                      WRITE (6, '('' ABORT IN NOZZLE'')')
                       STOP 
                  ENDIF
                  ICNT = ICNT + 1
                  GO TO 3
              ELSE
                  ICNT = ICNT - 1
                  IF (ICNT <= 0) THEN
                      WRITE (6, '('' NO NOZZLE P/T HISTORY, ABORT'')')
                       CLOSE(UNIT=5)
                      STOP 
                  ENDIF
                  CLOSE(UNIT=5)
                  WRITE (6, '(''1PRESSURE-TIME HISTORY FOR CHAMBER''/)')
                   DO IJ = 1, ICNT
                      P(IJ) = P(IJ)/1.727865
                      WRITE (6, '('' TIME='',1PE12.5,'' PRES='',E12.5)')&
     &                     T(IJ), P(IJ)
                  END DO
                  P0 = P(1)
                  FIRST = .FALSE.
                  IOLD = ICNT - 1
                  RETURN 
              ENDIF
          ENDIF
          IF (TIME >= T(ICNT)) THEN
              N = ICNT - 1
          ELSE IF (TIME < T(1)) THEN
              N = 1
          ELSE
              NN = ICNT - 1
              IF (TIME < T(IOLD+1)) NN = IOLD
              DO I = NN, 1, -1
                  N = I
                  IF (TIME>=T(I) .AND. TIME<T(I+1)) GO TO 20
              END DO
          ENDIF
   20     CONTINUE
          X1 = T(N)
          Y1 = P(N)
          X2 = T(N+1)
          Y2 = T(N+2)
          IOLD = N
          SLOPE = (Y2 - Y1)/(X2 - X1)
          B = Y2 - SLOPE*X2
          PRES = TIME*SLOPE + B
          ENER = E0
          DENS = PRES/((GAMMA - 1.0)*ENER)
          VEL = C0
      ELSE
!
!        FLOW IS SET, CALCULATE CONSTANT FLOW
!
          VEL = FLOW/(D0*AREA)
          ENER = E0
          DENS = D0
          PRES = P0
      ENDIF
      END SUBROUTINE NOZZLE
