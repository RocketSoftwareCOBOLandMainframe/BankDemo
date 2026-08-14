//PYMULTI  JOB CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1)
//*
//* Demonstration: Multi-step Python batch processing via PYLDM.
//* Step 1 - FILTER: Read BNKCUST, filter customers by PID pattern,
//*                  write matches to stdout AND to an output dataset.
//* Step 2 - REPORT: Read BNKACC, decode COMP-3 balances, produce report.
//*                  Report parameters from control cards via STDIN DD.
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
//*         Writes results to stdout AND to OUTFILE dataset.
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
//********************************************************************
//* Application DDs                                                  *
//********************************************************************
//CUSTDATA DD  DSN=MFI01V.MFIDEMO.BNKCUST,DISP=SHR
//* Output dataset for filtered results (FB, lrecl=132)
//OUTFILE  DD  DSN=MFI01V.MFIDEMO.CUST.FILTER,
//             DISP=(OLD,CATLG,DELETE),
//             LRECL=132,RECFM=FB
//*
//* -------------------------------------------------------------------
//* Step 2: Account balance report with control cards from STDIN
//*         Control cards override report title and max records.
//* -------------------------------------------------------------------
//STEP2    EXEC PROC=PYPROC,
//             PYSCRIPT='bank_cust_acct_report.py',
//             ARGS='REPORT'
//STDOUT   DD  SYSOUT=*
//STDERR   DD  SYSOUT=*
//STDENV   DD  *
set PYTHONPATH=%BANKROOT%\sources\python;%PYTHONPATH%
set ESPY_WORKING_DIR=%BANKROOT%\sources\python
set ESPY_OUTPUT_ENCODING=ASCII
set ESPY_ENABLE_OUTPUT_TRANSCODING=false
set ESPY_MERGE_SYSOUT=false
/*
//********************************************************************
//* Application DDs                                                  *
//********************************************************************
//ACCDATA  DD  DSN=MFI01V.MFIDEMO.BNKACC,DISP=SHR
//* Control cards: KEY=VALUE pairs read via sys.stdin
//STDIN    DD  *
* Report configuration (lines starting with * are comments)
REPORT_TITLE=BankDemo Account Summary Report
MAX_RECORDS=50
/*
//
