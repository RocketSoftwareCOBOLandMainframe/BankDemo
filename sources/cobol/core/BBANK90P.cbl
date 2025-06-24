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
      * Program:     BBANK90P.CBL                                     *
      * Layer:       Business logic                                   *
      * Function:    Obtain data for "more information"               *
      *****************************************************************

       IDENTIFICATION DIVISION.
       PROGRAM-ID.
           BBANK90P.
       DATE-WRITTEN.
           September 2002.
       DATE-COMPILED.
           Today.

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-MISC-STORAGE.
         05  WS-PROGRAM-ID                         PIC X(8)
             VALUE 'BBANK90P'.
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

       01  WS-INF-DATA.
         05  WS-INF-DATA01.
           10  FILLER                              PIC X(40)
               VALUE 'Sorry. The information you requested is '.
           10  FILLER                              PIC X(35)
               VALUE 'not available at this time.        '.
         05  WS-INF-DATA03.
           10  FILLER                              PIC X(40)
               VALUE 'Please try our web site at:             '.
           10  FILLER                              PIC X(35)
               VALUE '                                   '.
         05  WS-INF-DATA05.
           10  FILLER                              PIC X(40)
               VALUE '    https://www.rocketsoftware.com      '.
           10  FILLER                              PIC X(35)
               VALUE '                                   '.
         05  WS-INF-DATA07.
           10  FILLER                              PIC X(40)
               VALUE 'or call our office at 1-855-577-4323    '.
           10  FILLER                              PIC X(35)
               VALUE '                                   '.
         05  WS-INF-DATA09.
           10  FILLER                              PIC X(40)
               VALUE 'Thank you for your interest.            '.
           10  FILLER                              PIC X(35)
               VALUE '                                   '.

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
              MOVE 'BBANK90P' TO BANK-LAST-PROG
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
                 MOVE 'BBANK90P' TO BANK-LAST-PROG
                 MOVE 'BBANK90P' TO BANK-NEXT-PROG
                 MOVE 'MBANK90' TO BANK-LAST-MAPSET
                 MOVE 'HELP90A' TO BANK-LAST-MAP
                 MOVE 'MBANK90' TO BANK-NEXT-MAPSET
                 MOVE 'BANK90A' TO BANK-NEXT-MAP
                 PERFORM POPULATE-SCR90-DATA THRU
                         POPULATE-SCR90-DATA-EXIT
                 GO TO COMMON-RETURN
              ELSE
                 MOVE 01 TO BANK-HELP-SCREEN
                 MOVE 'BBANK90P' TO BANK-LAST-PROG
                 MOVE 'BBANK90P' TO BANK-NEXT-PROG
                 MOVE 'MBANK90' TO BANK-LAST-MAPSET
                 MOVE 'BANK90A' TO BANK-LAST-MAP
                 MOVE 'MBANK90' TO BANK-NEXT-MAPSET
                 MOVE 'HELP90A' TO BANK-NEXT-MAP
                 MOVE 'BANK90' TO HELP01I-SCRN
                 COPY CHELPX01.
                 MOVE HELP01O-DATA TO BANK-HELP-DATA
                 GO TO COMMON-RETURN
           END-IF.

      *****************************************************************
      * Check the AID to see if we have to return to previous screen  *
      *****************************************************************
           IF BANK-AID-PFK04
              MOVE 'BBANK90P' TO BANK-LAST-PROG
              MOVE 'BBANK20P' TO BANK-NEXT-PROG
              MOVE 'MBANK20' TO BANK-NEXT-MAPSET
              MOVE 'BANK20A' TO BANK-NEXT-MAP
              SET BANK-AID-ENTER TO TRUE
              SET BANK-NO-CONV-IN-PROGRESS TO TRUE
              GO TO COMMON-RETURN
           END-IF.

      * Check if we have set the screen up before or is this 1st time
           IF BANK-LAST-MAPSET IS NOT EQUAL TO 'MBANK90'
              MOVE WS-RETURN-MSG TO BANK-ERROR-MSG
              MOVE 'BBANK90P' TO BANK-LAST-PROG
              MOVE 'BBANK90P' TO BANK-NEXT-PROG
              MOVE 'MBANK90' TO BANK-LAST-MAPSET
              MOVE 'BANK90A' TO BANK-LAST-MAP
              MOVE 'MBANK90' TO BANK-NEXT-MAPSET
              MOVE 'BANK90A' TO BANK-NEXT-MAP
              PERFORM POPULATE-SCR90-DATA THRU
                      POPULATE-SCR90-DATA-EXIT
              GO TO COMMON-RETURN
           END-IF.

           PERFORM VALIDATE-DATA THRU
                   VALIDATE-DATA-EXIT.

      * If we had an error display error and return
           IF INPUT-ERROR
              MOVE WS-ERROR-MSG TO BANK-ERROR-MSG
              MOVE 'BBANK90P' TO BANK-LAST-PROG
              MOVE 'BBANK90P' TO BANK-NEXT-PROG
              MOVE 'MBANK90' TO BANK-LAST-MAPSET
              MOVE 'BANK90A' TO BANK-LAST-MAP
              MOVE 'MBANK90' TO BANK-NEXT-MAPSET
              MOVE 'BANK90A' TO BANK-NEXT-MAP
              GO TO COMMON-RETURN
           END-IF.

           PERFORM POPULATE-SCR90-DATA THRU
                   POPULATE-SCR90-DATA-EXIT.
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

       POPULATE-SCR90-DATA.
           MOVE 'INFO90' TO HELP01I-SCRN.
           COPY CHELPX01.
           IF HELP-NOT-FOUND
              MOVE SPACES TO HELP01O-INDIVIDUAL-LINES
              MOVE WS-INF-DATA01 TO HELP01O-L01
              MOVE WS-INF-DATA03 TO HELP01O-L03
              MOVE WS-INF-DATA05 TO HELP01O-L05
              MOVE WS-INF-DATA07 TO HELP01O-L07
              MOVE WS-INF-DATA09 TO HELP01O-L09
           END-IF.
           MOVE HELP01O-DATA TO BANK-SCREEN90-DATA.
       POPULATE-SCR90-DATA-EXIT.
           EXIT.

      * $ Version 5.99c sequenced on Wednesday 3 Mar 2011 at 1:00pm
