      *****************************************************************
      *                                                               *
      * Copyright 2010-2021 Rocket Software, Inc. or its affiliates.  *
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
      * Program:     BBANK10P.CBL                                     *
      * Layer:       Business logic                                   *
      * Function:    Signon to system to identify user                *
      *****************************************************************

       IDENTIFICATION DIVISION.
       PROGRAM-ID.
           BBANK10P.
       DATE-WRITTEN.
           September 2002.
       DATE-COMPILED.
           Today.

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-MISC-STORAGE.
         05  WS-PROGRAM-ID                         PIC X(8)
             VALUE 'BBANK10P'.
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

       01  WS-BANK-DATA.
       COPY CBANKDAT.

       01  WS-HELP-DATA.
       COPY CHELPD01.

       01  WS-PERSON.
       COPY CBANKD01.

       01  WS-SECURITY.
       COPY CPSWDD01.

       COPY CABENDD.

       LINKAGE SECTION.
       01  DFHCOMMAREA.
         05  LK-COMMAREA                           PIC X(6144).

      *COPY CENTRY.
       PROCEDURE DIVISION.

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
      * If this is the first time in, then we have to do set up the   *
      * COMMAREA and ask for the first map to be displayed.           *
      *****************************************************************
           IF BANK-NO-CONV-IN-PROGRESS
              SET BANK-CONV-IN-PROGRESS TO TRUE
              MOVE 'BBANK10P' TO BANK-LAST-PROG
              MOVE 'BBANK10P' TO BANK-NEXT-PROG
              MOVE LOW-VALUES TO BANK-SIGNON-ID
              MOVE LOW-VALUES TO BANK-USERID
              MOVE LOW-VALUES TO BANK-PSWD
              MOVE SPACES TO BANK-LAST-MAPSET
              MOVE SPACES TO BANK-LAST-MAP
              MOVE 'MBANK10' TO BANK-NEXT-MAPSET
              MOVE 'BANK10A' TO BANK-NEXT-MAP
              GO TO COMMON-RETURN
           END-IF.

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
              BANK-AID-PFK03
              SET PFK-VALID TO TRUE
           END-IF.
           IF BANK-AID-PFK01 AND
              BANK-HELP-INACTIVE
              SET BANK-HELP-ACTIVE TO TRUE
              SET PFK-VALID TO TRUE
           END-IF.
           IF BANK-AID-PFK04 AND
              BANK-HELP-ACTIVE
              SET PFK-VALID TO TRUE
           END-IF.
           IF PFK-INVALID
              SET BANK-AID-ENTER TO TRUE
           END-IF.

      *****************************************************************
      * Check the AID to see if we have to quit                       *
      *****************************************************************
           IF BANK-AID-PFK03
              MOVE 'BBANK10P' TO BANK-LAST-PROG
              MOVE 'BBANK99P' TO BANK-NEXT-PROG
              MOVE 'MBANK10' TO BANK-LAST-MAPSET
              MOVE 'BANK10A' TO BANK-LAST-MAP
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
                 MOVE 'BBANK10P' TO BANK-LAST-PROG
                 MOVE 'BBANK10P' TO BANK-NEXT-PROG
                 MOVE 'MBANK10' TO BANK-LAST-MAPSET
                 MOVE 'HELP10A' TO BANK-LAST-MAP
                 MOVE 'MBANK10' TO BANK-NEXT-MAPSET
                 MOVE 'BANK10A' TO BANK-NEXT-MAP
                 GO TO COMMON-RETURN
              ELSE
                 MOVE 01 TO BANK-HELP-SCREEN
                 MOVE 'BBANK10P' TO BANK-LAST-PROG
                 MOVE 'BBANK10P' TO BANK-NEXT-PROG
                 MOVE 'MBANK10' TO BANK-LAST-MAPSET
                 MOVE 'BANK10A' TO BANK-LAST-MAP
                 MOVE 'MBANK10' TO BANK-NEXT-MAPSET
                 MOVE 'HELP10A' TO BANK-NEXT-MAP
                 MOVE 'BANK10' TO HELP01I-SCRN
      *          COPY CHELPX01.
                 EXEC CICS LINK PROGRAM('DHELP01P')
                          COMMAREA(HELP01-DATA)
                          LENGTH(LENGTH OF HELP01-DATA)
                 END-EXEC

                 MOVE HELP01O-DATA TO BANK-HELP-DATA
                 GO TO COMMON-RETURN
           END-IF.

           PERFORM VALIDATE-USER THRU
                   VALIDATE-USER-EXIT.

      * If we had an error display error and return
           IF INPUT-ERROR
              MOVE WS-ERROR-MSG TO BANK-ERROR-MSG
              MOVE 'SBANK10P' TO BANK-LAST-PROG
              MOVE 'SBANK10P' TO BANK-NEXT-PROG
              MOVE 'MBANK10' TO BANK-LAST-MAPSET
              MOVE 'BANK10A' TO BANK-LAST-MAP
              MOVE 'MBANK10' TO BANK-NEXT-MAPSET
              MOVE 'BANK10A' TO BANK-NEXT-MAP
              GO TO COMMON-RETURN
           END-IF.

           MOVE 'BBANK20P' TO BANK-NEXT-PROG.
           GO TO COMMON-RETURN.

       COMMON-RETURN.
           MOVE WS-BANK-DATA TO DFHCOMMAREA (1:LENGTH OF WS-BANK-DATA).
      *COPY CRETURN.
           EXEC CICS RETURN
           END-EXEC.
           GOBACK.


       VALIDATE-USER.
           SET INPUT-OK TO TRUE.
           INSPECT BANK-SIGNON-ID
             CONVERTING 'abcdefghijklmnopqrstuvwxyz'
                     TO 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.
           IF BANK-SIGNON-ID IS EQUAL TO 'GUEST'
              MOVE 'GUEST' TO BANK-USERID
              MOVE 'Guest' TO BANK-USERID-NAME
              GO TO VALIDATE-USER-EXIT
           END-IF.
           IF BANK-SIGNON-ID IS EQUAL TO LOW-VALUES
              MOVE 'Please input user id' TO WS-ERROR-MSG
              GO TO VALIDATE-USER-ERROR
           END-IF.
           IF BANK-PSWD IS EQUAL TO LOW-VALUES
              MOVE 'Please input password' TO WS-ERROR-MSG
              GO TO VALIDATE-USER-ERROR
           END-IF.
      * We now make sure the user is valid.......
           MOVE SPACES TO CPSWDD01-DATA.
           MOVE BANK-SIGNON-ID TO CPSWDD01I-USERID.
           MOVE BANK-PSWD TO CPSWDD01I-PASSWORD
      * If user starts with "Z" then treat as "B"
           IF CPSWDD01I-USERID(1:1) IS EQUAL TO 'Z'
              MOVE 'B' TO  CPSWDD01I-USERID(1:1)
           END-IF.

           SET PSWD-SIGNON TO TRUE

      *COPY CPSWDX01.
           EXEC CICS LINK PROGRAM('SPSWD01P')
                          COMMAREA(CPSWDD01-DATA)
                          LENGTH(LENGTH OF CPSWDD01-DATA)
           END-EXEC

           IF CPSWDD01O-MESSAGE IS NOT EQUAL TO SPACES
              MOVE CPSWDD01O-MESSAGE TO WS-ERROR-MSG
              GO TO VALIDATE-USER-ERROR
           END-IF.
      * We now make sure the user is actually a customer......
           MOVE SPACES TO CD01-DATA.
           MOVE BANK-SIGNON-ID TO CD01I-PERSON-PID.
      * If user starts with "Z" then treat as "B"
           IF CD01I-PERSON-PID(1:1) IS EQUAL TO 'Z'
              MOVE 'B' TO  CD01I-PERSON-PID(1:1)
           END-IF.
      *COPY CBANKX01.
           EXEC CICS LINK PROGRAM('DBANK01P')
                          COMMAREA(CD01-DATA)
                          LENGTH(LENGTH OF CD01-DATA)
           END-EXEC.

           IF CD01O-PERSON-PID IS EQUAL TO SPACES
              MOVE CD01O-PERSON-NAME TO WS-ERROR-MSG
              GO TO VALIDATE-USER-ERROR
           ELSE
              MOVE CD01O-PERSON-NAME TO BANK-USERID-NAME
              MOVE BANK-SIGNON-ID TO BANK-USERID
              IF BANK-USERID(1:1) IS EQUAL TO 'Z'
                 MOVE 'B' TO  BANK-USERID(1:1)
              END-IF
              GO TO VALIDATE-USER-EXIT
           END-IF.
       VALIDATE-USER-ERROR.
           SET INPUT-ERROR TO TRUE.
       VALIDATE-USER-EXIT.
           EXIT.

      * $ Version 5.99c sequenced on Wednesday 3 Mar 2011 at 1:00pm
