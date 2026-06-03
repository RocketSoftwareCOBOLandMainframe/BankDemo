//JVMFILT  JOB 'BANK-FILTER',CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1)
//*-------------------------------------------------------------------*
//* Filter bank account data using Java via JVMLDM procedure.
//* Demonstrates:
//*   - Inline JVM procedure
//*   - Inline STDENV DD for JVM configuration
//*   - MAINARGS DD to pass dataset name and regex filter
//*   - Application DD (ACCDATA) for ZFile dataset access
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
//             JAVACLS='BankAcctFilter',
//             ARGS=''
//*
//* Environment configuration required for interop
//STDENV DD *
set JAVA_HOME=C:\Program Files (x86)\Rocket Software\^
Enterprise Developer\AdoptOpenJDK
set PATH=%JAVA_HOME%\bin\server;%PATH%
set CLASSPATH=%ESP%\loadlib;%CLASSPATH%
set JZOS_JVM_OPTIONS=-Dfile.encoding=ISO-8859-1
/*
//*
//* Arguments to Java main(): dataset name and regex filter pattern
//MAINARGS DD *
'MFI01V.MFIDEMO.BNKACC' '[0-9]{5}'
/*
//*
//* Application DD - dataset opened by Java via ZFile
//ACCDATA DD DSN=MFI01V.MFIDEMO.BNKACC,DISP=SHR
//
