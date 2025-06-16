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
      * Program:     BBANKZZP.CBL                                     *
      * Layer:       Business logic                                   *
      * Function:    Create various problem / error conditions        *
      *****************************************************************

       IDENTIFICATION DIVISION.
       PROGRAM-ID.
           BBANKZZP.
       DATE-WRITTEN.
           September 2002.
       DATE-COMPILED.
           Today.

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-MISC-STORAGE.
         05  WS-PROGRAM-ID                         PIC X(8)
             VALUE 'BBANKZZP'.
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
           88  WS-SEL-OPTION-1                     VALUE '1'.
           88  WS-SEL-OPTION-2                     VALUE '2'.
           88  WS-SEL-OPTION-3                     VALUE '3'.
           88  WS-SEL-OPTION-4                     VALUE '4'.
           88  WS-SEL-OPTION-5                     VALUE '5'.
           88  WS-SEL-OPTION-6                     VALUE '6'.
           88  WS-SEL-OPTION-7                     VALUE '7'.
           88  WS-SEL-OPTION-8                     VALUE '8'.
         05  WS-SEL-MATRIX                         PIC X(8).

       01  WS-PROBLEM-DATA.
         05  WS-PROB-SUB                           PIC 9(8) COMP.
         05  WS-PROB-TABLE.
           10  WS-PROB-TABLE-ITEM                  PIC 9(3)
               OCCURS 10 TIMES.
         05  WS-PROB-MODULE                        PIC X(8).
         05  WS-FLD-A                              PIC X(9).
         05  WS-FLD-A-NUM REDEFINES WS-FLD-A       PIC 9(5).99-.
         05  WS-FLD-B                              PIC S9(5)V99.

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

       01  LK-PROB-LINKAGE                         PIC X(1).

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
              MOVE 'BBANKZZP' TO BANK-LAST-PROG
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
                 MOVE 'BBANKZZP' TO BANK-LAST-PROG
                 MOVE 'BBANKZZP' TO BANK-NEXT-PROG
                 MOVE 'MBANKZZ' TO BANK-LAST-MAPSET
                 MOVE 'HELP20A' TO BANK-LAST-MAP
                 MOVE 'MBANKZZ' TO BANK-NEXT-MAPSET
                 MOVE 'BANKZZA' TO BANK-NEXT-MAP
                 PERFORM POPULATE-OPTIONS THRU
                         POPULATE-OPTIONS-EXIT
                 GO TO COMMON-RETURN
              ELSE
                 MOVE 01 TO BANK-HELP-SCREEN
                 MOVE 'BBANKZZP' TO BANK-LAST-PROG
                 MOVE 'BBANKZZP' TO BANK-NEXT-PROG
                 MOVE 'MBANKZZ' TO BANK-LAST-MAPSET
                 MOVE 'BANKZZA' TO BANK-LAST-MAP
                 MOVE 'MBANKZZ' TO BANK-NEXT-MAPSET
                 MOVE 'HELP20A' TO BANK-NEXT-MAP
                 MOVE 'BANKZZ' TO HELP01I-SCRN
                 COPY CHELPX01.
                 MOVE HELP01O-DATA TO BANK-HELP-DATA
                 GO TO COMMON-RETURN
           END-IF.

      *****************************************************************
      * Check the AID to see if we have to return to previous screen  *
      *****************************************************************
           IF BANK-AID-PFK04
              MOVE 'BBANKZZP' TO BANK-LAST-PROG
              MOVE 'BBANK10P' TO BANK-NEXT-PROG
              MOVE 'MBANK10' TO BANK-NEXT-MAPSET
              MOVE 'BANK10A' TO BANK-NEXT-MAP
              SET BANK-AID-ENTER TO TRUE
              SET BANK-NO-CONV-IN-PROGRESS TO TRUE
              GO TO COMMON-RETURN
           END-IF.

      * Check if we have set the screen up before or is this 1st time
           IF BANK-LAST-MAPSET IS NOT EQUAL TO 'MBANKZZ'
              MOVE WS-RETURN-MSG TO BANK-ERROR-MSG
              MOVE 'BBANKZZP' TO BANK-LAST-PROG
              MOVE 'BBANKZZP' TO BANK-NEXT-PROG
              MOVE 'MBANKZZ' TO BANK-LAST-MAPSET
              MOVE 'BANKZZA' TO BANK-LAST-MAP
              MOVE 'MBANKZZ' TO BANK-NEXT-MAPSET
              MOVE 'BANKZZA' TO BANK-NEXT-MAP
              MOVE LOW-VALUES TO BANK-SCRZZ-SEL1IP
              MOVE LOW-VALUES TO BANK-SCRZZ-SEL2IP
              MOVE LOW-VALUES TO BANK-SCRZZ-SEL3IP
              MOVE LOW-VALUES TO BANK-SCRZZ-SEL4IP
              MOVE LOW-VALUES TO BANK-SCRZZ-SEL5IP
              MOVE LOW-VALUES TO BANK-SCRZZ-SEL6IP
              MOVE LOW-VALUES TO BANK-SCRZZ-SEL7IP
              MOVE LOW-VALUES TO BANK-SCRZZ-SEL8IP
              IF GUEST
                 MOVE 'LI      ' TO WS-SEL-MATRIX
              ELSE
                MOVE SPACES TO CD08-DATA
                MOVE BANK-USERID TO CD08I-CONTACT-ID
      * Now go get the data
                COPY CBANKX08.
                IF CD08O-COUNT IS EQUAL TO 0
                   IF PROBLEM-USER
                      MOVE '123     ' TO WS-SEL-MATRIX
                   ELSE
                      MOVE '12      ' TO WS-SEL-MATRIX
                   END-IF
                END-IF
                IF CD08O-COUNT IS EQUAL TO 1
                   IF PROBLEM-USER
                      MOVE '123456  ' TO WS-SEL-MATRIX
                   ELSE
                      MOVE '12345   ' TO WS-SEL-MATRIX
                   END-IF
                END-IF
                IF CD08O-COUNT IS GREATER THAN 1
                   IF PROBLEM-USER
                      MOVE '12345678' TO WS-SEL-MATRIX
                   ELSE
                      MOVE '1234567 ' TO WS-SEL-MATRIX
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
              MOVE 'BBANKZZP' TO BANK-LAST-PROG
              MOVE 'BBANKZZP' TO BANK-NEXT-PROG
              MOVE 'MBANKZZ' TO BANK-LAST-MAPSET
              MOVE 'BANKZZA' TO BANK-LAST-MAP
              MOVE 'MBANKZZ' TO BANK-NEXT-MAPSET
              MOVE 'BANKZZA' TO BANK-NEXT-MAP
              PERFORM POPULATE-OPTIONS THRU
                      POPULATE-OPTIONS-EXIT
              GO TO COMMON-RETURN
           END-IF.

           IF BANK-SCRZZ-SEL1IP IS NOT EQUAL TO LOW-VALUES
              MOVE BANK-SCRZZ-SEL1ID TO WS-SEL-OPTION
           END-IF.
           IF BANK-SCRZZ-SEL2IP IS NOT EQUAL TO LOW-VALUES
              MOVE BANK-SCRZZ-SEL2ID TO WS-SEL-OPTION
           END-IF.
           IF BANK-SCRZZ-SEL3IP IS NOT EQUAL TO LOW-VALUES
              MOVE BANK-SCRZZ-SEL3ID TO WS-SEL-OPTION
           END-IF.
           IF BANK-SCRZZ-SEL4IP IS NOT EQUAL TO LOW-VALUES
              MOVE BANK-SCRZZ-SEL4ID TO WS-SEL-OPTION
           END-IF.
           IF BANK-SCRZZ-SEL5IP IS NOT EQUAL TO LOW-VALUES
              MOVE BANK-SCRZZ-SEL5ID TO WS-SEL-OPTION
           END-IF.
           IF BANK-SCRZZ-SEL6IP IS NOT EQUAL TO LOW-VALUES
              MOVE BANK-SCRZZ-SEL6ID TO WS-SEL-OPTION
           END-IF.
           IF BANK-SCRZZ-SEL7IP IS NOT EQUAL TO LOW-VALUES
              MOVE BANK-SCRZZ-SEL7ID TO WS-SEL-OPTION
           END-IF.
           IF BANK-SCRZZ-SEL8IP IS NOT EQUAL TO LOW-VALUES
              MOVE BANK-SCRZZ-SEL8ID TO WS-SEL-OPTION
           END-IF.

           MOVE ALL '*' TO WS-PROBLEM-DATA.

           EVALUATE TRUE
              WHEN WS-SEL-OPTION IS EQUAL TO '1'
                PERFORM SCENARIO-1 THRU
                        SCENARIO-1-EXIT
              WHEN WS-SEL-OPTION IS EQUAL TO '2'
                PERFORM SCENARIO-2 THRU
                        SCENARIO-2-EXIT
              WHEN WS-SEL-OPTION IS EQUAL TO '3'
                PERFORM SCENARIO-3 THRU
                        SCENARIO-3-EXIT
              WHEN WS-SEL-OPTION IS EQUAL TO '4'
                PERFORM SCENARIO-4 THRU
                        SCENARIO-4-EXIT
              WHEN WS-SEL-OPTION IS EQUAL TO '5'
                PERFORM SCENARIO-5 THRU
                        SCENARIO-5-EXIT
              WHEN WS-SEL-OPTION IS EQUAL TO '6'
                PERFORM SCENARIO-6 THRU
                        SCENARIO-6-EXIT
              WHEN WS-SEL-OPTION IS EQUAL TO '7'
                PERFORM SCENARIO-7 THRU
                        SCENARIO-7-EXIT
              WHEN WS-SEL-OPTION IS EQUAL TO '8'
                PERFORM SCENARIO-8 THRU
                        SCENARIO-8-EXIT
              WHEN OTHER
                PERFORM SCENARIO-9 THRU
                        SCENARIO-9-EXIT
           END-EVALUATE.

           GO TO COMMON-RETURN.

       COMMON-RETURN.
           MOVE WS-BANK-DATA TO DFHCOMMAREA (1:LENGTH OF WS-BANK-DATA).
       COPY CRETURN.

       VALIDATE-DATA.
           SET INPUT-OK TO TRUE.
           MOVE ZERO TO WS-SEL-COUNT.

           IF BANK-SCRZZ-SEL1IP IS NOT EQUAL TO LOW-VALUES
              ADD 1 TO WS-SEL-COUNT
           END-IF.
           IF BANK-SCRZZ-SEL2IP IS NOT EQUAL TO LOW-VALUES
              ADD 1 TO WS-SEL-COUNT
           END-IF.
           IF BANK-SCRZZ-SEL3IP IS NOT EQUAL TO LOW-VALUES
              ADD 1 TO WS-SEL-COUNT
           END-IF.
           IF BANK-SCRZZ-SEL4IP IS NOT EQUAL TO LOW-VALUES
              ADD 1 TO WS-SEL-COUNT
           END-IF.
           IF BANK-SCRZZ-SEL5IP IS NOT EQUAL TO LOW-VALUES
              ADD 1 TO WS-SEL-COUNT
           END-IF.
           IF BANK-SCRZZ-SEL6IP IS NOT EQUAL TO LOW-VALUES
              ADD 1 TO WS-SEL-COUNT
           END-IF.
           IF BANK-SCRZZ-SEL7IP IS NOT EQUAL TO LOW-VALUES
              ADD 1 TO WS-SEL-COUNT
           END-IF.
           IF BANK-SCRZZ-SEL8IP IS NOT EQUAL TO LOW-VALUES
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
           DIVIDE LENGTH BANK-SCREENZZ-FIELD
             INTO LENGTH OF BANK-SCREENZZ-DATA-R
               GIVING WS-SUB1-LIMIT.
       POPULATE-OPTIONS-LOOP.
           ADD 1 TO WS-SUB1.
           IF WS-SUB1 IS GREATER THAN WS-SUB1-LIMIT
              GO TO POPULATE-OPTIONS-EXIT
           END-IF.
           IF WS-SEL-MATRIX IS NOT EQUAL TO SPACES
              MOVE WS-SEL-MATRIX (WS-SUB1:1) TO BANK-SCRZZ-ID (WS-SUB1)
           END-IF.
           MOVE SPACES TO BANK-SCRZZ-TX (WS-SUB1).
           IF BANK-SCRZZ-ID (WS-SUB1) IS EQUAL TO '1'
              MOVE 'Problem scenario 1'
                TO BANK-SCRZZ-TX (WS-SUB1)
           END-IF.
           IF BANK-SCRZZ-ID (WS-SUB1) IS EQUAL TO '2'
              MOVE 'Problem scenario 2'
                TO BANK-SCRZZ-TX (WS-SUB1)
           END-IF.
           IF BANK-SCRZZ-ID (WS-SUB1) IS EQUAL TO '3'
              MOVE 'Problem scenario 3'
                TO BANK-SCRZZ-TX (WS-SUB1)
           END-IF.
           IF BANK-SCRZZ-ID (WS-SUB1) IS EQUAL TO '4'
              MOVE 'Problem scenario 4'
                TO BANK-SCRZZ-TX (WS-SUB1)
           END-IF.
           IF BANK-SCRZZ-ID (WS-SUB1) IS EQUAL TO '5'
              MOVE 'Problem scenario 5'
                TO BANK-SCRZZ-TX (WS-SUB1)
           END-IF.
           IF BANK-SCRZZ-ID (WS-SUB1) IS EQUAL TO '6'
              MOVE 'Problem scenario 6'
                TO BANK-SCRZZ-TX (WS-SUB1)
           END-IF.
           IF BANK-SCRZZ-ID (WS-SUB1) IS EQUAL TO '7'
              MOVE 'Problem scenario 7'
                TO BANK-SCRZZ-TX (WS-SUB1)
           END-IF.
           IF BANK-SCRZZ-ID (WS-SUB1) IS EQUAL TO '8'
              MOVE 'Problem scenario 8'
                TO BANK-SCRZZ-TX (WS-SUB1)
           END-IF.
           GO TO POPULATE-OPTIONS-LOOP.
       POPULATE-OPTIONS-EXIT.
           EXIT.

      *****************************************************************
      * Problem scenario 1                                            *
      *****************************************************************
       SCENARIO-1.
           MOVE 99 TO WS-PROB-SUB
           MOVE WS-PROB-TABLE-ITEM(1)
             TO WS-PROB-TABLE-ITEM(WS-PROB-SUB).
       SCENARIO-1-EXIT.
           EXIT.

      *****************************************************************
      * Problem scenario 2                                            *
      *****************************************************************
       SCENARIO-2.
           ADD 1 TO WS-PROB-TABLE-ITEM(1).
       SCENARIO-2-EXIT.
           EXIT.

      *****************************************************************
      * Problem scenario 3                                            *
      *****************************************************************
       SCENARIO-3.
           CALL WS-PROB-MODULE.
       SCENARIO-3-EXIT.
           EXIT.

      *****************************************************************
      * Problem scenario 4                                            *
      *****************************************************************
       SCENARIO-4.
           MOVE 40960 TO WS-PROB-SUB.
           MOVE LOW-VALUES TO WS-PROBLEM-DATA(1:WS-PROB-SUB).
       SCENARIO-4-EXIT.
           EXIT.

      *****************************************************************
      * Problem scenario 5                                            *
      *****************************************************************
       SCENARIO-5.
           MOVE ALL '*' TO LK-PROB-LINKAGE.
       SCENARIO-5-EXIT.
           EXIT.

      *****************************************************************
      * Problem scenario 6                                            *
      *****************************************************************
       SCENARIO-6.
           GO TO NOWHERE.
       SCENARIO-6-EXIT.
           EXIT.

      *****************************************************************
      * Problem scenario 7                                            *
      *****************************************************************
       SCENARIO-7.
      *    PERFORM SCENARIO-7.
            CONTINUE.
       SCENARIO-7-EXIT.
           EXIT.

      *****************************************************************
      * Problem scenario 8                                            *
      *****************************************************************
       SCENARIO-8.
      *    call 'CBL_DEBUGBREAK'.
           MOVE '  123.45 ' TO WS-FLD-A.
           MOVE 99999.99 TO WS-FLD-B.
           MOVE WS-FLD-A-NUM TO WS-FLD-B .
       SCENARIO-8-EXIT.
           EXIT.

      *****************************************************************
      * Problem scenario 9                                            *
      *****************************************************************
       SCENARIO-9.
            CONTINUE.
       SCENARIO-9-EXIT.
           EXIT.

       NOWHERE.

      * $ Version 5.99c sequenced on Wednesday 3 Mar 2011 at 1:00pm
