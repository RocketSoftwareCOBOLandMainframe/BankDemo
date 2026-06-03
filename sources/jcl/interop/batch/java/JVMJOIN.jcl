//JVMJOIN JOB 'CUST-JOIN',CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1)
//*-------------------------------------------------------------------*
//* STEP 7: Customer-Account Join Report
//*-------------------------------------------------------------------*
//* Demonstrates opening MULTIPLE ZFile DDs in a single Java step
//* to perform an in-memory join across two VSAM datasets.
//*
//* Java reads the Customer file (CUSTDATA) and the Account file
//* (ACCTDATA) simultaneously, joins on Customer PID, and produces
//* a consolidated report showing each customer with their accounts
//* and balances — something that would require SORT/MERGE or a
//* complex COBOL program in a traditional batch environment.
//*
//* Key JVMLDM features demonstrated:
//*   - Multiple ZFile instances open concurrently
//*   - COMP-3 (packed decimal) field decoding in Java
//*   - HashMap-based in-memory join logic
//*   - Control-card driven output format (CSV vs REPORT)
//*   - Conditional return codes (RC=0 success, RC=4 warnings)
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
//STEP01   EXEC PROC=JVMPROC,
//             JAVACLS='BankCustJoin',
//             ARGS=''
//*
//STDENV DD *
set JAVA_HOME=C:\Program Files (x86)\Rocket Software\^
Enterprise Developer\AdoptOpenJDK
set PATH=%JAVA_HOME%\bin\server;%PATH%
set CLASSPATH=%ESP%\loadlib;%CLASSPATH%
/*
//*
//* Control cards: OUTPUT_FORMAT = REPORT | CSV | SUMMARY
//*                MIN_BALANCE   = minimum balance filter (cents)
//*                INCLUDE_EMPTY = Y to include customers with no accts
//STDIN DD *
OUTPUT_FORMAT=REPORT
MIN_BALANCE=0
INCLUDE_EMPTY=N
/*
//*
//* Two dataset DDs opened concurrently by the Java program
//CUSTDATA DD DSN=MFI01V.MFIDEMO.BNKCUST,DISP=SHR
//ACCTDATA DD DSN=MFI01V.MFIDEMO.BNKACC,DISP=SHR
//
