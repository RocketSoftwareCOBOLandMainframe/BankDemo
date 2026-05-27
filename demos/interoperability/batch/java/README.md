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
7. [Source Files Reference](#sources)
8. [Troubleshooting](#troubleshooting)

---

## <a name="prerequisites"></a>Prerequisites

- Rocket&reg; Enterprise Developer (to compile COBOL programs) or Rocket&reg; Enterprise Server (to run pre-built programs)
- A Java Development Kit (JDK) 8 or later installed and available on your system PATH
- An Enterprise Server instance configured for JCL batch processing (e.g. the [BANKVSAM](../../../demos/onprem/vsam/README.md) demonstration)
- Ensure that the Directory Server (MFDS) service is running
- Ensure that the Enterprise Server Common Web Administration (ESCWA) service is running and listening on the default port (10086)

---

## <a name="overview"></a>Overview

Rocket Enterprise Server supports two patterns for running Java code from a JCL batch job:

| Pattern | How It Works | When to Use |
|---------|-------------|-------------|
| **COBOL-to-Java CALL** | A COBOL program invokes a Java method using `CALL "Java.<class>.<method>"` | When you want COBOL to orchestrate logic and selectively call Java |
| **JVMLDM Direct** | JCL invokes JVMLDM as the program (`PGM=JVMLDM86`), which sets up the JVM and runs a Java class directly | When you want Java to be the main entry point for the batch step |

Both patterns support:
- Accessing datasets and DD allocations from Java via the `ZFile` API
- Redirecting `System.in`, `System.out`, and `System.err` to DD allocations
- Passing arguments to the Java program via PARM or environment variables

---

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

In this step, you create a simple COBOL program that calls a Java method, and a JCL job that executes it.

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
           DISPLAY "COBOL: Before Java call."

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
//SYSOUT   DD  SYSOUT=*
//STDOUT   DD  SYSOUT=*
//STDERR   DD  SYSOUT=*
//STDIN    DD  DUMMY
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

1. **Compile the Java class and link it the jzos jar file located in the products installed folder:**
   ```
   javac -cp "C:\Program Files (x86)\Rocket Software\Enterprise Developer\bin64\jzos.jar" HelloBatch.java
   ```

2. **Compile the COBOL program** using Enterprise Developer or the command line:
   ```
   cbllink -D HELLOJAV.cbl
   ```

3. **Deploy** the compiled COBOL program (`HELLOJAV.dll` or `.so`) to your Enterprise Server's loadlib directory, and the compiled Java class (`HelloBatch.class`) to a location on the server's CLASSPATH. You will also need to update the PATH within the regions Environmental variables to include the server subdirectory of your java install, e.g. PATH=C:\Program Files (x86)\Rocket Software\Enterprise Developer\AdoptOpenJDK\bin\server;$PATH

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
class BatchReport {
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

### 2.2 Create the STDENV Script

JVMLDM reads an environment setup script from the `STDENV` DD allocation. This script sets the CLASSPATH and any other Java environment variables.

**Windows** — Create `STDENV.cmd`:
```cmd
@echo off
REM STDENV script for JVMLDM batch Java execution
REM Sets up the Java environment for the batch step

set JAVA_HOME=C:\Program Files\Java\jdk-17
set PATH=%JAVA_HOME%\bin;%PATH%
set CLASSPATH=C:\path\to\your\classes;%CLASSPATH%
```

**Linux** — Create `STDENV.sh`:
```bash
#!/bin/sh
# STDENV script for JVMLDM batch Java execution
# Sets up the Java environment for the batch step

export JAVA_HOME=/usr/lib/jvm/java-17
export PATH=$JAVA_HOME/bin:$PATH
export CLASSPATH=/path/to/your/classes:$CLASSPATH
```

### 2.3 Write the JCL

Create the file `JVMDEMO.jcl`:

```jcl
//JVMDEMO  JOB CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1)
//*
//* Invoke Java class directly using JVMLDM (64-bit).
//* PARM format: [loglevel] <classname> [program arguments]
//*
//STEP1    EXEC PGM=JVMLDM86,
//         PARM='BatchReport arg1 arg2'
//STEPLIB  DD  DSN=LOADLIB,DISP=SHR
//STDENV   DD  DSN=CONFIG(STDENV),DISP=SHR
//SYSPRINT DD  SYSOUT=*
//SYSOUT   DD  SYSOUT=*
//STDOUT   DD  SYSOUT=*
//STDERR   DD  SYSOUT=*
//
```

> **DD Allocations:**
> | DD Name | Purpose |
> |---------|---------|
> | STDENV | Environment setup script (sets CLASSPATH, JAVA_HOME, etc.) |
> | SYSPRINT | System standard output from JVMLDM |
> | SYSOUT | System standard error from JVMLDM |
> | STDOUT | Java `System.out` (after stream redirection) |
> | STDERR | Java `System.err` (after stream redirection) |

### 2.4 Compile and Deploy

1. **Compile the Java class:**
   ```
   javac BatchReport.java
   ```

2. **Deploy** `BatchReport.class` to the directory referenced in your STDENV script's CLASSPATH.

3. **Deploy** your STDENV script to a dataset or PDS member accessible from the JCL (as referenced by the `STDENV` DD).

4. **Ensure JVMLDM86** (64-bit) or **JVMLDM80** (32-bit) is available in the loadlib. These are provided with Enterprise Server.

5. **Submit the JCL** and check the STDOUT DD output:
   ```
   === Batch Report Generator ===
   Arguments received: 2
     arg[0] = arg1
     arg[1] = arg2
   Report complete. RC=0
   ```

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
class ReadBankData {
    public static void run() {
        System.setProperty("com.microfocus.cobol.allowLoadLibrary", "true");

        System.out.println("=== Reading Bank Account Data ===");
        readAccountFile();
        System.out.println("=== Complete ===");
    }

    private static void readAccountFile() {
        // Open the dataset allocated to DD name ACCDATA
        ZFile zFile = new ZFile("//DD:ACCDATA", "rb,type=record");
        try {
            byte[] record = new byte[zFile.getLrecl()];
            int bytesRead;
            int count = 0;

            while ((bytesRead = zFile.read(record)) >= 0) {
                count++;
                // Extract fields from fixed-length record
                String accountId = new String(record, 0, 9).trim();
                String custId = new String(record, 9, 5).trim();
                String accountType = new String(record, 14, 1).trim();

                System.out.printf("  Account: %s  Customer: %s  Type: %s%n",
                    accountId, custId, accountType);

                if (count >= 5) {
                    System.out.println("  ... (showing first 5 records)");
                    break;
                }
            }

            System.out.printf("  Total records shown: %d%n", count);
        } finally {
            zFile.close();
        }
    }
}
```

### 3.2 Write the COBOL Bootstrap

Create the file `READBNKJ.cbl`:

```cobol
      $set dialect(entcobol)
       IDENTIFICATION DIVISION.
       PROGRAM-ID. READBNKJ.
      *
      * Invokes the Java class ReadBankData to read account
      * information from a dataset allocated via JCL DD.
      *
       PROCEDURE DIVISION.
           DISPLAY "Reading bank data via Java..."

           CALL "Java.ReadBankData.run"
               ON EXCEPTION
                   DISPLAY "ERROR: Java call failed."
                   MOVE 16 TO RETURN-CODE
               NOT ON EXCEPTION
                   DISPLAY "Java processing complete."
           END-CALL

           GOBACK
           .
       END PROGRAM READBNKJ.
```

### 3.3 Write the JCL

Create the file `READBNKJ.jcl`:

```jcl
//READBNKJ JOB CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1)
//*
//* Read Bankdemo account data using Java ZFile API.
//* The COBOL program READBNKJ calls Java.ReadBankData.run()
//* which reads the dataset allocated to DD ACCDATA.
//*
//* DD Allocations:
//*   SYSOUT   - COBOL DISPLAY output
//*   STDOUT   - Java System.out (redirected stream)
//*   STDERR   - Java System.err (redirected stream)
//*   STDIN    - Java System.in  (redirected stream)
//*   ACCDATA  - Application DD: opened by Java via
//*              ZFile("//DD:ACCDATA", ...)
//*
//STEP1    EXEC PGM=READBNKJ
//STEPLIB  DD  DSN=LOADLIB,DISP=SHR
//*
//* --- Stream redirection DDs ---
//SYSOUT   DD  SYSOUT=*
//STDOUT   DD  SYSOUT=*
//STDERR   DD  SYSOUT=*
//STDIN    DD  DUMMY
//*
//* --- Application DDs (opened by Java via ZFile) ---
//ACCDATA  DD  DSN=MFI01V.MFIDEMO.BNKACC,DISP=SHR
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

1. **Compile the Java class:**
   ```
   javac -cp esjos.jar ReadBankData.java
   ```
   The `esjos.jar` file is provided with Enterprise Server and contains the `com.rocketsoftware.jzos` package.

2. **Compile the COBOL program:**
   ```
   cobol READBNKJ.cbl dialect(entcobol) ilgen;
   cbllink -o READBNKJ READBNKJ.obj
   ```

3. **Deploy** the compiled artifacts to your Enterprise Server instance:
   - `READBNKJ.dll` (or `.so`) → loadlib
   - `ReadBankData.class` → a directory on the CLASSPATH

4. **Ensure** the `MFI01V.MFIDEMO.BNKACC` dataset is cataloged (it is automatically cataloged if you have run the [VSAM demonstration](../../../demos/onprem/vsam/README.md)).

5. **Submit the JCL** and check output:
   ```
   Reading bank data via Java...
   === Reading Bank Account Data ===
     Account: 00000001  Customer: 00001  Type: C
     Account: 00000002  Customer: 00001  Type: S
     ...
   === Complete ===
   Java processing complete.
   ```

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
