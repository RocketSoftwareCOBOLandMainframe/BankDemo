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
      * Program:     BBANK40P.CBL                                     *
      * Layer:       Business logic                                   *
      * Function:    Populate transaction deltails list for user      *
      *****************************************************************

       IDENTIFICATION DIVISION.
       PROGRAM-ID.
           BBANK40P.
       DATE-WRITTEN.
           September 2002.
       DATE-COMPILED.
           Today.

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-MISC-STORAGE.
         05  WS-PROGRAM-ID                         PIC X(8)
             VALUE 'BBANK40P'.
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
         05  WS-EDIT-AMT                           PIC Z,ZZZ,ZZ9.99-.
         05  WS-DYNAMIC-PGM                        PIC X(8)
             VALUE 'UNKNOWN'.
         05  WS-SUB1                               PIC S9(4) COMP.
         05  WS-SUB-LIMIT                          PIC S9(4) COMP.
         05  WS-TEMP-TIME-IP                       PIC X(8).
         05  WS-TEMP-TIME-OP                       PIC X(8).

       01  WS-TIME-DATE-WORK-AREA.
       COPY CDATED.

       01  WS-BANK-DATA.
       COPY CBANKDAT.

       01  WS-HELP-DATA.
       COPY CHELPD01.

       01  WS-TXN-LIST.
       COPY CBANKD05.

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
              BANK-AID-PFK07 OR
              BANK-AID-PFK08
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
              MOVE 'BBANK40P' TO BANK-LAST-PROG
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
                 MOVE 'BBANK40P' TO BANK-LAST-PROG
                 MOVE 'BBANK40P' TO BANK-NEXT-PROG
                 MOVE 'MBANK40' TO BANK-LAST-MAPSET
                 MOVE 'HELP40A' TO BANK-LAST-MAP
                 MOVE 'MBANK40' TO BANK-NEXT-MAPSET
                 MOVE 'BANK40A' TO BANK-NEXT-MAP
                 GO TO COMMON-RETURN
              ELSE
                 MOVE 01 TO BANK-HELP-SCREEN
                 MOVE 'BBANK40P' TO BANK-LAST-PROG
                 MOVE 'BBANK40P' TO BANK-NEXT-PROG
                 MOVE 'MBANK40' TO BANK-LAST-MAPSET
                 MOVE 'BANK40A' TO BANK-LAST-MAP
                 MOVE 'MBANK40' TO BANK-NEXT-MAPSET
                 MOVE 'HELP40A' TO BANK-NEXT-MAP
                 MOVE 'BANK40' TO HELP01I-SCRN
                 COPY CHELPX01.
                 MOVE HELP01O-DATA TO BANK-HELP-DATA
                 GO TO COMMON-RETURN
           END-IF.

      *****************************************************************
      * Check the AID to see if we have to return to previous screen  *
      *****************************************************************
           IF BANK-AID-PFK04
              MOVE 'BBANK40P' TO BANK-LAST-PROG
              IF BANK-RETURN-TO-PROG IS EQUAL TO 'BBANK35P'
                 MOVE 'BBANK35P' TO BANK-NEXT-PROG
                 MOVE 'MBANK35' TO BANK-NEXT-MAPSET
                 MOVE 'BANK35A' TO BANK-NEXT-MAP
              ELSE
                 MOVE 'BBANK30P' TO BANK-NEXT-PROG
                 MOVE 'MBANK30' TO BANK-NEXT-MAPSET
                 MOVE 'BANK30A' TO BANK-NEXT-MAP
              END-IF
              SET BANK-AID-ENTER TO TRUE
              GO TO COMMON-RETURN
           END-IF.

      * Check if we have set the screen up before or is this 1st time
           IF BANK-LAST-MAPSET IS NOT EQUAL TO 'MBANK40'
              MOVE 'BBANK40P' TO BANK-LAST-PROG
              MOVE 'BBANK40P' TO BANK-NEXT-PROG
              MOVE 'MBANK40' TO BANK-LAST-MAPSET
              MOVE 'BANK40A' TO BANK-LAST-MAP
              MOVE 'MBANK40' TO BANK-NEXT-MAPSET
              MOVE 'BANK40A' TO BANK-NEXT-MAP
              SET BANK-PAGING-OFF TO TRUE
              PERFORM POPULATE-SCREEN-DATA THRU
                      POPULATE-SCREEN-DATA-EXIT
              GO TO COMMON-RETURN
           END-IF.

      *****************************************************************
      * Check to see if we have a paging request                      *
      *****************************************************************
           IF BANK-AID-PFK07 OR
              BANK-AID-PFK08
              MOVE 'BBANK40P' TO BANK-LAST-PROG
              MOVE 'BBANK40P' TO BANK-NEXT-PROG
              MOVE 'MBANK40' TO BANK-LAST-MAPSET
              MOVE 'BANK40A' TO BANK-LAST-MAP
              MOVE 'MBANK40' TO BANK-NEXT-MAPSET
              MOVE 'BANK40A' TO BANK-NEXT-MAP
              IF BANK-AID-PFK07 AND
                 (BANK-PAGING-OFF OR
                  BANK-PAGING-FIRST)
                 MOVE 'Already at first page. Cannot page back.'
                   TO BANK-ERROR-MSG
                 GO TO COMMON-RETURN
              END-IF
              IF BANK-AID-PFK08 AND
                 (BANK-PAGING-OFF OR
                  BANK-PAGING-LAST)
                 MOVE 'Already at last page. Cannot page forward.'
                   TO BANK-ERROR-MSG
                 GO TO COMMON-RETURN
              END-IF
              PERFORM POPULATE-SCREEN-DATA THRU
                      POPULATE-SCREEN-DATA-EXIT
              GO TO COMMON-RETURN
           END-IF.

      * Check if we have set the screen up before or is this 1st time
           IF BANK-LAST-MAPSET IS EQUAL TO 'MBANK40'
              MOVE 'BBANK40P' TO BANK-LAST-PROG
              MOVE 'BBANK40P' TO BANK-NEXT-PROG
              MOVE 'MBANK40' TO BANK-LAST-MAPSET
              MOVE 'BANK40A' TO BANK-LAST-MAP
              MOVE 'MBANK40' TO BANK-NEXT-MAPSET
              MOVE 'BANK40A' TO BANK-NEXT-MAP
              PERFORM POPULATE-SCREEN-DATA THRU
                      POPULATE-SCREEN-DATA-EXIT
              GO TO COMMON-RETURN
           END-IF.

      *****************************************************************
      * If we get this far then we have an error in our logic as we   *
      * don't know where to go next.                                  *
      *****************************************************************
           IF NOT BANK-ENV-CICS
              MOVE WS-PROGRAM-ID TO ABEND-CULPRIT
              MOVE '0001' TO ABEND-CODE
              MOVE SPACES TO ABEND-REASON
              COPY CABENDPO.
           END-IF.
           GOBACK.

       COMMON-RETURN.
           MOVE WS-BANK-DATA TO DFHCOMMAREA (1:LENGTH OF WS-BANK-DATA).
       COPY CRETURN.

       POPULATE-SCREEN-DATA.
           MOVE SPACES TO CD05-DATA.
           MOVE BANK-SCR40-ACC TO CD05I-ACC.
      * Set criteria for search to populate screen
           IF BANK-PAGING-OFF
              MOVE LOW-VALUES TO CD05I-START-ID
              MOVE '0001-01-01 00:00:00.000000' TO CD05I-START-ID       
              SET CD05-START-EQUAL TO TRUE
           ELSE
              IF WS-RETURN-FLAG-ON
                 MOVE BANK-PAGING-FIRST-ENTRY TO CD05I-START-ID
                 SET CD05-START-EQUAL TO TRUE
              END-IF
              IF WS-RETURN-FLAG-OFF
                 IF BANK-AID-PFK07
                    MOVE BANK-PAGING-FIRST-ENTRY TO CD05I-START-ID
                    SET CD05-START-LOW TO TRUE
                 ELSE
                    IF BANK-AID-PFK08
                       MOVE BANK-PAGING-LAST-ENTRY TO CD05I-START-ID
                       SET CD05-START-HIGH TO TRUE
                    ELSE
                       MOVE BANK-PAGING-FIRST-ENTRY TO CD05I-START-ID
                       SET CD05-START-EQUAL TO TRUE
                     END-IF
                 END-IF
              END-IF
           END-IF.
      * Now go get the data
       COPY CBANKX05.
           IF WS-RETURN-FLAG-OFF
              IF BANK-PAGING-OFF AND
                 CD05-IS-MORE-DATA
                 SET BANK-PAGING-FIRST TO TRUE
              ELSE
                 IF NOT BANK-AID-ENTER
                    IF BANK-PAGING-FIRST
                       IF CD05-IS-MORE-DATA
                          SET BANK-PAGING-MIDDLE TO TRUE
                       END-IF
                       IF CD05-NO-MORE-DATA
                          SET BANK-PAGING-LAST TO TRUE
                       END-IF
                    ELSE
                       IF BANK-PAGING-MIDDLE
                          IF BANK-AID-PFK08 AND
                             CD05-NO-MORE-DATA
                             SET BANK-PAGING-LAST TO TRUE
                          END-IF
                          IF BANK-AID-PFK07 AND
                             CD05-NO-MORE-DATA
                             SET BANK-PAGING-FIRST TO TRUE
                          END-IF
                       ELSE
                          IF BANK-PAGING-LAST
                             IF CD05-IS-MORE-DATA
                                SET BANK-PAGING-MIDDLE TO TRUE
                             END-IF
                          IF CD05-NO-MORE-DATA
                             SET BANK-PAGING-FIRST TO TRUE
                          END-IF
                       END-IF
                    END-IF
                 END-IF
              END-IF
           END-IF.
           MOVE LOW-VALUES TO BANK-SCR40-TXN-FIELDS.
           MOVE CD05O-ID1 TO BANK-PAGING-FIRST-ENTRY.
           MOVE CD05O-ID1 TO BANK-PAGING-LAST-ENTRY.
           MOVE 0 TO WS-SUB1.
           PERFORM POPULATE-ENTRY THRU
                   POPULATE-ENTRY-EXIT 8 TIMES.
           GO TO POPULATE-SCREEN-DATA-EXIT.
       POPULATE-ENTRY.
           ADD 1 TO WS-SUB1.
           IF CD05O-DATE (WS-SUB1) IS EQUAL TO SPACES
              MOVE CD05O-DATE (WS-SUB1) TO BANK-SCR40-DATE (WS-SUB1)
           ELSE
              MOVE CD05O-DATE (WS-SUB1) TO DDI-DATA
              SET DDI-ISO TO TRUE
              SET DDO-DD-MMM-YYYY TO TRUE
              PERFORM CALL-DATECONV THRU
                     CALL-DATECONV-EXIT
              MOVE DDO-DATA TO BANK-SCR40-DATE (WS-SUB1)
           END-IF.
           IF CD05O-TIME (WS-SUB1) IS EQUAL TO SPACES
              MOVE CD05O-TIME (WS-SUB1) TO BANK-SCR40-TIME (WS-SUB1)
           ELSE
              MOVE CD05O-TIME (WS-SUB1) TO WS-TEMP-TIME-IP
              MOVE WS-TEMP-TIME-IP (1:2) TO WS-TEMP-TIME-OP (1:2)
              MOVE ':' TO WS-TEMP-TIME-OP (3:1)
              MOVE WS-TEMP-TIME-IP (4:2) TO WS-TEMP-TIME-OP (4:2)
              MOVE ':' TO WS-TEMP-TIME-OP (6:1)
              MOVE WS-TEMP-TIME-IP (7:2) TO WS-TEMP-TIME-OP (7:2)
              MOVE WS-TEMP-TIME-OP TO BANK-SCR40-TIME (WS-SUB1)
           END-IF.
           IF CD05O-AMT (WS-SUB1) IS EQUAL TO SPACES
              MOVE CD05O-AMT (WS-SUB1) TO BANK-SCR40-AMNT (WS-SUB1)
           ELSE
              MOVE CD05O-AMT-N (WS-SUB1) TO WS-EDIT-AMT
              MOVE WS-EDIT-AMT TO BANK-SCR40-AMNT (WS-SUB1)
           END-IF.
           MOVE CD05O-DESC (WS-SUB1) TO BANK-SCR40-DESC (WS-SUB1).
           MOVE CD05O-ID (WS-SUB1) TO BANK-PAGING-LAST-ENTRY.
       POPULATE-ENTRY-EXIT.
           EXIT.

       POPULATE-SCREEN-DATA-EXIT.
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
