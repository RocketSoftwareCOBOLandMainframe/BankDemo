      $set dialect(entcobol)
       IDENTIFICATION DIVISION.
       PROGRAM-ID. JVMBNKF.
      *
      * COBOL bootstrap for Java BankAcctFilter via interop CALL.
      * Demonstrates passing parameters from JCL PARM to Java
      * using the COBOL-to-Java CALL mechanism.
      *
      * The Java class is invoked with the dataset and filter
      * pattern. Alternative to using JVMLDM directly when COBOL
      * pre-processing or condition checking is needed.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-DATASET         PIC X(44)
                             VALUE 'MFI01V.MFIDEMO.BNKACC'.
       01 WS-FILTER          PIC X(80)
                             VALUE '.*'.
       01 WS-RETURN-CODE     PIC 9(4) VALUE 0.

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           DISPLAY "JVMBNKF: Starting bank account filter..."
           DISPLAY "JVMBNKF: Dataset=" WS-DATASET
           DISPLAY "JVMBNKF: Filter=" WS-FILTER

           CALL "Java.BankAcctFilter.main"
               ON EXCEPTION
                   DISPLAY "JVMBNKF: Java call FAILED."
                   MOVE 16 TO RETURN-CODE
               NOT ON EXCEPTION
                   DISPLAY "JVMBNKF: Java call succeeded."
           END-CALL

           DISPLAY "JVMBNKF: Processing complete. RC="
                   RETURN-CODE
           GOBACK
           .
       END PROGRAM JVMBNKF.
