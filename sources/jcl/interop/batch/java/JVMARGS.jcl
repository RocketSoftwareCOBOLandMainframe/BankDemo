//JVMARGS  JOB 'MAINARGS-DEMO',CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1)
//*-------------------------------------------------------------------*
//* Demonstrate MAINARGS DD passing complex arguments to Java.
//* Uses inline JVM procedure with STDENV and MAINARGS.
//*
//* This pattern mirrors the IBM JZOS Batch Launcher approach:
//*   - JAVACLS symbolic specifies the Java class
//*   - STDENV DD configures the JVM environment inline
//*   - MAINARGS DD passes arguments to Java main()
//*-------------------------------------------------------------------*
//*
//********************************************************************
//* Inline JVM procedure
//********************************************************************
//JVMPROC PROC JAVACLS=,
//             ARGS='',
//             VERSION='',
//             LOGLVL='+I',
//             REGSIZE='0M',
//             LEPARM=''
//JAVAJVM  EXEC PGM=JVMLDM&VERSION,REGION=&REGSIZE,
//             PARM='&LEPARM/&LOGLVL &JAVACLS &ARGS'
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//STDOUT   DD SYSOUT=*
//STDERR   DD SYSOUT=*
//CEEDUMP  DD SYSOUT=*
//ABNLIGNR DD DUMMY
//         PEND
//********************************************************************
//*
//STEP00   EXEC PROC=JVMPROC,
//             JAVACLS='MainArgsDemo',
//             ARGS=''
//*
//* Environment configuration (inline) - equivalent to STDENV script
//STDENV DD *
set JAVA_HOME=C:\Program Files (x86)\Rocket Software\^
Enterprise Developer\AdoptOpenJDK
set PATH=%JAVA_HOME%\bin\server;%PATH%
set CLASSPATH=%ESP%\loadlib;%CLASSPATH%
/*
//*
//* Passing arguments to the Java main() method via MAINARGS DD.
//* JVMLDM parses quoted strings as individual arguments.
//MAINARGS DD *
'Test string 1' 'T[e].+[0-9]' '--verbose'
/*
//
