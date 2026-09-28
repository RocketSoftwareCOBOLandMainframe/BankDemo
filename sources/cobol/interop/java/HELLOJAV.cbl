      $set FCDCAT
      $set outdd"SYSOUT"
      *
      * Simple demonstration of calling a Java class from COBOL.
      * The Java class HelloBatch.run() is invoked using the
      * Enterprise Server Java interoperability mechanism.
      *
       identification division.
       program-id. HELLOJAV.

       procedure division.
           call "Java.HelloBatch.run"
           display "COBOL: Java call succeeded."
           goback
           .
