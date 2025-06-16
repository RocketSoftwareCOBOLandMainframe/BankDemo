      *****************************************************************
      *                                                               *
      * Copyright 2010-2025 Rocket Software, Inc. or its affiliates.  *
      * This software may be used, modified, and distributed          *
      * (provided this notice is included without modification)       *
      * solely for internal demonstration purposes with other         *
      * Rocket products, and is otherwise subject to the EULA at      *
      * https://www.rocketsoftware.com/company/trust/agreements.      *
      *                                                               *
      * THIS SOFTWARE IS PROVIDED "AS IS" AND ALL IMPLIED             *
      * WARRANTIES, INCLUDING THE IMPLIED WARRANTIES OF               *
      * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE,         *
      * SHALL NOT APPLY.                                              *
      * TO THE EXTENT PERMITTED BY LAW, IN NO EVENT WILL              *
      * ROCKET SOFTWARE HAVE ANY LIABILITY WHATSOEVER IN CONNECTION   *
      * WITH THIS SOFTWARE.                                           *
      *                                                               *
      *****************************************************************

      *****************************************************************
      * Program:     BBANK70P.CBL                                     *
      * Layer:       Business logic                                   *
      * Function:    Calculate cost of loan                           *
      *****************************************************************

       IDENTIFICATION DIVISION.
       PROGRAM-ID.
           BBANK70P.
       DATE-WRITTEN.
           September 2002.
       DATE-COMPILED.
           Today.

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-MISC-STORAGE.
         05  WS-PROGRAM-ID                         PIC X(8)
             VALUE 'BBANK70P'.
         05  WS-INPUT-FLAG                         PIC X(1).
           88  INPUT-OK                            VALUE '0'.
           88  INPUT-ERROR                         VALUE '1'.
         05  WS-RETURN-FLAG                        PIC X(1).
           88  WS-RETURN-FLAG-OFF                  VALUE LOW-VALUES.
           88  WS-RETURN-FLAG-ON                   VALUE '1'.
         05  WS-PFK-FLAG                           PIC X(1).
           88  PFK-VALID                           VALUE '0'.
           88  PFK-INVALID                         VALUE '1'.
         05  WS-RETURN-MSG                         PIC X(75)
                                                   VALUE SPACES.
         05  WS-ERROR-MSG                          PIC X(75).
      *
         05  WS-CALC-WORK-AREAS.
      * Used to count no of periods in rate
           10  WS-CALC-WORK-RATE-PERIOD            PIC 9(1).
      * Generate work area
           10  WS-CALC-WORK-TEMP                   PIC X(7).
      * Work area for AMOUNT
           10  WS-CALC-WORK-AMOUNT                 PIC X(7).
           10  WS-CALC-WORK-AMOUNT-N REDEFINES WS-CALC-WORK-AMOUNT
                                                   PIC 9(7).
      * Work area for RATE
           10  WS-CALC-WORK-RATE                   PIC X(7).
      * Used to hold first part of rate (before the period)
           10  WS-CALC-WORK-RATE-P1                PIC X(6).
           10  WS-CALC-WORK-RATE-P1-N REDEFINES WS-CALC-WORK-RATE-P1
                                                   PIC 9(6).
      * Used to hold second part of rate (before the period)
           10  WS-CALC-WORK-RATE-P2                PIC X(6).
           10  WS-CALC-WORK-RATE-P2-N REDEFINES WS-CALC-WORK-RATE-P2
                                                   PIC 9(6).
      * Used to hold rate as percentage (xxxvxxx)
           10  WS-CALC-WORK-PERC                   PIC X(6).
           10  WS-CALC-WORK-PERC-N REDEFINES WS-CALC-WORK-PERC
                                                   PIC 9(3)V9(3).
      * Work area for TERM
           10  WS-CALC-WORK-TERM                   PIC X(5).
           10  WS-CALC-WORK-TERM-N REDEFINES WS-CALC-WORK-TERM
                                                   PIC 9(5).
      * Work area for PAYMENT
           10  WS-CALC-WORK-PAYMENT                PIC X(9).
           10  WS-CALC-WORK-PAYMENT-N REDEFINES WS-CALC-WORK-PAYMENT
                                                   PIC $$$$$9.99.

         05  WS-LOAN-AREAS.
           10  WS-LOAN-PRINCIPAL                   PIC S9(7).
           10  WS-LOAN-INTEREST                    PIC SV9(8).
           10  WS-LOAN-TERM                        PIC S9(5).
           10  WS-LOAN-MONTHLY-PAYMENT             PIC S9(6)V99.

       01  WS-BANK-DATA.
       COPY CBANKDAT.

       01  WS-HELP-DATA.
       COPY CHELPD01.

       COPY CABENDD.

       LINKAGE SECTION.
       01  DFHCOMMAREA.
         05  LK-COMMAREA                           PIC X(6144).

       COPY CENTRY.
      *****************************************************************
      * Make ourselves re-entrant                                     *
      *****************************************************************
           MOVE SPACES TO WS-ERROR-MSG.

      *****************************************************************
      * Move the passed area to Bour area                              *
      *****************************************************************
           MOVE DFHCOMMAREA (1:LENGTH OF WS-BANK-DATA) TO WS-BANK-DATA.

      *****************************************************************
      * Ensure error message is cleared                               *
      *****************************************************************
           MOVE SPACES TO BANK-ERROR-MSG.

      *****************************************************************
      * This is the main process                                      *
      *****************************************************************

      *****************************************************************
      * Save the passed return message and then turn it off           *
      *****************************************************************
           MOVE BANK-RETURN-MSG TO WS-RETURN-MSG.
           SET BANK-RETURN-MSG-OFF TO TRUE.

      *****************************************************************
      * Check the AID to see if its valid at this point               *
      *****************************************************************
           SET PFK-INVALID TO TRUE.
           IF BANK-AID-ENTER OR
              BANK-AID-PFK03 OR
              BANK-AID-PFK04
              SET PFK-VALID TO TRUE
           END-IF.
           IF BANK-AID-PFK01 AND
              BANK-HELP-INACTIVE
              SET BANK-HELP-ACTIVE TO TRUE
              SET PFK-VALID TO TRUE
           END-IF.
           IF PFK-INVALID
              SET BANK-AID-ENTER TO TRUE
           END-IF.

      *****************************************************************
      * Check the AID to see if we have to quit                       *
      *****************************************************************
           IF BANK-AID-PFK03
              MOVE 'BBANK70P' TO BANK-LAST-PROG
              MOVE 'BBANK99P' TO BANK-NEXT-PROG
              MOVE 'MBANK99' TO BANK-NEXT-MAPSET
              MOVE 'BANK99A' TO BANK-NEXT-MAP
              GO TO COMMON-RETURN
           END-IF.

      *****************************************************************
      * Check the to see if user needs or has been using help         *
      *****************************************************************
           IF BANK-HELP-ACTIVE
              IF BANK-AID-PFK04
                 SET BANK-HELP-INACTIVE TO TRUE
                 MOVE 00 TO BANK-HELP-SCREEN
                 MOVE 'BBANK70P' TO BANK-LAST-PROG
                 MOVE 'BBANK70P' TO BANK-NEXT-PROG
                 MOVE 'MBANK70' TO BANK-LAST-MAPSET
                 MOVE 'HELP70A' TO BANK-LAST-MAP
                 MOVE 'MBANK70' TO BANK-NEXT-MAPSET
                 MOVE 'BANK70A' TO BANK-NEXT-MAP
                 GO TO COMMON-RETURN
              ELSE
                 MOVE 01 TO BANK-HELP-SCREEN
                 MOVE 'BBANK70P' TO BANK-LAST-PROG
                 MOVE 'BBANK70P' TO BANK-NEXT-PROG
                 MOVE 'MBANK70' TO BANK-LAST-MAPSET
                 MOVE 'BANK70A' TO BANK-LAST-MAP
                 MOVE 'MBANK70' TO BANK-NEXT-MAPSET
                 MOVE 'HELP70A' TO BANK-NEXT-MAP
                 MOVE 'BANK70' TO HELP01I-SCRN
                 COPY CHELPX01.
                 MOVE HELP01O-DATA TO BANK-HELP-DATA
                 GO TO COMMON-RETURN
           END-IF.

      *****************************************************************
      * Check the AID to see if we have to return to previous screen  *
      *****************************************************************
           IF BANK-AID-PFK04
              MOVE 'BBANK70P' TO BANK-LAST-PROG
              MOVE 'BBANK20P' TO BANK-NEXT-PROG
              MOVE 'MBANK20' TO BANK-NEXT-MAPSET
              MOVE 'BANK20A' TO BANK-NEXT-MAP
              SET BANK-AID-ENTER TO TRUE
              GO TO COMMON-RETURN
           END-IF.

      * Check if we have set the screen up before or is this 1st time
           IF BANK-LAST-MAPSET IS NOT EQUAL TO 'MBANK70'
              MOVE SPACES TO BANK-SCR70-AMOUNT
              MOVE SPACES TO BANK-SCR70-RATE
              MOVE SPACES TO BANK-SCR70-TERM
              MOVE SPACES TO BANK-SCR70-PAYMENT
              MOVE WS-RETURN-MSG TO BANK-ERROR-MSG
              MOVE 'BBANK70P' TO BANK-LAST-PROG
              MOVE 'BBANK70P' TO BANK-NEXT-PROG
              MOVE 'MBANK70' TO BANK-LAST-MAPSET
              MOVE 'BANK70A' TO BANK-LAST-MAP
              MOVE 'MBANK70' TO BANK-NEXT-MAPSET
              MOVE 'BANK70A' TO BANK-NEXT-MAP
              GO TO COMMON-RETURN
           END-IF.

           PERFORM VALIDATE-DATA THRU
                   VALIDATE-DATA-EXIT.

      * If we had an error display error and return
           IF INPUT-ERROR
              MOVE SPACES TO BANK-SCR70-PAYMENT
              MOVE WS-ERROR-MSG TO BANK-ERROR-MSG
              MOVE 'BBANK70P' TO BANK-LAST-PROG
              MOVE 'BBANK70P' TO BANK-NEXT-PROG
              MOVE 'MBANK70' TO BANK-LAST-MAPSET
              MOVE 'BANK70A' TO BANK-LAST-MAP
              MOVE 'MBANK70' TO BANK-NEXT-MAPSET
              MOVE 'BANK70A' TO BANK-NEXT-MAP
              GO TO COMMON-RETURN
           END-IF.

      * Now calculate the monthly cost of the loan
           MOVE WS-CALC-WORK-AMOUNT-N TO WS-LOAN-PRINCIPAL.
           DIVIDE 100 INTO WS-CALC-WORK-PERC-N
             GIVING WS-LOAN-INTEREST.
           MOVE WS-CALC-WORK-TERM-N TO WS-LOAN-TERM.
           MOVE ZERO TO WS-LOAN-MONTHLY-PAYMENT.

           DIVIDE WS-LOAN-INTEREST BY 12
             GIVING WS-LOAN-INTEREST ROUNDED.
           COMPUTE WS-LOAN-MONTHLY-PAYMENT ROUNDED =
             ((WS-LOAN-INTEREST * ((1 + WS-LOAN-INTEREST)
                 ** WS-LOAN-TERM)) /
             (((1 + WS-LOAN-INTEREST) ** WS-LOAN-TERM) - 1 ))
               * WS-LOAN-PRINCIPAL.
           MOVE WS-LOAN-MONTHLY-PAYMENT TO WS-CALC-WORK-PAYMENT-N.
           MOVE WS-CALC-WORK-PAYMENT TO BANK-SCR70-PAYMENT.
      * Left justify the result
       LEFT-JUST-PAYMENT.
           IF BANK-SCR70-PAYMENT (1:1) IS EQUAL TO ' '
              MOVE BANK-SCR70-PAYMENT (2:8) TO BANK-SCR70-PAYMENT (1:8)
              MOVE ' ' TO BANK-SCR70-PAYMENT (9:1)
              GO TO LEFT-JUST-PAYMENT
           END-IF

           GO TO COMMON-RETURN.

       COMMON-RETURN.
           MOVE WS-BANK-DATA TO DFHCOMMAREA (1:LENGTH OF WS-BANK-DATA).
       COPY CRETURN.

       VALIDATE-DATA.
           SET INPUT-OK TO TRUE.

           MOVE BANK-SCR70-AMOUNT TO WS-CALC-WORK-AMOUNT.
           PERFORM VALIDATE-AMOUNT THRU
                   VALIDATE-AMOUNT-EXIT.
           IF NOT INPUT-OK
              GO TO VALIDATE-DATA-ERROR
           END-IF.

           MOVE BANK-SCR70-RATE TO WS-CALC-WORK-RATE.
           PERFORM VALIDATE-RATE THRU
                   VALIDATE-RATE-EXIT.
           IF NOT INPUT-OK
              GO TO VALIDATE-DATA-ERROR
           END-IF.

           MOVE BANK-SCR70-TERM TO WS-CALC-WORK-TERM.
           PERFORM VALIDATE-TERM THRU
                   VALIDATE-TERM-EXIT.
           IF NOT INPUT-OK
              GO TO VALIDATE-DATA-ERROR
           END-IF.

           GO TO VALIDATE-DATA-EXIT.

       VALIDATE-DATA-ERROR.
           SET INPUT-ERROR TO TRUE.
       VALIDATE-DATA-EXIT.
           EXIT.

       VALIDATE-AMOUNT.
            CONTINUE.
       VALIDATE-AMOUNT-RIGHT-JUSTIFY.
           IF WS-CALC-WORK-AMOUNT IS EQUAL TO SPACES OR
              WS-CALC-WORK-AMOUNT IS EQUAL TO LOW-VALUES
              MOVE 'Please enter an amount'
                TO WS-ERROR-MSG
              GO TO VALIDATE-AMOUNT-ERROR
           END-IF.
           IF WS-CALC-WORK-AMOUNT (7:1) IS EQUAL TO SPACES OR
              WS-CALC-WORK-AMOUNT (7:1) IS EQUAL TO LOW-VALUE
              MOVE WS-CALC-WORK-AMOUNT (1:6) TO WS-CALC-WORK-TEMP
              MOVE SPACES TO WS-CALC-WORK-AMOUNT
              MOVE WS-CALC-WORK-TEMP (1:6) TO WS-CALC-WORK-AMOUNT (2:6)
              GO TO VALIDATE-AMOUNT-RIGHT-JUSTIFY
           END-IF.
           INSPECT WS-CALC-WORK-AMOUNT
             REPLACING LEADING SPACES BY ZEROS.
           IF WS-CALC-WORK-AMOUNT IS NOT NUMERIC
              MOVE 'Amount is invalid (not numeric)'
                TO WS-ERROR-MSG
              GO TO VALIDATE-AMOUNT-ERROR
           END-IF.
           IF WS-CALC-WORK-AMOUNT IS EQUAL TO ZERO
              MOVE 'Please enter a non-zero amount'
                TO WS-ERROR-MSG
              GO TO VALIDATE-AMOUNT-ERROR
           END-IF.

           GO TO VALIDATE-AMOUNT-EXIT.

       VALIDATE-AMOUNT-ERROR.
           SET INPUT-ERROR TO TRUE.
       VALIDATE-AMOUNT-EXIT.
           EXIT.

       VALIDATE-RATE.
            CONTINUE.
       VALIDATE-RATE-RIGHT-JUSTIFY.
           IF WS-CALC-WORK-RATE IS EQUAL TO SPACES OR
              WS-CALC-WORK-RATE IS EQUAL TO LOW-VALUES
              MOVE 'Please enter an interest rate in the form 999.999'
                TO WS-ERROR-MSG
              GO TO VALIDATE-RATE-ERROR
           END-IF.
           IF WS-CALC-WORK-RATE (7:1) IS EQUAL TO SPACES OR
              WS-CALC-WORK-RATE (7:1) IS EQUAL TO LOW-VALUE
              MOVE WS-CALC-WORK-RATE (1:6) TO WS-CALC-WORK-TEMP
              MOVE SPACES TO WS-CALC-WORK-RATE
              MOVE WS-CALC-WORK-TEMP (1:6) TO WS-CALC-WORK-RATE (2:6)
              GO TO VALIDATE-RATE-RIGHT-JUSTIFY
           END-IF.
           INSPECT WS-CALC-WORK-RATE REPLACING LEADING SPACES BY ZERO.
           MOVE ZERO TO WS-CALC-WORK-RATE-PERIOD.
           MOVE ZEROS TO WS-CALC-WORK-RATE-P1.
           MOVE ZEROS TO WS-CALC-WORK-RATE-P2.
      * Rate is in form .xxxxxx
           IF WS-CALC-WORK-RATE (1:1) IS EQUAL TO '.'
              MOVE ZEROS                   TO WS-CALC-WORK-RATE-P1
              MOVE WS-CALC-WORK-RATE (2:6) TO WS-CALC-WORK-RATE-P2 (1:6)
              ADD 1 TO WS-CALC-WORK-RATE-PERIOD
           END-IF.
      * Rate is in form x.xxxxx
           IF WS-CALC-WORK-RATE (2:1) IS EQUAL TO '.'
              MOVE WS-CALC-WORK-RATE (1:1) TO WS-CALC-WORK-RATE-P1 (6:1)
              MOVE WS-CALC-WORK-RATE (3:5) TO WS-CALC-WORK-RATE-P2 (1:5)
              ADD 1 TO WS-CALC-WORK-RATE-PERIOD
           END-IF.
      * Rate is in form xx.xxxx
           IF WS-CALC-WORK-RATE (3:1) IS EQUAL TO '.'
              MOVE WS-CALC-WORK-RATE (1:2) TO WS-CALC-WORK-RATE-P1 (5:2)
              MOVE WS-CALC-WORK-RATE (4:4) TO WS-CALC-WORK-RATE-P2 (1:4)
              ADD 1 TO WS-CALC-WORK-RATE-PERIOD
           END-IF.
      * Rate is in form xxx.xxx
           IF WS-CALC-WORK-RATE (4:1) IS EQUAL TO '.'
              MOVE WS-CALC-WORK-RATE (1:3) TO WS-CALC-WORK-RATE-P1 (4:3)
              MOVE WS-CALC-WORK-RATE (5:3) TO WS-CALC-WORK-RATE-P2 (1:3)
              ADD 1 TO WS-CALC-WORK-RATE-PERIOD
           END-IF.
      * Rate is in form xxxx.xx
           IF WS-CALC-WORK-RATE (5:1) IS EQUAL TO '.'
              MOVE WS-CALC-WORK-RATE (1:4) TO WS-CALC-WORK-RATE-P1 (3:4)
              MOVE WS-CALC-WORK-RATE (6:2) TO WS-CALC-WORK-RATE-P2 (1:2)
              ADD 1 TO WS-CALC-WORK-RATE-PERIOD
           END-IF.
      * Rate is in form xxxxx.x
           IF WS-CALC-WORK-RATE (6:1) IS EQUAL TO '.'
              MOVE WS-CALC-WORK-RATE (1:5) TO WS-CALC-WORK-RATE-P1 (2:5)
              MOVE WS-CALC-WORK-RATE (7:1) TO WS-CALC-WORK-RATE-P2 (1:1)
              ADD 1 TO WS-CALC-WORK-RATE-PERIOD
           END-IF.
      * Rate is in form xxxxxx.
           IF WS-CALC-WORK-RATE (7:1) IS EQUAL TO '.'
              MOVE WS-CALC-WORK-RATE (1:6) TO WS-CALC-WORK-RATE-P1 (1:6)
              MOVE ZEROS                   TO WS-CALC-WORK-RATE-P2 (1:1)
              ADD 1 TO WS-CALC-WORK-RATE-PERIOD
           END-IF.
           IF WS-CALC-WORK-RATE-PERIOD IS NOT EQUAL TO 1
              MOVE 'Decimal point missing/misplaced in interest rate'
                TO WS-ERROR-MSG
              GO TO VALIDATE-RATE-ERROR
           END-IF.
           IF WS-CALC-WORK-RATE-P1 IS NOT NUMERIC OR
              WS-CALC-WORK-RATE-P2 IS NOT NUMERIC
              MOVE 'Rate is not numeric'
                TO WS-ERROR-MSG
              GO TO VALIDATE-RATE-ERROR
           END-IF.
           IF WS-CALC-WORK-RATE-P2 (4:3) IS NOT EQUAL TO '000'
              MOVE 'Rate has too many decimal places'
                TO WS-ERROR-MSG
              GO TO VALIDATE-RATE-ERROR
           END-IF.
      * Bring parts of rate together with no physical decimal point
           MOVE WS-CALC-WORK-RATE-P1 (4:3) TO WS-CALC-WORK-PERC (1:3).
           MOVE WS-CALC-WORK-RATE-P2 (1:3) TO WS-CALC-WORK-PERC (4:3).

           IF WS-CALC-WORK-PERC-N IS NOT GREATER THAN ZERO
              MOVE 'Nothing''s free. Rate must be greater than 0%'
                TO WS-ERROR-MSG
              GO TO VALIDATE-RATE-ERROR
           END-IF.
           IF WS-CALC-WORK-PERC-N IS NOT LESS THAN 100.000
              MOVE 'Outrageous rate - 100% or more'
                TO WS-ERROR-MSG
              GO TO VALIDATE-RATE-ERROR
           END-IF.

           GO TO VALIDATE-RATE-EXIT.

       VALIDATE-RATE-ERROR.
           SET INPUT-ERROR TO TRUE.
       VALIDATE-RATE-EXIT.
           EXIT.

       VALIDATE-TERM.
            CONTINUE.
       VALIDATE-TERM-RIGHT-JUSTIFY.
           IF WS-CALC-WORK-TERM IS EQUAL TO SPACES OR
              WS-CALC-WORK-TERM IS EQUAL TO LOW-VALUES
              MOVE 'Please enter a term as a number of months'
                TO WS-ERROR-MSG
              GO TO VALIDATE-TERM-ERROR
           END-IF.
           IF WS-CALC-WORK-TERM (5:1) IS EQUAL TO SPACES OR
              WS-CALC-WORK-TERM (5:1) IS EQUAL TO LOW-VALUE
              MOVE WS-CALC-WORK-TERM (1:4) TO WS-CALC-WORK-TEMP
              MOVE SPACES TO WS-CALC-WORK-TERM
              MOVE WS-CALC-WORK-TEMP (1:4) TO WS-CALC-WORK-TERM (2:4)
              GO TO VALIDATE-TERM-RIGHT-JUSTIFY
           END-IF.
           INSPECT WS-CALC-WORK-TERM
             REPLACING LEADING SPACES BY ZEROS.
           IF WS-CALC-WORK-TERM IS NOT NUMERIC
              MOVE 'Term is invalid (not numeric)'
                TO WS-ERROR-MSG
              GO TO VALIDATE-TERM-ERROR
           END-IF.
           IF WS-CALC-WORK-TERM IS EQUAL TO ZERO
              MOVE 'Please enter a non-zero term'
                TO WS-ERROR-MSG
              GO TO VALIDATE-TERM-ERROR
           END-IF.
           IF WS-CALC-WORK-TERM-N IS GREATER THAN 1200
              MOVE 'Term exceeds 100 years!'
                TO WS-ERROR-MSG
              GO TO VALIDATE-TERM-ERROR
           END-IF.

           GO TO VALIDATE-TERM-EXIT.

       VALIDATE-TERM-ERROR.
           SET INPUT-ERROR TO TRUE.
       VALIDATE-TERM-EXIT.
           EXIT.

      * $ Version 5.99c sequenced on Wednesday 3 Mar 2011 at 1:00pm
