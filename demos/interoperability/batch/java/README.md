# Batch Java Interoperability with JVMLDM

This demonstration walks you through invoking Java classes from JCL batch jobs using Rocket Enterprise Server's language interoperability features. You will learn how to use the **JVMLDM** (JVM Load Module) launcher and the **COBOL-to-Java CALL** mechanism to execute Java programs that can access Enterprise Server datasets and DD allocations.

Rocket&reg; Enterprise Suite products provide a proprietary runtime engine to enable compatibility for customers' IBM mainframe batch applications. IBM is a registered trademark of International Business Machines Corp. Rocket Enterprise Suite products do not include an IBM engine and are not affiliated with IBM.

## Contents

1. [Prerequisites](#prerequisites)
2. [Overview](#overview)
3. [How It Works](#how-it-works)
4. [Step 1 — Hello World: COBOL Calling Java](#step1)
5. [Step 2 — Using JVMLDM Directly from JCL](#step2)
6. [Step 3 — Accessing Datasets from Java with ZFile](#step3)
7. [Step 4 — Multi-Step Batch with Java](#step4)
8. [Source Files Reference](#sources)
9. [Exploring the JZOS API](#jzos-api)
10. [Troubleshooting](#troubleshooting)

---

## <a name="prerequisites"></a>Prerequisites

- Rocket&reg; Enterprise Developer (to compile COBOL programs) or Rocket&reg; Enterprise Server (to run pre-built programs)
- A Java Development Kit (JDK) 8 or later installed and available on your system PATH
- An Enterprise Server instance configured for JCL batch processing (e.g. the [BANKVSAM](../../../demos/onprem/vsam/README.md) demonstration)
- Ensure that the Directory Server (MFDS) service is running
- Ensure that the Enterprise Server Common Web Administration (ESCWA) service is running and listening on the default port (10086)


## <a name="how-it-works"></a>How It Works

```
┌────────────────────────────────────────┐
│  JCL Job Step                          │
│  EXEC PGM=BOOTSTRP  (or JVMLDM86)     │
│  DD allocations (STDIN, STDOUT, etc.)  │
└───────────────────┬────────────────────┘
                    │
                    ▼
┌────────────────────────────────────────┐
│  COBOL Bootstrap (or JVMLDM directly)  │
│  CALL "Java.MyClass.myMethod"          │
└───────────────────┬────────────────────┘
                    │
                    ▼
┌────────────────────────────────────────┐
│  Java Runtime                          │
│  - Executes your Java class            │
│  - Uses ZFile to read/write datasets   │
│  - Uses ZUtil for stream redirection   │
└───────────────────┬────────────────────┘
                    │
                    ▼
┌────────────────────────────────────────┐
│  Enterprise Server                     │
│  - Manages DD allocations              │
│  - Provides dataset I/O               │
│  - Returns exit code to JCL            │
└────────────────────────────────────────┘
```

---
## <a name="step1"></a>Step 1 — Hello World: COBOL Calling Java

In this step, you create a simple COBOL program that calls a Java method, and a JCL job that executes it. In this example, demonstrates how to setup a bare metal JCL, Cobol program invoking a Java function which redirects the standard streams. Allowing usage of System.out, System.err & System.in.

### Setup
#### Ensure the region's environment variables include:
   - `JAVA_HOME=C:\Program Files (x86)\Rocket Software\Enterprise Developer\AdoptOpenJDK`
   - `PATH=C:\Program Files (x86)\Rocket Software\Enterprise Developer\AdoptOpenJDK\bin\server;$PATH`
   - `CLASSPATH=C:\Program Files (x86)\Rocket Software\Enterprise Developer\bin64\esjos.jar;$ESP\loadlib`

### 1.1 Write the Java Class

Create the file `HelloBatch.java`:

```java
import com.rocketsoftware.jzos.ZUtil;

/**
 * A simple Java class invoked from COBOL in a batch JCL job.
 * The static run() method is the entry point called by COBOL.
 *
 * Usage: CALL "Java.HelloBatch.run" from COBOL
 */
class HelloBatch {
    public static void run() {
        try {
            // Explicitly map Java standard streams to JCL DDs when not using JVMLDM.
            ZUtil.redirectStandardStreams("iso-8859-1", true);

            System.out.println("Hello from Java in a batch job!");
            System.out.println("Java version: " + System.getProperty("java.version"));
            System.out.println("Working directory: " + System.getProperty("user.dir"));
        } finally {
            ZUtil.restoreStandardStreams();
        }
    }
}
```

> **Key point:** The method called from COBOL must be `public static`. The COBOL CALL statement uses the format `"Java.<ClassName>.<methodName>"`.

### 1.2 Write the COBOL Bootstrap Program

Create the file `HELLOJAV.cbl`:

```cobol
      $set dialect(entcobol)
       IDENTIFICATION DIVISION.
       PROGRAM-ID. HELLOJAV.
      *
      * Simple demonstration of calling a Java class from COBOL.
      * The Java class HelloBatch.run() is invoked using the
      * Enterprise Server Java interoperability mechanism.
      *
       PROCEDURE DIVISION.
           CALL "Java.HelloBatch.run"
               ON EXCEPTION
                   DISPLAY "COBOL: Java call FAILED."
                   MOVE 16 to RETURN-CODE
               NOT ON EXCEPTION
                   DISPLAY "COBOL: Java call succeeded."
           END-CALL

           DISPLAY "COBOL: After Java call."
           GOBACK
           .
       END PROGRAM HELLOJAV.
```

### 1.3 Write the JCL

Create the file `HELLOJAV.jcl`:

```jcl
//HELLOJAV JOB CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1)
//*
//* Demonstration: COBOL bootstrap calling Java.
//* The COBOL program HELLOJAV calls Java.HelloBatch.run()
//*
//* DD Allocations:
//*   SYSOUT   - COBOL DISPLAY output
//*   STDOUT   - Java System.out (redirected stream)
//*   STDERR   - Java System.err (redirected stream)
//*   STDIN    - Java System.in  (redirected stream, optional)
//*
//STEP1    EXEC PGM=HELLOJAV
//STEPLIB  DD  DSN=LOADLIB,DISP=SHR
//STDOUT   DD  SYSOUT=*
//STDERR   DD  SYSOUT=*
//
```

> **Understanding the DDs:**
> | DD Name | Required | Purpose |
> |---------|----------|----------|
> | SYSOUT | Yes | Captures COBOL `DISPLAY` output and system messages |
> | STDOUT | Yes | Java `System.out` — mapped by the runtime's stream redirection |
> | STDERR | Yes | Java `System.err` — mapped by the runtime's stream redirection |
> | STDIN | Optional | Java `System.in` — if your Java code reads from `System.in`, allocate this DD with input data or `DUMMY` |

### 1.4 Compile and Run

1. **Compile the Java class** using the JDK bundled with Enterprise Developer:
   ```
   "javac -cp "C:\Program Files (x86)\Rocket Software\Enterprise Developer\bin64\esjos.jar" HelloBatch.java
   ```

2. **Compile the COBOL program** using the Enterprise Developer 64-bit Command Prompt:
   ```
   cbllink -D HELLOJAV.cbl
   ```

3. **Deploy** the compiled COBOL program `HELLOJAV.dll` & `HelloBatch.class` to your Enterprise Server's loadlib directory (`$ESP/loadlib`).

4. **Submit the JCL** through ESCWA (JES > Control) or by using the Python submission scripts provided in the `scripts` directory of this project.

5. **Check output** in the job's SYSOUT. You should see:
   ```
   COBOL: Before Java call.
   Hello from Java in a batch job!
   Java version: 17.0.x
   Working directory: /path/to/server
   COBOL: Java call succeeded.
   COBOL: After Java call.
   ```

---

## <a name="step2"></a>Step 2 — Using JVMLDM Directly from JCL

In this step, you bypass the COBOL bootstrap and invoke a Java class directly from JCL using the **JVMLDM** load module. This is useful when Java is the primary language for your batch step. This step also covers argument passing via multiple sources (PARM, JZOS_MAIN_ARGS, MAINARGS DD) and inline STDENV configuration.

### 2.1 Write the Java Class

Create the file `BatchReport.java`:

```java
/**
 * A Java batch program invoked directly via JVMLDM.
 * Demonstrates receiving arguments and writing output.
 */
public class BatchReport {
    public static void main(String[] args) {
        System.out.println("=== Batch Report Generator ===");
        System.out.println("Arguments received: " + args.length);

        for (int i = 0; i < args.length; i++) {
            System.out.println("  arg[" + i + "] = " + args[i]);
        }

        System.out.println("Report complete. RC=0");
    }
}
```

### 2.2 Write the JCL

Create the file `JVMDEMO.jcl`:

```jcl
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
//JAVAJVM  EXEC PGM=JVMLDM&VERSION,REGION=&REGSIZE,
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
set CLASSPATH=C:\dev\sources\bankdemo\BANKVSAM\system\loadlib;^
%CLASSPATH%
set JZOS_MAIN_ARGS=arg5 arg6
set JAVA_HOME=C:\Program Files (x86)\Rocket Software\Enterprise Developer\^
AdoptOpenJDK
/*
//MAINARGS DD *
arg3 arg4
/*
//
```

### 2.3 DD Allocations

| DD Name | Purpose |
|---------|---------|
| STDENV | Environment setup script (sets CLASSPATH, JAVA_HOME, etc.) |
| SYSPRINT | System standard output from JVMLDM |
| SYSOUT | System standard error from JVMLDM |
| STDOUT | Java `System.out` (after stream redirection) |
| STDERR | Java `System.err` (after stream redirection) |
| STDIN | Java `System.in` (allocated as DUMMY if not needed) |
| MAINARGS | Additional arguments passed to Java `main()` |

### 2.4 How Arguments Are Assembled

JVMLDM assembles `main()` arguments from multiple sources, appended in this order:

1. **ARGS (PARM)** — Arguments specified on the EXEC statement after the class name
2. **JZOS_MAIN_ARGS** — Environment variable set in STDENV
3. **MAINARGS DD** — An inline or dataset DD containing arguments

Arguments in MAINARGS are parsed as quoted strings, supporting:
- Single-quoted tokens: `'Test string 1'`
- Regex patterns: `'T[e].+[0-9]'`
- Flags and options: `'--verbose'`

### 2.5 Inline STDENV Configuration

The `STDENV` DD is an inline script that configures the JVM environment. JVMLDM parses the following variables:

| Variable | Purpose |
|----------|---------|
| `JAVA_HOME` | JDK installation path |
| `CLASSPATH` | Java class search path |
| `JZOS_JVM_OPTIONS` | JVM command-line options (e.g. `-Xmx512m`, `-XX:+Enable3164Interoperability`) |
| `JZOS_MAIN_ARGS` | Additional arguments appended to main() args |
| `JZOS_OUTPUT_ENCODING` | Output encoding for stream redirection (default: UTF-8) |
| `JZOS_ENABLE_OUTPUT_TRANSCODING` | `true`/`false` — enable/disable output transcoding |

Example with JVM options:

```jcl
//STDENV    DD *
set JAVA_HOME=C:\Program Files (x86)\Rocket Software\Enterprise Developer\AdoptOpenJDK
set PATH=%JAVA_HOME%\bin\server;%PATH%
set CLASSPATH=%ESP%\loadlib;%CLASSPATH%
set JZOS_JVM_OPTIONS=-XX:+Enable3164Interoperability
/*
```

### 2.6 Compile and Deploy

1. **Compile the Java class** using the JDK bundled with Enterprise Developer:
   ```
   javac BatchReport.java
   ```

2. **Deploy** `BatchReport.class` to the directory referenced in your STDENV script's CLASSPATH (e.g. `$ESP/loadlib`).

3. **Ensure JVMLDM** on Windows, JVMLDM64 (64-bit) or **JVMLDM80** (32-bit) on Linux is available in the loadlib. These are provided with Enterprise Server.

4. **Submit the JCL** and check the STDOUT DD output:
   ```
     === Batch Report Generator ===                                                                                                        
     Arguments received: 6                                                                                                                 
       arg[0] = arg1                                                                                                                       
       arg[1] = arg2                                                                                                                       
       arg[2] = arg5                                                                                                                       
       arg[3] = arg6                                                                                                                       
       arg[4] = arg3                                                                                                                       
       arg[5] = arg4                                                                                                                       
     Report complete. RC=0                                                                                                                 
   ```

> **Note:** The arguments appear in non-sequential order because they are appended in the order **ARGS → JZOS_MAIN_ARGS → MAINARGS**. In Step 1 we saw that JVMLDM handles adding `esjos.jar` to the CLASSPATH implicitly and manages stream redirection automatically.

---

## <a name="step3"></a>Step 3 — Accessing Datasets from Java with ZFile

This step demonstrates how a Java program invoked from JCL can read and write Enterprise Server datasets using the `ZFile` API from the `com.rocketsoftware.jzos` package.

### 3.1 Write the Java Class

Create the file `ReadBankData.java`:

```java
import com.rocketsoftware.jzos.*;

/**
 * Reads bank account data from a dataset allocated via JCL DD.
 * Demonstrates using ZFile to access VSAM/sequential datasets
 * from Java in a batch environment.
 */
public class ReadBankData {
    public static void main(String[] args) {
        if(args.length != 1) {
            throw new IllegalArgumentException("Number of passed arguments do not meet the minimum of 1.");
        }

        int recordsToShow = Integer.parseInt(args[0]); // Can throw if argument is not args[0] a parsable integer.

        System.out.println("=== Reading Bank Account Data ===");
        readAccountFile(recordsToShow);
        System.out.println("=== Complete ===");
    }

    public static void readAccountFile(int displayN) {
        // Open the dataset allocated to DD name ACCDATA
        ZFile zFile = new ZFile("//DD:ACCDATA", "rb,type=record");

        try {
            byte[] record = new byte[zFile.getLrecl()];
            int bytesRead;
            int count = 0;

            while ((bytesRead = zFile.read(record)) >= 0) {
                // Extract fields from fixed-length record
                String accountId = new String(record, 0, 9).trim();
                String custId = new String(record, 9, 5).trim();
                String accountType = new String(record, 14, 1).trim();

                count++;
                if (count <= displayN) {
                    System.out.printf("  Account: %s  Customer: %s  Type: %s%n", accountId, custId, accountType);

                    if (count == displayN) {
                        System.out.println("  ... (showing first " + displayN + " records)");
                    }
                }
            }

            System.out.printf("  Total records: %d%n", count);
        } finally {
            zFile.close();
        }
    }
}
```

### 3.2 Write the JCL

Create the file `READBNKJ.jcl`:

```jcl
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
//JAVAJVM  EXEC PGM=JVMLDM&VERSION,REGION=&REGSIZE,
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
//******************************************************************** 
//* Application DDs (opened by Java via ZFile)                       * 
//******************************************************************** 
//ACCDATA   DD DSN=MFI01V.MFIDEMO.BNKACC,DISP=SHR
//
```

> **Understanding the DDs:**
>
> The JCL must allocate **two categories** of DDs:
>
> 1. **Stream redirection DDs** — These are mapped automatically by the runtime to Java's standard I/O streams:
>    | DD Name | Maps To |
>    |---------|----------|
>    | STDOUT | `System.out` |
>    | STDERR | `System.err` |
>    | STDIN | `System.in` |
>    | SYSOUT | COBOL `DISPLAY` / system messages |
>
> 2. **Application DDs** — Any dataset your Java code opens explicitly via `ZFile("//DD:<name>", ...)` must be allocated in the JCL:
>    | DD Name | Opened By |
>    |---------|----------|
>    | ACCDATA | `new ZFile("//DD:ACCDATA", "rb,type=record")` in `ReadBankData.java` |
>
> If your Java program opens additional datasets (e.g. an output file), add corresponding DD allocations to the JCL.

### 3.4 Compile and Run

1. **Compile the Java class** using the JDK bundled with Enterprise Developer:
   ```
   javac -cp "C:\Program Files (x86)\Rocket Software\Enterprise Developer\bin64\esjos.jar" ReadBankData.java
   ```
   The `esjos.jar` file is provided with Enterprise Developer/Server at `bin64\esjos.jar` and contains the `com.rocketsoftware.jzos` package.

2. **Deploy** the compiled artifacts to your Enterprise Server instance:
   - `READBNKJ.dll` (or `.so`) → loadlib
   - `ReadBankData.class` → loadlib

4. **Ensure** the `MFI01V.MFIDEMO.BNKACC` dataset is cataloged (it is automatically cataloged if you have run the [VSAM demonstration](../../../demos/onprem/vsam/README.md)).

5. **Submit the JCL** and check STDOUT DD:
   ```
    === Reading Bank Account Data ===                                                                                                     
       Account: T00010000  Customer: 00001  Type: 1                                                                                        
       Account: T00010000  Customer: 00002  Type: 2                                                                                        
       Account: T00010000  Customer: 00003  Type: 3                                                                                        
       Account: T00010000  Customer: 00004  Type: 4                                                                                        
       Account: T00010000  Customer: 00005  Type: 5                                                                                        
       ... (showing first 5 records)                                                                                                       
       Total records: 108                                                                                                                  
     === Complete ===  
   ```

5.1 *The Java program* is able to accept an integer (which can be passed via ARGS, MAINARGS or JZOS_MAIN_ARGS environmental variable). This will determine how many records will be displayed. Changing this from 5, to a non parsable integer. Should result in an exception which can viewed in the jobs STDERR output.

---

## <a name="step4"></a>Step 4 — Multi-Step Batch: Customer Account Summary

This step brings everything together in a realistic multi-step batch job that processes BankDemo datasets. The job reads customer records, joins them with account data, decodes packed-decimal balances, reads control parameters from STDIN, writes a formatted report to STDOUT, and logs diagnostics to STDERR. It demonstrates `ZFile` for VSAM I/O, `ZUtil` for stream redirection and job introspection, `ZFileException` handling, and MAINARGS-driven filtering.

### 4.1 Java Class: BankCustAcctReport.java

```java
import com.rocketsoftware.jzos.*;
import java.io.*;
import java.math.BigDecimal;
import java.util.*;

/**
 * Multi-step BankDemo batch report.
 *
 * FILTER: Reads BNKCUST, filters by customer ID regex pattern from MAINARGS.
 * REPORT: Reads BNKACC, decodes packed-decimal balances, writes formatted report.
 *
 * Usage via JVMLDM:
 *   PARM='... BankCustAcctReport FILTER <pattern>'
 *   PARM='... BankCustAcctReport REPORT <maxRecords>'
 */
public class BankCustAcctReport {

    // BNKCUST record layout
    private static final int CUST_PID_OFF = 0,   CUST_PID_LEN = 5;
    private static final int CUST_NAME_OFF = 5,  CUST_NAME_LEN = 25;
    private static final int CUST_STATE_OFF = 139, CUST_STATE_LEN = 2;
    private static final int CUST_EMAIL_OFF = 159, CUST_EMAIL_LEN = 30;

    // BNKACC record layout
    private static final int ACC_PID_OFF = 0,     ACC_PID_LEN = 5;
    private static final int ACC_ACCNO_OFF = 5,   ACC_ACCNO_LEN = 9;
    private static final int ACC_TYPE_OFF = 14,   ACC_TYPE_LEN = 1;
    private static final int ACC_BALANCE_OFF = 15, ACC_BALANCE_LEN = 5; // S9(7)V99 COMP-3

    private static final String SEPARATOR = "=".repeat(72);

    public static void main(String[] args) {
        try {
            run(args);
        } catch (Throwable t) {
            System.err.println("FATAL: " + t.getClass().getName() + ": " + t.getMessage());
            t.printStackTrace(System.err);
            System.exit(16);
        }
    }

    private static void run(String[] args) throws Exception {
        if (args.length < 1) {
            System.err.println("ERROR: Missing step argument (FILTER or REPORT)");
            System.exit(12);
        }

        String step = args[0].toUpperCase();
        logJobContext(step);

        switch (step) {
            case "FILTER":
                runFilter(args.length > 1 ? args[1] : ".*");
                break;
            case "REPORT":
                int maxRecords = args.length > 1 ? Integer.parseInt(args[1]) : 50;
                runReport(maxRecords, readControlCards());
                break;
            default:
                System.err.println("ERROR: Unknown step '" + step + "'. Use FILTER or REPORT.");
                System.exit(12);
        }
    }

    private static void logJobContext(String step) {
        System.err.printf("Job: %s (ID: %s)  Step: %s  User: %s%n",
            ZUtil.getCurrentJobname(), ZUtil.getCurrentJobId(),
            ZUtil.getCurrentStepname(), ZUtil.getCurrentUser());
        System.err.printf("Mode: %s  Encoding: %s%n", step, ZUtil.getDefaultPlatformEncoding());
    }

    // -------------------------------------------------------------------------
    // FILTER step
    // -------------------------------------------------------------------------

    private static void runFilter(String pattern) throws IOException {
        ZFile outFile = new ZFile("//'MFI01V.MFIDEMO.CUST.FILTER'", "wb,lrecl=132,type=record");
        try {
            writeLine(outFile, "=== Customer Filter Step ===");
            writeLine(outFile, "Filter pattern: " + pattern);
            System.out.println("=== Customer Filter Step ===");
            System.out.println("Filter pattern: " + pattern);

            ZFile custFile = new ZFile("//DD:CUSTDATA", "rb,type=record");
            try {
                byte[] record = new byte[custFile.getLrecl()];
                int totalRead = 0, matched = 0;

                while (custFile.read(record) >= 0) {
                    totalRead++;
                    String pid = extractField(record, CUST_PID_OFF, CUST_PID_LEN);

                    if (pid.matches(pattern)) {
                        matched++;
                        String line = String.format("  MATCH: PID=%-5s  Name=%-25s  State=%-2s  Email=%s",
                            pid,
                            extractField(record, CUST_NAME_OFF, CUST_NAME_LEN),
                            extractField(record, CUST_STATE_OFF, CUST_STATE_LEN),
                            extractField(record, CUST_EMAIL_OFF, CUST_EMAIL_LEN));
                        System.out.println(line);
                        writeLine(outFile, line);
                    }
                }

                String summary = String.format("Filter complete: %d/%d customers matched.", matched, totalRead);
                System.out.println(summary);
                writeLine(outFile, summary);
                System.err.printf("DIAG: Processed %d records, %d matched '%s'%n",
                    totalRead, matched, pattern);
            } finally {
                custFile.close();
            }
        } finally {
            outFile.close();
        }
    }

    // -------------------------------------------------------------------------
    // REPORT step
    // -------------------------------------------------------------------------

    private static void runReport(int maxRecords, Map<String, String> controlCards)
            throws IOException {
        String title = controlCards.getOrDefault("REPORT_TITLE", "Bank Account Summary");

        ZFile outFile = new ZFile("//'MFI01V.MFIDEMO.ACCT.SUMMARY'", "wb,lrecl=132,type=record");
        try {
            printBoth(outFile, SEPARATOR);
            printBoth(outFile, "  " + title);
            printBoth(outFile, String.format("  Generated by: %s / %s",
                ZUtil.getCurrentJobname(), ZUtil.getCurrentStepname()));
            printBoth(outFile, SEPARATOR);
            printBoth(outFile, String.format("  %-5s  %-9s  %-4s  %12s", "PID", "Account", "Type", "Balance"));
            printBoth(outFile, "  " + "-".repeat(38));

            ZFile accFile = new ZFile("//DD:ACCDATA", "rb,type=record");
            try {
                byte[] record = new byte[accFile.getLrecl()];
                int count = 0;
                BigDecimal totalBalance = BigDecimal.ZERO;

                while (accFile.read(record) >= 0 && count < maxRecords) {
                    String pid = extractField(record, ACC_PID_OFF, ACC_PID_LEN);
                    String accNo = extractField(record, ACC_ACCNO_OFF, ACC_ACCNO_LEN);
                    String accType = extractField(record, ACC_TYPE_OFF, ACC_TYPE_LEN);
                    BigDecimal balance = unpackDecimal(record, ACC_BALANCE_OFF, ACC_BALANCE_LEN, 2);

                    String line = String.format("  %-5s  %-9s  %-4s  %12s",
                        pid, accNo, accType, balance.toPlainString());
                    printBoth(outFile, line);

                    totalBalance = totalBalance.add(balance);
                    count++;
                }

                printBoth(outFile, "  " + "-".repeat(38));
                printBoth(outFile, String.format("  Records: %d   Total Balance: %s",
                    count, totalBalance.toPlainString()));
                printBoth(outFile, SEPARATOR);
                System.err.printf("DIAG: Report displayed %d records%n", count);
            } finally {
                accFile.close();
            }
        } finally {
            outFile.close();
        }
    }

    // -------------------------------------------------------------------------
    // Utilities
    // -------------------------------------------------------------------------

    private static String extractField(byte[] record, int offset, int length) {
        return new String(record, offset, length).trim();
    }

    private static void writeLine(ZFile file, String text) throws IOException {
        file.write(String.format("%-132s", text).getBytes());
    }

    private static void printBoth(ZFile file, String text) throws IOException {
        System.out.println(text);
        writeLine(file, text);
    }

    private static Map<String, String> readControlCards() {
        Map<String, String> cards = new LinkedHashMap<>();
        try {
            BufferedReader reader = new BufferedReader(new InputStreamReader(System.in));
            String line;
            while ((line = reader.readLine()) != null) {
                line = line.trim();
                if (line.isEmpty() || line.startsWith("*")) continue;
                int eq = line.indexOf('=');
                if (eq > 0) {
                    cards.put(line.substring(0, eq).trim(), line.substring(eq + 1).trim());
                }
            }
        } catch (IOException e) {
            System.err.println("WARN: Could not read control cards: " + e.getMessage());
        }
        System.err.printf("DIAG: Read %d control cards from STDIN%n", cards.size());
        return cards;
    }

    private static BigDecimal unpackDecimal(byte[] data, int offset, int length, int scale) {
        StringBuilder digits = new StringBuilder();
        for (int i = 0; i < length; i++) {
            int b = data[offset + i] & 0xFF;
            digits.append((b >> 4) & 0x0F);
            if (i < length - 1) {
                digits.append(b & 0x0F);
            }
        }

        int signNibble = data[offset + length - 1] & 0x0F;
        BigDecimal value = new BigDecimal(digits.toString()).movePointLeft(scale);
        return (signNibble == 0x0D) ? value.negate() : value;
    }
}
```

### 4.2 Multi-Step JCL (JVMMULTI.jcl)

```jcl
//JVMMULTI JOB 'CUSTACCT-RPT',CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1)
//*
//*-------------------------------------------------------------------*
//* Inline JVM procedure (replaces external PROC reference)           *
//*-------------------------------------------------------------------*
//JVMPROC PROC JAVACLS=,
//             ARGS='',
//             VERSION='',
//             LOGLVL='+I',
//             REGSIZE='0M'
//JAVAJVM  EXEC PGM=JVMLDM&VERSION,REGION=&REGSIZE,
//             PARM='&LOGLVL &JAVACLS &ARGS'
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//STDOUT   DD SYSOUT=*
//STDERR   DD SYSOUT=*
//CEEDUMP  DD SYSOUT=*
//ABNLIGNR DD DUMMY
//         PEND
//*-------------------------------------------------------------------*
//*
//* STEP 1: Filter customers matching pattern from MAINARGS
//*         Writes matched PIDs to temporary dataset for Step 2
//*
//STEP01   EXEC PROC=JVMPROC,
//             JAVACLS='BankCustAcctReport',
//             ARGS='FILTER'
//STDENV    DD *
set JAVA_HOME=C:\Program Files (x86)\Rocket Software\^
Enterprise Developer\AdoptOpenJDK
set CLASSPATH=%ESP%\loadlib;%CLASSPATH%
/*
//STDIN    DD  *
/*
//MAINARGS DD *
'B000[1-5]'
/*
//CUSTDATA DD DSN=MFI01V.MFIDEMO.BNKCUST,DISP=SHR
//*
//* STEP 2: Generate account summary report for filtered customers
//*         Reads control cards from STDIN, account data from ACCDATA,
//*         and the filtered PID list from Step 1's CUST.DATASET
//*
//STEP02   EXEC PROC=JVMPROC,
//             JAVACLS='BankCustAcctReport',
//             ARGS='REPORT 25'
//STDENV    DD *
set JAVA_HOME=C:\Program Files (x86)\Rocket Software\^
Enterprise Developer\AdoptOpenJDK
set CLASSPATH=%ESP%\loadlib;%CLASSPATH%
/*
//STDIN    DD *
REPORT_TITLE=Daily Customer Account Summary - Filtered
/*
//ACCDATA  DD DSN=MFI01V.MFIDEMO.BNKACC,DISP=SHR
//
```

> **Key points:**
> - Step 1 filters customers by regex and writes results to `MFI01V.MFIDEMO.CUST.FILTER` (created by ZFile)
> - Step 2 reads account data, decodes COMP-3 balances, and writes a report to `MFI01V.MFIDEMO.ACCT.SUMMARY`
> - Both steps write to STDOUT *and* to a cataloged dataset simultaneously
> - Control cards in STDIN configure the report title dynamically
> - Diagnostics are written to STDERR for operational visibility without polluting the report
> - Packed-decimal (COMP-3) balance fields are decoded in Java for human-readable output
>
> **Note:** The output datasets (`MFI01V.MFIDEMO.CUST.FILTER` and `MFI01V.MFIDEMO.ACCT.SUMMARY`) are created on first run. On subsequent runs, ZFile's `"wb"` mode will overwrite them. If you encounter a file-already-exists error, delete the datasets via ESCWA or the catalog utility before re-submitting.

### 4.3 Compile and Deploy

1. **Compile:**
   ```
   javac -cp "C:\Program Files (x86)\Rocket Software\Enterprise Developer\bin64\esjos.jar" BankCustAcctReport.java
   ```

2. **Deploy** `BankCustAcctReport.class` to your CLASSPATH directory (e.g. `$ESP/loadlib`).

3. **Ensure** datasets `MFI01V.MFIDEMO.BNKCUST` and `MFI01V.MFIDEMO.BNKACC` are cataloged (they are set up by the [VSAM demonstration](../../../demos/onprem/vsam/README.md)).

4. **Submit** `JVMMULTI.jcl` and review the output:

**STDOUT (Step 1 — Filter):**
```
Loaded
 === Customer Filter Step ===                                                                                                          
 Filter pattern: B000[1-5]                                                                                                             
   MATCH: PID=B0001  Name=Fred Bloggs                State=4    Email=NN0001                                                            
   MATCH: PID=B0002  Name=Loretta Morden             State=4    Email=NN0002                                                            
   MATCH: PID=B0003  Name=Eleanor Rigby              State=7    Email=NN0003                                                            
   MATCH: PID=B0004  Name=Desmond Jones              State=9    Email=NN0004                                                            
   MATCH: PID=B0005  Name=Felicity Arkwright         State=5    Email=NN0005                                                            
 Filter complete: 5/38 customers matched.       
```

**STDERR (Step 1 — Diagnostics):**
```
 Job: JVMMULTI (ID: J0001139)  Step: STEP01  User: JESUSER                                                                             
 Mode: FILTER  Encoding: windows-1252                                                                                                  
 DIAG: Opened DD:CUSTDATA  LRECL=250  RECFM=  BLKSIZE=0                                                                                
 DIAG: Processed 38 records, 5 matched 'B000[1-5]' 
```

**STDOUT (Step 2 — Report):**
```
 ========================================================================                                                              
   Daily Customer Account Summary - Filtered                                                                                           
   Generated by: JVMMULTI / STEP02                                                                                                     
 ========================================================================                                                              
   PID    Account    Type       Balance                                                                                                
   --------------------------------------                                                                                              
   T0001  000000001  1            91.14                                                                                                
   T0001  000000002  2           -79.40                                                                                                
   T0001  000000003  3           795.52                                                                                                
   T0001  000000004  4           192.24                                                                                                
   T0001  000000005  5          1453.97                                                                                                
   B0004  014289253  2           -79.40                                                                                                
   B0015  021501544  1           222.60                                                                                                
   B0026  025399550  4           351.00                                                                                                
   B0019  048424439  4           526.05                                                                                                
   B0035  054228132  4           252.56                                                                                                
   B0004  067606426  4           192.24                                                                                                
   B0004  067606427  5          1453.97                                                                                                
   B0028  090543026  4           682.08                                                                                                
   B0011  097510533  4           292.50                                                                                                
   B0026  103842702  2             2.98                                                                                                
          111112222                0.00                                                                                                
   B0008  126195094  3           423.60                                                                                                
   B0029  143898379  4           697.60                                                                                                
   B0021  148367063  3           397.94                                                                                                
   B0034  154460444  2           271.44                                                                                                
   B0019  159914519  2           336.87                                                                                                
   B0023  178238731  1           432.39                                                                                                
   B0029  213882639  5           121.41                                                                                                
   B0034  228552724  4            79.92                                                                                                
   B0016  250299477  3           148.50                                                                                                
   --------------------------------------                                                                                              
   Records: 25   Total Balance: 9259.72                                                                                                
 ========================================================================                                              
```

**STDERR (Step 2 — Diagnostics):**
```
 Job: JVMMULTI (ID: J0001139)  Step: STEP02  User: JESUSER                                                                             
 Mode: REPORT  Encoding: windows-1252                                                                                                  
 DIAG: Read 1 control cards from STDIN                                                                                                 
 DIAG: Opened DD:ACCDATA  LRECL=200  RECFM=  BLKSIZE=0                                                                                 
 DIAG: Report displayed 25 records       
```

---

## <a name="sources"></a>Source Files Reference

The source files for this demonstration are located in the following directories:

| File | Location | Description |
|------|----------|-------------|
| `HELLOJAV.cbl` | `sources/cobol/interop/batch/java/` | COBOL bootstrap for Hello World |
| `HelloBatch.java` | `sources/java/interop/batch/` | Hello World Java class |
| `HELLOJAV.jcl` | `sources/jcl/interop/batch/java/` | JCL for Hello World demo |
| `ReadBankData.java` | `sources/java/interop/batch/` | ZFile dataset reader |
| `READBNKJ.jcl` | `sources/jcl/interop/batch/java/` | JCL for ZFile demo |
| `BatchReport.java` | `sources/java/interop/batch/` | Direct JVMLDM Java class |
| `JVMDEMO.jcl` | `sources/jcl/interop/batch/java/` | JCL for JVMLDM direct demo |
| `BankCustAcctReport.java` | `sources/java/interop/batch/` | Multi-step customer/account report |
| `JVMMULTI.jcl` | `sources/jcl/interop/batch/java/` | Multi-step Java batch job |
| `STDENV.cmd` | `sources/config/interop/` | STDENV script (Windows) |
| `STDENV.sh` | `sources/config/interop/` | STDENV script (Linux) |

---

## <a name="troubleshooting"></a>Troubleshooting

| Problem | Cause | Solution |
|---------|-------|----------|
| `Java call FAILED` with ON EXCEPTION | Java class not found on CLASSPATH | Verify your CLASSPATH includes the directory containing the compiled `.class` file |
| Return code 101 (RC_CONFIG_ERR) | JVMLDM cannot initialize the JVM | Check STDENV script sets JAVA_HOME correctly and the JDK is installed |
| Return code 102 (RC_SYSTEM_ERR) | System-level failure | Check SYSPRINT/SYSOUT DD output for detailed error messages |
| Return code 100 (RC_MAIN_EXCEPTION) | Unhandled exception in Java code | Check STDERR DD output for the Java stack trace |
| RTS 145 (COBOL interop error) | Stream closed prematurely or DCB conflict | Don't close `System.in`; don't duplicate DCB attrs in both DD and ZFile open string |
| `ZFile` cannot open dataset | DD not allocated or dataset not cataloged | Verify the DD name in JCL matches what ZFile opens (e.g. `//DD:ACCDATA`) |

### Exception and System.exit Behavior

When Java code throws an unhandled exception or calls `System.exit(n)` with a non-zero code, JVMLDM reports this as:

- **STDERR DD** — Contains the full Java stack trace (exception class, message, and cause chain). This is always your first place to look for diagnostics.
- **Step condition code** — Maps to an RTS code in the JES output:
  - `System.exit(0)` → normal completion (CC 0000)
  - `System.exit(n)` where n > 0 → reported as `RTS0145` (COBOL interoperability error) in the JCL step abend message
  - Unhandled exception (no explicit `System.exit`) → RC 100 (`RC_MAIN_EXCEPTION`)
- **SYSPRINT DD** — JVMLDM logs a `JVMJZBL` message indicating whether `main()` completed or threw

**Best practice:** Catch exceptions in your `main()` method, print diagnostics to `System.err`, and call `System.exit(16)` (or another meaningful code). The error details will appear in the STDERR DD of the job output, making diagnosis straightforward without needing to decode RTS codes.

---

## <a name="jzos-api"></a>Exploring the JZOS API (`com.rocketsoftware.jzos`)

The `esjos.jar` library (located at `bin64/esjos.jar` in your Enterprise Developer/Server installation) provides the `com.rocketsoftware.jzos` package — a Java API for interacting with Enterprise Server datasets, job context, and I/O streams. This section summarizes the key classes and what you can do with them beyond the basics shown in this tutorial. Here is additional information on the type of functions you can explore with as the next step.

### ZFile — Dataset I/O

`ZFile` is the primary class for reading and writing datasets (sequential, VSAM KSDS/RRDS/ESDS, and PDS members).

#### Opening Datasets

| Open String | Description |
|-------------|-------------|
| `"//DD:MYDD", "rb,type=record"` | Read binary, record mode, via DD name |
| `"//'MY.DATASET'", "rb,type=record"` | Read binary, record mode, via cataloged dataset name |
| `"//'MY.DATASET'", "wb,lrecl=80,type=record"` | Create/write a dataset (creates if not exists) |
| `"//DD:MYDD", "rb,type=record,noseek"` | Read without seek support (more efficient for sequential access) |

#### Instance Methods

| Method | Description |
|--------|-------------|
| `read(byte[])` | Read next record into buffer; returns bytes read or -1 at EOF |
| `write(byte[])` | Write a record |
| `update(byte[])` | Update the last-read record in place (VSAM) |
| `delrec()` | Delete the last-read record (VSAM) |
| `close()` | Close the file (always call in a `finally` block) |
| `getLrecl()` | Logical record length |
| `getRecfm()` | Record format string |
| `getBlksize()` | Block size |
| `getDsorg()` | Dataset organization |
| `seek(int offset, int origin)` | Seek to a position (use `ZFileConstants.SEEK_*`) |
| `tell()` | Return current position |
| `getPos()` | Get position token (byte array, for save/restore) |
| `setPos(byte[])` | Restore a saved position |
| `locate(byte[] key, int flags)` | Locate a VSAM record by key |
| `locate(int value, int flags)` | Locate a VSAM record by RBA or RRN |
| `getVsamType()` | Returns VSAM type (KSDS, RRDS, ESDS) |
| `getVsamKeyLength()` | Returns the VSAM key length |

#### Static Methods

| Method | Description |
|--------|-------------|
| `ZFile.exists(String name)` | Check if a dataset or DD exists |
| `ZFile.ddExists(String ddName)` | Check if a DD name is allocated in current step |
| `ZFile.dsExists(String dsName)` | Check if a cataloged dataset exists |
| `ZFile.getFullyQualifiedDSN(String)` | Resolve a dataset name to its fully qualified form |
| `ZFile.getSlashSlashQuotedDSN(String)` | Format a DSN as `//'DSN.NAME'` for ZFile open |

### ZFileConstants — Seek and Locate Flags

Use these constants with `seek()` and `locate()` for VSAM operations:

| Constant | Description |
|----------|-------------|
| `SEEK_SET` | Seek from beginning |
| `SEEK_CUR` | Seek from current position |
| `SEEK_END` | Seek from end |
| `LOCATE_KEY_EQ` | Locate record with exact key match |
| `LOCATE_KEY_GE` | Locate record with key >= given key |
| `LOCATE_KEY_EQ_BWD` | Locate exact key, position for backward read |
| `LOCATE_KEY_FIRST` | Position to first record |
| `LOCATE_KEY_LAST` | Position to last record |
| `LOCATE_RBA_EQ` | Locate by relative byte address (ESDS) |
| `VSAM_TYPE_KSDS` | Key-sequenced dataset |
| `VSAM_TYPE_RRDS` | Relative-record dataset |
| `VSAM_TYPE_ESDS` | Entry-sequenced dataset |

### ZUtil — Job Context and Stream Management

| Method | Description |
|--------|-------------|
| `ZUtil.redirectStandardStreams(String encoding, boolean merge)` | Redirect `System.in/out/err` to JCL DDs (STDIN/STDOUT/STDERR). Required when calling Java from COBOL without JVMLDM. |
| `ZUtil.restoreStandardStreams()` | Restore original streams (call in `finally`) |
| `ZUtil.getCurrentJobname()` | Current JCL job name |
| `ZUtil.getCurrentJobId()` | Current job ID (e.g. `J0001234`) |
| `ZUtil.getCurrentStepname()` | Current step name |
| `ZUtil.getCurrentUser()` | User ID running the job |
| `ZUtil.getDefaultPlatformEncoding()` | Platform character encoding |

### ZFileException — Error Handling

`ZFileException` extends `IOException` and provides dataset-specific error context:

| Method | Description |
|--------|-------------|
| `getFileName()` | The dataset/DD name that caused the error |
| `getErrno()` | System error number |
| `getMessage()` | Human-readable error description |

### Important Gotchas

| Issue | Explanation |
|-------|-------------|
| **Don't close `System.in`** | JVMLDM manages STDIN. Closing it via try-with-resources causes RTS 145 on step exit. Read from `System.in` without closing the stream. |
| **Don't specify DCB attributes in both DD and ZFile** | If the JCL DD has `DCB=(RECFM=F,LRECL=80)`, open with just `"wb,type=record"` — not `"wb,type=record,lrecl=80,recfm=F"`. Conflicting attributes cause RTS 145. |
| **JVMLDM auto-redirects streams** | Unlike the COBOL bootstrap path (Step 1), JVMLDM handles `ZUtil.redirectStandardStreams()` automatically. Do not call it yourself when using JVMLDM. |
| **Dataset creation via ZFile** | Opening a non-existent dataset name with `"wb,lrecl=N,type=record"` creates it. No DD or JCL allocation is needed. |
| **`ZFile.exists()` vs `ZFile.ddExists()`** | `exists()` checks both DD and DSN. `ddExists()` only checks if a DD is allocated in the current step. `dsExists()` only checks the catalog. |

### VSAM Operations Example

```java
// Locate and read a specific record by key
ZFile vsam = new ZFile("//DD:MYKSDS", "rb,type=record");
try {
    byte[] key = "00005".getBytes();
    vsam.locate(key, ZFileConstants.LOCATE_KEY_EQ);

    byte[] record = new byte[vsam.getLrecl()];
    if (vsam.read(record) >= 0) {
        System.out.println("Found: " + new String(record).trim());
    }
} finally {
    vsam.close();
}
```

```java
// Update a VSAM record in place
ZFile vsam = new ZFile("//DD:MYKSDS", "r+b,type=record");
try {
    byte[] key = "00005".getBytes();
    vsam.locate(key, ZFileConstants.LOCATE_KEY_EQ);

    byte[] record = new byte[vsam.getLrecl()];
    if (vsam.read(record) >= 0) {
        // Modify the record
        System.arraycopy("UPDATED".getBytes(), 0, record, 50, 7);
        vsam.update(record);
    }
} finally {
    vsam.close();
}
```

```java
// Delete a VSAM record
ZFile vsam = new ZFile("//DD:MYKSDS", "r+b,type=record");
try {
    byte[] key = "00005".getBytes();
    vsam.locate(key, ZFileConstants.LOCATE_KEY_EQ);

    byte[] record = new byte[vsam.getLrecl()];
    if (vsam.read(record) >= 0) {
        vsam.delrec();
        System.out.println("Deleted record with key 00005");
    }
} finally {
    vsam.close();
}
```

---

## Next Steps

- Explore the [VSAM demonstration](../../../demos/onprem/vsam/README.md) to set up the Bankdemo datasets referenced in Step 3
- Review the `com.rocketsoftware.jzos` API documentation for additional ZFile and ZUtil capabilities
- Try writing a Java program that creates and writes to a new dataset using `ZFile` with write mode
- Experiment with `ZUtil.redirectStandardStreams()` to map `System.in`/`System.out`/`System.err` to DD allocations
- Use `ZFileConstants.LOCATE_*` with VSAM datasets to implement keyed record access, updates, and deletes
