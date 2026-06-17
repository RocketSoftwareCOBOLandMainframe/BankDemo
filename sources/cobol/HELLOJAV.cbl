      $set dialect(entcobol)
      *
      * Simple demonstration of calling a Java class from COBOL.
      * The Java class HelloBatch.run() is invoked using the
      * Enterprise Server Java interoperability mechanism.
      *
       procedure division.
           call "Java.HelloBatch.run"
           display "COBOL: Java call succeeded."
           goback
           .
