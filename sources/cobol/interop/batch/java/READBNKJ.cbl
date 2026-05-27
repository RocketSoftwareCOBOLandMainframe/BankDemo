      $set dialect(entcobol)
       IDENTIFICATION DIVISION.
       PROGRAM-ID. READBNKJ.
      *
      * Invokes the Java class ReadBankData to read account
      * information from a dataset allocated via JCL DD.
      *
       PROCEDURE DIVISION.
           DISPLAY "Reading bank data via Java..."

           CALL "Java.ReadBankData.run"
               ON EXCEPTION
                   DISPLAY "ERROR: Java call failed."
                   MOVE 16 TO RETURN-CODE
               NOT ON EXCEPTION
                   DISPLAY "Java processing complete."
           END-CALL

           GOBACK
           .
       END PROGRAM READBNKJ.
