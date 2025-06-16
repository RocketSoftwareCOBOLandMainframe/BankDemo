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
      * Program:     BBANK30P.CBL                                     *
      * Layer:       Business logic                                   *
      * Function:    Display account balances                         *
      *****************************************************************

       IDENTIFICATION DIVISION.
       PROGRAM-ID.
           BBANK30P.
       DATE-WRITTEN.
           September 2003.
       DATE-COMPILED.
           Today.

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-MISC-STORAGE.
         05  WS-PROGRAM-ID                         PIC X(8)
             VALUE 'BBANK30P'.
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
         05  WS-SUB1                               PIC S9(4) COMP.
         05  WS-SUB-LIMIT                          PIC S9(4) COMP.
         05  WS-EDIT-BALANCE                       PIC Z,ZZZ,ZZ9.99-.
         05  WS-DYNAMIC-PGM                        PIC X(8)
             VALUE 'UNKNOWN'.

       01  WS-SERVICE-CHARGES.
         05  WS-SRV-MSG.
           10  FILLER                              PIC X(43)
               VALUE 'Service charges are estimated based on your'.
           10  FILLER                              PIC X(19)
               VALUE ' existing balances '.
         05  WS-SRV-BAL                            PIC X(9).
         05  WS-SRV-BAL-N REDEFINES WS-SRV-BAL     PIC S9(7)V99.
         05  WS-SRV-CHARGE                         PIC ZZ9.99
                                                   BLANK ZERO.
         05  WS-SRV-AMT                            PIC 9(3)V99.
         05  WS-SRV-CHARGE-LIMITS.
           10  WS-SRV-BAND0.
             15  WS-SRV-BAL0     VALUE 9999999       PIC S9(7).
             15  WS-SRV-CHG0     VALUE 050.00        PIC 9(3)V99.
           10  WS-SRV-BAND1.
             15  WS-SRV-BAL1     VALUE 0000000       PIC S9(7).
             15  WS-SRV-CHG1     VALUE 025.00        PIC 9(3)V99.
           10  WS-SRV-BAND2.
             15  WS-SRV-BAL2     VALUE 0001000       PIC S9(7).
             15  WS-SRV-CHG2     VALUE 020.00        PIC 9(3)V99.
           10  WS-SRV-BAND3.
             15  WS-SRV-BAL3     VALUE 0005000       PIC S9(7).
             15  WS-SRV-CHG3     VALUE 015.00        PIC 9(3)V99.
           10  WS-SRV-BAND4.
             15  WS-SRV-BAL4     VALUE 0010000       PIC S9(7).
             15  WS-SRV-CHG4     VALUE 010.00        PIC 9(3)V99.
           10  WS-SRV-BAND5.
             15  WS-SRV-BAL5     VALUE 0100000       PIC S9(7).
             15  WS-SRV-CHG5     VALUE 000.00        PIC 9(3)V99.

       01  WS-TIME-DATE-WORK-AREA.
       COPY CDATED.

       01  WS-BANK-DATA.
       COPY CBANKDAT.

       01  WS-HELP-DATA.
       COPY CHELPD01.

       01  WS-ACCOUNT-DATA.
       COPY CBANKD03.

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
      * Move the passed area to our area                              *
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
      * Save the passed return flag and then turn it off              *
      *****************************************************************
           MOVE BANK-RETURN-FLAG TO WS-RETURN-FLAG.
           SET BANK-RETURN-FLAG-OFF TO TRUE.

      *****************************************************************
      * Check the AID to see if its valid at this point               *
      *****************************************************************
           SET PFK-INVALID TO TRUE.
           IF BANK-AID-ENTER OR
              BANK-AID-PFK03 OR
              BANK-AID-PFK04 OR
              BANK-AID-PFK06
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
              MOVE 'BBANK30P' TO BANK-LAST-PROG
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
                 MOVE 'BBANK30P' TO BANK-LAST-PROG
                 MOVE 'BBANK30P' TO BANK-NEXT-PROG
                 MOVE 'MBANK30' TO BANK-LAST-MAPSET
                 MOVE 'HELP30A' TO BANK-LAST-MAP
                 MOVE 'MBANK30' TO BANK-NEXT-MAPSET
                 MOVE 'BANK30A' TO BANK-NEXT-MAP
                 GO TO COMMON-RETURN
              ELSE
                 MOVE 01 TO BANK-HELP-SCREEN
                 MOVE 'BBANK30P' TO BANK-LAST-PROG
                 MOVE 'BBANK30P' TO BANK-NEXT-PROG
                 MOVE 'MBANK30' TO BANK-LAST-MAPSET
                 MOVE 'BANK30A' TO BANK-LAST-MAP
                 MOVE 'MBANK30' TO BANK-NEXT-MAPSET
                 MOVE 'HELP30A' TO BANK-NEXT-MAP
                 MOVE 'BANK30' TO HELP01I-SCRN
                 COPY CHELPX01.
                 MOVE HELP01O-DATA TO BANK-HELP-DATA
                 GO TO COMMON-RETURN
           END-IF.

      *****************************************************************
      * Check the AID to see if we have to return to previous screen  *
      *****************************************************************
           IF BANK-AID-PFK04
              MOVE 'BBANK30P' TO BANK-LAST-PROG
              MOVE 'BBANK20P' TO BANK-NEXT-PROG
              MOVE 'MBANK20' TO BANK-NEXT-MAPSET
              MOVE 'BANK20A' TO BANK-NEXT-MAP
              SET BANK-AID-ENTER TO TRUE
              GO TO COMMON-RETURN
           END-IF.

      * Check if we have set the screen up before or is this 1st time
           IF BANK-LAST-MAPSET IS NOT EQUAL TO 'MBANK30'
              MOVE WS-RETURN-MSG TO BANK-ERROR-MSG
              MOVE 'BBANK30P' TO BANK-LAST-PROG
              MOVE 'BBANK30P' TO BANK-NEXT-PROG
              MOVE 'MBANK30' TO BANK-LAST-MAPSET
              MOVE 'BANK30A' TO BANK-LAST-MAP
              MOVE 'MBANK30' TO BANK-NEXT-MAPSET
              MOVE 'BANK30A' TO BANK-NEXT-MAP
              PERFORM POPULATE-SCREEN-DATA THRU
                      POPULATE-SCREEN-DATA-EXIT
              GO TO COMMON-RETURN
           END-IF.

           MOVE 0 TO WS-SUB1.
           MOVE SPACES TO BANK-SCR40-ACC.
      * Calculate no of entries in table
           DIVIDE LENGTH OF BANK-SCREEN30-INPUT (1)
             INTO LENGTH OF BANK-SCREEN30-INPUT-DATA
               GIVING WS-SUB-LIMIT.
       SCAN-INPUT-LOOP.
           ADD 1 TO WS-SUB1.
           IF BANK-SCR30-DET (WS-SUB1) IS NOT = LOW-VALUES
              MOVE LOW-VALUES TO BANK-SCR30-DET (WS-SUB1)
              IF BANK-AID-ENTER
                 MOVE BANK-SCR30-ACC (WS-SUB1) TO BANK-SCR35-ACC
                 MOVE BANK-SCR30-DSC (WS-SUB1) TO BANK-SCR35-DSC
                 MOVE BANK-SCR30-BAL (WS-SUB1) TO BANK-SCR35-BAL
                 MOVE BANK-SCR30-DTE (WS-SUB1) TO BANK-SCR35-DTE
                 MOVE BANK-SCR30-TXN (WS-SUB1) TO BANK-SCR35-TRANS
                 MOVE 'BBANK30P' TO BANK-LAST-PROG
                 MOVE 'BBANK35P' TO BANK-NEXT-PROG
                 MOVE 'BBANK30P' TO BANK-RETURN-TO-PROG
                 GO TO COMMON-RETURN
              END-IF
              IF BANK-AID-PFK06
                 IF BANK-SCR30-TXN (WS-SUB1) IS NOT EQUAL TO SPACES
                    MOVE BANK-SCR30-ACC (WS-SUB1) TO BANK-SCR40-ACC
                    MOVE BANK-SCR30-DSC (WS-SUB1) TO BANK-SCR40-ACCTYPE
                    MOVE 'BBANK30P' TO BANK-LAST-PROG
                    MOVE 'BBANK40P' TO BANK-NEXT-PROG
                    MOVE 'BBANK30P' TO BANK-RETURN-TO-PROG
                    GO TO COMMON-RETURN
                 ELSE
                    MOVE 'No transactions to show' TO WS-ERROR-MSG
                    MOVE WS-ERROR-MSG TO BANK-ERROR-MSG
                    MOVE 'BBANK30P' TO BANK-LAST-PROG
                    MOVE 'BBANK30P' TO BANK-NEXT-PROG
                    MOVE 'MBANK30' TO BANK-LAST-MAPSET
                    MOVE 'BANK30A' TO BANK-LAST-MAP
                    MOVE 'MBANK30' TO BANK-NEXT-MAPSET
                    MOVE 'BANK30A' TO BANK-NEXT-MAP
                    GO TO COMMON-RETURN
                 END-IF
              END-IF
           END-IF.

           IF WS-SUB1 IS LESS THAN WS-SUB-LIMIT
              GO TO SCAN-INPUT-LOOP
           END-IF.

      * As this is a display screen we need PFK03/4 to get out so we
      * will just redisplay the data
           PERFORM POPULATE-SCREEN-DATA THRU
                   POPULATE-SCREEN-DATA-EXIT.

           GO TO COMMON-RETURN.

       COMMON-RETURN.
           MOVE WS-BANK-DATA TO DFHCOMMAREA (1:LENGTH OF WS-BANK-DATA).
       COPY CRETURN.

       VALIDATE-DATA.
           SET INPUT-OK TO TRUE.
           GO TO VALIDATE-DATA-EXIT.

       VALIDATE-DATA-ERROR.
           SET INPUT-ERROR TO TRUE.
       VALIDATE-DATA-EXIT.
           EXIT.

       POPULATE-SCREEN-DATA.
           MOVE SPACES TO CD03-DATA.
           MOVE BANK-USERID TO CD03I-CONTACT-ID.
      * Now go get the data
       COPY CBANKX03.
           MOVE CD03O-ACC1 TO BANK-SCR30-ACC1.
           MOVE CD03O-DSC1 TO BANK-SCR30-DSC1.
           IF CD03O-BAL1 IS EQUAL TO SPACES
              MOVE CD03O-BAL1 TO BANK-SCR30-BAL1
           ELSE
              MOVE CD03O-BAL1N TO WS-EDIT-BALANCE
              MOVE WS-EDIT-BALANCE TO BANK-SCR30-BAL1
           END-IF.
           MOVE CD03O-BAL1 TO WS-SRV-BAL.
           PERFORM CALC-SERVICE-CHARGE THRU
                   CALC-SERVICE-CHARGE-EXIT.
           MOVE WS-SRV-CHARGE TO BANK-SCR30-SRV1.
           IF CD03O-DTE1 IS EQUAL TO SPACES
              MOVE CD03O-DTE1 TO BANK-SCR30-DTE1
           ELSE
              MOVE CD03O-DTE1 TO DDI-DATA
              SET DDI-ISO TO TRUE
              SET DDO-DD-MMM-YYYY TO TRUE
              PERFORM CALL-DATECONV THRU
                     CALL-DATECONV-EXIT
              MOVE DDO-DATA TO BANK-SCR30-DTE1
           END-IF.
           MOVE CD03O-TXN1 TO BANK-SCR30-TXN1.

           MOVE CD03O-ACC2 TO BANK-SCR30-ACC2.
           MOVE CD03O-DSC2 TO BANK-SCR30-DSC2.
           IF CD03O-BAL2 IS EQUAL TO SPACES
              MOVE CD03O-BAL2 TO BANK-SCR30-BAL2
           ELSE
              MOVE CD03O-BAL2N TO WS-EDIT-BALANCE
              MOVE WS-EDIT-BALANCE TO BANK-SCR30-BAL2
           END-IF.
           MOVE CD03O-BAL2 TO WS-SRV-BAL
           PERFORM CALC-SERVICE-CHARGE THRU
                   CALC-SERVICE-CHARGE-EXIT.
           MOVE WS-SRV-CHARGE TO BANK-SCR30-SRV2.
           IF CD03O-DTE2 IS EQUAL TO SPACES
              MOVE CD03O-DTE2 TO BANK-SCR30-DTE2
           ELSE
              MOVE CD03O-DTE2 TO DDI-DATA
              SET DDI-ISO TO TRUE
              SET DDO-DD-MMM-YYYY TO TRUE
              PERFORM CALL-DATECONV THRU
                      CALL-DATECONV-EXIT
              MOVE DDO-DATA TO BANK-SCR30-DTE2
           END-IF.
           MOVE CD03O-TXN2 TO BANK-SCR30-TXN2.

           MOVE CD03O-ACC3 TO BANK-SCR30-ACC3.
           MOVE CD03O-DSC3 TO BANK-SCR30-DSC3.
           IF CD03O-BAL3 IS EQUAL TO SPACES
              MOVE CD03O-BAL3 TO BANK-SCR30-BAL3
           ELSE
              MOVE CD03O-BAL3N TO WS-EDIT-BALANCE
              MOVE WS-EDIT-BALANCE TO BANK-SCR30-BAL3
           END-IF.
           MOVE CD03O-BAL3 TO WS-SRV-BAL.
           PERFORM CALC-SERVICE-CHARGE THRU
                   CALC-SERVICE-CHARGE-EXIT.
           MOVE WS-SRV-CHARGE TO BANK-SCR30-SRV3.
           IF CD03O-DTE3 IS EQUAL TO SPACES
              MOVE CD03O-DTE3 TO BANK-SCR30-DTE3
           ELSE
              MOVE CD03O-DTE3 TO DDI-DATA
              SET DDI-ISO TO TRUE
              SET DDO-DD-MMM-YYYY TO TRUE
              PERFORM CALL-DATECONV THRU
                      CALL-DATECONV-EXIT
              MOVE DDO-DATA TO BANK-SCR30-DTE3
           END-IF.
           MOVE CD03O-TXN3 TO BANK-SCR30-TXN3.

           MOVE CD03O-ACC4 TO BANK-SCR30-ACC4.
           MOVE CD03O-DSC4 TO BANK-SCR30-DSC4.
           IF CD03O-BAL4 IS EQUAL TO SPACES
              MOVE CD03O-BAL4 TO BANK-SCR30-BAL4
           ELSE
              MOVE CD03O-BAL4N TO WS-EDIT-BALANCE
              MOVE WS-EDIT-BALANCE TO BANK-SCR30-BAL4
           END-IF.
           MOVE CD03O-BAL4 TO WS-SRV-BAL.
           PERFORM CALC-SERVICE-CHARGE THRU
                   CALC-SERVICE-CHARGE-EXIT.
           MOVE WS-SRV-CHARGE TO BANK-SCR30-SRV4.
           IF CD03O-DTE4 IS EQUAL TO SPACES
              MOVE CD03O-DTE4 TO BANK-SCR30-DTE4
           ELSE
              MOVE CD03O-DTE4 TO DDI-DATA
              SET DDI-ISO TO TRUE
              SET DDO-DD-MMM-YYYY TO TRUE
              PERFORM CALL-DATECONV THRU
                      CALL-DATECONV-EXIT
              MOVE DDO-DATA TO BANK-SCR30-DTE4
           END-IF.
           MOVE CD03O-TXN4 TO BANK-SCR30-TXN4.

           MOVE CD03O-ACC5 TO BANK-SCR30-ACC5.
           MOVE CD03O-DSC5 TO BANK-SCR30-DSC5.
           IF CD03O-BAL5 IS EQUAL TO SPACES
              MOVE CD03O-BAL5 TO BANK-SCR30-BAL5
           ELSE
              MOVE CD03O-BAL5N TO WS-EDIT-BALANCE
              MOVE WS-EDIT-BALANCE TO BANK-SCR30-BAL5
           END-IF.

           MOVE CD03O-BAL5 TO WS-SRV-BAL.
           PERFORM CALC-SERVICE-CHARGE THRU
                   CALC-SERVICE-CHARGE-EXIT.
           MOVE WS-SRV-CHARGE TO BANK-SCR30-SRV5.
           IF CD03O-DTE5 IS EQUAL TO SPACES
              MOVE CD03O-DTE5 TO BANK-SCR30-DTE5
           ELSE
              MOVE CD03O-DTE5 TO DDI-DATA
              SET DDI-ISO TO TRUE
              SET DDO-DD-MMM-YYYY TO TRUE
              PERFORM CALL-DATECONV THRU
                      CALL-DATECONV-EXIT
              MOVE DDO-DATA TO BANK-SCR30-DTE5
           END-IF.
           MOVE CD03O-TXN5 TO BANK-SCR30-TXN5.

           MOVE CD03O-ACC6 TO BANK-SCR30-ACC6.
           MOVE CD03O-DSC6 TO BANK-SCR30-DSC6.
           IF CD03O-BAL6 IS EQUAL TO SPACES
              MOVE CD03O-BAL6 TO BANK-SCR30-BAL6
           ELSE
              MOVE CD03O-BAL6N TO WS-EDIT-BALANCE
              MOVE WS-EDIT-BALANCE TO BANK-SCR30-BAL6
           END-IF.

           MOVE CD03O-BAL6 TO WS-SRV-BAL.
           PERFORM CALC-SERVICE-CHARGE THRU
                   CALC-SERVICE-CHARGE-EXIT.
           MOVE WS-SRV-CHARGE TO BANK-SCR30-SRV6.
           IF CD03O-DTE6 IS EQUAL TO SPACES
              MOVE CD03O-DTE6 TO BANK-SCR30-DTE6
           ELSE
              MOVE CD03O-DTE6 TO DDI-DATA
              SET DDI-ISO TO TRUE
              SET DDO-DD-MMM-YYYY TO TRUE
              PERFORM CALL-DATECONV THRU
                      CALL-DATECONV-EXIT
              MOVE DDO-DATA TO BANK-SCR30-DTE6
           END-IF.
           MOVE CD03O-TXN6 TO BANK-SCR30-TXN6.

           IF BANK-SCR30-SRV1 IS NOT EQUAL TO SPACES OR
              BANK-SCR30-SRV2 IS NOT EQUAL TO SPACES OR
              BANK-SCR30-SRV3 IS NOT EQUAL TO SPACES OR
              BANK-SCR30-SRV4 IS NOT EQUAL TO SPACES OR
              BANK-SCR30-SRV5 IS NOT EQUAL TO SPACES OR
              BANK-SCR30-SRV6 IS NOT EQUAL TO SPACES
              MOVE WS-SRV-MSG TO BANK-SCR30-SRVMSG
           ELSE
              MOVE SPACES TO BANK-SCR30-SRVMSG
           END-IF.

       POPULATE-SCREEN-DATA-EXIT.
           EXIT.


      *****************************************************************
      * Calculate any service charges based on provided balance       *
      *****************************************************************
       CALC-SERVICE-CHARGE.
           IF WS-SRV-BAL IS EQUAL TO SPACES
              MOVE 0 TO WS-SRV-AMT
              GO TO CALC-SERVICE-CHARGE-EDIT
           END-IF.
           IF WS-SRV-BAL-N IS GREATER THAN WS-SRV-BAL5
              MOVE WS-SRV-CHG5 TO WS-SRV-AMT
              GO TO CALC-SERVICE-CHARGE-EDIT
           END-IF.
           IF WS-SRV-BAL-N IS GREATER THAN WS-SRV-BAL4
              MOVE WS-SRV-CHG4 TO WS-SRV-AMT
              GO TO CALC-SERVICE-CHARGE-EDIT
           END-IF.
           IF WS-SRV-BAL-N IS GREATER THAN WS-SRV-BAL3
              MOVE WS-SRV-CHG3 TO WS-SRV-AMT
              GO TO CALC-SERVICE-CHARGE-EDIT
           END-IF.
           IF WS-SRV-BAL-N IS GREATER THAN WS-SRV-BAL2
              MOVE WS-SRV-CHG2 TO WS-SRV-AMT
              GO TO CALC-SERVICE-CHARGE-EDIT
           END-IF.
           IF WS-SRV-BAL-N IS GREATER THAN WS-SRV-BAL1
              MOVE WS-SRV-CHG1 TO WS-SRV-AMT
              GO TO CALC-SERVICE-CHARGE-EDIT
           ELSE
              MOVE WS-SRV-CHG0 TO WS-SRV-AMT
              GO TO CALC-SERVICE-CHARGE-EDIT
           END-IF.
       CALC-SERVICE-CHARGE-EDIT.
           MOVE WS-SRV-AMT TO WS-SRV-CHARGE.
       CALC-SERVICE-CHARGE-EXIT.
           EXIT.

      *****************************************************************
      * Call common routine to perform date conversions               *
      *****************************************************************
       CALL-DATECONV.
           MOVE BANK-ENV TO DD-ENV.
           MOVE 'UDATECNV' TO WS-DYNAMIC-PGM.
           CALL WS-DYNAMIC-PGM USING WS-TIME-DATE-WORK-AREA.
       CALL-DATECONV-EXIT.
           EXIT.

      * $ Version 5.99c sequenced on Wednesday 3 Mar 2011 at 1:00pm
