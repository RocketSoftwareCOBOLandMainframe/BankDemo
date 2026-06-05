      $set dialect(entcobol)
       IDENTIFICATION DIVISION.
       PROGRAM-ID. HELLOJAV.
      *
      * Simple demonstration of calling a Java class from COBOL.
      * The Java class HelloBatch.run() is invoked using the
      * Enterprise Server Java interoperability mechanism.
      *
       PROCEDURE DIVISION.
           CALL "Java.HelloBatch.run"
               ON EXCEPTION
                   DISPLAY "COBOL: Java call FAILED."
                   MOVE 16 to RETURN-CODE
               NOT ON EXCEPTION
                   DISPLAY "COBOL: Java call succeeded."
           END-CALL
           GOBACK
           .
       END PROGRAM HELLOJAV.
