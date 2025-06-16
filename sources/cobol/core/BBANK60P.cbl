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
      * Program:     BBANK60P.CBL                                     *
      * Layer:       Business logic                                   *
      * Function:    Update address information                       *
      *****************************************************************

       IDENTIFICATION DIVISION.
       PROGRAM-ID.
           BBANK60P.
       DATE-WRITTEN.
           September 2007.
       DATE-COMPILED.
           Today.

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-MISC-STORAGE.
         05  WS-PROGRAM-ID                         PIC X(8)
             VALUE 'BBANK60P'.
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
         05  WS-ADDR-CHANGE                        PIC X(1).
           88  ADDR-DATA-UNCHANGED                 VALUE '0'.
           88  ADDR-DATA-CHANGED                   VALUE '1'.

       01  WS-BANK-DATA.
       COPY CBANKDAT.

       01  WS-HELP-DATA.
       COPY CHELPD01.

       01  WS-ADDR-DATA.
       COPY CBANKD02.

       COPY CBANKD07.

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
              MOVE 'BBANK60P' TO BANK-LAST-PROG
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
                 MOVE 'BBANK60P' TO BANK-LAST-PROG
                 MOVE 'BBANK60P' TO BANK-NEXT-PROG
                 MOVE 'MBANK60' TO BANK-LAST-MAPSET
                 MOVE 'HELP60A' TO BANK-LAST-MAP
                 MOVE 'MBANK60' TO BANK-NEXT-MAPSET
                 MOVE 'BANK60A' TO BANK-NEXT-MAP
                 GO TO COMMON-RETURN
              ELSE
                 MOVE 01 TO BANK-HELP-SCREEN
                 MOVE 'BBANK60P' TO BANK-LAST-PROG
                 MOVE 'BBANK60P' TO BANK-NEXT-PROG
                 MOVE 'MBANK60' TO BANK-LAST-MAPSET
                 MOVE 'BANK60A' TO BANK-LAST-MAP
                 MOVE 'MBANK60' TO BANK-NEXT-MAPSET
                 MOVE 'HELP60A' TO BANK-NEXT-MAP
                 MOVE 'BANK60' TO HELP01I-SCRN
                 COPY CHELPX01.
                 MOVE HELP01O-DATA TO BANK-HELP-DATA
                 GO TO COMMON-RETURN
           END-IF.

      *****************************************************************
      * Check the AID to see if we have to return to previous screen  *
      *****************************************************************
           IF BANK-AID-PFK04
              MOVE 'BBANK60P' TO BANK-LAST-PROG
              MOVE 'BBANK20P' TO BANK-NEXT-PROG
              MOVE 'MBANK20' TO BANK-NEXT-MAPSET
              MOVE 'BANK20A' TO BANK-NEXT-MAP
              SET BANK-AID-ENTER TO TRUE
              GO TO COMMON-RETURN
           END-IF.

      * Check if we have set the screen up before or is this 1st time
           IF BANK-LAST-MAPSET IS NOT EQUAL TO 'MBANK60'
              MOVE WS-RETURN-MSG TO BANK-ERROR-MSG
              MOVE 'BBANK60P' TO BANK-LAST-PROG
              MOVE 'BBANK60P' TO BANK-NEXT-PROG
              MOVE 'MBANK60' TO BANK-LAST-MAPSET
              MOVE 'BANK60A' TO BANK-LAST-MAP
              MOVE 'MBANK60' TO BANK-NEXT-MAPSET
              MOVE 'BANK60A' TO BANK-NEXT-MAP
              PERFORM POPULATE-SCREEN-DATA THRU
                      POPULATE-SCREEN-DATA-EXIT
              GO TO COMMON-RETURN
           END-IF.

      *****************************************************************
      * Check to see if the data changed                              *
      *****************************************************************
           IF ADDR-CHANGE-REQUEST
              IF BANK-SCR60-OLD-ADDR1 IS NOT EQUAL TO
                   BANK-SCR60-NEW-ADDR1 OR
                 BANK-SCR60-OLD-ADDR2 IS NOT EQUAL TO
                   BANK-SCR60-NEW-ADDR2 OR
                 BANK-SCR60-OLD-STATE IS NOT EQUAL TO
                   BANK-SCR60-NEW-STATE OR
                 BANK-SCR60-OLD-CNTRY IS NOT EQUAL TO
                   BANK-SCR60-NEW-CNTRY OR
                 BANK-SCR60-OLD-PSTCDE IS NOT EQUAL TO
                   BANK-SCR60-NEW-PSTCDE OR
                 BANK-SCR60-OLD-TELNO IS NOT EQUAL TO
                   BANK-SCR60-NEW-TELNO OR
                 BANK-SCR60-OLD-EMAIL IS NOT EQUAL TO
                   BANK-SCR60-NEW-EMAIL OR
                 BANK-SCR60-OLD-SEND-MAIL IS NOT EQUAL TO
                   BANK-SCR60-NEW-SEND-MAIL OR
                 BANK-SCR60-OLD-SEND-EMAIL IS NOT EQUAL TO
                   BANK-SCR60-NEW-SEND-EMAIL
                SET ADDR-DATA-CHANGED TO TRUE
              ELSE
                SET ADDR-DATA-UNCHANGED TO TRUE
              END-IF
           END-IF.
      * Data has changed, we need to validate changes
           IF ADDR-DATA-CHANGED AND
              ADDR-CHANGE-REQUEST
              PERFORM VALIDATE-DATA THRU
                      VALIDATE-DATA-EXIT
              IF INPUT-ERROR
                 MOVE WS-ERROR-MSG TO BANK-ERROR-MSG
                 MOVE 'BBANK60P' TO BANK-LAST-PROG
                 MOVE 'BBANK60P' TO BANK-NEXT-PROG
                 MOVE 'MBANK60' TO BANK-LAST-MAPSET
                 MOVE 'BANK60A' TO BANK-LAST-MAP
                 MOVE 'MBANK60' TO BANK-NEXT-MAPSET
                 MOVE 'BANK60A' TO BANK-NEXT-MAP
                 GO TO COMMON-RETURN
              END-IF
           END-IF.

      * Data has changed, we need to verify the change
           IF ADDR-DATA-CHANGED AND
              ADDR-CHANGE-REQUEST
              MOVE 'Please use F10 to confirm changes' TO WS-ERROR-MSG
              SET ADDR-CHANGE-VERIFY TO TRUE
              MOVE WS-ERROR-MSG TO BANK-ERROR-MSG
              MOVE 'BBANK60P' TO BANK-LAST-PROG
              MOVE 'BBANK60P' TO BANK-NEXT-PROG
              MOVE 'MBANK60' TO BANK-LAST-MAPSET
              MOVE 'BANK60A' TO BANK-LAST-MAP
              MOVE 'MBANK60' TO BANK-NEXT-MAPSET
              MOVE 'BANK60A' TO BANK-NEXT-MAP
              GO TO COMMON-RETURN
           END-IF.
      * Data was changed and verified
           IF ADDR-CHANGE-VERIFY AND
              BANK-AID-PFK10
              MOVE SPACES TO CD02-DATA
              MOVE BANK-SCR60-CONTACT-ID TO CD02I-CONTACT-ID
      * Set criteria for I/O rotine
              SET CD02I-WRITE TO TRUE
      * Move the new data
              MOVE BANK-SCR60-CONTACT-NAME TO CD02I-CONTACT-NAME
              MOVE BANK-SCR60-NEW-ADDR1 TO CD02I-CONTACT-ADDR1
              MOVE BANK-SCR60-NEW-ADDR2 TO CD02I-CONTACT-ADDR2
              MOVE BANK-SCR60-NEW-STATE TO CD02I-CONTACT-STATE
              MOVE BANK-SCR60-NEW-CNTRY TO CD02I-CONTACT-CNTRY
              MOVE BANK-SCR60-NEW-PSTCDE TO CD02I-CONTACT-PSTCDE
              MOVE BANK-SCR60-NEW-TELNO TO CD02I-CONTACT-TELNO
              MOVE BANK-SCR60-NEW-EMAIL TO CD02I-CONTACT-EMAIL
              MOVE BANK-SCR60-NEW-SEND-MAIL TO CD02I-CONTACT-SEND-MAIL
              MOVE BANK-SCR60-NEW-SEND-EMAIL TO CD02I-CONTACT-SEND-EMAIL
      * Now go update the data
       COPY CBANKX02.
              MOVE SPACES TO CD07-DATA
              MOVE BANK-SCR60-CONTACT-ID TO CD07I-PERSON-PID
              MOVE BANK-SCR60-OLD-ADDR1 TO CD07I-OLD-ADDR1
              MOVE BANK-SCR60-OLD-ADDR2 TO CD07I-OLD-ADDR2
              MOVE BANK-SCR60-OLD-STATE TO CD07I-OLD-STATE
              MOVE BANK-SCR60-OLD-CNTRY TO CD07I-OLD-CNTRY
              MOVE BANK-SCR60-OLD-PSTCDE TO CD07I-OLD-PSTCDE
              MOVE BANK-SCR60-OLD-TELNO TO CD07I-OLD-TELNO
              MOVE BANK-SCR60-OLD-EMAIL TO CD07I-OLD-EMAIL
              MOVE BANK-SCR60-OLD-SEND-MAIL TO CD07I-OLD-SEND-MAIL
              MOVE BANK-SCR60-OLD-SEND-EMAIL TO CD07I-OLD-SEND-EMAIL
              MOVE BANK-SCR60-NEW-ADDR1 TO CD07I-NEW-ADDR1
              MOVE BANK-SCR60-NEW-ADDR2 TO CD07I-NEW-ADDR2
              MOVE BANK-SCR60-NEW-STATE TO CD07I-NEW-STATE
              MOVE BANK-SCR60-NEW-CNTRY TO CD07I-NEW-CNTRY
              MOVE BANK-SCR60-NEW-PSTCDE TO CD07I-NEW-PSTCDE
              MOVE BANK-SCR60-NEW-TELNO TO CD07I-NEW-TELNO
              MOVE BANK-SCR60-NEW-EMAIL TO CD07I-NEW-EMAIL
              MOVE BANK-SCR60-NEW-SEND-MAIL TO CD07I-NEW-SEND-MAIL
              MOVE BANK-SCR60-NEW-SEND-EMAIL TO CD07I-NEW-SEND-EMAIL
       COPY CBANKX07.
              MOVE 'Contact information updated' TO BANK-RETURN-MSG
              MOVE SPACES TO BANK-SCREEN60-DATA
              MOVE 'BBANK60P' TO BANK-LAST-PROG
              MOVE 'BBANK20P' TO BANK-NEXT-PROG
              MOVE 'MBANK20' TO BANK-NEXT-MAPSET
              MOVE 'BANK20A' TO BANK-NEXT-MAP
              SET BANK-AID-ENTER TO TRUE
              GO TO COMMON-RETURN
           END-IF.

      * Turn off update flags and redisplay
           SET ADDR-CHANGE-REQUEST TO TRUE.
           MOVE 'BBANK60P' TO BANK-LAST-PROG
           MOVE 'BBANK60P' TO BANK-NEXT-PROG
           MOVE 'MBANK60' TO BANK-LAST-MAPSET
           MOVE 'BANK60A' TO BANK-LAST-MAP
           MOVE 'MBANK60' TO BANK-NEXT-MAPSET
           MOVE 'BANK60A' TO BANK-NEXT-MAP
           GO TO COMMON-RETURN.

       COMMON-RETURN.
           MOVE WS-BANK-DATA TO DFHCOMMAREA (1:LENGTH OF WS-BANK-DATA).
       COPY CRETURN.

       VALIDATE-DATA.
           SET INPUT-OK TO TRUE.
           MOVE SPACES TO STATE-PROV-WK-CNTRY.
           MOVE BANK-SCR60-NEW-CNTRY TO STATE-PROV-TMP-CNTRY
           INSPECT STATE-PROV-TMP-CNTRY
             CONVERTING 'abcdefghijklmnopqrstuvwxyz'
                     TO 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.
           INSPECT BANK-SCR60-NEW-STATE
             CONVERTING 'abcdefghijklmnopqrstuvwxyz'
                     TO 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.
           INSPECT BANK-SCR60-NEW-SEND-MAIL
             CONVERTING 'abcdefghijklmnopqrstuvwxyz'
                     TO 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.
           INSPECT BANK-SCR60-NEW-SEND-EMAIL
             CONVERTING 'abcdefghijklmnopqrstuvwxyz'
                     TO 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.
           IF STATE-PROV-TMP-CNTRY IS EQUAL TO 'USA'
              MOVE 'USA' TO STATE-PROV-WK-CNTRY
           END-IF.
           IF STATE-PROV-TMP-CNTRY IS EQUAL TO 'CANADA'
              MOVE 'CDN' TO STATE-PROV-WK-CNTRY
           END-IF.
           IF STATE-PROV-WK-CNTRY IS EQUAL TO SPACES
              MOVE 'Country must be USA or CANADA' TO WS-ERROR-MSG
              GO TO VALIDATE-DATA-ERROR
           END-IF.

           MOVE 0 TO STATE-PROV-SUB.
           DIVIDE LENGTH OF STATE-PROV-DATA (1) INTO
             LENGTH OF STATE-PROV-TABLE
               GIVING STATE-PROV-COUNT.
       VALIDATE-DATA-LOOP1.
           ADD 1 TO STATE-PROV-SUB.
           IF STATE-PROV-SUB IS GREATER THAN STATE-PROV-COUNT
              MOVE 'Invlaid State/Prov code' TO WS-ERROR-MSG
              GO TO VALIDATE-DATA-ERROR
           END-IF.
           IF BANK-SCR60-NEW-STATE IS EQUAL TO
                STATE-PROV-CODE (STATE-PROV-SUB)
              GO TO VALIDATE-DATA-LOOP1-EXIT
           END-IF.
           GO TO VALIDATE-DATA-LOOP1.
       VALIDATE-DATA-LOOP1-EXIT.
           IF STATE-PROV-CNTRY (STATE-PROV-SUB) IS NOT EQUAL TO
              STATE-PROV-WK-CNTRY
              MOVE 'State/Prov not valid for Country' TO WS-ERROR-MSG
              GO TO VALIDATE-DATA-ERROR
           END-IF.
           IF BANK-SCR60-NEW-EMAIL IS NOT EQUAL TO SPACES
              MOVE 0 TO STATE-PROV-SUB
              INSPECT BANK-SCR60-NEW-EMAIL TALLYING STATE-PROV-SUB
                FOR ALL '@'
              IF STATE-PROV-SUB IS NOT EQUAL TO 1
                 MOVE 'E-Mail address format invalid' TO WS-ERROR-MSG
                 GO TO VALIDATE-DATA-ERROR
              END-IF
           END-IF.
           IF BANK-SCR60-NEW-SEND-MAIL IS NOT EQUAL TO ' ' AND
              BANK-SCR60-NEW-SEND-MAIL IS NOT EQUAL TO 'N' AND
              BANK-SCR60-NEW-SEND-MAIL IS NOT EQUAL TO 'Y'
              MOVE 'Send mail must be blank, Y or N' TO WS-ERROR-MSG
              GO TO VALIDATE-DATA-ERROR
           END-IF.
           IF BANK-SCR60-NEW-SEND-EMAIL IS NOT EQUAL TO ' ' AND
              BANK-SCR60-NEW-SEND-EMAIL IS NOT EQUAL TO 'N' AND
              BANK-SCR60-NEW-SEND-EMAIL IS NOT EQUAL TO 'Y'
              MOVE 'Send E-Mail must be blank, Y or N' TO WS-ERROR-MSG
              GO TO VALIDATE-DATA-ERROR
           END-IF.
           IF BANK-SCR60-NEW-SEND-EMAIL IS EQUAL TO 'Y' AND
              BANK-SCR60-NEW-EMAIL IS EQUAL TO SPACES
              MOVE 'Send E-Mail required E-Mail address' TO WS-ERROR-MSG
              GO TO VALIDATE-DATA-ERROR
           END-IF.

           GO TO VALIDATE-DATA-EXIT.

       VALIDATE-DATA-ERROR.
           SET INPUT-ERROR TO TRUE.
       VALIDATE-DATA-EXIT.
           EXIT.

       POPULATE-SCREEN-DATA.
           MOVE SPACES TO CD02-DATA.
           MOVE BANK-USERID TO BANK-SCR60-CONTACT-ID.
           MOVE BANK-SCR60-CONTACT-ID TO CD02I-CONTACT-ID.
      * Set criteria for I/O rotine
           SET CD02I-READ TO TRUE.
      * Now go get the data
       COPY CBANKX02.
           MOVE SPACES TO BANK-SCR60-OLD-DETS.
           MOVE SPACES TO BANK-SCR60-NEW-DETS.
           IF CD02O-CONTACT-ID IS EQUAL TO CD02I-CONTACT-ID
              MOVE CD02O-CONTACT-ID TO BANK-SCR60-CONTACT-ID
              MOVE CD02O-CONTACT-NAME TO BANK-SCR60-CONTACT-NAME
              MOVE CD02O-CONTACT-ADDR1 TO BANK-SCR60-OLD-ADDR1
              MOVE CD02O-CONTACT-ADDR2 TO BANK-SCR60-OLD-ADDR2
              MOVE CD02O-CONTACT-STATE TO BANK-SCR60-OLD-STATE
              MOVE CD02O-CONTACT-CNTRY TO BANK-SCR60-OLD-CNTRY
              MOVE CD02O-CONTACT-PSTCDE TO BANK-SCR60-OLD-PSTCDE
              MOVE CD02O-CONTACT-TELNO TO BANK-SCR60-OLD-TELNO
              MOVE CD02O-CONTACT-EMAIL TO BANK-SCR60-OLD-EMAIL
              MOVE CD02O-CONTACT-SEND-MAIL TO BANK-SCR60-OLD-SEND-MAIL
              MOVE CD02O-CONTACT-SEND-EMAIL TO BANK-SCR60-OLD-SEND-EMAIL
              MOVE CD02O-CONTACT-ADDR1 TO BANK-SCR60-NEW-ADDR1
              MOVE CD02O-CONTACT-ADDR2 TO BANK-SCR60-NEW-ADDR2
              MOVE CD02O-CONTACT-STATE TO BANK-SCR60-NEW-STATE
              MOVE CD02O-CONTACT-CNTRY TO BANK-SCR60-NEW-CNTRY
              MOVE CD02O-CONTACT-PSTCDE TO BANK-SCR60-NEW-PSTCDE
              MOVE CD02O-CONTACT-TELNO TO BANK-SCR60-NEW-TELNO
              MOVE CD02O-CONTACT-EMAIL TO BANK-SCR60-NEW-EMAIL
              MOVE CD02O-CONTACT-SEND-MAIL TO BANK-SCR60-NEW-SEND-MAIL
              MOVE CD02O-CONTACT-SEND-EMAIL TO BANK-SCR60-NEW-SEND-EMAIL
           ELSE
              MOVE CD02O-CONTACT-NAME TO BANK-SCR60-CONTACT-NAME
           END-IF.
       POPULATE-SCREEN-DATA-EXIT.
           EXIT.

      * $ Version 5.99c sequenced on Wednesday 3 Mar 2011 at 1:00pm
