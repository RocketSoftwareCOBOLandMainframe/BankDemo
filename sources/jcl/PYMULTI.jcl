//PYMULTI  JOB CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1)
//*
//* Demonstration: Multi-step Python batch processing via PYLDM.
//* Step 1 - FILTER: Read BNKCUST, filter customers by PID pattern.
//* Step 2 - REPORT: Read BNKACC, decode COMP-3 balances, produce report.
//*
//* Shows same Python script invoked with different modes/arguments.
//*
//********************************************************************
//* Python procedure                                                 *
//********************************************************************
//PYPROC  PROC PYSCRIPT=,           < Python script or -m module
//             ARGS='',             < Args to Python script
//             LOGLVL='+I',         < Debug LVL: +I(info) +T(trc)
//             REGSIZE='0M',        < EXECUTION REGION SIZE
//             LEPARM=''
//PYLDM    EXEC PGM=PYLDM,REGION=&REGSIZE,
//             PARM='&LEPARM/&LOGLVL &PYSCRIPT &ARGS'
//SYSPRINT DD  SYSOUT=*             < System stdout
//SYSOUT   DD  SYSOUT=*             < System stderr / COBOL DISPLAY
//STDOUT   DD  SYSOUT=*             < Python sys.stdout
//STDERR   DD  SYSOUT=*             < Python sys.stderr
//CEEDUMP  DD  SYSOUT=*
//ABNLIGNR DD  DUMMY
//         PEND
//********************************************************************
//* End Python procedure                                             *
//********************************************************************
//*
//* -------------------------------------------------------------------
//* Step 1: Filter customers matching pattern (all customers)
//* -------------------------------------------------------------------
//STEP1    EXEC PROC=PYPROC,
//             PYSCRIPT='bank_cust_acct_report.py',
//             ARGS='FILTER .*'
//STDOUT   DD  SYSOUT=*
//STDERR   DD  SYSOUT=*
//STDENV   DD  *
set PYTHONPATH=%BANKROOT%\sources\python;%PYTHONPATH%
set ESPY_WORKING_DIR=%BANKROOT%\sources\python
set ESPY_OUTPUT_ENCODING=ASCII
set ESPY_ENABLE_OUTPUT_TRANSCODING=false
set ESPY_MERGE_SYSOUT=false
/*
//CUSTDATA DD  DSN=MFI01V.MFIDEMO.BNKCUST,DISP=SHR
//*
//* -------------------------------------------------------------------
//* Step 2: Account balance report (first 20 accounts)
//* -------------------------------------------------------------------
//STEP2    EXEC PROC=PYPROC,
//             PYSCRIPT='bank_cust_acct_report.py',
//             ARGS='REPORT 20'
//STDOUT   DD  SYSOUT=*
//STDERR   DD  SYSOUT=*
//STDENV   DD  *
set PYTHONPATH=%BANKROOT%\sources\python;%PYTHONPATH%
set ESPY_WORKING_DIR=%BANKROOT%\sources\python
set ESPY_OUTPUT_ENCODING=ASCII
set ESPY_ENABLE_OUTPUT_TRANSCODING=false
set ESPY_MERGE_SYSOUT=false
/*
//ACCDATA  DD  DSN=MFI01V.MFIDEMO.BNKACC,DISP=SHR
//
