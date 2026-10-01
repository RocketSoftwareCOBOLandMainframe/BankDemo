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
//PYPROC  PROC PYSCRIPT=,     < Python script or -m module (required)
//             ARGS=,         < Arguments to Python script
//             LOGLVL=''      < +T(trace) +D(debug) +I(info) +W(warn)
//PYLDM    EXEC PGM=PYLDM,
//             PARM='/&LOGLVL &PYSCRIPT &ARGS'
//SYSPRINT DD SYSOUT=*          < System stdout
//SYSOUT   DD SYSOUT=*          < System stderr / COBOL DISPLAY
//STDOUT   DD SYSOUT=*          < Python sys.stdout
//STDERR   DD SYSOUT=*          < Python sys.stderr
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
export ESPY_WORKING_DIR=$ESP/../../sources/python
/*
//********************************************************************
//* Application DDs                                                  *
//********************************************************************
//CUSTDATA DD  DSN=MFI01V.MFIDEMO.BNKCUST,DISP=SHR
//* Output dataset for filtered results (F, lrecl=132).
//* Cataloged at region provision time - scripts/datasets_ps/CUSTFILT.json
//OUTFILE  DD  DSN=MFI01V.MFIDEMO.CUST.FILTER,DISP=OLD
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
export ESPY_WORKING_DIR=$ESP/../../sources/python
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
