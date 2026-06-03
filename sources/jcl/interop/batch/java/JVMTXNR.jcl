//JVMTXNR JOB 'TXN-REPORT',CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1)
//*-------------------------------------------------------------------*
//* Generate a bank transaction report using Java via JVMLDM.
//* Demonstrates:
//*   - Inline JVM procedure
//*   - Inline STDENV with JVM options (3164 interoperability)
//*   - STDIN DD for control card parameters
//*   - TXNDATA DD for application dataset access
//*   - Multi-DD pattern combining system and application DDs
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
//             JAVACLS='BankTxnReport',
//             ARGS=''
//*
//* Environment configuration with JVM options
//STDENV DD *
set JAVA_HOME=C:\Program Files (x86)\Rocket Software\^
Enterprise Developer\AdoptOpenJDK
set PATH=%JAVA_HOME%\bin\server;%PATH%
set CLASSPATH=%ESP%\loadlib;%CLASSPATH%
set JZOS_JVM_OPTIONS=-XX:+Enable3164Interoperability
/*
//*
//* Control cards read by Java from System.in (STDIN DD)
//STDIN DD *
REPORT_TITLE=Monthly Transaction Summary
MAX_RECORDS=50
/*
//*
//* Application DD - transaction dataset opened by Java via ZFile
//TXNDATA DD DSN=MFI01V.MFIDEMO.BNKTXN,DISP=SHR
//
