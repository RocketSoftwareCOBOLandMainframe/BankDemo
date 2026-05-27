//READBNKJ JOB CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1)
//*
//* Read Bankdemo account data using Java ZFile API.
//* The COBOL program READBNKJ calls Java.ReadBankData.run()
//* which reads the dataset allocated to DD ACCDATA.
//*
//STEP1    EXEC PGM=READBNKJ
//STEPLIB  DD  DSN=LOADLIB,DISP=SHR
//SYSOUT   DD  SYSOUT=*
//*
//* --- Stream redirection DDs ---
//STDOUT   DD  SYSOUT=*
//STDERR   DD  SYSOUT=*
//STDIN    DD  DUMMY
//*
//* --- Application DDs (opened by Java via ZFile) ---
//ACCDATA  DD  DSN=MFI01V.MFIDEMO.BNKACC,DISP=SHR
//
