//MYJOB    JOB 'JCLCOMP',CLASS=A,MSGCLASS=A
//* 
//******************************************************************** 
//* Custom JVM procedure                                             * 
//******************************************************************** 
//JVMPROC PROC JAVACLS=,            < Fully Qfied Java class..RQD
//             ARGS=,               < Args to Java class
//             VERSION='',          < JVMLDM version: 21
//             LOGLVL='+I',         < Debug LVL: +I(info) +T(trc)
//             REGSIZE='0M',        < EXECUTION REGION SIZE
//             LEPARM=''
//JAVAJVM  EXEC PGM=JVMLDM&VERSION,REGION=&REGSIZE,
//             PARM='&LEPARM/&LOGLVL &JAVACLS &ARGS'
//SYSPRINT  DD SYSOUT=* < System stdout
//SYSOUT    DD SYSOUT=* < System stderr
//STDOUT    DD SYSOUT=* < Java System.out
//STDERR    DD SYSOUT=* < Java System.err
//CEEDUMP  DD SYSOUT=* 
//CEEOPTS DD * 
TRAP(ON,NOSPIE) 
/*
//ABNLIGNR DD DUMMY
//         PEND
//******************************************************************** 
//* End Custom JVM procedure                                         * 
//******************************************************************** 
//STEP00   EXEC PROC=JVMPROC,
//             JAVACLS='ReadBankData',
//             ARGS='5'
//* Standard Output redirection
//STDOUT    DD SYSOUT=*
//STDERR    DD SYSOUT=*
//STDENV    DD *
set CLASSPATH=C:\dev\sources\bankdemo\BANKVSAM\system\loadlib;^
%CLASSPATH%
set JAVA_HOME=C:\Program Files (x86)\Rocket Software\Enterprise Developer\^
AdoptOpenJDK
/*
//STDIN    DD  *
/*
//******************************************************************** 
//* Application DDs (opened by Java via ZFile)                       * 
//******************************************************************** 
//ACCDATA   DD DSN=MFI01V.MFIDEMO.BNKACC,DISP=SHR
//