//PYCBLCL  JOB CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1)
//*
//* Demonstration: Calling COBOL programs from Python via _mFpyCobcall.
//*
//* Python calls COBOL subroutines by building LINKAGE
//* SECTION buffers with ctypes.
//*
//* Step 1 - VERSION:  Call SVERSONP (trivial 1-param output)
//* Step 2 - DATECONV: Call UDATECNV (structured group parameter)
//* Step 3 - TWOSCOMP: Call UTWOSCMP (3 params including COMP binary)
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
//* Step 1: Get application version from SVERSONP
//* -------------------------------------------------------------------
//STEP1    EXEC PROC=PYPROC,
//             PYSCRIPT='cobol_interop.py',
//             ARGS='VERSION'
//STDOUT   DD  SYSOUT=*
//STDERR   DD  SYSOUT=*
//STDENV   DD  *
set PYTHONPATH=%BANKROOT%\sources\python;%PYTHONPATH%
set ESPY_WORKING_DIR=%BANKROOT%\sources\python
set ESPY_OUTPUT_ENCODING=ASCII
set ESPY_ENABLE_OUTPUT_TRANSCODING=false
set ESPY_MERGE_SYSOUT=false
/*
//*
//* -------------------------------------------------------------------
//* Step 2: Convert date from YYYYMMDD to DD.MMM.YYYY via UDATECNV
//* -------------------------------------------------------------------
//STEP2    EXEC PROC=PYPROC,
//             PYSCRIPT='cobol_interop.py',
//             ARGS='DATECONV 20260624'
//STDOUT   DD  SYSOUT=*
//STDERR   DD  SYSOUT=*
//STDENV   DD  *
set PYTHONPATH=%BANKROOT%\sources\python;%PYTHONPATH%
set ESPY_WORKING_DIR=%BANKROOT%\sources\python
set ESPY_OUTPUT_ENCODING=ASCII
set ESPY_ENABLE_OUTPUT_TRANSCODING=false
set ESPY_MERGE_SYSOUT=false
/*
//*
//* -------------------------------------------------------------------
//* Step 3: Two's complement computation via UTWOSCMP
//* -------------------------------------------------------------------
//STEP3    EXEC PROC=PYPROC,
//             PYSCRIPT='cobol_interop.py',
//             ARGS='TWOSCOMP HELLO'
//STDOUT   DD  SYSOUT=*
//STDERR   DD  SYSOUT=*
//STDENV   DD  *
set PYTHONPATH=%BANKROOT%\sources\python;%PYTHONPATH%
set ESPY_WORKING_DIR=%BANKROOT%\sources\python
set ESPY_OUTPUT_ENCODING=ASCII
set ESPY_ENABLE_OUTPUT_TRANSCODING=false
set ESPY_MERGE_SYSOUT=false
/*
//
