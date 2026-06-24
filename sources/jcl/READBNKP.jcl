//READBNKP JOB CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1)
//*
//* Demonstration: Reading dataset records from Python via PYLDM.
//* Uses zoautil_py.zoau_io.zopen() to read MFI01V.MFIDEMO.BNKACC
//* allocated via DD name.
//*
//* This is the Python equivalent of READBNKJ.jcl (Java/ZFile).
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
//* Read first 5 account records from BNKACC dataset
//* -------------------------------------------------------------------
//STEP1    EXEC PROC=PYPROC,
//             PYSCRIPT='read_bank_data.py',
//             ARGS='5'
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
//* Application DDs (opened by Python via zopen)                     *
//********************************************************************
//ACCDATA  DD  DSN=MFI01V.MFIDEMO.BNKACC,DISP=SHR
//
