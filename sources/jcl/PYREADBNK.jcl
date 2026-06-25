//PYRDBNK  JOB CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1)
//*
//* Demonstration: Non-VSAM Sequential File I/O from Python via PYLDM.
//* Uses zoautil_py zopen() to read/write a Physical Sequential (PS)
//* dataset with Fixed (F) records - same DD pattern as VSAM.
//*
//* Two steps:
//*   1. WRITE - Write sample transaction records to the PS dataset
//*   2. READ  - Read them back and produce a summary report
//*
//* This is the Python equivalent of JVMREADBNK.jcl (Java/ZFile).
//*
//********************************************************************
//* Python procedure (mirrors JVMPROC for Java)                      *
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
//* Step 1: Write sample transaction records to the PS dataset
//* -------------------------------------------------------------------
//WRITE    EXEC PROC=PYPROC,
//             PYSCRIPT='sequential_file_ops.py',
//             ARGS='WRITE'
//STDOUT   DD  SYSOUT=*
//STDERR   DD  SYSOUT=*
//STDENV   DD  *
set PYTHONPATH=%BANKROOT%\sources\python;%PYTHONPATH%
set ESPY_WORKING_DIR=%BANKROOT%\sources\python
set ESPY_OUTPUT_ENCODING=ASCII
set ESPY_ENABLE_OUTPUT_TRANSCODING=false
set ESPY_MERGE_SYSOUT=false
/*
//TXNDATA  DD  DSN=MFI01V.MFIDEMO.PYTXN,DISP=OLD
//*
//* -------------------------------------------------------------------
//* Step 2: Read records back and produce a summary report
//* -------------------------------------------------------------------
//READ     EXEC PROC=PYPROC,
//             PYSCRIPT='sequential_file_ops.py',
//             ARGS='READ'
//STDOUT   DD  SYSOUT=*
//STDERR   DD  SYSOUT=*
//STDENV   DD  *
set PYTHONPATH=%BANKROOT%\sources\python;%PYTHONPATH%
set ESPY_WORKING_DIR=%BANKROOT%\sources\python
set ESPY_OUTPUT_ENCODING=ASCII
set ESPY_ENABLE_OUTPUT_TRANSCODING=false
set ESPY_MERGE_SYSOUT=false
/*
//TXNDATA  DD  DSN=MFI01V.MFIDEMO.PYTXN,DISP=SHR
//
