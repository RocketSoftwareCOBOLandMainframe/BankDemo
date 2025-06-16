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
      * Program:     BBANK80P.CBL                                     *
      * Layer:       Business logic                                   *
      * Function:    Print statements                                 *
      *****************************************************************

       IDENTIFICATION DIVISION.
       PROGRAM-ID.
           BBANK80P.
       DATE-WRITTEN.
           September 2002.
       DATE-COMPILED.
           Today.

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-MISC-STORAGE.
         05  WS-PROGRAM-ID                         PIC X(8)
             VALUE 'BBANK80P'.
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

       01  WS-ADDR-DATA.
       COPY CBANKD09.

       01  WS-STMT-REQUEST-DATA.
       COPY CSTMTD01.

       COPY CSTATESD.

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
              BANK-AID-PFK10
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
              MOVE 'BBANK80P' TO BANK-LAST-PROG
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
                 MOVE 'BBANK80P' TO BANK-LAST-PROG
                 MOVE 'BBANK80P' TO BANK-NEXT-PROG
                 MOVE 'MBANK80' TO BANK-LAST-MAPSET
                 MOVE 'HELP80A' TO BANK-LAST-MAP
                 MOVE 'MBANK80' TO BANK-NEXT-MAPSET
                 MOVE 'BANK80A' TO BANK-NEXT-MAP
                 GO TO COMMON-RETURN
              ELSE
                 MOVE 01 TO BANK-HELP-SCREEN
                 MOVE 'BBANK80P' TO BANK-LAST-PROG
                 MOVE 'BBANK80P' TO BANK-NEXT-PROG
                 MOVE 'MBANK80' TO BANK-LAST-MAPSET
                 MOVE 'BANK80A' TO BANK-LAST-MAP
                 MOVE 'MBANK80' TO BANK-NEXT-MAPSET
                 MOVE 'HELP80A' TO BANK-NEXT-MAP
                 MOVE 'BANK80' TO HELP01I-SCRN
                 COPY CHELPX01.
                 MOVE HELP01O-DATA TO BANK-HELP-DATA
                 GO TO COMMON-RETURN
           END-IF.

      *****************************************************************
      * Check the AID to see if we have to return to previous screen  *
      *****************************************************************
           IF BANK-AID-PFK04
              MOVE 'BBANK80P' TO BANK-LAST-PROG
              MOVE 'BBANK20P' TO BANK-NEXT-PROG
              MOVE 'MBANK20' TO BANK-NEXT-MAPSET
              MOVE 'BANK20A' TO BANK-NEXT-MAP
              SET BANK-AID-ENTER TO TRUE
              GO TO COMMON-RETURN
           END-IF.

      * Check if we have set the screen up before or is this 1st time
           IF BANK-LAST-MAPSET IS NOT EQUAL TO 'MBANK80'
              MOVE WS-RETURN-MSG TO BANK-ERROR-MSG
              MOVE 'BBANK80P' TO BANK-LAST-PROG
              MOVE 'BBANK80P' TO BANK-NEXT-PROG
              MOVE 'MBANK80' TO BANK-LAST-MAPSET
              MOVE 'BANK80A' TO BANK-LAST-MAP
              MOVE 'MBANK80' TO BANK-NEXT-MAPSET
              MOVE 'BANK80A' TO BANK-NEXT-MAP
              PERFORM POPULATE-SCREEN-DATA THRU
                      POPULATE-SCREEN-DATA-EXIT
              IF BANK-SCR80-EMAIL IS EQUAL TO SPACES
                 MOVE 'Please use F10 to confirm request.'
                   TO WS-ERROR-MSG
                 SET PRINT-CONFIRM TO TRUE
                 MOVE WS-ERROR-MSG TO BANK-ERROR-MSG
              ELSE
                 SET PRINT-REQUEST TO TRUE
              END-IF
              GO TO COMMON-RETURN
           END-IF.

      *****************************************************************
      * Check  the data                                                *
      *****************************************************************
           PERFORM VALIDATE-DATA THRU
                   VALIDATE-DATA-EXIT.
           IF INPUT-ERROR
              MOVE WS-ERROR-MSG TO BANK-ERROR-MSG
              MOVE 'BBANK80P' TO BANK-LAST-PROG
              MOVE 'BBANK80P' TO BANK-NEXT-PROG
              MOVE 'MBANK80' TO BANK-LAST-MAPSET
              MOVE 'BANK80A' TO BANK-LAST-MAP
              MOVE 'MBANK80' TO BANK-NEXT-MAPSET
              MOVE 'BANK80A' TO BANK-NEXT-MAP
              GO TO COMMON-RETURN
           END-IF

      * We want to verify the request
           IF PRINT-REQUEST
              MOVE 'Please use F10 to confirm request' TO WS-ERROR-MSG
              SET PRINT-CONFIRM TO TRUE
              MOVE WS-ERROR-MSG TO BANK-ERROR-MSG
              MOVE 'BBANK80P' TO BANK-LAST-PROG
              MOVE 'BBANK80P' TO BANK-NEXT-PROG
              MOVE 'MBANK80' TO BANK-LAST-MAPSET
              MOVE 'BANK80A' TO BANK-LAST-MAP
              MOVE 'MBANK80' TO BANK-NEXT-MAPSET
              MOVE 'BANK80A' TO BANK-NEXT-MAP
              GO TO COMMON-RETURN
           END-IF.
      * Data was changed and verified
           IF PRINT-CONFIRM AND
              BANK-AID-PFK10
              MOVE SPACES TO CSTMTD01-DATA
              MOVE BANK-SCR80-CONTACT-ID TO CSTMTD01I-CONTACT-ID
              IF BANK-SCR80-EMAIL IS EQUAL TO SPACES
                 SET CSTMTD01I-POST TO TRUE
              END-IF
              IF BANK-SCR80-OPT1 IS NOT EQUAL TO LOW-VALUES
                 SET CSTMTD01I-POST TO TRUE
              END-IF
              IF BANK-SCR80-OPT2 IS NOT EQUAL TO LOW-VALUES
                 SET CSTMTD01I-EMAIL TO TRUE
              END-IF
      * all the routine that will invoke the print process
       COPY CSTMTX01.
              IF CSTMTD01I-POST
                 STRING 'Statement print has been requested'
                           DELIMITED BY SIZE
                        ' and will be sent to your postal address'
                          DELIMITED BY SIZE
                   INTO BANK-RETURN-MSG
              ELSE
                 STRING 'Statement print has been requested'
                           DELIMITED BY SIZE
                        ' and will be sent to your E-Mail address'
                          DELIMITED BY SIZE
                   INTO BANK-RETURN-MSG
              END-IF
              MOVE SPACES TO BANK-SCREEN80-DATA
              MOVE 'BBANK80P' TO BANK-LAST-PROG
              MOVE 'BBANK20P' TO BANK-NEXT-PROG
              MOVE 'MBANK20' TO BANK-NEXT-MAPSET
              MOVE 'BANK20A' TO BANK-NEXT-MAP
              SET BANK-AID-ENTER TO TRUE
              GO TO COMMON-RETURN
           END-IF.

      * Turn off update flags and redisplay
           SET PRINT-REQUEST TO TRUE.
           MOVE 'BBANK80P' TO BANK-LAST-PROG
           MOVE 'BBANK80P' TO BANK-NEXT-PROG
           MOVE 'MBANK80' TO BANK-LAST-MAPSET
           MOVE 'BANK80A' TO BANK-LAST-MAP
           MOVE 'MBANK80' TO BANK-NEXT-MAPSET
           MOVE 'BANK80A' TO BANK-NEXT-MAP
           GO TO COMMON-RETURN.

       COMMON-RETURN.
           MOVE WS-BANK-DATA TO DFHCOMMAREA (1:LENGTH OF WS-BANK-DATA).
       COPY CRETURN.

       VALIDATE-DATA.
           SET INPUT-OK TO TRUE.
           IF BANK-SCR80-EMAIL IS NOT EQUAL TO SPACES
              IF BANK-SCR80-OPT1 IS EQUAL TO LOW-VALUES AND
                 BANK-SCR80-OPT2 IS EQUAL TO LOW-VALUES
                 MOVE 'Must select an option' TO WS-ERROR-MSG
                 GO TO VALIDATE-DATA-ERROR
              END-IF
              IF BANK-SCR80-OPT1 IS NOT EQUAL TO LOW-VALUES AND
                 BANK-SCR80-OPT2 IS NOT EQUAL TO LOW-VALUES
                 MOVE 'Select only one of mail or e-mail'
                   TO WS-ERROR-MSG
                 GO TO VALIDATE-DATA-ERROR
              END-IF
           END-IF.
      * Disallow email as we cant really send it
      *    IF BANK-SCR80-OPT2 IS NOT EQUAL TO LOW-VALUES
      *       MOVE SPACES TO WS-ERROR-MSG
      *       STRING 'Could not validate email address. '
      *                DELIMITED BY SIZE
      *              'Please select "mail" or Return'
      *                DELIMITED BY SIZE
      *         INTO WS-ERROR-MSG
      *       MOVE HIGH-VALUES TO BANK-SCR80-OPT2
      *       GO TO VALIDATE-DATA-ERROR
      *    END-IF.

           GO TO VALIDATE-DATA-EXIT.

       VALIDATE-DATA-ERROR.
           SET INPUT-ERROR TO TRUE.
       VALIDATE-DATA-EXIT.
           EXIT.

       POPULATE-SCREEN-DATA.
           MOVE SPACES TO CD09-DATA.
           MOVE BANK-USERID TO BANK-SCR80-CONTACT-ID.
           MOVE BANK-SCR80-CONTACT-ID TO CD09I-CONTACT-ID.
      * Now go get the data
       COPY CBANKX09.
           MOVE SPACES TO BANK-SCR80-DETS.
           MOVE '_' TO BANK-SCR80-OPT1.
           MOVE '_' TO BANK-SCR80-OPT2.
           IF CD09O-CONTACT-ID IS EQUAL TO CD09I-CONTACT-ID
              MOVE CD09O-CONTACT-ID TO BANK-SCR80-CONTACT-ID
              MOVE CD09O-CONTACT-NAME TO BANK-SCR80-CONTACT-NAME
              MOVE CD09O-CONTACT-ADDR1 TO BANK-SCR80-ADDR1
              MOVE CD09O-CONTACT-ADDR2 TO BANK-SCR80-ADDR2
              MOVE CD09O-CONTACT-STATE TO BANK-SCR80-STATE
              MOVE CD09O-CONTACT-CNTRY TO BANK-SCR80-CNTRY
              MOVE CD09O-CONTACT-PSTCDE TO BANK-SCR80-PSTCDE
              MOVE CD09O-CONTACT-EMAIL TO BANK-SCR80-EMAIL
           ELSE
              MOVE CD09O-CONTACT-NAME TO BANK-SCR80-CONTACT-NAME
           END-IF.
       POPULATE-SCREEN-DATA-EXIT.
           EXIT.

      * $ Version 5.99c sequenced on Wednesday 3 Mar 2011 at 1:00pm
