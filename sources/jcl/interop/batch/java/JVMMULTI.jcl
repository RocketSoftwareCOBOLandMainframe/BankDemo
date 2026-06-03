//JVMMULTI JOB 'MULTI-STEP',CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1)
//*-------------------------------------------------------------------*
//* Multi-step JCL demonstrating various JVMLDM invocation patterns.
//* Shows how to chain multiple Java steps in a single job using
//* an inline JVM procedure with different configurations.
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
//*-------------------------------------------------------------------*
//* STEP 1: Filter accounts using regex from MAINARGS
//*-------------------------------------------------------------------*
//STEP01   EXEC PROC=JVMPROC,
//             JAVACLS='BankAcctFilter',
//             ARGS=''
//STDENV DD *
set JAVA_HOME=C:\Program Files (x86)\Rocket Software\^
Enterprise Developer\AdoptOpenJDK
set PATH=%JAVA_HOME%\bin\server;%PATH%
set CLASSPATH=%ESP%\loadlib;%CLASSPATH%
/*
//MAINARGS DD *
'MFI01V.MFIDEMO.BNKACC' '0000[1-5]'
/*
//ACCDATA DD DSN=MFI01V.MFIDEMO.BNKACC,DISP=SHR
//*
//*-------------------------------------------------------------------*
//* STEP 2: Generate transaction report with control cards
//*-------------------------------------------------------------------*
//STEP02   EXEC PROC=JVMPROC,
//             JAVACLS='BankTxnReport',
//             ARGS=''
//STDENV DD *
set JAVA_HOME=C:\Program Files (x86)\Rocket Software\^
Enterprise Developer\AdoptOpenJDK
set PATH=%JAVA_HOME%\bin\server;%PATH%
set CLASSPATH=%ESP%\loadlib;%CLASSPATH%
/*
//STDIN DD *
REPORT_TITLE=Daily Batch Run - Filtered Transactions
MAX_RECORDS=25
/*
//TXNDATA DD DSN=MFI01V.MFIDEMO.BNKTXN,DISP=SHR
//*
//*-------------------------------------------------------------------*
//* STEP 3: Simple MAINARGS demonstration with verbose flag
//*-------------------------------------------------------------------*
//STEP03   EXEC PROC=JVMPROC,
//             JAVACLS='MainArgsDemo',
//             ARGS='',
//             LOGLVL='+T'
//STDENV DD *
set JAVA_HOME=C:\Program Files (x86)\Rocket Software\^
Enterprise Developer\AdoptOpenJDK
set PATH=%JAVA_HOME%\bin\server;%PATH%
set CLASSPATH=%ESP%\loadlib;%CLASSPATH%
/*
//MAINARGS DD *
'BatchStep3Data' 'Batch.+[0-9]' '--verbose'
/*
//
