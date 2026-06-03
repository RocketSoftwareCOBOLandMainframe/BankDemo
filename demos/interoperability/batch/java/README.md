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
7. [Step 4 — Using a JCL Procedure (JVMPRC86)](#step4)
8. [Step 5 — MAINARGS DD and Inline STDENV](#step5)
9. [Step 6 — Multi-Step Batch with Java](#step6)
10. [Source Files Reference](#sources)
11. [Troubleshooting](#troubleshooting)

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
        System.setProperty("com.microfocus.cobol.allowLoadLibrary", "true");

        try {
            // Explicitly map Java standard streams to JCL DDs when not using JVMLDM.
            ZUtil.redirectStandardStreams("iso-8859-1", true);

            System.out.println("Hello from Java in a batch job!");
            System.out.println("Java version: " + System.getProperty("java.version"));
            System.out.println("Working directory: " + System.getProperty("user.dir"));
        } finally {
            ZUtil.restoreStandardStreams();
            System.clearProperty("com.microfocus.cobol.allowLoadLibrary");
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

In this step, you bypass the COBOL bootstrap and invoke a Java class directly from JCL using the **JVMLDM** load module. This is useful when Java is the primary language for your batch step.

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

> **DD Allocations:**
> | DD Name | Purpose |
> |---------|---------|
> | STDENV | Environment setup script (sets CLASSPATH, JAVA_HOME, etc.).
> | SYSPRINT | System standard output from JVMLDM |
> | SYSOUT | System standard error from JVMLDM |
> | STDOUT | Java `System.out` (after stream redirection) |
> | STDERR | Java `System.err` (after stream redirection) |
> | STDIN | Java `System.in` (allocated as DUMMY if not needed) |

### 2.4 Compile and Deploy

1. **Compile the Java class** using the JDK bundled with Enterprise Developer:
   ```
   javac BatchReport.java
   ```

2. **Deploy** `BatchReport.class` to the directory referenced in your STDENV script's CLASSPATH (e.g. `$ESP/loadlib`).

3. **Ensure JVMLDM** on Windows, JVMLDM64 (64-bit) or **JVMLDM80** (32-bit) on Linux is available in the loadlib. These are provided with Enterprise Server.

5. **Submit the JCL** and check the STDOUT DD output:
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

   5.1 *Note:* We can see the inputted arguments are in a non-sequential order. This is because, arguments will be appended in the order of ARGS+JZOS_MAIN_ARGS+MAINARGS.
   5.2 *In step 1,* we can notice JVMLDM handling the CLASSPATH environmental variable to include esjos.jar implicitly. Along with this, JVMLDM, is handling the redirection of standard streams for us also.

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

5.1 *The Java program* is able to accept an integer (which can be passed via ARGS, MAINARGS or JZOS_MAIN_ARGS environmental variable). This will determine how many records will be displayed. Changing this from 5, to a non parsable integer. Should result in an exception which can viewed in the jobs output.

---

## <a name="step4"></a>Step 4 — Using a JCL Procedure (JVMPRC86)

This step introduces a **reusable JCL procedure** that encapsulates the JVMLDM invocation. This mirrors the IBM z/OS JZOS Batch Launcher pattern (`JVMPRC21`/`JVMPRC31`) and simplifies Java batch job definitions.

### 4.1 The JVMPRC86 Procedure

The procedure `JVMPRC86.prc` is located in `sources/proclib/` and provides symbolic parameters:

```jcl
//JVMPRC86 PROC JAVACLS=,
//             ARGS='',
//             LOGLVL='',
//             LEPARM=''
//*
//JAVA     EXEC PGM=JVMLDM86,
//         PARM='&LOGLVL &JAVACLS &ARGS'
//STEPLIB  DD  DSN=LOADLIB,DISP=SHR
//SYSPRINT DD  SYSOUT=*
//SYSOUT   DD  SYSOUT=*
//STDOUT   DD  SYSOUT=*
//STDERR   DD  SYSOUT=*
//STDIN    DD  DUMMY
//         PEND
```

| Symbolic | Purpose |
|----------|---------|
| `JAVACLS` | Fully qualified Java class name to execute (required) |
| `ARGS` | Additional arguments appended to the PARM string |
| `LOGLVL` | JVMLDM log level (`+T` for trace, blank for default) |
| `LEPARM` | Language environment parameters (optional) |

### 4.2 Calling the Procedure

To invoke a Java class, the calling JCL uses `EXEC PROC=JVMPRC86` and overrides DDs with the `JAVA.` step prefix:

```jcl
//MYJOB    JOB 'JCLCOMP',CLASS=A,MSGCLASS=A
//*
//STEP00   EXEC PROC=JVMPRC86,
//             JAVACLS='com.package.Demo1',
//             ARGS=''
//* Override standard output
//JAVA.STDOUT DD SYSOUT=*
//JAVA.STDERR DD SYSOUT=*
//* Inline environment configuration
//JAVA.STDENV DD *
set JAVA_HOME=C:\Program Files (x86)\Rocket Software\Enterprise Developer\AdoptOpenJDK
set PATH=%JAVA_HOME%\bin\server;%PATH%
set CLASSPATH=%ESP%\loadlib;%CLASSPATH%
/*
//
```

> **Key point:** DDs are overridden using the `JAVA.` prefix (matching the step name inside the proc). This allows the caller to provide inline STDENV, add application DDs, or override stream redirections.

---

## <a name="step5"></a>Step 5 — MAINARGS DD and Inline STDENV

JVMLDM supports receiving Java `main()` arguments from the **MAINARGS DD** (in addition to or instead of the PARM string). This is analogous to IBM's `JZOS_MAIN_ARGS` environment variable or the MAINARGS DD.

### 5.1 How MAINARGS Works

JVMLDM assembles arguments from multiple sources (in order of precedence):
1. **PARM** — The `PARM=` on the EXEC statement (after the class name)
2. **JZOS_MAIN_ARGS** environment variable — Set in STDENV
3. **MAINARGS DD** — An inline or dataset DD containing arguments

Arguments in MAINARGS are parsed as quoted strings, supporting:
- Single-quoted tokens: `'Test string 1'`
- Regex patterns: `'T[e].+[0-9]'`
- Flags and options: `'--verbose'`

### 5.2 Write the Java Class

Create `MainArgsDemo.java`:

```java
import com.rocketsoftware.jzos.*;

/**
 * Demonstrates MAINARGS DD argument parsing.
 * Receives quoted strings, regex patterns, and flags from MAINARGS.
 */
class MainArgsDemo {
    public static void main(String[] args) {
        System.out.println("=== MAINARGS Demonstration ===");
        System.out.println("Total arguments: " + args.length);

        for (int i = 0; i < args.length; i++) {
            System.out.printf("  args[%d] = '%s' (length=%d)%n",
                i, args[i], args[i].length());
        }

        // Demonstrate using args as regex patterns
        if (args.length >= 2) {
            String testData = args[0];
            String pattern = args[1];
            System.out.println("Regex test:");
            System.out.println("  Data:    '" + testData + "'");
            System.out.println("  Pattern: '" + pattern + "'");
            boolean matches = testData.matches(pattern);
            System.out.println("  Match:   " + matches);
        }

        System.out.println("=== MAINARGS Demo Complete. RC=0 ===");
    }
}
```

### 5.3 Write the JCL

Create `JVMARGS.jcl`:

```jcl
//JVMARGS  JOB 'MAINARGS-DEMO',CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1)
//*
//STEP00   EXEC PROC=JVMPRC86,
//             JAVACLS='MainArgsDemo',
//             ARGS=''
//*
//* Environment configuration (inline STDENV)
//JAVA.STDENV DD *
set JAVA_HOME=C:\Program Files (x86)\Rocket Software\Enterprise Developer\AdoptOpenJDK
set PATH=%JAVA_HOME%\bin\server;%PATH%
set CLASSPATH=%ESP%\loadlib;%CLASSPATH%
/*
//*
//* Arguments passed to Java main() via MAINARGS DD
//JAVA.MAINARGS DD *
'Test string 1' 'T[e].+[0-9]' '--verbose'
/*
//
```

### 5.4 Inline STDENV with JVM Options

The `STDENV` DD can also set `JZOS_JVM_OPTIONS` to pass JVM flags:

```jcl
//JAVA.STDENV DD *
set JAVA_HOME=C:\Program Files (x86)\Rocket Software\Enterprise Developer\AdoptOpenJDK
set PATH=%JAVA_HOME%\bin\server;%PATH%
set CLASSPATH=%ESP%\loadlib;%CLASSPATH%
set JZOS_JVM_OPTIONS=-XX:+Enable3164Interoperability
/*
```

> **Environment variables parsed by JVMLDM from STDENV:**
> | Variable | Purpose |
> |----------|---------|
> | `JAVA_HOME` | JDK installation path |
> | `CLASSPATH` | Java class search path |
> | `JZOS_JVM_OPTIONS` | JVM command-line options (e.g. `-Xmx512m`, `-XX:+Enable3164Interoperability`) |
> | `JZOS_MAIN_ARGS` | Additional arguments appended to main() args |
> | `JZOS_OUTPUT_ENCODING` | Output encoding for stream redirection (default: UTF-8) |
> | `JZOS_ENABLE_OUTPUT_TRANSCODING` | `true`/`false` — enable/disable output transcoding |

### 5.5 Expected Output

```
=== MAINARGS Demonstration ===
Total arguments: 3
  args[0] = 'Test string 1' (length=13)
  args[1] = 'T[e].+[0-9]' (length=11)
  args[2] = '--verbose' (length=9)

Regex test:
  Data:    'Test string 1'
  Pattern: 'T[e].+[0-9]'
  Match:   true

Verbose mode enabled. System properties:
  java.version = 17.0.x
  java.home    = C:\Program Files (x86)\Rocket Software\...
  user.dir     = C:\path\to\server
  file.encoding= ISO-8859-1

=== MAINARGS Demo Complete. RC=0 ===
```

---

## <a name="step6"></a>Step 6 — Multi-Step Batch with Java

This step demonstrates chaining multiple Java steps in a single JCL job, each using the `JVMPRC86` procedure with different configurations. This is the typical production pattern for batch processing pipelines.

### 6.1 Bank Account Filter (BankAcctFilter.java)

A Java class that reads bank account data and filters by a regex pattern supplied via MAINARGS:

```java
import com.rocketsoftware.jzos.*;
import java.util.regex.Pattern;
import java.util.regex.Matcher;

class BankAcctFilter {
    public static void main(String[] args) {
        String datasetName = args[0];
        String filterPattern = args.length > 1 ? args[1] : ".*";

        Pattern regex = Pattern.compile(filterPattern);
        // Opens dataset via ZFile and filters account records...
    }
}
```

### 6.2 Multi-Step JCL (JVMMULTI.jcl)

```jcl
//JVMMULTI JOB 'MULTI-STEP',CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1)
//*
//* STEP 1: Filter accounts using regex from MAINARGS
//STEP01   EXEC PROC=JVMPRC86,
//             JAVACLS='BankAcctFilter'
//JAVA.STDENV DD *
set JAVA_HOME=C:\Program Files (x86)\Rocket Software\Enterprise Developer\AdoptOpenJDK
set PATH=%JAVA_HOME%\bin\server;%PATH%
set CLASSPATH=%ESP%\loadlib;%CLASSPATH%
/*
//JAVA.MAINARGS DD *
'MFI01V.MFIDEMO.BNKACC' '0000[1-5]'
/*
//JAVA.ACCDATA DD DSN=MFI01V.MFIDEMO.BNKACC,DISP=SHR
//*
//* STEP 2: Generate transaction report with control cards
//STEP02   EXEC PROC=JVMPRC86,
//             JAVACLS='BankTxnReport'
//JAVA.STDENV DD *
set JAVA_HOME=C:\Program Files (x86)\Rocket Software\Enterprise Developer\AdoptOpenJDK
set PATH=%JAVA_HOME%\bin\server;%PATH%
set CLASSPATH=%ESP%\loadlib;%CLASSPATH%
/*
//JAVA.STDIN DD *
REPORT_TITLE=Daily Batch Run - Filtered Transactions
MAX_RECORDS=25
/*
//JAVA.TXNDATA DD DSN=MFI01V.MFIDEMO.BNKTXN,DISP=SHR
//*
//* STEP 3: MAINARGS demo with verbose trace logging
//STEP03   EXEC PROC=JVMPRC86,
//             JAVACLS='MainArgsDemo',
//             LOGLVL='+T'
//JAVA.STDENV DD *
set JAVA_HOME=C:\Program Files (x86)\Rocket Software\Enterprise Developer\AdoptOpenJDK
set PATH=%JAVA_HOME%\bin\server;%PATH%
set CLASSPATH=%ESP%\loadlib;%CLASSPATH%
/*
//JAVA.MAINARGS DD *
'BatchStep3Data' 'Batch.+[0-9]' '--verbose'
/*
//
```

### 6.3 Compile and Deploy

1. **Compile all Java classes:**
   ```
   javac -cp "C:\Program Files (x86)\Rocket Software\Enterprise Developer\bin64\esjos.jar" BankAcctFilter.java BankTxnReport.java MainArgsDemo.java
   ```

2. **Deploy** all `.class` files to the CLASSPATH directory (e.g. `$ESP/loadlib`).

3. **Ensure** the datasets `MFI01V.MFIDEMO.BNKACC` and `MFI01V.MFIDEMO.BNKTXN` are cataloged.

4. **Submit** `JVMMULTI.jcl` — each step executes independently with its own STDENV and arguments.

---

## <a name="sources"></a>Source Files Reference

The source files for this demonstration are located in the following directories:

| File | Location | Description |
|------|----------|-------------|
| `HELLOJAV.cbl` | `sources/cobol/interop/batch/java/` | COBOL bootstrap for Hello World |
| `HelloBatch.java` | `sources/java/interop/batch/` | Hello World Java class |
| `HELLOJAV.jcl` | `sources/jcl/interop/batch/java/` | JCL for Hello World demo |
| `READBNKJ.cbl` | `sources/cobol/interop/batch/java/` | COBOL bootstrap for ZFile demo |
| `ReadBankData.java` | `sources/java/interop/batch/` | ZFile dataset reader |
| `READBNKJ.jcl` | `sources/jcl/interop/batch/java/` | JCL for ZFile demo |
| `BatchReport.java` | `sources/java/interop/batch/` | Direct JVMLDM Java class |
| `JVMDEMO.jcl` | `sources/jcl/interop/batch/java/` | JCL for JVMLDM direct demo |
| `JVMPRC86.prc` | `sources/proclib/` | JVM Batch Launcher procedure (64-bit) |
| `MainArgsDemo.java` | `sources/java/interop/batch/` | MAINARGS DD demonstration class |
| `BankAcctFilter.java` | `sources/java/interop/batch/` | Regex-based account filter via MAINARGS |
| `BankTxnReport.java` | `sources/java/interop/batch/` | Transaction report with STDIN control cards |
| `JVMBNKF.cbl` | `sources/cobol/interop/batch/java/` | COBOL bootstrap for BankAcctFilter |
| `JVMARGS.jcl` | `sources/jcl/interop/batch/java/` | JCL for MAINARGS demo |
| `JVMFILT.jcl` | `sources/jcl/interop/batch/java/` | JCL for account filter via proc |
| `JVMTXNR.jcl` | `sources/jcl/interop/batch/java/` | JCL for transaction report via proc |
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
| `ZFile` cannot open dataset | DD not allocated or dataset not cataloged | Verify the DD name in JCL matches what ZFile opens (e.g. `//DD:ACCDATA`) |
| `allowLoadLibrary` error | Missing system property | Ensure `System.setProperty("com.microfocus.cobol.allowLoadLibrary", "true")` is called before ZFile operations |

---

## Next Steps

- Explore the [VSAM demonstration](../../../demos/onprem/vsam/README.md) to set up the Bankdemo datasets referenced in Step 3
- Review the `com.rocketsoftware.jzos` API documentation for additional ZFile and ZUtil capabilities
- Try writing a Java program that creates and writes to a new dataset using `ZFile` with write mode
- Experiment with `ZUtil.redirectStandardStreams()` to map `System.in`/`System.out`/`System.err` to DD allocations
