//JVMXPRT JOB 'JSON-EXPORT',CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1)
//*-------------------------------------------------------------------*
//* STEP 10: JSON/API-Ready Data Export Pipeline
//*-------------------------------------------------------------------*
//* The "bridge to modern" step. Reads VSAM datasets and produces
//* structured JSON output suitable for REST APIs, data lakes,
//* or event streaming platforms (Kafka, MQ, etc.)
//*
//* This demonstrates the most compelling JVMLDM use case:
//* transforming legacy fixed-format VSAM data into modern formats
//* without modifying a single COBOL program — run as a scheduled
//* batch export alongside existing production workloads.
//*
//* Key JVMLDM features demonstrated:
//*   - No external dependencies (uses built-in Java JSON-like output)
//*   - ZFile for reading, System.out for writing (captured by SYSOUT)
//*   - MAINARGS selects export scope and format options
//*   - STDENV passes target configuration (API URLs, auth tokens)
//*   - Multi-step: extract → transform → validate schema
//*   - GDG-like versioning via JCL symbolic substitution
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
//* EXTRACT: Read VSAM data and emit JSON to SYSOUT
//*-------------------------------------------------------------------*
//EXTRACT  EXEC PROC=JVMPROC,
//             JAVACLS='BankJsonExport',
//             ARGS=''
//*
//STDENV DD *
set JAVA_HOME=C:\Program Files (x86)\Rocket Software\^
Enterprise Developer\AdoptOpenJDK
set PATH=%JAVA_HOME%\bin\server;%PATH%
set CLASSPATH=%ESP%\loadlib;%CLASSPATH%
set EXPORT_VERSION=1.0
set EXPORT_TIMESTAMP=2026-06-03T08:00:00Z
set INCLUDE_METADATA=true
/*
//*
//* MAINARGS: 'entity_type' 'format' 'max_records'
//*   entity: CUSTOMERS | ACCOUNTS | TRANSACTIONS | FULL
//*   format: JSON_LINES | JSON_ARRAY | NDJSON
//*   max:    number or ALL
//MAINARGS DD *
'FULL' 'JSON_LINES' 'ALL'
/*
//*
//CUSTDATA DD DSN=MFI01V.MFIDEMO.BNKCUST,DISP=SHR
//ACCTDATA DD DSN=MFI01V.MFIDEMO.BNKACC,DISP=SHR
//TXNDATA  DD DSN=MFI01V.MFIDEMO.BNKTXN,DISP=SHR
//*
//*-------------------------------------------------------------------*
//* SCHEMA: Validate the exported JSON structure (self-test)
//*-------------------------------------------------------------------*
//SCHEMA   EXEC PROC=JVMPROC,
//             JAVACLS='BankJsonExport',
//             ARGS=''
//*
//STDENV DD *
set JAVA_HOME=C:\Program Files (x86)\Rocket Software\^
Enterprise Developer\AdoptOpenJDK
set PATH=%JAVA_HOME%\bin\server;%PATH%
set CLASSPATH=%ESP%\loadlib;%CLASSPATH%
set EXPORT_VERSION=1.0
set INCLUDE_METADATA=true
/*
//MAINARGS DD *
'SCHEMA_ONLY' 'JSON_ARRAY' '0'
/*
//CUSTDATA DD DSN=MFI01V.MFIDEMO.BNKCUST,DISP=SHR
//ACCTDATA DD DSN=MFI01V.MFIDEMO.BNKACC,DISP=SHR
//TXNDATA  DD DSN=MFI01V.MFIDEMO.BNKTXN,DISP=SHR
//
