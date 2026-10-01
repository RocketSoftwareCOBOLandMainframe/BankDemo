//JVMMULTI JOB 'CUSTACCT-RPT',CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1)
//*
//*-------------------------------------------------------------------*
//* Inline JVM procedure (replaces external PROC reference)           *
//*-------------------------------------------------------------------*
//JVMPROC PROC JAVACLS=,      < Fully qualified Java class (required)
//             ARGS=,         < Arguments to Java class
//             LOGLVL=''      < +T(trace) +D(debug) +I(info) +W(warn)
//JAVAJVM  EXEC PGM=JVMLDM,
//             PARM='&LOGLVL &JAVACLS &ARGS'
//SYSPRINT DD  SYSOUT=*
//SYSOUT   DD  SYSOUT=*
//STDOUT   DD  SYSOUT=*
//STDERR   DD  SYSOUT=*
//         PEND
//*-------------------------------------------------------------------*
//*
//* STEP 1: Filter customers matching pattern from MAINARGS
//*         Writes matched PIDs to temporary dataset for Step 2
//*
//STEP01   EXEC PROC=JVMPROC,
//             JAVACLS='BankCustAcctReport',
//             ARGS='FILTER'
//STDENV   DD  DUMMY
//STDIN    DD  *
/*
//MAINARGS DD *
'B000[1-5]'
/*
//CUSTDATA DD DSN=MFI01V.MFIDEMO.BNKCUST,DISP=SHR
//*
//* STEP 2: Generate account summary report for filtered customers
//*         Reads control cards from STDIN, account data from ACCDATA,
//*         and the filtered PID list from Step 1's CUST.DATASET
//*
//STEP02   EXEC PROC=JVMPROC,
//             JAVACLS='BankCustAcctReport',
//             ARGS='REPORT 25'
//STDENV   DD  DUMMY
//STDIN    DD  *
REPORT_TITLE=Daily Customer Account Summary - Filtered
/*
//ACCDATA  DD  DSN=MFI01V.MFIDEMO.BNKACC,DISP=SHR
//
