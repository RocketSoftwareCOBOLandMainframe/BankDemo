//JVMDEMO  JOB CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1)
//*
//* Invoke Java class directly using JVMLDM (64-bit).
//* JVMLDM86 creates the JVM, executes STDENV to configure the
//* environment, then runs the Java class specified in PARM.
//*
//* PARM format: [loglevel] <classname|-jar filename> [args]
//*
//STEP1    EXEC PGM=JVMLDM86,
//         PARM='BatchReport arg1 arg2'
//STEPLIB  DD  DSN=LOADLIB,DISP=SHR
//STDENV   DD  DSN=CONFIG(STDENV),DISP=SHR
//SYSPRINT DD  SYSOUT=*
//SYSOUT   DD  SYSOUT=*
//*
//* --- Stream redirection DDs ---
//STDOUT   DD  SYSOUT=*
//STDERR   DD  SYSOUT=*
//STDIN    DD  DUMMY
//
