//JVMAUDT JOB 'DATA-AUDIT',CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1)
//*-------------------------------------------------------------------*
//* STEP 9: Data Integrity Audit & Reconciliation
//*-------------------------------------------------------------------*
//* Demonstrates using JVMLDM for a complete data quality framework.
//* Java scans all three BankDemo datasets and cross-validates
//* referential integrity, data format rules, and business logic.
//*
//* This is the kind of batch job that replaces hundreds of lines
//* of COBOL validation code with concise, testable Java logic —
//* while still running natively in the JES batch scheduler.
//*
//* Key JVMLDM features demonstrated:
//*   - ZUtil.getEnv() to read JCL symbolic values at runtime
//*   - Writing to SYSPRINT for audit trail (SYSOUT=* capture)
//*   - Multiple validation passes with aggregate error reporting
//*   - COND parameter checking across steps (RC cascading)
//*   - MAINARGS for audit severity level control
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
//* PASS 1: Structural validation (orphan detection)
//*-------------------------------------------------------------------*
//AUDIT1   EXEC PROC=JVMPROC,
//             JAVACLS='BankDataAudit',
//             ARGS=''
//*
//STDENV DD *
set JAVA_HOME=C:\Program Files (x86)\Rocket Software\^
Enterprise Developer\AdoptOpenJDK
set PATH=%JAVA_HOME%\bin\server;%PATH%
set CLASSPATH=%ESP%\loadlib;%CLASSPATH%
set AUDIT_RUN_ID=DAILY-2026-06-03
set AUDIT_MODE=FULL
/*
//*
//* MAINARGS: 'audit_pass' 'severity_level'
//*   pass: STRUCTURAL | FORMAT | BUSINESS | ALL
//*   severity: WARN | ERROR | STRICT
//MAINARGS DD *
'ALL' 'WARN'
/*
//*
//CUSTDATA DD DSN=MFI01V.MFIDEMO.BNKCUST,DISP=SHR
//ACCTDATA DD DSN=MFI01V.MFIDEMO.BNKACC,DISP=SHR
//TXNDATA  DD DSN=MFI01V.MFIDEMO.BNKTXN,DISP=SHR
//*
//*-------------------------------------------------------------------*
//* PASS 2: Generate fix-up recommendations (only if PASS 1 has warns)
//*-------------------------------------------------------------------*
//AUDIT2   EXEC PROC=JVMPROC,
//             JAVACLS='BankDataAudit',
//             ARGS='',
//             COND=(8,LT)
//*
//STDENV DD *
set JAVA_HOME=C:\Program Files (x86)\Rocket Software\^
Enterprise Developer\AdoptOpenJDK
set PATH=%JAVA_HOME%\bin\server;%PATH%
set CLASSPATH=%ESP%\loadlib;%CLASSPATH%
set AUDIT_RUN_ID=DAILY-2026-06-03
set AUDIT_MODE=FIXUP
/*
//MAINARGS DD *
'STRUCTURAL' 'STRICT'
/*
//CUSTDATA DD DSN=MFI01V.MFIDEMO.BNKCUST,DISP=SHR
//ACCTDATA DD DSN=MFI01V.MFIDEMO.BNKACC,DISP=SHR
//TXNDATA  DD DSN=MFI01V.MFIDEMO.BNKTXN,DISP=SHR
//
