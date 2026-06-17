//MYJOB    JOB 'JCLCOMP',CLASS=A,MSGCLASS=A
//* 
//******************************************************************** 
//* Custom JVM procedure                                             * 
//******************************************************************** 
//JVMPROC PROC JAVACLS=,            < Fully Qfied Java class..RQD
//             ARGS=,               < Args to Java class
//             VERSION='',          < PGM name suffix (e.g. 64)
//             LOGLVL='+I'          < +T(trace) +I(info) +W(warn)
//JAVAJVM  EXEC PGM=JVMLDM&VERSION,
//             PARM='&LOGLVL &JAVACLS &ARGS'
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
//             JAVACLS='BatchReport',
//             ARGS='arg1 arg2'
//* Standard Output redirection
//STDOUT    DD SYSOUT=*
//STDERR    DD SYSOUT=*
//STDENV    DD *
set JAVA_HOME=%COBDIR%\AdoptOpenJDK
set CLASSPATH=C:\dev\sources\bankdemo\BANKVSAM\system\loadlib;^
%CLASSPATH%
set JZOS_MAIN_ARGS=arg3 arg4
/*
//MAINARGS DD *
arg5 arg6
/*
//
