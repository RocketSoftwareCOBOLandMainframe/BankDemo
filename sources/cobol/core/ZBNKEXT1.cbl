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
      * Prgram:      ZBNKEXT1.CBL                                     *
      * Function:    Extract data to print bank statements            *
      *****************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID.
           ZBNKEXT1.
       DATE-WRITTEN.
           September 2002.
       DATE-COMPILED.
           Today.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT   SECTION.
         FILE-CONTROL.
           SELECT EXTRACT-FILE
                  ASSIGN       TO EXTRACT
                  ORGANIZATION IS SEQUENTIAL
                  ACCESS MODE  IS SEQUENTIAL
                  FILE STATUS  IS WS-EXTRACT-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  EXTRACT-FILE
           RECORDING MODE IS V
           RECORD CONTAINS 66 TO 95 CHARACTERS.
       COPY CBANKXT1.

       WORKING-STORAGE SECTION.
       COPY CTIMERD.

       01  WS-MISC-STORAGE.
         05  WS-PROGRAM-ID                         PIC X(8)
             VALUE 'ZBNKEXT1'.
         05  WS-EXTRACT-STATUS.
           10  WS-EXTRACT-STAT1                    PIC X(1).
           10  WS-EXTRACT-STAT2                    PIC X(1).

         05  WS-IO-STATUS.
           10  WS-IO-STAT1                         PIC X(1).
           10  WS-IO-STAT2                         PIC X(1).

         05  WS-TWO-BYTES.
           10  WS-TWO-BYTES-LEFT                   PIC X(1).
           10  WS-TWO-BYTES-RIGHT                  PIC X(1).
         05 WS-TWO-BYTES-BINARY REDEFINES WS-TWO-BYTES
                                                   PIC 9(1) COMP.

         05  WS-RECORD-COUNTER1                    PIC 9(5)
             VALUE ZERO.
         05  WS-RECORD-COUNTER2                    PIC 9(5)
             VALUE ZERO.

         05  WS-LAST-PID                           PIC X(5)
             VALUE LOW-VALUES.

       01  WS-ZBNKRPC1-FIELDS.
         05  WS-ZBNKRPC1-REQUESTED                 PIC X(1)
             VALUE LOW-VALUES.
           88  RPC-REQUESTED                       VALUE 'Y'.
         05  WS-ZBNKRPC1-PGM                       PIC X(8)
             VALUE SPACES.
         05  WS-ZBNKRPC1-IND                       PIC X(1)
             VALUE LOW-VALUES.
         05  WS-ZBNKRPC1-DATA.
           10  WS-ZBNKRPC1-DATA-PT1                PIC X(80).
           10  WS-ZBNKRPC1-DATA-PT2                PIC X(80).

       01  WS-DATA-REPOSITORY.
         05  WS-DATA-ACCESS                        PIC X(3).
           88  DATA-ACCESS-DLI                     VALUE 'DLI'.
           88  DATA-ACCESS-SQL                     VALUE 'SQL'.
           88  DATA-ACCESS-VSM                     VALUE 'VSM'.
         05  WS-DATA-ACCESS-SQL-TYPE               PIC X(3).
           88  SQL-ACCESS-DB2                      VALUE 'DB2'.
           88  SQL-ACCESS-XDB                      VALUE 'XDB'.

       01  WS-CONSOLE-MESSAGE                      PIC X(60).

       01  WS-EXEC-PARM.
         05  WS-EXEC-PARM-LL                       PIC S9(4) COMP.
         05  WS-EXEC-PARM-DATA                     PIC X(12).

       01  WS-PARM-PTR                             POINTER.

       01  WS-COMMAREA.
       COPY CIOFUNCS.
       COPY CBANKD51.
       COPY CBANKD52.

       COPY CABENDD.

       COPY CIMSCONS.

       COPY CIMSAIB.

       01  WS-ENV-AREA                             PIC X(200).
       01  WS-ENV-AREA-R REDEFINES WS-ENV-AREA.
         05  WS-ENVIRON-DATA                       PIC X(100).
         05  WS-ENV-DATA REDEFINES WS-ENVIRON-DATA.
           10  WS-ENV-ID                           PIC X(8).
           10  WS-ENV-REL                          PIC X(4).
           10  WS-ENV-CTLTYPE                      PIC X(8).
           10  WS-ENV-APPTYPE                      PIC X(8).
           10  WS-ENV-RGNID                        PIC X(4).
           10  WS-ENV-APPNAME                      PIC X(8).
           10  WS-ENV-PSBNAME                      PIC X(8).
           10  WS-ENV-TRNNAME                      PIC X(8).
           10  WS-ENV-UID                          PIC X(8).
           10  WS-ENV-GRPNAME                      PIC X(8).
           10  WS-ENV-STATUS                       PIC X(4).
           10  WS-ENV-RECTOK                       POINTER.
           10  WS-ENV-ADDRPRM                      POINTER.
           10  WS-ENV-SHRQ                         PIC X(4).
           10  WS-ENV-UADS                         PIC X(8).
           10  WS-ENV-UIND                         PIC X(4).
         05  WS-RECOVER-TOKEN                      PIC X(18).

       LINKAGE SECTION.
       01  LK-EXEC-PARM.
         05  LK-EXEC-PARM-LL                       PIC S9(4) COMP.
         05  LK-EXEC-PARM-DATA                     PIC X(32).

       PROCEDURE DIVISION USING LK-EXEC-PARM.
      *****************************************************************
      * Perform RUN-TIME to initialse time and display start time     *
      *****************************************************************
           PERFORM RUN-TIME.


      *****************************************************************
      * EXEC-CARD processing is slightly different from normal MVS    *
      * processing in that we check the pointer (or address) of the   *
      * parm area first. This is so that we can migrate it to         *
      * distributed (Windows/Unix) environment wihout change.         *
      *****************************************************************
           MOVE ZEROES TO WS-EXEC-PARM-LL.
           MOVE SPACES TO WS-EXEC-PARM-DATA.

           SET WS-PARM-PTR TO ADDRESS OF LK-EXEC-PARM.
           IF WS-PARM-PTR IS NOT EQUAL TO NULL
              MOVE LK-EXEC-PARM-LL TO WS-EXEC-PARM-LL
              IF WS-EXEC-PARM-LL IS GREATER THAN
                   LENGTH OF WS-EXEC-PARM-DATA
                 MOVE LENGTH OF WS-EXEC-PARM-DATA TO WS-EXEC-PARM-LL
              END-IF
              IF WS-EXEC-PARM-LL IS GREATER THAN ZERO
                 MOVE LK-EXEC-PARM-DATA (1:WS-EXEC-PARM-LL)
                   TO WS-EXEC-PARM-DATA (1:WS-EXEC-PARM-LL)
              END-IF
           END-IF.

           IF WS-EXEC-PARM-LL IS EQUAL TO ZERO
              MOVE 'No exec card parm present'
                TO WS-CONSOLE-MESSAGE
              PERFORM DISPLAY-CONSOLE-MESSAGE
              MOVE '  Selecting all records'
                TO WS-CONSOLE-MESSAGE
              PERFORM DISPLAY-CONSOLE-MESSAGE
              MOVE 3 TO WS-EXEC-PARM-LL
              MOVE 'ALL' TO WS-EXEC-PARM-DATA
           ELSE
             MOVE SPACES TO WS-CONSOLE-MESSAGE
             STRING 'Exec parm is "' DELIMITED BY SIZE
                    WS-EXEC-PARM-DATA (1:WS-EXEC-PARM-LL)
                      DELIMITED BY SIZE
                    '"' DELIMITED BY SIZE
               INTO WS-CONSOLE-MESSAGE
             PERFORM DISPLAY-CONSOLE-MESSAGE
             MOVE SPACES TO WS-CONSOLE-MESSAGE
             STRING '  Selecting records for ' DELIMITED BY SIZE
                    WS-EXEC-PARM-DATA (1:WS-EXEC-PARM-LL)
                      DELIMITED BY SIZE
                    ' only' DELIMITED BY SIZE
               INTO WS-CONSOLE-MESSAGE
             PERFORM DISPLAY-CONSOLE-MESSAGE
           END-IF.
           INSPECT WS-EXEC-PARM-DATA (1:WS-EXEC-PARM-LL)
             CONVERTING 'abcdefghijklmnopqrstuvwxyz'
                     TO 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.

      *****************************************************************
      * Check to see if we want to demonstrate ES calling a module    *
      * that resides on the mainframe.                                *
      *****************************************************************
           IF RPC-REQUESTED
              PERFORM RPC-PROCESS
           END-IF.

      *****************************************************************
      * Open our output file                                          *
      *****************************************************************
           PERFORM EXTRACT-OPEN.

      *****************************************************************
      * Open the customer details input then read the data and create *
      * output records as appropriate.                                *
      *****************************************************************
           PERFORM SOURCE1-OPEN.
           PERFORM UNTIL IO-REQUEST-STATUS-EOF
             IF NOT IO-REQUEST-STATUS-EOF
                PERFORM SOURCE1-READ
                IF IO-REQUEST-STATUS-OK
                   ADD 1 TO WS-RECORD-COUNTER1
                   IF WS-RECORD-COUNTER1 IS LESS THAN 6
                      MOVE WS-COMMAREA TO WS-CONSOLE-MESSAGE
                      PERFORM DISPLAY-CONSOLE-MESSAGE
                   ELSE
                      IF WS-RECORD-COUNTER2 IS EQUAL TO 6
                         MOVE 'Suppressing record display...'
                            TO WS-CONSOLE-MESSAGE
                         PERFORM DISPLAY-CONSOLE-MESSAGE
                      END-IF
                   END-IF

                   IF CD51O-PID IS NOT EQUAL TO WS-LAST-PID
                      MOVE SPACES TO BANKXT01-REC0
                      MOVE '0' TO BANKXT01-0-TYPE
                      MOVE CD51O-PID TO BANKXT01-1-PID
                      MOVE CD51O-NAME TO BANKXT01-0-NAME
                      MOVE CD51O-EMAIL TO BANKXT01-0-EMAIL
                      PERFORM EXTRACT-PUT
                      MOVE SPACES TO BANKXT01-REC1
                      MOVE '1' TO BANKXT01-1-TYPE
                      MOVE CD51O-PID TO BANKXT01-1-PID
                      MOVE CD51O-NAME TO BANKXT01-1-NAME
                      MOVE CD51O-ADDR1 TO BANKXT01-1-ADDR1
                      MOVE CD51O-ADDR2 TO BANKXT01-1-ADDR2
                      MOVE CD51O-STATE TO BANKXT01-1-STATE
                      MOVE CD51O-CNTRY TO BANKXT01-1-CNTRY
                      MOVE CD51O-POST-CODE TO BANKXT01-1-PST-CDE
                      PERFORM EXTRACT-PUT
                      MOVE CD51O-PID TO WS-LAST-PID
                   END-IF
                   MOVE SPACES TO BANKXT01-REC2
                   MOVE '2' TO BANKXT01-2-TYPE
                   MOVE CD51O-PID TO BANKXT01-2-PID
                   MOVE CD51O-ACC-NO TO BANKXT01-2-ACC-NO
                   MOVE CD51O-ACC-DESC TO BANKXT01-2-ACC-DESC
                   MOVE CD51O-ACC-CURR-BAL TO BANKXT01-2-ACC-CURR-BAL
                   MOVE CD51O-ACC-LAST-STMT-DTE
                     TO BANKXT01-2-ACC-LAST-STMT-DTE
                   MOVE CD51O-ACC-LAST-STMT-BAL
                     TO BANKXT01-2-ACC-LAST-STMT-BAL
                   PERFORM EXTRACT-PUT
                END-IF
             END-IF
           END-PERFORM.
           PERFORM SOURCE1-CLOSE.

      *****************************************************************
      * Open the transactions details file then read the data and     *
      * create output records as appropriate.                         *
      *****************************************************************
           PERFORM SOURCE2-OPEN.
           PERFORM UNTIL IO-REQUEST-STATUS-EOF
             IF NOT IO-REQUEST-STATUS-EOF
                PERFORM SOURCE2-READ
                IF IO-REQUEST-STATUS-OK
                   ADD 1 TO WS-RECORD-COUNTER2
                   IF WS-RECORD-COUNTER2 IS LESS THAN 6
                      MOVE WS-COMMAREA TO WS-CONSOLE-MESSAGE
                      PERFORM DISPLAY-CONSOLE-MESSAGE
                   ELSE
                      IF WS-RECORD-COUNTER2 IS EQUAL TO 6
                         MOVE 'Suppressing record display...'
                            TO WS-CONSOLE-MESSAGE
                         PERFORM DISPLAY-CONSOLE-MESSAGE
                      END-IF
                   END-IF

                   MOVE SPACES TO BANKXT01-REC3
                   MOVE '3' TO BANKXT01-3-TYPE
                   MOVE CD52O-PID TO BANKXT01-3-PID
                   MOVE CD52O-ACC-NO TO BANKXT01-2-ACC-NO
                   MOVE CD52O-AMOUNT TO BANKXT01-3-AMOUNT
                   MOVE CD52O-TIMESTAMP TO BANKXT01-3-TIMESTAMP
                   MOVE CD52O-DESC TO BANKXT01-3-DESC
                   PERFORM EXTRACT-PUT
                END-IF
             END-IF
           END-PERFORM.
           PERFORM SOURCE2-CLOSE.

      *****************************************************************
      * Close our output file                                         *
      *****************************************************************
           PERFORM EXTRACT-CLOSE.

      *****************************************************************
      * Display messages to show what we created                      *
      *****************************************************************
           MOVE 'SOURCE data has been extracted'
             TO WS-CONSOLE-MESSAGE.
           PERFORM DISPLAY-CONSOLE-MESSAGE.
           MOVE SPACES TO WS-CONSOLE-MESSAGE.
           STRING WS-RECORD-COUNTER1 DELIMITED BY SIZE
                  ' from SOURCE1 (Customer details)'
                    DELIMITED BY SIZE
             INTO WS-CONSOLE-MESSAGE.
           PERFORM DISPLAY-CONSOLE-MESSAGE.
           MOVE SPACES TO WS-CONSOLE-MESSAGE.
           STRING WS-RECORD-COUNTER2 DELIMITED BY SIZE
                  ' from SOURCE2 (Transactions)'
                    DELIMITED BY SIZE
             INTO WS-CONSOLE-MESSAGE.
           PERFORM DISPLAY-CONSOLE-MESSAGE.
           MOVE 'End Of Job'
             TO WS-CONSOLE-MESSAGE.
           PERFORM DISPLAY-CONSOLE-MESSAGE.

      *****************************************************************
      * Perform RUN-TIME to calculate run time and display end time   *
      *****************************************************************
           PERFORM RUN-TIME.

      *****************************************************************
      * Step return code and return                                   *
      *****************************************************************
           MOVE 0 TO RETURN-CODE.

           GOBACK.

      *****************************************************************
      * Open the source file                                          *
      *****************************************************************
       SOURCE1-OPEN.
           MOVE SPACES TO WS-COMMAREA.
           MOVE WS-EXEC-PARM-DATA TO CD51I-PID.
           SET IO-REQUEST-FUNCTION-OPEN TO TRUE.
           CALL 'DBANK51P' USING WS-COMMAREA.
           IF IO-REQUEST-STATUS-OK
              MOVE 'SOURCE1 (Customer details) file opened OK'
                TO WS-CONSOLE-MESSAGE
              PERFORM DISPLAY-CONSOLE-MESSAGE
           ELSE
              MOVE 'SOURCE1 (Customer details) file open failure...'
                TO WS-CONSOLE-MESSAGE
              PERFORM DISPLAY-CONSOLE-MESSAGE
              PERFORM ABORT-PROGRAM
              END-IF.
       SOURCE2-OPEN.
           MOVE SPACES TO WS-COMMAREA.
           MOVE WS-EXEC-PARM-DATA TO CD52I-PID.
           SET IO-REQUEST-FUNCTION-OPEN TO TRUE.
           CALL 'DBANK52P' USING WS-COMMAREA.
           IF IO-REQUEST-STATUS-OK
              MOVE 'SOURCE2 (Transactions) file opened OK'
                TO WS-CONSOLE-MESSAGE
              PERFORM DISPLAY-CONSOLE-MESSAGE
           ELSE
              MOVE 'SOURCE2 (Transactions) file open failure...'
                TO WS-CONSOLE-MESSAGE
              PERFORM DISPLAY-CONSOLE-MESSAGE
              PERFORM ABORT-PROGRAM
              END-IF.

      *****************************************************************
      * Read a record from the source file                            *
      *****************************************************************
       SOURCE1-READ.
           MOVE SPACES TO WS-COMMAREA.
           MOVE WS-EXEC-PARM-DATA TO CD51I-PID.
           SET IO-REQUEST-FUNCTION-READ TO TRUE.
           CALL 'DBANK51P' USING WS-COMMAREA.
           IF IO-REQUEST-STATUS-ERROR
              MOVE 'SOURCE1 (Customer details) Error reading file ...'
                TO WS-CONSOLE-MESSAGE
               PERFORM DISPLAY-CONSOLE-MESSAGE
               PERFORM ABORT-PROGRAM
           END-IF.
       SOURCE2-READ.
           MOVE SPACES TO WS-COMMAREA.
           MOVE WS-EXEC-PARM-DATA TO CD52I-PID.
           SET IO-REQUEST-FUNCTION-READ TO TRUE.
           CALL 'DBANK52P' USING WS-COMMAREA.
           IF IO-REQUEST-STATUS-ERROR
              MOVE 'SOURCE2 (Transactions) Error reading file ...'
                TO WS-CONSOLE-MESSAGE
               PERFORM DISPLAY-CONSOLE-MESSAGE
               PERFORM ABORT-PROGRAM
           END-IF.

      *****************************************************************
      * Close the source file.                                        *
      *****************************************************************
       SOURCE1-CLOSE.
           MOVE SPACES TO WS-COMMAREA.
           MOVE WS-EXEC-PARM-DATA TO CD51I-PID.
           SET IO-REQUEST-FUNCTION-CLOSE TO TRUE.
           CALL 'DBANK51P' USING WS-COMMAREA.
           IF IO-REQUEST-STATUS-ERROR
              MOVE 'SOURCE1 (Customer details) Error closing file ...'
                TO WS-CONSOLE-MESSAGE
               PERFORM DISPLAY-CONSOLE-MESSAGE
               PERFORM ABORT-PROGRAM
           END-IF.
       SOURCE2-CLOSE.
           MOVE SPACES TO WS-COMMAREA.
           MOVE WS-EXEC-PARM-DATA TO CD52I-PID.
           SET IO-REQUEST-FUNCTION-CLOSE TO TRUE.
           CALL 'DBANK52P' USING WS-COMMAREA.
           IF IO-REQUEST-STATUS-ERROR
              MOVE 'SOURCE2 (Transactions) Error closing file ...'
                TO WS-CONSOLE-MESSAGE
               PERFORM DISPLAY-CONSOLE-MESSAGE
               PERFORM ABORT-PROGRAM
           END-IF.

      *****************************************************************
      * Open the seqential extract file as output                     *
      *****************************************************************
       EXTRACT-OPEN.
           OPEN OUTPUT EXTRACT-FILE.
           IF WS-EXTRACT-STATUS = '00'
              MOVE 'EXTRACT file opened OK'
                TO WS-CONSOLE-MESSAGE
              PERFORM DISPLAY-CONSOLE-MESSAGE
           ELSE
              MOVE 'EXTRACT file open failure...'
                TO WS-CONSOLE-MESSAGE
              PERFORM DISPLAY-CONSOLE-MESSAGE
              MOVE WS-EXTRACT-STATUS TO WS-IO-STATUS
              PERFORM DISPLAY-IO-STATUS
              PERFORM ABORT-PROGRAM
              END-IF.

      *****************************************************************
      * Write a record to the squential file                          *
      *****************************************************************
       EXTRACT-PUT.
           IF BANKXT01-1-TYPE IS EQUAL TO '0'
              WRITE BANKXT01-REC0
           END-IF.
           IF BANKXT01-1-TYPE IS EQUAL TO '1'
              WRITE BANKXT01-REC1
           END-IF.
           IF BANKXT01-2-TYPE IS EQUAL TO '2'
              WRITE BANKXT01-REC2
           END-IF.
           IF BANKXT01-3-TYPE IS EQUAL TO '3'
              WRITE BANKXT01-REC3
           END-IF.
           IF WS-EXTRACT-STATUS NOT = '00'
              MOVE 'EXTRACT Error Writing file ...'
                TO WS-CONSOLE-MESSAGE
              PERFORM DISPLAY-CONSOLE-MESSAGE
              MOVE WS-EXTRACT-STATUS TO WS-IO-STATUS
              PERFORM DISPLAY-IO-STATUS
              PERFORM ABORT-PROGRAM
           END-IF.

      *****************************************************************
      * Close the seqential extract file                              *
      *****************************************************************
       EXTRACT-CLOSE.
           CLOSE EXTRACT-FILE.
           IF WS-EXTRACT-STATUS = '00'
              MOVE 'EXTRACT file closed OK'
                TO WS-CONSOLE-MESSAGE
              PERFORM DISPLAY-CONSOLE-MESSAGE
           ELSE
              MOVE 'EXTRACT file close failure...'
                TO WS-CONSOLE-MESSAGE
              PERFORM DISPLAY-CONSOLE-MESSAGE
              MOVE WS-EXTRACT-STATUS TO WS-IO-STATUS
              PERFORM DISPLAY-IO-STATUS
              PERFORM ABORT-PROGRAM
           END-IF.

      *****************************************************************
      * Display the file status bytes. This routine will display as   *
      * two digits if the full two byte file status is numeric. If    *
      * second byte is non-numeric then it will be treated as a       *
      * binary number.                                                *
      *****************************************************************
       DISPLAY-IO-STATUS.
           IF WS-IO-STATUS NUMERIC
              MOVE SPACE TO WS-CONSOLE-MESSAGE
              STRING 'File status -' DELIMITED BY SIZE
                     WS-IO-STATUS DELIMITED BY SIZE
                INTO WS-CONSOLE-MESSAGE
              PERFORM DISPLAY-CONSOLE-MESSAGE
           ELSE
              SUBTRACT WS-TWO-BYTES-BINARY FROM WS-TWO-BYTES-BINARY
              MOVE WS-IO-STAT2 TO WS-TWO-BYTES-RIGHT
              MOVE SPACE TO WS-CONSOLE-MESSAGE
              STRING 'File status -' DELIMITED BY SIZE
                     WS-IO-STAT1 DELIMITED BY SIZE
                     '/' DELIMITED BY SIZE
                     WS-TWO-BYTES DELIMITED BY SIZE
                INTO WS-CONSOLE-MESSAGE
              PERFORM DISPLAY-CONSOLE-MESSAGE
           END-IF.

      *****************************************************************
      * 'ABORT' the program.                                          *
      * Post a message to the console and issue a STOP RUN            *
      *****************************************************************
       ABORT-PROGRAM.
           IF WS-CONSOLE-MESSAGE NOT = SPACES
              PERFORM DISPLAY-CONSOLE-MESSAGE
           END-IF.
           MOVE 'Program is abending...'  TO WS-CONSOLE-MESSAGE.
           PERFORM DISPLAY-CONSOLE-MESSAGE.
           MOVE 16 TO RETURN-CODE.
           GOBACK.

      *****************************************************************
      * This process will attempt to call a small module which is     *
      * meant toreside on th emainframe                               *
      *****************************************************************
       RPC-PROCESS.
           MOVE '0' TO WS-ZBNKRPC1-IND.
           MOVE LOW-VALUES TO WS-ZBNKRPC1-DATA-PT1.
           MOVE HIGH-VALUES TO WS-ZBNKRPC1-DATA-PT2.
           MOVE 'ZBNKRPC1' TO WS-ZBNKRPC1-PGM.
           CALL WS-ZBNKRPC1-PGM USING WS-ZBNKRPC1-DATA
             ON EXCEPTION
               MOVE '1' TO WS-ZBNKRPC1-IND
           END-CALL.
           IF WS-ZBNKRPC1-IND IS EQUAL TO '1'
              MOVE 'Call to ZBNKRPC1 failed. Program not found.'
                TO WS-CONSOLE-MESSAGE
              PERFORM DISPLAY-CONSOLE-MESSAGE
           ELSE
              IF WS-ZBNKRPC1-DATA-PT1 IS EQUAL TO LOW-VALUES AND
                 WS-ZBNKRPC1-DATA-PT2 IS EQUAL TO HIGH-VALUES
                 MOVE 'Call to ZBNKRPC1 was to a stub program.'
                   TO WS-CONSOLE-MESSAGE
                 PERFORM DISPLAY-CONSOLE-MESSAGE
                 MOVE 'Passed data area was unchanged.'
                   TO WS-CONSOLE-MESSAGE
                 PERFORM DISPLAY-CONSOLE-MESSAGE
              ELSE
                 MOVE WS-ZBNKRPC1-DATA-PT1 TO WS-CONSOLE-MESSAGE
                 PERFORM DISPLAY-CONSOLE-MESSAGE
                 MOVE WS-ZBNKRPC1-DATA-PT2 TO WS-CONSOLE-MESSAGE
                 PERFORM DISPLAY-CONSOLE-MESSAGE
              END-IF
           END-IF.

      *****************************************************************
      * Display CONSOLE messages...                                   *
      *****************************************************************
       DISPLAY-CONSOLE-MESSAGE.
           DISPLAY WS-PROGRAM-ID ' - ' WS-CONSOLE-MESSAGE.
           DISPLAY WS-PROGRAM-ID ' - ' WS-CONSOLE-MESSAGE
             UPON CONSOLE.
           MOVE ALL SPACES TO WS-CONSOLE-MESSAGE.

      *COPY CTIMERP.
       RUN-TIME.
           IF TIMER-START IS EQUAL TO ZERO
              ACCEPT TIMER-START FROM TIME
              MOVE 'Timer started' TO WS-CONSOLE-MESSAGE
              PERFORM DISPLAY-CONSOLE-MESSAGE
           ELSE
              ACCEPT TIMER-END FROM TIME
              MOVE 'Timer stopped' TO WS-CONSOLE-MESSAGE
              PERFORM DISPLAY-CONSOLE-MESSAGE
              COMPUTE TIMER-ELAPSED =
                        ((TIMER-END-HH * 60 * 60 * 100) +
                         (TIMER-END-MM * 60 * 100) +
                         (TIMER-END-SS * 100) +
                          TIMER-END-DD) -
                        ((TIMER-START-HH * 60 * 60 * 100) +
                         (TIMER-START-MM * 60 * 100) +
                         (TIMER-START-SS * 100) +
                          TIMER-START-DD)
              MOVE TIMER-ELAPSED-R TO TIMER-RUN-TIME-ELAPSED
              MOVE TIMER-RUN-TIME TO WS-CONSOLE-MESSAGE
              PERFORM DISPLAY-CONSOLE-MESSAGE
           END-IF.


      * $ Version 5.99c sequenced on Wednesday 3 Mar 2011 at 1:00pm
