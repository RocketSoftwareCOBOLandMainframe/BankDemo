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
      * Program:     BBANK35P.CBL                                     *
      * Layer:       Business logic                                   *
      * Function:    Populate details of specific account             *
      *****************************************************************

       IDENTIFICATION DIVISION.
       PROGRAM-ID.
           BBANK35P.
       DATE-WRITTEN.
           September 2004.
       DATE-COMPILED.
           Today.

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-MISC-STORAGE.
         05  WS-PROGRAM-ID                         PIC X(8)
             VALUE 'BBANK35P'.
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
         05  WS-EDIT-AMT-3                         PIC ZZ9.
         05  WS-EDIT-AMT-5-2                       PIC ZZ,ZZ9.99-.
         05  WS-EDIT-AMT-7-2                       PIC Z,ZZZ,ZZ9.99-.
         05  WS-DYNAMIC-PGM                        PIC X(8)
             VALUE 'UNKNOWN'.
         05  WS-SUB1                               PIC S9(4) COMP.
         05  WS-SUB-LIMIT                          PIC S9(4) COMP.

       01  WS-TIME-DATE-WORK-AREA.
       COPY CDATED.

       01  WS-BANK-DATA.
       COPY CBANKDAT.

       01  WS-HELP-DATA.
       COPY CHELPD01.

       01  WS-TXN-LIST.
       COPY CBANKD11.

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
              BANK-AID-PFK04
              SET PFK-VALID TO TRUE
           END-IF.
           IF BANK-AID-PFK01 AND
              BANK-HELP-INACTIVE
              SET BANK-HELP-ACTIVE TO TRUE
              SET PFK-VALID TO TRUE
           END-IF.
           IF BANK-AID-PFK06 AND
              BANK-SCR35-TRANS(1:1) IS NUMERIC
              SET PFK-VALID TO TRUE
           END-IF.
           IF PFK-INVALID
              SET BANK-AID-ENTER TO TRUE
           END-IF.

      *****************************************************************
      * Check the AID to see if we have to quit                       *
      *****************************************************************
           IF BANK-AID-PFK03
              MOVE 'BBANK35P' TO BANK-LAST-PROG
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
                 MOVE 'BBANK35P' TO BANK-LAST-PROG
                 MOVE 'BBANK35P' TO BANK-NEXT-PROG
                 MOVE 'MBANK35' TO BANK-LAST-MAPSET
                 MOVE 'HELP35A' TO BANK-LAST-MAP
                 MOVE 'MBANK35' TO BANK-NEXT-MAPSET
                 MOVE 'BANK35A' TO BANK-NEXT-MAP
                 GO TO COMMON-RETURN
              ELSE
                 MOVE 01 TO BANK-HELP-SCREEN
                 MOVE 'BBANK35P' TO BANK-LAST-PROG
                 MOVE 'BBANK35P' TO BANK-NEXT-PROG
                 MOVE 'MBANK35' TO BANK-LAST-MAPSET
                 MOVE 'BANK35A' TO BANK-LAST-MAP
                 MOVE 'MBANK35' TO BANK-NEXT-MAPSET
                 MOVE 'HELP35A' TO BANK-NEXT-MAP
                 MOVE 'BANK35' TO HELP01I-SCRN
                 COPY CHELPX01.
                 MOVE HELP01O-DATA TO BANK-HELP-DATA
                 GO TO COMMON-RETURN
           END-IF.

      *****************************************************************
      * Check the AID to see if we have to return to previous screen  *
      *****************************************************************
           IF BANK-AID-PFK04
              MOVE 'BBANK35P' TO BANK-LAST-PROG
              MOVE 'BBANK30P' TO BANK-NEXT-PROG
              MOVE 'MBANK30' TO BANK-NEXT-MAPSET
              MOVE 'BANK30A' TO BANK-NEXT-MAP
              SET BANK-AID-ENTER TO TRUE
              GO TO COMMON-RETURN
           END-IF.

      *****************************************************************
      * Check the AID to see if we have to show transactions          *
      *****************************************************************
           IF BANK-AID-PFK06
              MOVE BANK-SCR35-ACC TO BANK-SCR40-ACC
              MOVE BANK-SCR35-DSC TO BANK-SCR40-ACCTYPE
              MOVE 'BBANK35P' TO BANK-LAST-PROG
              MOVE 'BBANK40P' TO BANK-NEXT-PROG
              MOVE 'MBANK40' TO BANK-NEXT-MAPSET
              MOVE 'BANK40A' TO BANK-NEXT-MAP
              MOVE 'BBANK35P' TO BANK-RETURN-TO-PROG
              SET BANK-AID-ENTER TO TRUE
              GO TO COMMON-RETURN
           END-IF.

      * Check if we have set the screen up before or is this 1st time
           IF BANK-LAST-MAPSET IS NOT EQUAL TO 'MBANK35'
              MOVE 'BBANK35P' TO BANK-LAST-PROG
              MOVE 'BBANK35P' TO BANK-NEXT-PROG
              MOVE 'MBANK35' TO BANK-LAST-MAPSET
              MOVE 'BANK35A' TO BANK-LAST-MAP
              MOVE 'MBANK35' TO BANK-NEXT-MAPSET
              MOVE 'BANK35A' TO BANK-NEXT-MAP
              SET BANK-PAGING-OFF TO TRUE
              PERFORM POPULATE-SCREEN-DATA THRU
                      POPULATE-SCREEN-DATA-EXIT
              GO TO COMMON-RETURN
           END-IF.


      * Check if we have set the screen up before or is this 1st time
           IF BANK-LAST-MAPSET IS EQUAL TO 'MBANK35'
              MOVE 'BBANK35P' TO BANK-LAST-PROG
              MOVE 'BBANK35P' TO BANK-NEXT-PROG
              MOVE 'MBANK35' TO BANK-LAST-MAPSET
              MOVE 'BANK35A' TO BANK-LAST-MAP
              MOVE 'MBANK35' TO BANK-NEXT-MAPSET
              MOVE 'BANK35A' TO BANK-NEXT-MAP
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
           MOVE SPACES TO BANK-SCR35-ATM-FIELDS.
           MOVE SPACES TO BANK-SCR35-RP-FIELDS.
           MOVE SPACES TO CD11-DATA.
      * Set criteria for search to populate screen
           MOVE BANK-SCR35-ACC TO CD11I-ACCNO.
      * Now go get the data
       COPY CBANKX11.

           IF CD11O-ACCNO IS NOT EQUAL TO SPACES
              MOVE CD11O-BAL TO BANK-SCR35-BAL
              IF CD11O-BAL IS EQUAL TO SPACES
                 MOVE CD11O-BAL TO BANK-SCR35-BAL
              ELSE
                 MOVE CD11O-BAL-N TO WS-EDIT-AMT-7-2
                 MOVE WS-EDIT-AMT-7-2 TO BANK-SCR35-BAL
              END-IF
              IF CD11O-DTE IS EQUAL TO SPACES
                 MOVE CD11O-DTE TO BANK-SCR35-DTE
              ELSE
                 MOVE CD11O-DTE TO DDI-DATA
                 SET DDI-ISO TO TRUE
                 SET DDO-DD-MMM-YYYY TO TRUE
                 PERFORM CALL-DATECONV THRU
                        CALL-DATECONV-EXIT
                 MOVE DDO-DATA TO BANK-SCR35-DTE
              END-IF
              MOVE CD11O-TRANS TO BANK-SCR35-TRANS
              MOVE CD11O-ATM-ENABLED TO BANK-SCR35-ATM-ENABLED
              IF CD11O-ATM-LIM IS EQUAL TO SPACES
                 MOVE CD11O-ATM-LIM TO BANK-SCR35-ATM-LIM
              ELSE
                 MOVE CD11O-ATM-LIM-N TO WS-EDIT-AMT-3
                 MOVE WS-EDIT-AMT-3 TO BANK-SCR35-ATM-LIM
              END-IF
              IF CD11O-ATM-LDTE IS EQUAL TO SPACES
                 MOVE CD11O-ATM-LDTE TO BANK-SCR35-DTE
              ELSE
                 MOVE CD11O-ATM-LDTE TO DDI-DATA
                 SET DDI-ISO TO TRUE
                 SET DDO-DD-MMM-YYYY TO TRUE
                 PERFORM CALL-DATECONV THRU
                        CALL-DATECONV-EXIT
                 MOVE DDO-DATA TO BANK-SCR35-ATM-LDTE
              END-IF
              IF CD11O-ATM-LAMT IS EQUAL TO SPACES
                 MOVE CD11O-ATM-LAMT TO BANK-SCR35-ATM-LAMT
              ELSE
                 MOVE CD11O-ATM-LAMT-N TO WS-EDIT-AMT-3
                 MOVE WS-EDIT-AMT-3 TO BANK-SCR35-ATM-LAMT
              END-IF
              MOVE CD11O-RP1DAY TO BANK-SCR35-RP1DAY
              IF CD11O-RP1AMT IS EQUAL TO SPACES
                 MOVE CD11O-RP1AMT TO BANK-SCR35-RP1AMT
              ELSE
                 MOVE CD11O-RP1AMT-N TO WS-EDIT-AMT-5-2
                 MOVE WS-EDIT-AMT-5-2 TO BANK-SCR35-RP1AMT
              END-IF
              MOVE CD11O-RP1PID TO BANK-SCR35-RP1PID
              MOVE CD11O-RP1ACC TO BANK-SCR35-RP1ACC
              IF CD11O-RP1DTE IS EQUAL TO SPACES
                 MOVE CD11O-RP1DTE TO BANK-SCR35-RP1DTE
              ELSE
                 MOVE CD11O-RP1DTE TO DDI-DATA
                 SET DDI-ISO TO TRUE
                 SET DDO-DD-MMM-YYYY TO TRUE
                 PERFORM CALL-DATECONV THRU
                        CALL-DATECONV-EXIT
                 MOVE DDO-DATA TO BANK-SCR35-RP1DTE
              END-IF
              MOVE CD11O-RP2DAY TO BANK-SCR35-RP2DAY
              IF CD11O-RP2AMT IS EQUAL TO SPACES
                 MOVE CD11O-RP2AMT TO BANK-SCR35-RP2AMT
              ELSE
                 MOVE CD11O-RP2AMT-N TO WS-EDIT-AMT-5-2
                 MOVE WS-EDIT-AMT-5-2 TO BANK-SCR35-RP2AMT
              END-IF
              MOVE CD11O-RP2PID TO BANK-SCR35-RP2PID
              MOVE CD11O-RP2ACC TO BANK-SCR35-RP2ACC
              IF CD11O-RP2DTE IS EQUAL TO SPACES
                 MOVE CD11O-RP2DTE TO BANK-SCR35-RP2DTE
              ELSE
                 MOVE CD11O-RP2DTE TO DDI-DATA
                 SET DDI-ISO TO TRUE
                 SET DDO-DD-MMM-YYYY TO TRUE
                 PERFORM CALL-DATECONV THRU
                        CALL-DATECONV-EXIT
                 MOVE DDO-DATA TO BANK-SCR35-RP2DTE
              END-IF
              MOVE CD11O-RP3DAY TO BANK-SCR35-RP3DAY
              MOVE CD11O-RP3AMT TO BANK-SCR35-RP3AMT
              IF CD11O-RP3AMT IS EQUAL TO SPACES
                 MOVE CD11O-RP3AMT TO BANK-SCR35-RP3AMT
              ELSE
                 MOVE CD11O-RP3AMT-N TO WS-EDIT-AMT-5-2
                 MOVE WS-EDIT-AMT-5-2 TO BANK-SCR35-RP3AMT
              END-IF
              MOVE CD11O-RP3PID TO BANK-SCR35-RP3PID
              MOVE CD11O-RP3ACC TO BANK-SCR35-RP3ACC
              IF CD11O-RP3DTE IS EQUAL TO SPACES
                 MOVE CD11O-RP3DTE TO BANK-SCR35-RP3DTE
              ELSE
                 MOVE CD11O-RP3DTE TO DDI-DATA
                 SET DDI-ISO TO TRUE
                 SET DDO-DD-MMM-YYYY TO TRUE
                 PERFORM CALL-DATECONV THRU
                        CALL-DATECONV-EXIT
                 MOVE DDO-DATA TO BANK-SCR35-RP3DTE
              END-IF
           END-IF.

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
