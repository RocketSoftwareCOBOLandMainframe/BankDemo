//JVMRISK JOB 'RISK-SCORE',CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1)
//*-------------------------------------------------------------------*
//* STEP 8: Fraud Risk Scoring Engine
//*-------------------------------------------------------------------*
//* Demonstrates a real-world batch analytics pattern: scanning all
//* transactions and applying configurable risk-scoring rules to
//* flag suspicious activity across the bank's customer portfolio.
//*
//* This shows JVMLDM's power for analytics workloads where Java's
//* collections, streaming, and algorithmic libraries outperform
//* traditional COBOL batch — while still reading native VSAM data.
//*
//* Key JVMLDM features demonstrated:
//*   - MAINARGS for rule thresholds (no recompile to tune)
//*   - Three concurrent ZFile DDs (customers, accounts, txns)
//*   - JZOS_JVM_OPTIONS for memory tuning on large datasets
//*   - Writing structured output to SYSPRINT via System.out
//*   - Non-zero return code signalling (RC=0/4/8/12)
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
//             JAVACLS='BankRiskScore',
//             ARGS=''
//*
//STDENV DD *
set JAVA_HOME=C:\Program Files (x86)\Rocket Software\^
Enterprise Developer\AdoptOpenJDK
set PATH=%JAVA_HOME%\bin\server;%PATH%
set CLASSPATH=%ESP%\loadlib;%CLASSPATH%
set JZOS_JVM_OPTIONS=-Xmx256m -XX:+UseG1GC
/*
//*
//* MAINARGS: scoring thresholds
//*   arg[0] = max transactions per account per day before flagging
//*   arg[1] = large transaction threshold (dollars)
//*   arg[2] = dormant account days before reactivation is suspicious
//MAINARGS DD *
'5' '9999.99' '90'
/*
//*
//* Rule definitions via control cards (extensible without recompile)
//STDIN DD *
* Risk Scoring Rules Configuration
* Weight values determine severity (1-10)
RULE_RAPID_FIRE_WEIGHT=8
RULE_LARGE_TXN_WEIGHT=6
RULE_DORMANT_REACTIVATION_WEIGHT=9
RULE_MULTI_ACCOUNT_WEIGHT=4
ALERT_THRESHOLD=15
/*
//*
//CUSTDATA DD DSN=MFI01V.MFIDEMO.BNKCUST,DISP=SHR
//ACCTDATA DD DSN=MFI01V.MFIDEMO.BNKACC,DISP=SHR
//TXNDATA  DD DSN=MFI01V.MFIDEMO.BNKTXN,DISP=SHR
//
