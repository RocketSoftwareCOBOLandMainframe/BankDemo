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
      * Program:     BBANK20P.CBL                                     *
      * Layer:       Business logic                                   *
      * Function:    Determine users options                          *
      *****************************************************************

       IDENTIFICATION DIVISION.
       PROGRAM-ID.
           BBANK20P.
       DATE-WRITTEN.
           September 2002.
       DATE-COMPILED.
           Today.

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-MISC-STORAGE.
         05  WS-PROGRAM-ID                         PIC X(8)
             VALUE 'BBANK20P'.
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
         05  WS-SUB1-LIMIT                         PIC S9(4) COMP.
         05  WS-SEL-COUNT                          PIC 9(1).
         05  WS-SEL-OPTION                         PIC X(1).
           88  WS-SEL-OPTION-NULL                  VALUES ' ', '.'.
           88  WS-SEL-OPTION-DISPLAY               VALUE 'D'.
           88  WS-SEL-OPTION-TRANSFER              VALUE 'X'.
           88  WS-SEL-OPTION-UPDATE                VALUE 'U'.
           88  WS-SEL-OPTION-LOAN                  VALUE 'L'.
           88  WS-SEL-OPTION-PRINT                 VALUE 'P'.
           88  WS-SEL-OPTION-INFO                  VALUE 'I'.
           88  WS-SEL-OPTION-ERRORS                VALUE 'Z'.
         05  WS-SEL-MATRIX                         PIC X(7).

       01  WS-BANK-DATA.
       COPY CBANKDAT.

       01  WS-HELP-DATA.
       COPY CHELPD01.

       01  WS-ACCOUNT-DATA.
       COPY CBANKD08.

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
      * Initialize the list of options available                      *
      *****************************************************************
           MOVE SPACES TO WS-SEL-MATRIX.

      *****************************************************************
      * Save the passed return message and then turn it off           *
      *****************************************************************
           MOVE BANK-RETURN-MSG TO WS-RETURN-MSG.
           SET BANK-RETURN-MSG-OFF TO TRUE.

           MOVE WS-RETURN-MSG TO WS-ERROR-MSG.

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
              MOVE 'BBANK20P' TO BANK-LAST-PROG
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
                 MOVE 'BBANK20P' TO BANK-LAST-PROG
                 MOVE 'BBANK20P' TO BANK-NEXT-PROG
                 MOVE 'MBANK20' TO BANK-LAST-MAPSET
                 MOVE 'HELP20A' TO BANK-LAST-MAP
                 MOVE 'MBANK20' TO BANK-NEXT-MAPSET
                 MOVE 'BANK20A' TO BANK-NEXT-MAP
                 PERFORM POPULATE-OPTIONS THRU
                         POPULATE-OPTIONS-EXIT
                 GO TO COMMON-RETURN
              ELSE
                 MOVE 01 TO BANK-HELP-SCREEN
                 MOVE 'BBANK20P' TO BANK-LAST-PROG
                 MOVE 'BBANK20P' TO BANK-NEXT-PROG
                 MOVE 'MBANK20' TO BANK-LAST-MAPSET
                 MOVE 'BANK20A' TO BANK-LAST-MAP
                 MOVE 'MBANK20' TO BANK-NEXT-MAPSET
                 MOVE 'HELP20A' TO BANK-NEXT-MAP
                 MOVE 'BANK20' TO HELP01I-SCRN
                 COPY CHELPX01.
                 MOVE HELP01O-DATA TO BANK-HELP-DATA
                 GO TO COMMON-RETURN
           END-IF.

      *****************************************************************
      * Check the AID to see if we have to return to previous screen  *
      *****************************************************************
           IF BANK-AID-PFK04
              MOVE 'BBANK20P' TO BANK-LAST-PROG
              MOVE 'BBANK10P' TO BANK-NEXT-PROG
              MOVE 'MBANK10' TO BANK-NEXT-MAPSET
              MOVE 'BANK10A' TO BANK-NEXT-MAP
              SET BANK-AID-ENTER TO TRUE
              SET BANK-NO-CONV-IN-PROGRESS TO TRUE
              GO TO COMMON-RETURN
           END-IF.

      * Check if we have set the screen up before or is this 1st time
           IF BANK-LAST-MAPSET IS NOT EQUAL TO 'MBANK20'
              MOVE WS-RETURN-MSG TO BANK-ERROR-MSG
              MOVE 'BBANK20P' TO BANK-LAST-PROG
              MOVE 'BBANK20P' TO BANK-NEXT-PROG
              MOVE 'MBANK20' TO BANK-LAST-MAPSET
              MOVE 'BANK20A' TO BANK-LAST-MAP
              MOVE 'MBANK20' TO BANK-NEXT-MAPSET
              MOVE 'BANK20A' TO BANK-NEXT-MAP
              MOVE LOW-VALUES TO BANK-SCR20-SEL1IP
              MOVE LOW-VALUES TO BANK-SCR20-SEL2IP
              MOVE LOW-VALUES TO BANK-SCR20-SEL3IP
              MOVE LOW-VALUES TO BANK-SCR20-SEL4IP
              MOVE LOW-VALUES TO BANK-SCR20-SEL5IP
              MOVE LOW-VALUES TO BANK-SCR20-SEL6IP
              MOVE LOW-VALUES TO BANK-SCR20-SEL7IP
              IF GUEST
                 MOVE 'LI     ' TO WS-SEL-MATRIX
              ELSE
                MOVE SPACES TO CD08-DATA
                MOVE BANK-USERID TO CD08I-CONTACT-ID
      * Now go get the data
                COPY CBANKX08.
                IF CD08O-COUNT IS EQUAL TO 0
                   IF PROBLEM-USER
                      MOVE 'LIZ    ' TO WS-SEL-MATRIX
                   ELSE
                      MOVE 'LI     ' TO WS-SEL-MATRIX
                   END-IF
                END-IF
                IF CD08O-COUNT IS EQUAL TO 1
                   IF PROBLEM-USER
                      MOVE 'DULPIZ ' TO WS-SEL-MATRIX
                   ELSE
                      MOVE 'DULPI  ' TO WS-SEL-MATRIX
                   END-IF
                END-IF
                IF CD08O-COUNT IS GREATER THAN 1
                   IF PROBLEM-USER
                      MOVE 'DXULPIZ' TO WS-SEL-MATRIX
                   ELSE
                      MOVE 'DXULPI ' TO WS-SEL-MATRIX
                   END-IF
                END-IF
              END-IF
              PERFORM POPULATE-OPTIONS THRU
                      POPULATE-OPTIONS-EXIT
              GO TO COMMON-RETURN
           END-IF.

           PERFORM VALIDATE-DATA THRU
                   VALIDATE-DATA-EXIT.

      * If we had an error display error and return
           IF INPUT-ERROR
              MOVE WS-ERROR-MSG TO BANK-ERROR-MSG
              MOVE 'BBANK20P' TO BANK-LAST-PROG
              MOVE 'BBANK20P' TO BANK-NEXT-PROG
              MOVE 'MBANK20' TO BANK-LAST-MAPSET
              MOVE 'BANK20A' TO BANK-LAST-MAP
              MOVE 'MBANK20' TO BANK-NEXT-MAPSET
              MOVE 'BANK20A' TO BANK-NEXT-MAP
              PERFORM POPULATE-OPTIONS THRU
                      POPULATE-OPTIONS-EXIT
              GO TO COMMON-RETURN
           END-IF.

           IF BANK-SCR20-SEL1IP IS NOT EQUAL TO LOW-VALUES
              MOVE BANK-SCR20-SEL1ID TO WS-SEL-OPTION
           END-IF.
           IF BANK-SCR20-SEL2IP IS NOT EQUAL TO LOW-VALUES
              MOVE BANK-SCR20-SEL2ID TO WS-SEL-OPTION
           END-IF.
           IF BANK-SCR20-SEL3IP IS NOT EQUAL TO LOW-VALUES
              MOVE BANK-SCR20-SEL3ID TO WS-SEL-OPTION
           END-IF.
           IF BANK-SCR20-SEL4IP IS NOT EQUAL TO LOW-VALUES
              MOVE BANK-SCR20-SEL4ID TO WS-SEL-OPTION
           END-IF.
           IF BANK-SCR20-SEL5IP IS NOT EQUAL TO LOW-VALUES
              MOVE BANK-SCR20-SEL5ID TO WS-SEL-OPTION
           END-IF.
           IF BANK-SCR20-SEL6IP IS NOT EQUAL TO LOW-VALUES
              MOVE BANK-SCR20-SEL6ID TO WS-SEL-OPTION
           END-IF.
           IF BANK-SCR20-SEL7IP IS NOT EQUAL TO LOW-VALUES
              MOVE BANK-SCR20-SEL7ID TO WS-SEL-OPTION
           END-IF.

           IF WS-SEL-OPTION IS EQUAL TO 'D'
              MOVE 'BBANK30P' TO BANK-NEXT-PROG
              GO TO COMMON-RETURN
           END-IF.

           IF WS-SEL-OPTION IS EQUAL TO 'X'
              MOVE 'BBANK50P' TO BANK-NEXT-PROG
              GO TO COMMON-RETURN
           END-IF.

           IF WS-SEL-OPTION IS EQUAL TO 'U'
              MOVE 'BBANK60P' TO BANK-NEXT-PROG
              MOVE SPACES TO BANK-SCREEN60-DATA
              MOVE BANK-USERID TO BANK-SCR60-CONTACT-ID
              MOVE BANK-USERID-NAME TO BANK-SCR60-CONTACT-NAME
              SET ADDR-CHANGE-REQUEST TO TRUE
              GO TO COMMON-RETURN
           END-IF.

           IF WS-SEL-OPTION IS EQUAL TO 'L'
              MOVE 'BBANK70P' TO BANK-NEXT-PROG
              GO TO COMMON-RETURN
           END-IF.

           IF WS-SEL-OPTION IS EQUAL TO 'P'
              MOVE 'BBANK80P' TO BANK-NEXT-PROG
              GO TO COMMON-RETURN
           END-IF.

           IF WS-SEL-OPTION IS EQUAL TO 'I'
              MOVE 'BBANK90P' TO BANK-NEXT-PROG
              GO TO COMMON-RETURN
           END-IF.

           IF WS-SEL-OPTION IS EQUAL TO 'Z'
              MOVE 'BBANKZZP' TO BANK-NEXT-PROG
              GO TO COMMON-RETURN
           END-IF.

      *****************************************************************
      * If we get this far then we have an error in our logic as we   *
      * don't know where to go next.                                  *
      *****************************************************************
           IF BANK-ENV-CICS
              MOVE WS-PROGRAM-ID TO ABEND-CULPRIT
              MOVE '0001' TO ABEND-CODE
              MOVE SPACES TO ABEND-REASON
              COPY CABENDPO.
           END-IF.
           GOBACK.

       COMMON-RETURN.
           MOVE WS-BANK-DATA TO DFHCOMMAREA (1:LENGTH OF WS-BANK-DATA).
       COPY CRETURN.

       VALIDATE-DATA.
           SET INPUT-OK TO TRUE.
           MOVE ZERO TO WS-SEL-COUNT.

           IF BANK-SCR20-SEL1IP IS NOT EQUAL TO LOW-VALUES
              ADD 1 TO WS-SEL-COUNT
           END-IF.
           IF BANK-SCR20-SEL2IP IS NOT EQUAL TO LOW-VALUES
              ADD 1 TO WS-SEL-COUNT
           END-IF.
           IF BANK-SCR20-SEL3IP IS NOT EQUAL TO LOW-VALUES
              ADD 1 TO WS-SEL-COUNT
           END-IF.
           IF BANK-SCR20-SEL4IP IS NOT EQUAL TO LOW-VALUES
              ADD 1 TO WS-SEL-COUNT
           END-IF.
           IF BANK-SCR20-SEL5IP IS NOT EQUAL TO LOW-VALUES
              ADD 1 TO WS-SEL-COUNT
           END-IF.
           IF BANK-SCR20-SEL6IP IS NOT EQUAL TO LOW-VALUES
              ADD 1 TO WS-SEL-COUNT
           END-IF.
           IF BANK-SCR20-SEL7IP IS NOT EQUAL TO LOW-VALUES
              ADD 1 TO WS-SEL-COUNT
           END-IF.


           IF WS-SEL-COUNT IS EQUAL TO ZERO
              MOVE 'Please select an option' TO WS-ERROR-MSG
              GO TO VALIDATE-DATA-ERROR
           END-IF.

           IF WS-SEL-COUNT IS GREATER THAN 1
              MOVE 'Please select a single option' TO WS-ERROR-MSG
              GO TO VALIDATE-DATA-ERROR
           END-IF.

           GO TO VALIDATE-DATA-EXIT.
       VALIDATE-DATA-ERROR.
           SET INPUT-ERROR TO TRUE.
       VALIDATE-DATA-EXIT.
           EXIT.

       POPULATE-OPTIONS.
           MOVE 0 TO WS-SUB1.
           DIVIDE LENGTH BANK-SCREEN20-FIELD
             INTO LENGTH OF BANK-SCREEN20-DATA-R
               GIVING WS-SUB1-LIMIT.
       POPULATE-OPTIONS-LOOP.
           ADD 1 TO WS-SUB1.
           IF WS-SUB1 IS GREATER THAN WS-SUB1-LIMIT
              GO TO POPULATE-OPTIONS-EXIT
           END-IF.
           IF WS-SEL-MATRIX IS NOT EQUAL TO SPACES
              MOVE WS-SEL-MATRIX (WS-SUB1:1) TO BANK-SCR20-ID (WS-SUB1)
           END-IF.
           MOVE SPACES TO BANK-SCR20-TX (WS-SUB1).
           IF BANK-SCR20-ID (WS-SUB1) IS EQUAL TO 'D'
              MOVE 'Display your account balances'
                TO BANK-SCR20-TX (WS-SUB1)
           END-IF.
           IF BANK-SCR20-ID (WS-SUB1) IS EQUAL TO 'X'
              MOVE 'Transfer funds between accounts'
                TO BANK-SCR20-TX (WS-SUB1)
           END-IF.
           IF BANK-SCR20-ID (WS-SUB1) IS EQUAL TO 'U'
              MOVE 'Update your contact information'
                TO BANK-SCR20-TX (WS-SUB1)
           END-IF.
           IF BANK-SCR20-ID (WS-SUB1) IS EQUAL TO 'L'
              MOVE 'Calculate the cost of a loan'
                TO BANK-SCR20-TX (WS-SUB1)
           END-IF.
           IF BANK-SCR20-ID (WS-SUB1) IS EQUAL TO 'P'
              MOVE 'Request printed statement(s)'
                TO BANK-SCR20-TX (WS-SUB1)
           END-IF.
           IF BANK-SCR20-ID (WS-SUB1) IS EQUAL TO 'I'
              MOVE 'Obtain more information'
                TO BANK-SCR20-TX (WS-SUB1)
           END-IF.
           IF BANK-SCR20-ID (WS-SUB1) IS EQUAL TO 'Z'
              MOVE 'Generate problems / errors'
                TO BANK-SCR20-TX (WS-SUB1)
           END-IF.
           GO TO POPULATE-OPTIONS-LOOP.
       POPULATE-OPTIONS-EXIT.
           EXIT.

      * $ Version 5.99c sequenced on Wednesday 3 Mar 2011 at 1:00pm
