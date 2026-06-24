//PYDEMO   JOB CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1)
//*
//* Demonstration: Invoking Python directly from JCL via PYLDM.
//* No COBOL bootstrap needed - PYLDM is the Python Language
//* Definition Module that initializes Python, redirects streams,
//* and runs the specified script or module.
//*
//* This is the Python equivalent of JVMDEMO.jcl (Java/JVMLDM).
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
//* Step 1: Script mode - run batch_report.py with PARM arguments
//* -------------------------------------------------------------------
//STEP1    EXEC PROC=PYPROC,
//             PYSCRIPT='batch_report.py',
//             ARGS='hello world'
//STDOUT   DD  SYSOUT=*
//STDERR   DD  SYSOUT=*
//STDENV   DD  *
set PYTHONPATH=%BANKROOT%\sources\python;%PYTHONPATH%
set ESPY_WORKING_DIR=%BANKROOT%\sources\python
set ESPY_OUTPUT_ENCODING=ASCII
set ESPY_ENABLE_OUTPUT_TRANSCODING=false
set ESPY_MERGE_SYSOUT=false
/*
//MAINARGS DD  *
arg3 arg4
/*
//*
//* -------------------------------------------------------------------
//* Step 2: Module mode - run batch_report as a module (-m flag)
//* -------------------------------------------------------------------
//STEP2    EXEC PROC=PYPROC,
//             PYSCRIPT='-m batch_report',
//             ARGS='moduleArg1 moduleArg2'
//STDOUT   DD  SYSOUT=*
//STDERR   DD  SYSOUT=*
//STDENV   DD  *
set PYTHONPATH=%BANKROOT%\sources\python;%PYTHONPATH%
set ESPY_OUTPUT_ENCODING=ASCII
set ESPY_ENABLE_OUTPUT_TRANSCODING=false
set ESPY_MERGE_SYSOUT=false
/*
//MAINARGS DD  *
//
