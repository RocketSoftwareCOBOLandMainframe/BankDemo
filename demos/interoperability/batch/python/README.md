# Batch Python Interoperability with PYLDM

This demonstration walks you through invoking Python scripts from JCL batch jobs using Rocket Enterprise Server's language interoperability features. You will learn how to use the **PYLDM** (Python Language Definition Module) launcher to execute Python programs that can access Enterprise Server datasets, call COBOL programs, and integrate with existing mainframe batch workflows.

Rocket&reg; Enterprise Suite products provide a proprietary runtime engine to enable compatibility for customers' IBM mainframe batch applications. IBM is a registered trademark of International Business Machines Corp. Rocket Enterprise Suite products do not include an IBM engine and are not affiliated with IBM.

## Contents

1. [Prerequisites](#prerequisites)
2. [Overview](#overview)
3. [How It Works](#how-it-works)
4. [Step 1 - Using PYLDM Directly from JCL](#step1)
5. [Step 2 - Sequential File I/O from Python](#step2)
6. [Step 3 - Multi-Step Batch with Python](#step3)
7. [Step 4 - VSAM Operations from Python](#step4)
8. [Step 5 - Calling COBOL from Python](#step5)
9. [Source Files Reference](#sources)
10. [Python API Reference](#api-reference)
11. [Troubleshooting](#troubleshooting)

---

## <a name="prerequisites"></a>Prerequisites

- Rocket&reg; Enterprise Developer (to compile COBOL programs) or Rocket&reg; Enterprise Server (to run pre-built programs)
- Python 3.8 or later, installed so that Enterprise Server can load it (see below)
- Ensure that the Directory Server (MFDS) service is running
- Ensure that the Enterprise Server Common Web Administration (ESCWA) service is running and listening on the default port (10086)

No additional Python packages are required — the `zoautil_py` and `esos` packages are provided by the Enterprise Server installation.

### Installing Python

PYLDM does not run the `python` executable. It loads the Python **shared library** into the Enterprise Server process, so it is that library which must be locatable:

**Windows** — install Python 3 from [python.org](https://www.python.org/downloads/) and tick *Add python.exe to PATH*. PYLDM loads `python3.dll` using the standard DLL search order, so the directory containing it must be on `PATH`.

**Linux** — install the Python 3 runtime *and* its development package, which provides the `libpython3.so` linker name:

```
sudo dnf install python3 python3-devel      # RHEL / Oracle Linux / Fedora
sudo apt install python3 python3-dev        # Ubuntu / Debian
```

PYLDM tries `libpython3.so` first, then `libpython3.so.1.0`. The library must be reachable through `ldconfig` or `LD_LIBRARY_PATH`. If your distribution only ships a versioned library, set `PYTHON_SHARED_LIB` in the region environment to name it explicitly, for example `libpython3.12.so`.

> **Important:** The Python you use at a shell prompt is not necessarily the one Enterprise Server can see. The region inherits its environment from wherever the server was started, so if you change `PATH` (Windows) or `LD_LIBRARY_PATH` (Linux) afterwards, restart the region. The bitness must also match: a 64-bit region needs 64-bit Python.

To confirm which interpreter PYLDM actually loaded, run [Step 1](#step1) — `batch_report.py` prints the running Python version.

### The BANKVSAM Region

These demonstrations run in the **BANKVSAM** enterprise server region, which is created by the [VSAM demonstration](../../../demos/onprem/vsam/README.md). If you have not already set it up, provision it from the `scripts` directory of this project:

```
cd scripts
python MF_Provision_Region.py vsam
```

This creates a 64-bit, JES-enabled region in a `BANKVSAM` subdirectory of the project and catalogs every dataset these demonstrations use:

| Dataset | Used by | Defined in |
|---------|---------|------------|
| `MFI01V.MFIDEMO.BNKCUST` | Steps 3, 4 (customer records, VSAM KSDS) | `scripts/datasets_vsam/BNKCUST.json` |
| `MFI01V.MFIDEMO.BNKACC` | Steps 3, 4 (account records, VSAM KSDS) | `scripts/datasets_vsam/BNKACC.json` |
| `MFI01V.MFIDEMO.PYTXN` | Step 2 (sequential transactions, PS) | `scripts/datasets_ps/PYTXN.json` |
| `MFI01V.MFIDEMO.CUST.FILTER` | Step 3 (filter output, PS) | `scripts/datasets_ps/CUSTFILT.json` |

Because all four datasets are cataloged during provisioning, the Python demonstrations are self-contained — you do not need to run the Java demonstrations first.

> **Note:** Provision BANKVSAM *before* starting any other region that uses this project's `system` directory. Provisioning copies that directory into the new region, so runtime files left behind by another region can cause resource definition errors.

### Region Configuration

No region configuration is required. The `esos` and `zoautil_py` packages supplied with Enterprise Server are located automatically, and the `STDENV` DD in each JCL job step adds the demonstration's own script directory to `PYTHONPATH` (e.g. `%ESP%\..\..\sources\python`) so PYLDM can find the `.py` files.

> **About `%ESP%`:** `ESP` is a standard Enterprise Server region variable holding the region's system directory (for example `C:\BankDemo\BANKVSAM\system`). Because the region directory is created inside the BankDemo project, `%ESP%\..\..` resolves back to the project root - so the JCL locates the demo scripts without needing any extra variable to be defined. The JCL in these demonstrations uses this relative form deliberately, so no additional region configuration is required.

### Running on Linux

The supplied JCL is written for Windows. Everything else in these demonstrations - the Python scripts, the dataset definitions, and the provisioning command - is identical on Linux, but the **STDENV DD is not portable** and must be edited before the jobs will run.

PYLDM writes the contents of the STDENV DD to a temporary script and executes it with the platform's own shell: `cmd.exe` on Windows, `/bin/sh` on Linux. The script therefore has to be written in the syntax of that shell:

| | Windows | Linux |
|---|---------|-------|
| Assign a variable | `set NAME=value` | `export NAME=value` |
| Reference a variable | `%NAME%` | `$NAME` |
| Directory separator | `\` | `/` |
| `PYTHONPATH` separator | `;` | `:` |

Each STDENV block in the five `PY*.jcl` files needs converting. For example, this Windows form:

```
//STDENV   DD  *
set PYTHONPATH=%ESP%\..\..\sources\python;%PYTHONPATH%
set ESPY_WORKING_DIR=%ESP%\..\..\sources\python
set ESPY_OUTPUT_ENCODING=ASCII
set ESPY_ENABLE_OUTPUT_TRANSCODING=false
set ESPY_MERGE_SYSOUT=false
/*
```

becomes this on Linux:

```
//STDENV   DD  *
export PYTHONPATH=$ESP/../../sources/python:$PYTHONPATH
export ESPY_WORKING_DIR=$ESP/../../sources/python
export ESPY_OUTPUT_ENCODING=ASCII
export ESPY_ENABLE_OUTPUT_TRANSCODING=false
export ESPY_MERGE_SYSOUT=false
/*
```

Note the two separator changes as well as `set` becoming `export`: `\` becomes `/`, and the `;` joining the two `PYTHONPATH` entries becomes `:`.

`ESP` itself is set by Enterprise Server on both platforms, so `$ESP/../..` resolves to the project root exactly as `%ESP%\..\..` does on Windows.

Everything else is unchanged. `python MF_Provision_Region.py vsam` provisions BANKVSAM on Linux the same way, the dataset names and DD names are identical, and the Python sources need no modification. For Step 5, the COBOL bridge is `libcblcpyiapi.so` rather than `cblcpyiapi.dll`, but `cobol_interop.py` resolves the platform-specific name itself.

---

## <a name="overview"></a>Overview

Enterprise Server provides Python interoperability through **PYLDM** — a COBOL program that hosts the Python interpreter within a JCL batch job step. PYLDM handles:

- Loading and initializing the Python interpreter
- Redirecting Python's `sys.stdout`, `sys.stderr`, and `sys.stdin` to JCL DD allocations
- Passing arguments from JCL PARM to the Python script via `sys.argv`
- Environment variable configuration via the STDENV DD

Unlike the Java interop (which requires `JAVA_HOME`, classpath configuration, and compiled `.class` files), Python requires **no compilation step** and **no explicit runtime path** — PYLDM automatically locates the installed Python interpreter.

---

## <a name="how-it-works"></a>How It Works

```
┌────────────────────────────────────────┐
│  JCL Job Step                          │
│  EXEC PGM=PYLDM,PARM='script.py args'  │
│  DD allocations (STDOUT, STDERR, etc.) │
└───────────────────┬────────────────────┘
                    │
                    ▼
┌────────────────────────────────────────┐
│  PYLDM (COBOL program)                 │
│  - Initializes Python via cblcpyiapi   │
│  - Redirects streams to JCL DDs        │
│  - Passes PARM + MAINARGS + env args   │
└───────────────────┬────────────────────┘
                    │
                    ▼
┌────────────────────────────────────────┐
│  Python Runtime                        │
│  - Executes your .py script            │
│  - Uses zoautil_py/esos for datasets   │
│  - Uses ctypes for COBOL callbacks     │
└───────────────────┬────────────────────┘
                    │
                    ▼
┌────────────────────────────────────────┐
│  Enterprise Server                     │
│  - Manages DD allocations              │
│  - Provides dataset I/O (VSAM, seq)    │
│  - Returns exit code to JCL            │
└────────────────────────────────────────┘
```

### PYLDM Invocation Modes

| Mode | PARM syntax | Entry point |
|------|-------------|-------------|
| **Script mode** | `'script.py arg1 arg2'` | Module-level code / `if __name__ == "__main__":` |
| **Module mode** | `'-m module_name arg1 arg2'` | `def main(args=None)` function |

### Environment Configuration (STDENV DD)

The STDENV DD contains environment variable assignments executed before the Python script runs. Its primary purpose is to add your **application script directories** to `PYTHONPATH` so PYLDM can locate the `.py` files to execute:

```
set PYTHONPATH=%ESP%\..\..\sources\python;%PYTHONPATH%
set ESPY_WORKING_DIR=%ESP%\..\..\sources\python
set ESPY_OUTPUT_ENCODING=ASCII
set ESPY_ENABLE_OUTPUT_TRANSCODING=false
set ESPY_MERGE_SYSOUT=false
```

| Variable | Purpose |
|----------|---------|
| `PYTHONPATH` | Adds the application script directory (uses `%PYTHONPATH%` to preserve existing entries) |
| `ESPY_WORKING_DIR` | Working directory for the script |
| `ESPY_OUTPUT_ENCODING` | Encoding for redirected output streams |
| `ESPY_ENABLE_OUTPUT_TRANSCODING` | Enable/disable encoding transcoding |
| `ESPY_MERGE_SYSOUT` | Merge stdout and stderr to SYSOUT DD |

> **Linux:** These examples use Windows batch syntax. PYLDM runs the STDENV script with the platform's own shell, so on Linux use `export NAME=value` and `$NAME` - see [Running on Linux](#running-on-linux).

---

## <a name="step1"></a>Step 1 - Using PYLDM Directly from JCL

In this step, you invoke a Python script directly from JCL using PYLDM. This demonstrates argument passing, stream redirection, and both script and module invocation modes.

### 1.1 The Python Script

The script `sources/python/batch_report.py` prints a formatted report showing the arguments it received and the PYLDM environment:

```python
def main(args=None):
    if args is None:
        args = sys.argv[1:]

    print("=" * 60)
    print("Python Batch Report (via PYLDM)")
    print("=" * 60)

    # sys.argv[0] is the script path (script mode) or module name (module mode)
    print(f"\nScript: {sys.argv[0]}")
    print(f"Python version: {sys.version}")
    print(f"Working directory: {os.getcwd()}")

    print(f"\nArguments received: {len(args)}")
    for i, arg in enumerate(args):
        print(f"  arg[{i}] = {arg!r}")
    # ... then prints the ESPY_* environment variables and PYTHONPATH entries
```

### 1.2 The JCL

`sources/jcl/PYDEMO.jcl` invokes the script in two steps — once as a script, once as a module:

```jcl
//PYPROC  PROC PYSCRIPT=,ARGS='',LOGLVL='+I',REGSIZE='0M',LEPARM=''
//PYLDM    EXEC PGM=PYLDM,REGION=&REGSIZE,
//             PARM='&LEPARM/&LOGLVL &PYSCRIPT &ARGS'
//SYSPRINT DD  SYSOUT=*
//SYSOUT   DD  SYSOUT=*
//STDOUT   DD  SYSOUT=*
//STDERR   DD  SYSOUT=*
//         PEND
//*
//STEP1    EXEC PROC=PYPROC,
//             PYSCRIPT='batch_report.py',
//             ARGS='hello world'
//STDENV   DD  *
set PYTHONPATH=%ESP%\..\..\sources\python;%PYTHONPATH%
set ESPY_WORKING_DIR=%ESP%\..\..\sources\python
/*
//MAINARGS DD  *
arg3 arg4
/*
```

### 1.3 Key Points

- **No compilation needed** — just place `.py` files where `PYTHONPATH` or `ESPY_WORKING_DIR` can find them
- **No `PYTHON_HOME` required** — PYLDM/cblcpyiapi automatically locates the Python installation
- **Argument assembly order**: PARM args → `ESPY_MAIN_ARGS` env var → MAINARGS DD content
- **Stream redirection is automatic** — `print()` writes to the STDOUT DD
- **Log level**: `+I` (info), `+T` (trace), `+D` (debug) — first character of PARM after the `/`

### 1.4 Deploy and Run

1. Ensure `batch_report.py` is in the directory referenced by `ESPY_WORKING_DIR` or `PYTHONPATH`
2. Submit `PYDEMO.jcl` via ESCWA or `casutil`
3. Check the job output — STDOUT DD shows the report, SYSPRINT shows PYLDM messages

### 1.5 Expected Output

STEP1 (script mode) writes the following to its STDOUT DD. The PARM arguments (`hello world`) and the MAINARGS DD content (`arg3 arg4`) are concatenated into `sys.argv`:

```
============================================================
Python Batch Report (via PYLDM)
============================================================

Script: batch_report.py
Python version: 3.13.9 (tags/v3.13.9:8183fa5, Oct 14 2025, 14:09:13) [MSC v.1944 64 bit (AMD64)]
Working directory: C:\dev\BankDemo\sources\python

Arguments received: 4
  arg[0] = 'hello'
  arg[1] = 'world'
  arg[2] = 'arg3'
  arg[3] = 'arg4'

PYLDM environment:
  ESPY_ENABLE_OUTPUT_TRANSCODING = false
  ESPY_MERGE_SYSOUT = false
  ESPY_OUTPUT_ENCODING = ASCII
  ESPY_WORKING_DIR = C:\dev\BankDemo\BANKVSAM\system\..\..\sources\python

PYTHONPATH entries:
  [1] C:\dev\BankDemo\BANKVSAM\system\..\..\sources\python
  [2] C:\Program Files (x86)\Rocket Software\Enterprise Developer\binpy\esos.zip
  [3] C:\Program Files (x86)\Rocket Software\Enterprise Developer\binpy\zoautil_py.zip

Report complete. RC=0
============================================================
```

STEP2 (module mode) produces the same report with its own arguments. Note that it does not set `ESPY_WORKING_DIR`, so the working directory stays at the region's default:

```
Working directory: C:\dev\BankDemo\BANKVSAM\system\loadlib

Arguments received: 2
  arg[0] = 'moduleArg1'
  arg[1] = 'moduleArg2'
```

The `esos.zip` and `zoautil_py.zip` entries appear automatically — the JCL only adds entry `[1]`. Both steps end with `RC=0000`, and the STDERR DD is empty.

---

## <a name="step2"></a>Step 2 - Sequential File I/O from Python

In this step, you read Fixed Block (FB) records from a data file via `DD PATH=` allocation and produce a formatted summary report, demonstrating non-VSAM sequential file I/O with `zoautil_py`.

### 2.1 The Python Script

`sources/python/sequential_file_ops.py` supports two modes:

**WRITE mode** — writes the sample transaction records to the PS dataset via the `TXNDATA` DD:
```python
from zoautil_py.zoau_io import zopen

LRECL = 80  # Fixed, 80-byte card-image format

def do_write():
    f = zopen("//DD:TXNDATA", "w", lrecl=LRECL, recfm="F")
    try:
        for txn in SAMPLE_TRANSACTIONS:
            record = format_record(*txn)   # 80-byte fixed-width
            f.write(record.encode("ascii"))
    finally:
        f.close()
```

**READ mode** — reads records back from the same DD and produces a summary report with totals by account:
```python
def do_read():
    f = zopen("//DD:TXNDATA", "r", lrecl=LRECL, recfm="F")
    try:
        records = []
        while True:
            try:
                record = f.readrecord()
                if not record:
                    break
                records.append(parse_record(record))
            except Exception:
                break   # EOF - see Known Issues

        # Accumulate totals by account, print listing and summary
    finally:
        f.close()
```

### 2.2 The JCL

`sources/jcl/PYREADBNK.jcl` runs two steps — display record format and read data file:

```jcl
//* Step 1: Write sample transaction records to the PS dataset
//WRITE    EXEC PROC=PYPROC,PYSCRIPT='sequential_file_ops.py',ARGS='WRITE'
//TXNDATA  DD  DSN=MFI01V.MFIDEMO.PYTXN,DISP=OLD
//*
//* Step 2: Read records back and produce a summary report
//READ     EXEC PROC=PYPROC,PYSCRIPT='sequential_file_ops.py',ARGS='READ'
//TXNDATA  DD  DSN=MFI01V.MFIDEMO.PYTXN,DISP=SHR
```

Both steps allocate the same DD name, so a single script can write and then read the dataset. `MFI01V.MFIDEMO.PYTXN` is cataloged when the region is provisioned, from `scripts/datasets_ps/PYTXN.json`.

### 2.3 Key Points

- **Non-VSAM I/O** — uses `recfm="F"` (Fixed) instead of `"KS"` (Key-Sequenced VSAM)
- **Write with `zopen("//DD:NAME", "w", ...)`** then **read with `"r"`** — the same DD serves both modes
- **`f.write(data)`** — takes `bytes`, so encode first (`record.encode("ascii")`)
- **80-byte card image** — classic mainframe record format (LRECL=80, RECFM=F)
- **Pre-cataloged dataset** — `DISP=OLD` to write, `DISP=SHR` to read; no `DISP=(NEW,CATLG)` or IEFBR14 cleanup needed
- **No VSAM positioning needed** — sequential access reads records in order

### 2.4 Expected Output

The WRITE step populates the dataset:

```
=== Sequential Write: Writing transaction records ===
  Wrote: TXN00001  Acct=10001  CR     1500.00
  Wrote: TXN00002  Acct=10001  DR       45.99
  Wrote: TXN00003  Acct=10002  CR     3200.00
  ...
  Wrote: TXN00010  Acct=10003  CR       75.00
  ---
  Total records written: 10
=== Write Complete ===
```

The READ step reads the same dataset back and accumulates totals by account:

```
=== Sequential Read: Transaction Summary ===
  TXN ID     ACCT    DATE       TYPE      AMOUNT  DESCRIPTION
  ---------- ------- ---------- ----- ----------  --------------------
  TXN00001   10001   20260615   CR       1500.00  Monthly salary deposit
  TXN00002   10001   20260616   DR         45.99  Grocery store purchase
  TXN00003   10002   20260616   CR       3200.00  Wire transfer received
  ...
  TXN00010   10003   20260620   CR         75.00  Interest credit

  ACCOUNT     RECORDS      CREDITS       DEBITS          NET
  ---------- -------- ------------ ------------ ------------
  10001             4      1700.00       165.99      1534.01
  10002             3      3200.00      1889.50      1310.50
  10003             3       575.00       250.00       325.00
  TOTAL            10      5475.00      2305.49      3169.51

  Total records read: 10
=== Read Complete ===
```

Because WRITE recreates the ten records each time, re-running the job is safe and always produces these totals.

---

## <a name="step3"></a>Step 3 - Multi-Step Batch with Python

In this step, a single Python script serves two different batch functions (FILTER and REPORT) depending on arguments, invoked from different JCL steps.

### 3.1 The Python Script

`sources/python/bank_cust_acct_report.py` supports two modes:

**FILTER mode** — reads BNKCUST, filters by regex, writes to stdout and optionally to an output dataset:
```python
def do_filter(args):
    pattern = args[0] if args else ".*"
    regex = re.compile(pattern)

    outfile = None
    try:
        outfile = zopen("//DD:OUTFILE", "w", lrecl=132, recfm="FB")
    except Exception:
        pass  # OUTFILE DD not allocated

    f = zopen("//DD:CUSTDATA", "r", lrecl=CUST_LRECL, recfm="KS")
    try:
        f._file.locate(b'', EsosLocateOption.KEY_FIRST)
        records = read_vsam_records(f)
        for record in records:
            pid = field(record, CUST_PID)
            if regex.search(pid):
                name = field(record, CUST_NAME)
                state = field(record, CUST_STATE)
                email = field(record, CUST_EMAIL)
                line = f"  {pid}  {name:<25s}  {state}  {email}"
                print(line)
                if outfile is not None:
                    outfile.write(line.encode("ascii").ljust(132))
    finally:
        f.close()
        if outfile is not None:
            outfile.close()
```

**REPORT mode** — reads BNKACC, decodes COMP-3 balances, reads control cards from STDIN:
```python
def do_report(args):
    cards = read_control_cards()  # reads KEY=VALUE from sys.stdin
    title = cards.get("REPORT_TITLE", "Account Balance Report")
    max_records = int(cards.get("MAX_RECORDS", "20"))

    f = zopen("//DD:ACCDATA", "r", lrecl=200, recfm="KS")
    try:
        for record in records:
            balance = unpack_comp3(record, ACC_BALANCE_OFFSET, 5, 2)
            total_balance += balance
    finally:
        f.close()
```

### 3.2 The JCL

`sources/jcl/PYMULTI.jcl` runs both modes in a two-step job:

```jcl
//* Step 1: Filter customers
//STEP1    EXEC PROC=PYPROC,PYSCRIPT='bank_cust_acct_report.py',ARGS='FILTER .*'
//CUSTDATA DD  DSN=MFI01V.MFIDEMO.BNKCUST,DISP=SHR
//OUTFILE  DD  DSN=MFI01V.MFIDEMO.CUST.FILTER,DISP=OLD
//*
//* Step 2: Account balance report with control cards
//STEP2    EXEC PROC=PYPROC,PYSCRIPT='bank_cust_acct_report.py',ARGS='REPORT'
//ACCDATA  DD  DSN=MFI01V.MFIDEMO.BNKACC,DISP=SHR
//STDIN    DD  *
* Report configuration
REPORT_TITLE=BankDemo Account Summary Report
MAX_RECORDS=50
/*
```

> **Note:** `MFI01V.MFIDEMO.CUST.FILTER` is cataloged when the region is provisioned, from `scripts/datasets_ps/CUSTFILT.json`. This demonstration is therefore self-contained — you do not need to run the Java demonstration first.

### 3.3 Key Points

- **COMP-3 packed decimal decoding** — the bridge provides `_mFpyDecimalFromCOBOL` or use pure Python byte manipulation
- **Dataset write** — `zopen("//DD:X", "w", ...)` + `f.write(data)` (NOT `writerecord`)
- **Control cards via STDIN DD** — `sys.stdin` is redirected by PYLDM to the STDIN DD
- **Dual output** — write to both stdout (for console viewing) and a dataset (for downstream jobs)
- **`if outfile is not None:`** — never use truthiness on RecordIO objects (`__len__` raises NotImplementedError)

### 3.4 Expected Output

STEP1 (FILTER) lists every customer matching the pattern and writes the same lines to the OUTFILE dataset:

```
=== Customer Filter: pattern='.*' ===
  ADMIN  The Bank
  B0001  Fred Bloggs                ON
  B0002  Loretta Morden             AB
  B0003  Eleanor Rigby              ON
  ...
  B0036  James Coleburn             QC
  T0001  Desmond Jones              BC
--- 38 customers matched out of 38 total ---
  (Results also written to OUTFILE DD)
```

STEP2 (REPORT) reads the control cards from STDIN, decodes the COMP-3 balances, and totals them:

```
=== BankDemo Account Summary Report ===
  (Control cards: REPORT_TITLE=BankDemo Account Summary Report, MAX_RECORDS=50)
PID    Account    Type       Balance
----------------------------------------
  T0001 000000001  1            91.14
  T0001 000000002  2           -79.40
  T0001 000000003  3           795.52
  ...
  ... (58 more records not shown)
----------------------------------------
  Total records: 108
  Total balance:    31,302.13
=== Report Complete ===
```

The report title and the 50-record display limit both come from the STDIN control cards — change them in the JCL and the output changes accordingly. The totals still cover all 108 records.

---

## <a name="step4"></a>Step 4 - VSAM Operations from Python

In this step, you perform direct VSAM keyed lookup, sequential browse, record update, and sequential reading using the low-level `esos` API. A cleanup step restores the modified record.

### 4.1 The Python Script

`sources/python/vsam_account_ops.py` demonstrates five VSAM operations on two datasets:

**LOOKUP** — exact key match on BNKCUST. `open_custdata()` builds the `FileOptions` describing the dataset:
```python
from esos.esos import (
    Esos, EsosException, EsosFileMode, EsosLocateOption, EsosOpenFlags,
    EsosDisposition, EsosDsorg, EsosVsamType, FileOptions,
)

def open_custdata(update=False):
    opts = FileOptions()
    opts.mode_flags = EsosFileMode.MODE_TYPE_READ
    opts.open_flags = EsosOpenFlags.OPEN_MODE_RECORD | EsosOpenFlags.OPEN_MODE_BINARY
    opts.recfm = "KS"                  # Key-Sequenced (VSAM KSDS)
    opts.lrecl = CUST_LRECL            # 250
    opts.disposition = EsosDisposition.FLAG_DISP_SHR
    opts.dsorg = EsosDsorg.VSAM
    opts.vsam_type = EsosVsamType.CLUSTER
    opts.vsam_key_length = 5           # Customer ID is 5 bytes
    return Esos.default.file_open("//DD:CUSTDATA", opts)

with open_custdata() as f:
    if f.locate(key, EsosLocateOption.KEY_EQ):
        buf = bytearray(CUST_LRECL)
        f.read(buf, 0, CUST_LRECL)
        # ... extract and display fields
```

**BROWSE** — sequential read from a starting position:
```python
    f.locate(start_key, EsosLocateOption.KEY_GE)
    for i in range(max_records):
        f.read(buf, 0, CUST_LRECL)
        # ... display record
```

**UPDATE** — locate, read, modify, write back (omitting email clears it). Passing `update=True` adds `MODE_FLAG_UPDATE` and `DISP=OLD`:
```python
with open_custdata(update=True) as f:
    if f.locate(key, EsosLocateOption.KEY_EQ):
        record = read_record(f)
        set_field(record, CUST_EMAIL, new_email)
        f.update(bytes(record), 0, CUST_LRECL)
```

**READ** — sequential read of the BNKACC (account) dataset:
```python
with open_accdata() as f:
    f.locate(b'', EsosLocateOption.KEY_FIRST)
    buf = bytearray(ACC_LRECL)
    while True:
        try:
            n = f.read(buf, 0, ACC_LRECL)
            if n == 0:
                break
        except EsosException:
            break  # EOF - see Known Issues
        # ... display record
```

### 4.2 The JCL

`sources/jcl/PYVSAM.jcl` runs five steps: LOOKUP, BROWSE, UPDATE, cleanup (restore), and READ:

```jcl
//STEP1    EXEC PROC=PYPROC,PYSCRIPT='vsam_account_ops.py',ARGS='LOOKUP B0001'
//CUSTDATA DD  DSN=MFI01V.MFIDEMO.BNKCUST,DISP=SHR
//*
//STEP2    EXEC PROC=PYPROC,PYSCRIPT='vsam_account_ops.py',ARGS='BROWSE B0002 5'
//CUSTDATA DD  DSN=MFI01V.MFIDEMO.BNKCUST,DISP=SHR
//*
//STEP3    EXEC PROC=PYPROC,PYSCRIPT='vsam_account_ops.py',
//             ARGS='UPDATE B0001 newemail@example.com'
//CUSTDATA DD  DSN=MFI01V.MFIDEMO.BNKCUST,DISP=OLD
//*
//STEP4    EXEC PROC=PYPROC,PYSCRIPT='vsam_account_ops.py',ARGS='UPDATE B0001'
//CUSTDATA DD  DSN=MFI01V.MFIDEMO.BNKCUST,DISP=OLD
//*
//STEP5    EXEC PROC=PYPROC,PYSCRIPT='vsam_account_ops.py',ARGS='READ 5'
//ACCDATA  DD  DSN=MFI01V.MFIDEMO.BNKACC,DISP=SHR
```

### 4.3 Key Points

- **`EsosFile` IS a context manager** — use `with ... as f:` (unlike RecordIO)
- **`locate()` returns `bool`** — `False` means key not found (VSAM status "23")
- **Update cycle**: `locate()` → `read()` → modify → `f.update()`
- **Cleanup pattern** — Step 4 calls UPDATE with no email (clears to blank) to undo Step 3
- **Two datasets** — BNKCUST for LOOKUP/BROWSE/UPDATE, BNKACC for READ
- **Two API layers**: `zoautil_py.zopen()` (high-level, Step 2) vs `esos` (low-level, this step)

### 4.4 Known Issues (esos.py workarounds)

One known bug in `esos.py` requires a workaround in the demo code:

1. **EOF raises an exception instead of returning empty bytes.**
   `EsosFile.read()` calls `raiseOnError()` on the native return code. At VSAM end-of-file (status "10"), the native function returns non-zero, so `raiseOnError()` raises `EsosException` instead of returning 0. This affects both `EsosFile.read()` (low-level) and `zoautil_py`'s `readrecord()` (high-level). All read loops in these demos use `try/except` to catch EOF.

### 4.5 Expected Output

STEP1 (LOOKUP) retrieves a single record by exact key:

```
=== VSAM LOOKUP: key='B0001' ===
  PID:    B0001
  Name:   Fred Bloggs
  Addr:   722 Parkland Ave
  State:  ON  Post: L5H3G8
  Tel:    800-555-1234
  Email:
=== Lookup Complete ===
```

STEP2 (BROWSE) reads forward from a starting key:

```
=== VSAM BROWSE: start='B0002', max=5 ===
PID    Name                      State  Email
----------------------------------------------------------------------
  B0002 Loretta Morden            AB
  B0003 Eleanor Rigby             ON
  B0004 Desmond Jones             BC
  B0005 Felicity Arkwright        QC
  B0006 James Tiberius Kirk       QC
----------------------------------------------------------------------
  5 records displayed.
=== Browse Complete ===
```

STEP3 (UPDATE) sets the email field, and STEP4 clears it again so the job can be re-run:

```
=== VSAM UPDATE: key='B0001', new_email='newemail@example.com' ===
  Before: email=''
  After:  email='newemail@example.com'
=== Update Complete ===

=== VSAM UPDATE: key='B0001', new_email='' ===
  Before: email='newemail@example.com'
  After:  email=''
=== Update Complete ===
```

STEP5 (READ) reads the account dataset sequentially:

```
=== VSAM READ: First 5 account records (esos API) ===
  Account: 000000001  Customer: T0001  Type: 1
  Account: 000000002  Customer: T0001  Type: 2
  Account: 000000003  Customer: T0001  Type: 3
  Account: 000000004  Customer: T0001  Type: 4
  Account: 000000005  Customer: T0001  Type: 5
  ... (103 more records not shown)
  Total records: 108
=== Read Complete ===
```

The `Before:` line in STEP3 shows the value STEP4 restores. If a previous run ended early, STEP3 may report a non-blank starting email — run the job again to return the record to its original state.

---

## <a name="step5"></a>Step 5 - Calling COBOL from Python

In this step, Python calls existing COBOL subroutines via the `_mFpyCobcall` bridge function — demonstrating bidirectional interoperability.

### 5.1 The Python Script

`sources/python/cobol_interop.py` calls three COBOL programs:

```python
import ctypes

# Must use PyDLL — the conversion functions call Python C APIs internally
bridge = ctypes.PyDLL("cblcpyiapi")

# int _mFpyCobcall(const char *prog_name, int argc, cobchar_t **argv)
bridge._mFpyCobcall.restype = ctypes.c_int
bridge._mFpyCobcall.argtypes = [
    ctypes.c_char_p, ctypes.c_int, ctypes.POINTER(ctypes.c_char_p)
]

# Returns a Python object, so restype must be py_object
bridge._mFpyStringFromCOBOL.restype = ctypes.py_object

def cobcall(prog_name, *buffers):
    """Call a COBOL program with LINKAGE SECTION buffers."""
    argc = len(buffers)
    argv = (ctypes.c_char_p * argc)()
    for i, buf in enumerate(buffers):
        argv[i] = ctypes.cast(buf, ctypes.c_char_p)
    return bridge._mFpyCobcall(prog_name.encode("ascii"), argc, argv)
```

**VERSION** — call SVERSONP (simplest: 1 output parameter):
```python
def do_version():
    lk_version = ctypes.create_string_buffer(7)  # PIC X(7)
    cobcall("SVERSONP", lk_version)
    version = bridge._mFpyStringFromCOBOL(lk_version.raw, COBOL_PIC_X, 7)
    print(f"  COBOL returned version: '{version}'")
```

**DATECONV** — call UDATECNV (structured 61-byte group parameter). Field offsets are
named constants matching the COBOL copybook layout:
```python
def do_dateconv(args):
    input_date = args[0]
    buf = ctypes.create_string_buffer(CDATED_LEN)          # 61-byte group item
    buf[CDATED_DDI_TYPE:CDATED_DDI_TYPE + 1] = b'1'        # Input format: YYYYMMDD
    buf[CDATED_DDI_DATA:CDATED_DDI_DATA + 20] = input_date.encode("ascii").ljust(20)
    buf[CDATED_DDO_TYPE:CDATED_DDO_TYPE + 1] = b'2'        # Output format: DD.MMM.YYYY
    cobcall("UDATECNV", buf)
    date_output = bridge._mFpyStringFromCOBOL(
        buf[CDATED_DDO_DATA:CDATED_DDO_DATA + 20], COBOL_PIC_X, 20
    )
```

**TWOSCOMP** — call UTWOSCMP (multiple params with COMP binary):
```python
def do_twoscomp(args):
    input_text = args[0]
    lk_len = ctypes.create_string_buffer(2)
    struct.pack_into('>h', lk_len, 0, len(input_text))  # PIC S9(4) COMP
    lk_input = ctypes.create_string_buffer(256)
    lk_output = ctypes.create_string_buffer(256)
    lk_input[:len(input_text)] = input_text.encode("ascii")
    cobcall("UTWOSCMP", lk_len, lk_input, lk_output)
```

### 5.2 The JCL

`sources/jcl/PYCBLCL.jcl` runs three steps calling each operation:

```jcl
//STEP1    EXEC PROC=PYPROC,PYSCRIPT='cobol_interop.py',ARGS='VERSION'
//STEP2    EXEC PROC=PYPROC,PYSCRIPT='cobol_interop.py',ARGS='DATECONV 20260624'
//STEP3    EXEC PROC=PYPROC,PYSCRIPT='cobol_interop.py',ARGS='TWOSCOMP HELLO'
```

### 5.3 Key Points

- **`ctypes.PyDLL` not `ctypes.CDLL`** — the bridge conversion functions call Python C APIs internally (require the GIL)
- **COMP fields are big-endian** — use `struct.pack('>h', value)` for PIC S9(4) COMP under ENTCOBOL
- **Group items = single contiguous buffer** — fields at fixed offsets, matching the COBOL COPY layout
- **`_mFpyCobcall` raises `RuntimeError`** on failure (error 173 = program not found)
- **Programs must be in the loadlib** — COBOL subroutines must already be compiled and available

### 5.4 Expected Output

Each step calls a different COBOL subroutine through the bridge:

```
=== Python -> COBOL: SVERSONP (Version String) ===
  COBOL returned version: ' V5.99c'
=== Complete ===

=== Python -> COBOL: UDATECNV (Date Conversion) ===
  Input: '20260624' (YYYYMMDD)
  Output date: '24.Jun.2026         '
  System time: '16:08:59'
=== Complete ===

=== Python -> COBOL: UTWOSCMP (Two's Complement) ===
  Input:  'HELLO' (length=5)
  Input bytes:  [72, 69, 76, 76, 79]
  Output bytes: [183, 186, 179, 179, 176]
  Verification: PASSED (255 - input = output for each byte)
=== Complete ===
```

The version string and system time reflect your installation, so those two values will differ. The trailing spaces in the converted date are the unused portion of the 20-byte `PIC X(20)` output field.

---

## <a name="sources"></a>Source Files Reference

| File | Description |
|------|-------------|
| `sources/python/batch_report.py` | Step 1: PYLDM invocation, argument handling |
| `sources/python/sequential_file_ops.py` | Step 2: Non-VSAM sequential write and read via zoautil_py |
| `sources/python/bank_cust_acct_report.py` | Step 3: Multi-step FILTER + REPORT, COMP-3, dataset write, control cards |
| `sources/python/vsam_account_ops.py` | Step 4: VSAM LOOKUP / BROWSE / UPDATE / READ via esos |
| `sources/python/cobol_interop.py` | Step 5: Python→COBOL via _mFpyCobcall |
| `sources/jcl/PYDEMO.jcl` | JCL for Step 1 (script + module mode) |
| `sources/jcl/PYREADBNK.jcl` | JCL for Step 2 (sequential write, then read) |
| `sources/jcl/PYMULTI.jcl` | JCL for Step 3 (multi-step filter/report) |
| `sources/jcl/PYVSAM.jcl` | JCL for Step 4 (VSAM operations) |
| `sources/jcl/PYCBLCL.jcl` | JCL for Step 5 (COBOL interop) |

---

## <a name="api-reference"></a>Python API Reference

### High-Level: zoautil_py

| Function/Class | Purpose |
|----------------|---------|
| `zopen(path, mode, lrecl=N, recfm="XX")` | Open a dataset. Returns `RecordIO` |
| `RecordIO.readrecord()` | Read one record (returns `bytes`) |
| `RecordIO.readrecords(ALL)` | Read all records (returns `list[bytes]`) |
| `RecordIO.write(data)` | Write one record |
| `RecordIO.close()` | Close the file (NOT a context manager) |

### Low-Level: esos

| Function/Class | Purpose |
|----------------|---------|
| `Esos.default.file_open(path, opts)` | Open with full VSAM control. Returns `EsosFile` (IS a context manager) |
| `EsosFile.locate(key, option)` | Position for keyed access (returns `bool`) |
| `EsosFile.read(buffer, offset, length)` | Read the record at the current position into `buffer`; returns bytes read |
| `EsosFile.write(buffer, offset, length)` | Write a new record |
| `EsosFile.update(buffer, offset, length)` | Update the last-read record |
| `EsosFile.close()` | Close the file (also handled by the `with` block) |

### Bridge Conversion API (via ctypes.PyDLL)

| Function | Purpose |
|----------|---------|
| `_mFpyStringFromCOBOL(src, type, slen)` | COBOL PIC X → Python `str` |
| `_mFpyStringToCOBOL(tgt, type, tlen, src)` | Python `str` → COBOL PIC X |
| `_mFpyDecimalFromCOBOL(src, type, intdig, decdig, sign)` | COBOL COMP-3/DISPLAY → `decimal.Decimal` |
| `_mFpyDecimalToCOBOL(tgt, type, intdig, decdig, sign, src)` | `decimal.Decimal` → COBOL COMP-3/DISPLAY |
| `_mFpyCobcall(prog, argc, argv)` | Call a COBOL program from Python |

**Important**: Use `ctypes.PyDLL("cblcpyiapi")` — not `ctypes.CDLL`. The conversion functions call Python C API functions internally which require the GIL to be held.

---

## <a name="troubleshooting"></a>Troubleshooting

### Common Return Codes

| RC | Meaning |
|----|---------|
| 0000 | Success |
| 0100 | Unhandled Python exception (caught by PYLDM's `pyonexception`) |
| 0101 | Configuration error |
| 0102 | System error |

### Common Issues

| Symptom | Cause | Solution |
|---------|-------|----------|
| RC 0100, traceback in STDERR | Python exception | Check STDERR DD for the traceback |
| `ModuleNotFoundError` | Script not on PYTHONPATH | Add directory to PYTHONPATH in STDENV |
| `OSError: access violation reading 0x...` | Used `ctypes.CDLL` instead of `ctypes.PyDLL` | Change to `ctypes.PyDLL("cblcpyiapi")` |
| `NotImplementedError` from RecordIO | Used `if outfile:` (triggers `__len__`) | Use `if outfile is not None:` |
| `AttributeError: no attribute 'writerecord'` | Wrong write method | Use `f.write(data)` not `f.writerecord(data)` |
| Error 173 from `_mFpyCobcall` | COBOL program not found | Ensure program is compiled and in the loadlib |
| No output in STDOUT DD | Error before or during STDENV setup | Check the SYSPRINT and SYSOUT DDs. If empty, check console log for RTS145 error |

### Diagnostic Tips

- Set log level to `+T` (trace) in the JCL PARM for detailed PYLDM diagnostics in SYSPRINT
- Check SYSPRINT DD for PYLDM initialization messages
- Check STDERR DD for Python tracebacks
- PYLDM handles unhandled exceptions safely — no need for try/except in scripts

### If Python or PYLDM Setup Fails

Failures that occur while PYLDM is starting the Python interpreter happen *before* Python's `sys.stdout` and `sys.stderr` are redirected to the STDOUT and STDERR DDs. Those DDs are therefore empty, and the error is reported through the Enterprise Server job log instead.

A setup failure of this kind raises a **fatal RTS 145 error** (COBOL interoperability error) and abends the step:

```
CASKC0027E Error executing service 'PGM#PYLDM'
Execution error : file 'pyldm'
error code: 145, pc=0, call=1, seg=0
145     COBOL interoperability error (Python: Failed to load python3.dll
        (Windows error 126). Ensure Python 3 is installed and its directory
        is on PATH.)
JCLCM0192S  STEP ABENDED   STEP1.PYLDM - COND CODE RTS0145
```

Note that this is a **COND CODE of RTS0145**, not RC 0100 or RC 0101 — an important distinction, because it means Python never started rather than your script failing.

Where to look, in order:

1. **The console log and the job log.** The RTS 145 text carries the reason, always prefixed with `Python: `.
2. **The SYSOUT and SYSPRINT DDs.** PYLDM writes its own messages there via the Enterprise Server logger, independently of the Python stream redirection, so any `ESPY-BL1006I <name> = <value>` lines it managed to emit are still visible.
3. **STDOUT and STDERR will be empty.** This is expected for this class of failure and is itself a useful signal.

Common causes:

| Message | Cause |
|---------|-------|
| `Failed to load python3.dll (Windows error 126)` | Python is not installed, or the directory containing `python3.dll` is not on `PATH` |
| `Failed to load Python shared library: ...` | On Linux, `libpython3.so` / `libpython3.so.1.0` is not reachable via `LD_LIBRARY_PATH` or `ldconfig` (install `python3-devel`), or set `PYTHON_SHARED_LIB` to an explicit library name |
| Bitness mismatch | A 32-bit Python with a 64-bit region (or vice versa) — the load fails even though Python is on `PATH` |

Because the region inherits `PATH` from the environment in which Enterprise Server was started, a Python installation that works from your own command prompt is not necessarily visible to the region. If `PATH` was changed after the region started, restart the region so it picks up the new value.

