//HELLOJAV JOB CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1)
//*
//* Demonstration: COBOL bootstrap calling Java.
//* The COBOL program HELLOJAV calls Java.HelloBatch.run()
//*
//* DD Allocations:
//*   SYSOUT   - COBOL DISPLAY output
//*   STDOUT   - Java System.out (redirected stream)
//*   STDERR   - Java System.err (redirected stream)
//*   STDIN    - Java System.in  (redirected stream, optional)
//*
//STEP1    EXEC PGM=HELLOJAV
//STEPLIB  DD  DSN=LOADLIB,DISP=SHR
//STDOUT   DD  SYSOUT=*
//STDERR   DD  SYSOUT=*
//CEEOPTS  DD *
ENVAR("ESOS_TEST_VAR=HELLO_FROM_ESOS")
/*
//