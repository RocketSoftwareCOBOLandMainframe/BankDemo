//JVMVSAM  JOB 'VSAM-OPS',CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1)
//*
//*-------------------------------------------------------------------*
//* Inline JVM procedure                                              *
//*-------------------------------------------------------------------*
//JVMPROC PROC JAVACLS=,      < Fully qualified Java class (required)
//             ARGS=,         < Arguments to Java class
//             LOGLVL=''      < +T(trace) +D(debug) +I(info) +W(warn)
//JAVAJVM  EXEC PGM=JVMLDM,
//             PARM='&LOGLVL &JAVACLS &ARGS'
//SYSPRINT DD  SYSOUT=*
//SYSOUT   DD  SYSOUT=*
//STDOUT   DD  SYSOUT=*
//STDERR   DD  SYSOUT=*
//         PEND
//*-------------------------------------------------------------------*
//*
//* STEP 1: LOOKUP - Find a specific customer by key
//*
//STEP01   EXEC PROC=JVMPROC,
//             JAVACLS='VsamAccountOps',
//             ARGS='LOOKUP'
//STDENV   DD  DUMMY
//STDIN    DD *
/*
//MAINARGS DD *
'B0001'
/*
//CUSTDATA DD DSN=MFI01V.MFIDEMO.BNKCUST,DISP=SHR
//*
//* STEP 2: BROWSE - Read 10 customers starting from a key
//*
//STEP02   EXEC PROC=JVMPROC,
//             JAVACLS='VsamAccountOps',
//             ARGS='BROWSE'
//STDENV   DD  DUMMY
//STDIN    DD *
/*
//MAINARGS DD *
'B0002' '10'
/*
//CUSTDATA DD DSN=MFI01V.MFIDEMO.BNKCUST,DISP=SHR
//*
//* STEP 3: UPDATE - Toggle SendMail flag on a customer
//*
//STEP03   EXEC PROC=JVMPROC,
//             JAVACLS='VsamAccountOps',
//             ARGS='UPDATE'
//STDENV   DD  DUMMY
//STDIN    DD *
/*
//MAINARGS DD *
'B0001'
/*
//CUSTDATA DD DSN=MFI01V.MFIDEMO.BNKCUST,DISP=SHR
//
