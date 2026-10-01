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
//* Step 1: Script mode - run batch_report.py with arguments from all
//*         three sources. They are assembled in this order:
//*           1. PARM      (ARGS= below)
//*           2. ESPY_MAIN_ARGS      env var (set in STDENV)
//*           3. ESPY_MAIN_ARGS_DD   DD, defaulting to MAINARGS
//* -------------------------------------------------------------------
//STEP1    EXEC PROC=PYPROC,
//             PYSCRIPT='batch_report.py',
//             ARGS='hello world'
//STDOUT   DD  SYSOUT=*
//STDERR   DD  SYSOUT=*
//STDENV   DD  *
set ESPY_WORKING_DIR=%ESP%\..\..\sources\python
set ESPY_MAIN_ARGS=envArg1 envArg2
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
set PYTHONPATH=%ESP%\..\..\sources\python;%PYTHONPATH%
/*
//MAINARGS DD  *
//
