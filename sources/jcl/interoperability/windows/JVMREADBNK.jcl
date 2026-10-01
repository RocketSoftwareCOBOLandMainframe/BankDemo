//JVMRDBNK JOB 'JCLCOMP',CLASS=A,MSGCLASS=A
//* 
//******************************************************************** 
//* Custom JVM procedure                                             * 
//******************************************************************** 
//JVMPROC PROC JAVACLS=,      < Fully qualified Java class (required)
//             ARGS=,         < Arguments to Java class
//             LOGLVL=''      < +T(trace) +D(debug) +I(info) +W(warn)
//JAVAJVM  EXEC PGM=JVMLDM,
//             PARM='&LOGLVL &JAVACLS &ARGS'
//SYSPRINT DD SYSOUT=*          < System stdout
//SYSOUT   DD SYSOUT=*          < System stderr
//STDOUT   DD SYSOUT=*          < Java System.out
//STDERR   DD SYSOUT=*          < Java System.err
//         PEND
//******************************************************************** 
//* End Custom JVM procedure                                         * 
//******************************************************************** 
//STEP00   EXEC PROC=JVMPROC,
//             JAVACLS='ReadBankData',
//             ARGS='5'
//* Standard Output redirection
//STDOUT   DD  SYSOUT=*
//STDERR   DD  SYSOUT=*
//STDENV   DD  DUMMY
//STDIN    DD  *
/*
//******************************************************************** 
//* Application DDs (opened by Java via ZFile)                       * 
//******************************************************************** 
//ACCDATA   DD DSN=MFI01V.MFIDEMO.BNKACC,DISP=SHR
//
