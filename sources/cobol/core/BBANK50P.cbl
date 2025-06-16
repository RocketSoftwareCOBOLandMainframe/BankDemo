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
      * Program:     BBANK50P.CBL                                     *
      * Layer:       Business logic                                   *
      * Function:    Transfer funds between accounts                  *
      *****************************************************************

       IDENTIFICATION DIVISION.
       PROGRAM-ID.
           BBANK50P.
       DATE-WRITTEN.
           September 2003.
       DATE-COMPILED.
           Today.

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-MISC-STORAGE.
         05  WS-PROGRAM-ID                         PIC X(8)
             VALUE 'BBANK50P'.
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
         05  WS-EDIT-BALANCE                       PIC Z,ZZZ,ZZ9.99-.
         05  WS-SEL-COUNT                          PIC 9(1).
         05  WS-XFER-AMT                           PIC X(8).
         05  WS-XFER-AMT-TMP                       PIC X(9).
         05  WS-XFER-AMT-TMP-N REDEFINES WS-XFER-AMT-TMP
                                                   PIC S9(7)V99.
         05  WS-XFER-AMT-NUM                       PIC X(9).
         05  WS-XFER-AMT-NUM-N REDEFINES WS-XFER-AMT-NUM
                                                   PIC S9(7)V99.
         05  WS-XFER-ACCT-FROM                     PIC X(9).
         05  WS-XFER-ACCT-FROM-BAL                 PIC X(13).
         05  WS-XFER-ACCT-FROM-BAL-N               PIC S9(7)V99.
         05  WS-XFER-ACCT-FROM-NEW-BAL-N           PIC S9(7)V99.
         05  WS-XFER-ACCT-TO                       PIC X(9).
         05  WS-XFER-ACCT-TO-BAL                   PIC X(13).
         05  WS-XFER-ACCT-TO-BAL-N                 PIC S9(7)V99.
         05  WS-XFER-ACCT-TO-NEW-BAL-N             PIC S9(7)V99.

       01  WS-BANK-DATA.
       COPY CBANKDAT.

       01  WS-HELP-DATA.
       COPY CHELPD01.

       01  WS-ACCT-DATA.
       COPY CBANKD03.

       01  WS-XFER-DATA.
       COPY CBANKD04.

       01  WS-TXN-DATA.
       COPY CBANKD06.

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
              MOVE 'BBANK50P' TO BANK-LAST-PROG
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
                 MOVE 'BBANK50P' TO BANK-LAST-PROG
                 MOVE 'BBANK50P' TO BANK-NEXT-PROG
                 MOVE 'MBANK50' TO BANK-LAST-MAPSET
                 MOVE 'HELP50A' TO BANK-LAST-MAP
                 MOVE 'MBANK50' TO BANK-NEXT-MAPSET
                 MOVE 'BANK50A' TO BANK-NEXT-MAP
                 GO TO COMMON-RETURN
              ELSE
                 MOVE 01 TO BANK-HELP-SCREEN
                 MOVE 'BBANK50P' TO BANK-LAST-PROG
                 MOVE 'BBANK50P' TO BANK-NEXT-PROG
                 MOVE 'MBANK50' TO BANK-LAST-MAPSET
                 MOVE 'BANK50A' TO BANK-LAST-MAP
                 MOVE 'MBANK50' TO BANK-NEXT-MAPSET
                 MOVE 'HELP50A' TO BANK-NEXT-MAP
                 MOVE 'BANK50' TO HELP01I-SCRN
                 COPY CHELPX01.
                 MOVE HELP01O-DATA TO BANK-HELP-DATA
                 GO TO COMMON-RETURN
           END-IF.

      *****************************************************************
      * Check the AID to see if we have to return to previous screen  *
      *****************************************************************
           IF BANK-AID-PFK04
              MOVE 'BBANK50P' TO BANK-LAST-PROG
              MOVE 'BBANK20P' TO BANK-NEXT-PROG
              MOVE 'MBANK20' TO BANK-NEXT-MAPSET
              MOVE 'BANK20A' TO BANK-NEXT-MAP
              SET BANK-AID-ENTER TO TRUE
              GO TO COMMON-RETURN
           END-IF.

      * Check if we have set the screen up before or is this 1st time
           IF BANK-LAST-MAPSET IS NOT EQUAL TO 'MBANK50'
              MOVE SPACES TO BANK-SCR50-XFER
              MOVE '_' TO BANK-SCR50-FRM1
              MOVE '_' TO BANK-SCR50-FRM2
              MOVE '_' TO BANK-SCR50-FRM3
              MOVE '_' TO BANK-SCR50-FRM4
              MOVE '_' TO BANK-SCR50-FRM5
              MOVE '_' TO BANK-SCR50-FRM6
              MOVE '_' TO BANK-SCR50-TO1
              MOVE '_' TO BANK-SCR50-TO2
              MOVE '_' TO BANK-SCR50-TO3
              MOVE '_' TO BANK-SCR50-TO4
              MOVE '_' TO BANK-SCR50-TO5
              MOVE '_' TO BANK-SCR50-TO6
              MOVE WS-RETURN-MSG TO BANK-ERROR-MSG
              MOVE 'BBANK50P' TO BANK-LAST-PROG
              MOVE 'BBANK50P' TO BANK-NEXT-PROG
              MOVE 'MBANK50' TO BANK-LAST-MAPSET
              MOVE 'BANK50A' TO BANK-LAST-MAP
              MOVE 'MBANK50' TO BANK-NEXT-MAPSET
              MOVE 'BANK50A' TO BANK-NEXT-MAP
              PERFORM POPULATE-SCREEN-DATA THRU
                      POPULATE-SCREEN-DATA-EXIT
              GO TO COMMON-RETURN
           END-IF.

           PERFORM VALIDATE-DATA THRU
                   VALIDATE-DATA-EXIT.

      * If we had an error display error and return
           IF INPUT-ERROR
              MOVE WS-ERROR-MSG TO BANK-ERROR-MSG
              MOVE 'BBANK50P' TO BANK-LAST-PROG
              MOVE 'BBANK50P' TO BANK-NEXT-PROG
              MOVE 'MBANK50' TO BANK-LAST-MAPSET
              MOVE 'BANK50A' TO BANK-LAST-MAP
              MOVE 'MBANK50' TO BANK-NEXT-MAPSET
              MOVE 'BANK50A' TO BANK-NEXT-MAP
              GO TO COMMON-RETURN
           END-IF.

      *****************************************************************
      * If we paying money to the bank (account 99999999n) then we    *
      * don't know the bank's balance so we pass the transfer amount  *
      * to the I/O routine and let it adjust the balance without      *
      * checking it first.                                            *
      *****************************************************************
           MOVE SPACES TO CD04-DATA.
           MOVE BANK-USERID TO CD04I-FROM-PID.
           MOVE WS-XFER-ACCT-FROM TO CD04I-FROM-ACC.
           MOVE WS-XFER-ACCT-FROM-BAL-N TO CD04I-FROM-OLD-BAL.
           SUBTRACT WS-XFER-AMT-NUM-N FROM WS-XFER-ACCT-FROM-BAL-N
             GIVING WS-XFER-ACCT-FROM-NEW-BAL-N.
           MOVE WS-XFER-ACCT-FROM-NEW-BAL-N TO CD04I-FROM-NEW-BAL.
           IF WS-XFER-ACCT-TO(1:8) IS EQUAL TO '99999999'
              MOVE 'BANK ' TO CD04I-TO-PID
              MOVE WS-XFER-ACCT-TO TO CD04I-TO-ACC
              MOVE WS-XFER-ACCT-TO-BAL-N TO CD04I-TO-OLD-BAL
              COMPUTE WS-XFER-ACCT-TO-NEW-BAL-N =
                      WS-XFER-AMT-NUM-N
           ELSE
              MOVE BANK-USERID TO CD04I-TO-PID
              MOVE WS-XFER-ACCT-TO TO CD04I-TO-ACC
              MOVE WS-XFER-ACCT-TO-BAL-N TO CD04I-TO-OLD-BAL
              COMPUTE WS-XFER-ACCT-TO-NEW-BAL-N =
                      WS-XFER-AMT-NUM-N + WS-XFER-ACCT-TO-BAL-N
           END-IF.
           MOVE WS-XFER-ACCT-TO-NEW-BAL-N TO CD04I-TO-NEW-BAL.
           MOVE WS-XFER-ACCT-FROM-BAL-N TO CD04I-FROM-OLD-BAL.
      * Now go attempt to update the data
       COPY CBANKX04.
           IF NOT CD04O-UPDATE-OK
              MOVE 'Unable to transfer funds. Update failed.'
                TO BANK-ERROR-MSG
           ELSE
              MOVE SPACES TO BANK-ERROR-MSG
              STRING 'Transferred ' DELIMITED BY SIZE
                     BANK-SCR50-XFER DELIMITED BY SIZE
                     ' from ' DELIMITED BY SIZE
                     WS-XFER-ACCT-FROM DELIMITED BY SIZE
                     ' to ' DELIMITED BY SIZE
                     WS-XFER-ACCT-TO DELIMITED BY SIZE
                INTO BANK-ERROR-MSG
      * Now produce the audit trail
              MOVE SPACES TO CD06-DATA
              MOVE CD04O-TIMESTAMP TO CD06I-TIMESTAMP
              MOVE BANK-USERID TO CD06I-FROM-PID
              MOVE CD04I-FROM-ACC TO CD06I-FROM-ACC
              MULTIPLY WS-XFER-AMT-NUM-N BY -1
                GIVING CD06I-FROM-AMOUNT
              STRING 'Transferred to a/c ' DELIMITED BY SIZE
                     CD04I-TO-ACC DELIMITED BY SIZE
                INTO CD06I-FROM-DESC
              MOVE BANK-USERID TO CD06I-TO-PID
              MOVE CD04I-TO-ACC TO CD06I-TO-ACC
              MULTIPLY WS-XFER-AMT-NUM-N BY +1
                GIVING CD06I-TO-AMOUNT
              STRING 'Transferred from a/c ' DELIMITED BY SIZE
                     CD04I-FROM-ACC DELIMITED BY SIZE
                INTO CD06I-TO-DESC
       COPY CBANKX06.

              MOVE SPACES TO BANK-SCR50-XFER
              MOVE '_' TO BANK-SCR50-FRM1
              MOVE '_' TO BANK-SCR50-FRM2
              MOVE '_' TO BANK-SCR50-FRM3
              MOVE '_' TO BANK-SCR50-FRM4
              MOVE '_' TO BANK-SCR50-FRM5
              MOVE '_' TO BANK-SCR50-FRM6
              MOVE '_' TO BANK-SCR50-TO1
              MOVE '_' TO BANK-SCR50-TO2
              MOVE '_' TO BANK-SCR50-TO3
              MOVE '_' TO BANK-SCR50-TO4
              MOVE '_' TO BANK-SCR50-TO5
              MOVE '_' TO BANK-SCR50-TO6
           END-IF.

           PERFORM POPULATE-SCREEN-DATA THRU
                   POPULATE-SCREEN-DATA-EXIT.

           GO TO COMMON-RETURN.

       COMMON-RETURN.
           MOVE WS-BANK-DATA TO DFHCOMMAREA (1:LENGTH OF WS-BANK-DATA).
       COPY CRETURN.

       VALIDATE-DATA.
           SET INPUT-OK TO TRUE.

           MOVE BANK-SCR50-XFER TO WS-XFER-AMT.
           PERFORM VALIDATE-XFER THRU
                   VALIDATE-XFER-EXIT.
           IF NOT INPUT-OK
              GO TO VALIDATE-DATA-ERROR
           END-IF.

           MOVE ZERO TO WS-SEL-COUNT.

           MOVE SPACES TO WS-XFER-ACCT-FROM.
           MOVE SPACES TO WS-XFER-ACCT-FROM-BAL.
           MOVE SPACES TO WS-XFER-ACCT-TO.

           IF BANK-SCR50-FRM1 IS NOT EQUAL TO LOW-VALUES
              ADD 1 TO WS-SEL-COUNT
              MOVE BANK-SCR50-ACC1 TO WS-XFER-ACCT-FROM
              MOVE BANK-SCR50-BAL1 TO WS-XFER-ACCT-FROM-BAL
           END-IF.
           IF BANK-SCR50-FRM2 IS NOT EQUAL TO LOW-VALUES
              ADD 1 TO WS-SEL-COUNT
              MOVE BANK-SCR50-ACC2 TO WS-XFER-ACCT-FROM
              MOVE BANK-SCR50-BAL2 TO WS-XFER-ACCT-FROM-BAL
           END-IF.
           IF BANK-SCR50-FRM3 IS NOT EQUAL TO LOW-VALUES
              ADD 1 TO WS-SEL-COUNT
              MOVE BANK-SCR50-ACC3 TO WS-XFER-ACCT-FROM
              MOVE BANK-SCR50-BAL3 TO WS-XFER-ACCT-FROM-BAL
           END-IF.
           IF BANK-SCR50-FRM4 IS NOT EQUAL TO LOW-VALUES
              ADD 1 TO WS-SEL-COUNT
              MOVE BANK-SCR50-ACC4 TO WS-XFER-ACCT-FROM
              MOVE BANK-SCR50-BAL4 TO WS-XFER-ACCT-FROM-BAL
           END-IF.
           IF BANK-SCR50-FRM5 IS NOT EQUAL TO LOW-VALUES
              ADD 1 TO WS-SEL-COUNT
              MOVE BANK-SCR50-ACC5 TO WS-XFER-ACCT-FROM
              MOVE BANK-SCR50-BAL5 TO WS-XFER-ACCT-FROM-BAL
           END-IF.
           IF BANK-SCR50-FRM6 IS NOT EQUAL TO LOW-VALUES
              ADD 1 TO WS-SEL-COUNT
              MOVE BANK-SCR50-ACC6 TO WS-XFER-ACCT-FROM
              MOVE BANK-SCR50-BAL6 TO WS-XFER-ACCT-FROM-BAL
           END-IF.

           IF WS-SEL-COUNT IS EQUAL TO ZERO
              MOVE 'Please select an account to transfer from'
                TO WS-ERROR-MSG
              GO TO VALIDATE-DATA-ERROR
           END-IF.

           IF WS-SEL-COUNT IS GREATER THAN 1
              MOVE 'Please select a single account to transfer from'
                TO WS-ERROR-MSG
              GO TO VALIDATE-DATA-ERROR
           END-IF.

           MOVE ZERO TO WS-SEL-COUNT.

           IF BANK-SCR50-TO1 IS NOT EQUAL TO LOW-VALUES
              ADD 1 TO WS-SEL-COUNT
              MOVE BANK-SCR50-ACC1 TO WS-XFER-ACCT-TO
              MOVE BANK-SCR50-BAL1 TO WS-XFER-ACCT-TO-BAL
           END-IF.
           IF BANK-SCR50-TO2 IS NOT EQUAL TO LOW-VALUES
              ADD 1 TO WS-SEL-COUNT
              MOVE BANK-SCR50-ACC2 TO WS-XFER-ACCT-TO
              MOVE BANK-SCR50-BAL2 TO WS-XFER-ACCT-TO-BAL
           END-IF.
           IF BANK-SCR50-TO3 IS NOT EQUAL TO LOW-VALUES
              ADD 1 TO WS-SEL-COUNT
              MOVE BANK-SCR50-ACC3 TO WS-XFER-ACCT-TO
              MOVE BANK-SCR50-BAL3 TO WS-XFER-ACCT-TO-BAL
           END-IF.
           IF BANK-SCR50-TO4 IS NOT EQUAL TO LOW-VALUES
              ADD 1 TO WS-SEL-COUNT
              MOVE BANK-SCR50-ACC4 TO WS-XFER-ACCT-TO
              MOVE BANK-SCR50-BAL4 TO WS-XFER-ACCT-TO-BAL
           END-IF.
           IF BANK-SCR50-TO5 IS NOT EQUAL TO LOW-VALUES
              ADD 1 TO WS-SEL-COUNT
              MOVE BANK-SCR50-ACC5 TO WS-XFER-ACCT-TO
              MOVE BANK-SCR50-BAL5 TO WS-XFER-ACCT-TO-BAL
           END-IF.
           IF BANK-SCR50-TO6 IS NOT EQUAL TO LOW-VALUES
              ADD 1 TO WS-SEL-COUNT
              MOVE BANK-SCR50-ACC6 TO WS-XFER-ACCT-TO
              MOVE BANK-SCR50-BAL6 TO WS-XFER-ACCT-TO-BAL
           END-IF.

           IF WS-SEL-COUNT IS EQUAL TO ZERO
              MOVE 'Please select an account to transfer to'
                TO WS-ERROR-MSG
              GO TO VALIDATE-DATA-ERROR
           END-IF.

           IF WS-SEL-COUNT IS GREATER THAN 1
              MOVE 'Please select a single account to transfer to'
                TO WS-ERROR-MSG
              GO TO VALIDATE-DATA-ERROR
           END-IF.

           IF WS-XFER-ACCT-FROM IS EQUAL TO WS-XFER-ACCT-TO
              MOVE 'Please select an different to & from accounts'
                TO WS-ERROR-MSG
              GO TO VALIDATE-DATA-ERROR
           END-IF.

      * Reformat balance in from a/c from 9,999,999.99- to 999999999.
           MOVE WS-XFER-ACCT-FROM-BAL (1:1) TO WS-XFER-AMT-TMP (1:1).
           MOVE WS-XFER-ACCT-FROM-BAL (3:3) TO WS-XFER-AMT-TMP (2:3).
           MOVE WS-XFER-ACCT-FROM-BAL (7:3) TO WS-XFER-AMT-TMP (5:3).
           MOVE WS-XFER-ACCT-FROM-BAL (11:2) TO WS-XFER-AMT-TMP (8:2).
           INSPECT WS-XFER-AMT-TMP REPLACING LEADING SPACES BY ZEROS.
           IF WS-XFER-ACCT-FROM-BAL (13:1) IS EQUAL TO '-'
              MULTIPLY -1 BY WS-XFER-AMT-TMP-N
                GIVING WS-XFER-ACCT-FROM-BAL-N
           ELSE
              MULTIPLY +1 BY WS-XFER-AMT-TMP-N
                GIVING WS-XFER-ACCT-FROM-BAL-N
           END-IF.
      * Reformat balance in to a/c from 9,999,999.99- to 999999999.
           MOVE WS-XFER-ACCT-TO-BAL (1:1) TO WS-XFER-AMT-TMP (1:1).
           MOVE WS-XFER-ACCT-TO-BAL (3:3) TO WS-XFER-AMT-TMP (2:3).
           MOVE WS-XFER-ACCT-TO-BAL (7:3) TO WS-XFER-AMT-TMP (5:3).
           MOVE WS-XFER-ACCT-TO-BAL (11:2) TO WS-XFER-AMT-TMP (8:2).
           INSPECT WS-XFER-AMT-TMP REPLACING LEADING SPACES BY ZEROS.
           IF WS-XFER-ACCT-TO-BAL (13:1) IS EQUAL TO '-'
              MULTIPLY -1 BY WS-XFER-AMT-TMP-N
                GIVING WS-XFER-ACCT-TO-BAL-N
           ELSE
              MULTIPLY +1 BY WS-XFER-AMT-TMP-N
                GIVING WS-XFER-ACCT-TO-BAL-N
           END-IF.
           IF WS-XFER-ACCT-FROM-BAL-N IS LESS THAN ZERO
              MOVE 'Cannot transfer from a negative balance'
                TO WS-ERROR-MSG
              GO TO VALIDATE-DATA-ERROR
           END-IF.
           IF WS-XFER-AMT-NUM-N IS GREATER THAN WS-XFER-ACCT-FROM-BAL-N
              MOVE 'Insufficient funds in from account'
                TO WS-ERROR-MSG
              GO TO VALIDATE-DATA-ERROR
           END-IF.

           GO TO VALIDATE-DATA-EXIT.

       VALIDATE-DATA-ERROR.
           SET INPUT-ERROR TO TRUE.
       VALIDATE-DATA-EXIT.
           EXIT.

       VALIDATE-XFER.
           CONTINUE.
       VALIDATE-XFER-RIGHT-JUSTIFY.
           IF WS-XFER-AMT IS EQUAL TO SPACES OR
              WS-XFER-AMT IS EQUAL TO LOW-VALUES
              MOVE 'Please enter transfer amount'
                TO WS-ERROR-MSG
              GO TO VALIDATE-XFER-ERROR
           END-IF.
           IF WS-XFER-AMT (8:1) IS EQUAL TO SPACE OR
              WS-XFER-AMT (8:1) IS EQUAL TO LOW-VALUE
              MOVE WS-XFER-AMT (1:7) TO WS-XFER-AMT-TMP
              MOVE SPACES TO WS-XFER-AMT
              MOVE WS-XFER-AMT-TMP TO WS-XFER-AMT (2:7)
              GO TO VALIDATE-XFER-RIGHT-JUSTIFY
           END-IF.
           IF WS-XFER-AMT (6:1) IS NOT EQUAL TO '.'
              MOVE 'Period missing/misplaced in transfer amount'
                TO WS-ERROR-MSG
              GO TO VALIDATE-XFER-ERROR
           END-IF.
           MOVE SPACES TO WS-XFER-AMT-NUM.
           MOVE WS-XFER-AMT (1:5) TO WS-XFER-AMT-NUM (3:5).
           MOVE WS-XFER-AMT (7:2) TO WS-XFER-AMT-NUM (8:2).
           INSPECT WS-XFER-AMT-NUM REPLACING LEADING SPACES BY ZEROS.
           IF WS-XFER-AMT-NUM IS NOT NUMERIC
              MOVE 'Transfer amount is invalid (not numeric)'
                TO WS-ERROR-MSG
              GO TO VALIDATE-XFER-ERROR
           END-IF.
           IF WS-XFER-AMT-NUM IS EQUAL TO ZERO
              MOVE 'Please enter a non-zero transfer amount'
                TO WS-ERROR-MSG
              GO TO VALIDATE-XFER-ERROR
           END-IF.

           GO TO VALIDATE-XFER-EXIT.

       VALIDATE-XFER-ERROR.
           SET INPUT-ERROR TO TRUE.
       VALIDATE-XFER-EXIT.
           EXIT.

       POPULATE-SCREEN-DATA.
           MOVE SPACES TO CD03-DATA.
           MOVE BANK-USERID TO CD03I-CONTACT-ID.
      * Now go get the data
       COPY CBANKX03.
           MOVE CD03O-ACC1 TO BANK-SCR50-ACC1.
           MOVE CD03O-DSC1 TO BANK-SCR50-DSC1.
           IF CD03O-BAL1 IS EQUAL TO SPACES
              MOVE CD03O-BAL1 TO BANK-SCR50-BAL1
           ELSE
              MOVE CD03O-BAL1N TO WS-EDIT-BALANCE
              MOVE WS-EDIT-BALANCE TO BANK-SCR50-BAL1.

           MOVE CD03O-ACC2 TO BANK-SCR50-ACC2.
           MOVE CD03O-DSC2 TO BANK-SCR50-DSC2.
           IF CD03O-BAL2 IS EQUAL TO SPACES
              MOVE CD03O-BAL2 TO BANK-SCR50-BAL2
           ELSE
              MOVE CD03O-BAL2N TO WS-EDIT-BALANCE
              MOVE WS-EDIT-BALANCE TO BANK-SCR50-BAL2.
           MOVE CD03O-ACC3 TO BANK-SCR50-ACC3.
           MOVE CD03O-DSC3 TO BANK-SCR50-DSC3.
           IF CD03O-BAL3 IS EQUAL TO SPACES
              MOVE CD03O-BAL3 TO BANK-SCR50-BAL3
           ELSE
              MOVE CD03O-BAL3N TO WS-EDIT-BALANCE
              MOVE WS-EDIT-BALANCE TO BANK-SCR50-BAL3.
           MOVE CD03O-ACC4 TO BANK-SCR50-ACC4.
           MOVE CD03O-DSC4 TO BANK-SCR50-DSC4.
           IF CD03O-BAL4 IS EQUAL TO SPACES
              MOVE CD03O-BAL4 TO BANK-SCR50-BAL4
           ELSE
              MOVE CD03O-BAL4N TO WS-EDIT-BALANCE
              MOVE WS-EDIT-BALANCE TO BANK-SCR50-BAL4.
           MOVE CD03O-ACC5 TO BANK-SCR50-ACC5.
           MOVE CD03O-DSC5 TO BANK-SCR50-DSC5.
           IF CD03O-BAL5 IS EQUAL TO SPACES
              MOVE CD03O-BAL5 TO BANK-SCR50-BAL5
           ELSE
              MOVE CD03O-BAL5N TO WS-EDIT-BALANCE
              MOVE WS-EDIT-BALANCE TO BANK-SCR50-BAL5.
           MOVE CD03O-ACC6 TO BANK-SCR50-ACC6.
           MOVE CD03O-DSC6 TO BANK-SCR50-DSC6.
           IF CD03O-BAL6 IS EQUAL TO SPACES
              MOVE CD03O-BAL6 TO BANK-SCR50-BAL6
           ELSE
              MOVE CD03O-BAL6N TO WS-EDIT-BALANCE
              MOVE WS-EDIT-BALANCE TO BANK-SCR50-BAL6.

       POPULATE-SCREEN-DATA-EXIT.
           EXIT.

      * $ Version 5.99c sequenced on Wednesday 3 Mar 2011 at 1:00pm
