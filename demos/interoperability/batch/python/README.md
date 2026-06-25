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
- Python 3.8 or later installed and available on your system PATH
- An Enterprise Server instance configured for JCL batch processing (e.g. the [BANKVSAM](../../../demos/onprem/vsam/README.md) demonstration)
- Ensure that the Directory Server (MFDS) service is running
- Ensure that the Enterprise Server Common Web Administration (ESCWA) service is running and listening on the default port (10086)

No additional Python packages are required — the `zoautil_py` and `esos` packages are provided by the Enterprise Server installation.

### Region Configuration

The Enterprise Server region must have its `PYTHONPATH` environment variable configured to include the runtime packages provided by the installation. Add the following to the region's environment variables (via ESCWA or the region configuration):

```
PYTHONPATH=C:\Program Files (x86)\Rocket Software\Enterprise Developer\binpy\esos.zip;C:\Program Files (x86)\Rocket Software\Enterprise Developer\binpy\zoautil_py.zip
```

This region-level `PYTHONPATH` provides access to the `esos` and `zoautil_py` packages that Python scripts need for dataset I/O.

> **Note:** The `STDENV` DD in each JCL job step *appends* to this region-level `PYTHONPATH` - it adds your application script directories (e.g. `%BANKROOT%\sources\python`) so PYLDM can locate your `.py` files.

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

The STDENV DD contains environment variable assignments executed before the Python script runs. Its primary purpose is to add your **application script directories** to `PYTHONPATH` so PYLDM can locate the `.py` files to execute. It appends to the region-level `PYTHONPATH` (which provides `esos.zip` and `zoautil_py.zip`):

```
set PYTHONPATH=%BANKROOT%\sources\python;%PYTHONPATH%
set ESPY_WORKING_DIR=%BANKROOT%\sources\python
set ESPY_OUTPUT_ENCODING=ASCII
set ESPY_ENABLE_OUTPUT_TRANSCODING=false
set ESPY_MERGE_SYSOUT=false
```

| Variable | Purpose |
|----------|---------|
| `PYTHONPATH` | Appends application script directories to the region-level path (uses `%PYTHONPATH%` to preserve existing entries) |
| `ESPY_WORKING_DIR` | Working directory for the script |
| `ESPY_OUTPUT_ENCODING` | Encoding for redirected output streams |
| `ESPY_ENABLE_OUTPUT_TRANSCODING` | Enable/disable encoding transcoding |
| `ESPY_MERGE_SYSOUT` | Merge stdout and stderr to SYSOUT DD |

---

## <a name="step1"></a>Step 1 - Using PYLDM Directly from JCL

In this step, you invoke a Python script directly from JCL using PYLDM. This demonstrates argument passing, stream redirection, and both script and module invocation modes.

### 1.1 The Python Script

The script `sources/python/batch_report.py` prints a formatted report showing the arguments it received and the PYLDM environment:

```python
def main(args=None):
    if args is None:
        args = sys.argv[1:]

    print("=== Python Batch Report ===")
    print(f"  Script: {__file__}")
    print(f"  Mode: {'module' if args != sys.argv[1:] else 'script'}")
    print(f"  Arguments: {args}")
    # ... prints ESPY_* env vars and PYTHONPATH
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
set PYTHONPATH=%BANKROOT%\sources\python;%PYTHONPATH%
set ESPY_WORKING_DIR=%BANKROOT%\sources\python
/*
//MAINARGS DD  *
extraArg1 extraArg2
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

---

## <a name="step2"></a>Step 2 - Sequential File I/O from Python

In this step, you read Fixed Block (FB) records from a data file via `DD PATH=` allocation and produce a formatted summary report, demonstrating non-VSAM sequential file I/O with `zoautil_py`.

### 2.1 The Python Script

`sources/python/sequential_file_ops.py` supports two modes:

**WRITE mode** — displays the sample transaction records in their 80-byte fixed format:
```python
def do_write():
    for txn in SAMPLE_TRANSACTIONS:
        record = format_record(*txn)  # 80-byte fixed-width
        print(f"  {record}")
```

**READ mode** — reads records from the INPUT DD and produces a summary report with totals by account:
```python
from zoautil_py.zoau_io import zopen

LRECL = 80  # Fixed Block, 80-byte card-image format

def do_read():
    f = zopen("//DD:INPUT", "r", lrecl=LRECL, recfm="FB")
    try:
        records = []
        while True:
            try:
                record = f.readrecord()
                if not record:
                    break
                records.append(parse_record(record))
            except Exception:
                break

        # Accumulate totals by account, print listing and summary
    finally:
        f.close()
```

### 2.2 The JCL

`sources/jcl/PYREADBNK.jcl` runs two steps — display record format and read data file:

```jcl
//* Step 1: Display sample transaction records (record format demo)
//WRITE    EXEC PROC=PYPROC,PYSCRIPT='sequential_file_ops.py',ARGS='WRITE'
//*
//* Step 2: Read transaction data file and produce a summary report
//READ     EXEC PROC=PYPROC,PYSCRIPT='sequential_file_ops.py',ARGS='READ'
//INPUT    DD  PATH='%BANKROOT%\sources\data\transactions.dat'
```

The `DD PATH=` allocates a file-system file as a sequential DD, avoiding the need to create or catalog a dataset.

### 2.3 Key Points

- **Non-VSAM I/O** — uses `recfm="FB"` (Fixed Block) instead of `"KS"` (Key-Sequenced VSAM)
- **Read with `zopen("//DD:NAME", "r", ...)`** — opens for sequential input
- **`DD PATH=`** — allocates a file-system file as a sequential DD, no catalog entry needed
- **80-byte card image** — classic mainframe record format (LRECL=80, RECFM=FB)
- **No dataset creation** — avoids `DISP=(NEW,CATLG)` and IEFBR14 cleanup complexity
- **No VSAM positioning needed** — sequential access reads records in order

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

    f = zopen("//DD:CUSTDATA", "r", lrecl=250, recfm="KS")
    try:
        f._file.locate(b'', EsosLocateOption.KEY_FIRST)
        for record in read_vsam_records(f):
            pid = field(record, CUST_PID)
            if regex.search(pid):
                print(f"  {pid}  {name}  {state}  {email}")
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
//OUTFILE  DD  DSN=MFI01V.MFIDEMO.CUST.FILTER,DISP=(OLD,CATLG,DELETE),
//             LRECL=132,RECFM=FB
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

### 3.3 Key Points

- **COMP-3 packed decimal decoding** — the bridge provides `_mFpyDecimalFromCOBOL` or use pure Python byte manipulation
- **Dataset write** — `zopen("//DD:X", "w", ...)` + `f.write(data)` (NOT `writerecord`)
- **Control cards via STDIN DD** — `sys.stdin` is redirected by PYLDM to the STDIN DD
- **Dual output** — write to both stdout (for console viewing) and a dataset (for downstream jobs)
- **`if outfile is not None:`** — never use truthiness on RecordIO objects (`__len__` raises NotImplementedError)

---

## <a name="step4"></a>Step 4 - VSAM Operations from Python

In this step, you perform direct VSAM keyed lookup, sequential browse, record update, and sequential reading using the low-level `esos` API. A cleanup step restores the modified record.

### 4.1 The Python Script

`sources/python/vsam_account_ops.py` demonstrates five VSAM operations on two datasets:

**LOOKUP** — exact key match on BNKCUST:
```python
from esos.esos import Esos, FileOptions, EsosLocateOption, EsosFileMode, EsosOpenFlags

opts = FileOptions()
opts.mode_flags = EsosFileMode.MODE_TYPE_READ
opts.open_flags = EsosOpenFlags.OPEN_MODE_BINARY | EsosOpenFlags.OPEN_MODE_RECORD

with Esos.default.file_open("//DD:CUSTDATA", opts) as f:
    if f.locate(key, EsosLocateOption.KEY_EQ):
        buf = bytearray(250)
        f.read(buf, 0, 250)
        # ... extract and display fields
```

**BROWSE** — sequential read from a starting position:
```python
    f.locate(start_key, EsosLocateOption.KEY_GE)
    for i in range(max_records):
        f.read(buf, 0, 250)
        # ... display record
```

**UPDATE** — locate, read, modify, write back (omitting email clears it):
```python
opts.mode_flags = EsosFileMode.MODE_TYPE_READ | EsosFileMode.MODE_FLAG_UPDATE

with Esos.default.file_open("//DD:CUSTDATA", opts) as f:
    if f.locate(key, EsosLocateOption.KEY_EQ):
        buf = bytearray(250)
        f.read(buf, 0, 250)
        set_field(buf, CUST_EMAIL, new_email)
        update_record(f, buf)   # workaround for esos update() bug
```

**READ** — sequential read of the BNKACC (account) dataset:
```python
with open_accdata() as f:
    f.locate(b'', EsosLocateOption.KEY_FIRST)
    buf = bytearray(200)
    while True:
        try:
            f.read(buf, 0, 200)
        except EsosError:
            break  # EOF
        # ... display record
```

### 4.2 The JCL

`sources/jcl/PYVSAM.jcl` runs five steps: LOOKUP, BROWSE, UPDATE, cleanup (restore), and READ:

```jcl
//STEP1    EXEC PROC=PYPROC,ARGS='LOOKUP B0001'
//CUSTDATA DD  DSN=MFI01V.MFIDEMO.BNKCUST,DISP=SHR
//*
//STEP2    EXEC PROC=PYPROC,ARGS='BROWSE B0002 5'
//CUSTDATA DD  DSN=MFI01V.MFIDEMO.BNKCUST,DISP=SHR
//*
//STEP3    EXEC PROC=PYPROC,ARGS='UPDATE B0001 newemail@example.com'
//CUSTDATA DD  DSN=MFI01V.MFIDEMO.BNKCUST,DISP=OLD
//*
//STEP4    EXEC PROC=PYPROC,ARGS='UPDATE B0001'
//CUSTDATA DD  DSN=MFI01V.MFIDEMO.BNKCUST,DISP=OLD
//*
//STEP5    EXEC PROC=PYPROC,ARGS='READ 5'
//ACCDATA  DD  DSN=MFI01V.MFIDEMO.BNKACC,DISP=SHR
```

### 4.3 Key Points

- **`EsosFile` IS a context manager** — use `with ... as f:` (unlike RecordIO)
- **`locate()` returns `bool`** — `False` means key not found (VSAM status "23")
- **Update cycle**: `locate()` → `read()` → modify → `update_record(f, buf)`
- **Cleanup pattern** — Step 4 calls UPDATE with no email (clears to blank) to undo Step 3
- **Two datasets** — BNKCUST for LOOKUP/BROWSE/UPDATE, BNKACC for READ
- **Two API layers**: `zoautil_py.zopen()` (high-level, Step 2) vs `esos` (low-level, this step)

---

## <a name="step5"></a>Step 5 - Calling COBOL from Python

In this step, Python calls existing COBOL subroutines via the `_mFpyCobcall` bridge function — demonstrating bidirectional interoperability.

### 5.1 The Python Script

`sources/python/cobol_interop.py` calls three COBOL programs:

```python
import ctypes

# Must use PyDLL — bridge functions call Python C APIs internally
bridge = ctypes.PyDLL("cblcpyiapi")
bridge._mFpyCobcall.restype = ctypes.c_int
bridge._mFpyCobcall.argtypes = [
    ctypes.c_char_p, ctypes.c_int, ctypes.POINTER(ctypes.c_char_p)
]

def cobcall(prog_name, *buffers):
    """Call a COBOL program with LINKAGE SECTION buffers."""
    argc = len(buffers)
    argv = (ctypes.c_char_p * argc)()
    for i, buf in enumerate(buffers):
        argv[i] = ctypes.cast(buf, ctypes.c_char_p)
    bridge._mFpyCobcall(prog_name.encode("ascii"), argc, argv)
```

**VERSION** — call SVERSONP (simplest: 1 output parameter):
```python
def do_version():
    lk_version = ctypes.create_string_buffer(7)  # PIC X(7)
    cobcall("SVERSONP", lk_version)
    version = bridge._mFpyStringFromCOBOL(lk_version.raw, COBOL_PIC_X, 7)
    print(f"  App version: '{version}'")
```

**DATECONV** — call UDATECNV (structured 61-byte group parameter):
```python
def do_dateconv(input_date):
    buf = ctypes.create_string_buffer(61)
    buf[19:20] = b'1'                           # Input format: YYYYMMDD
    buf[20:28] = input_date.encode("ascii")     # Input date
    buf[40:41] = b'2'                           # Output format: DD.MMM.YYYY
    cobcall("UDATECNV", buf)
    date_output = bridge._mFpyStringFromCOBOL(buf[41:61], COBOL_PIC_X, 20)
```

**TWOSCOMP** — call UTWOSCMP (multiple params with COMP binary):
```python
def do_twoscomp(input_text):
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

---

## <a name="sources"></a>Source Files Reference

| File | Description |
|------|-------------|
| `sources/python/batch_report.py` | Step 1: PYLDM invocation, argument handling |
| `sources/python/sequential_file_ops.py` | Step 2: Non-VSAM sequential file read via zoautil_py |
| `sources/python/bank_cust_acct_report.py` | Step 3: Multi-step FILTER + REPORT, COMP-3, dataset write, control cards |
| `sources/python/vsam_account_ops.py` | Step 4: VSAM LOOKUP / BROWSE / UPDATE / READ via esos |
| `sources/python/cobol_interop.py` | Step 5: Python→COBOL via _mFpyCobcall |
| `sources/jcl/PYDEMO.jcl` | JCL for Step 1 (script + module mode) |
| `sources/jcl/PYREADBNK.jcl` | JCL for Step 2 (sequential write, read, cleanup) |
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
| `EsosFile.read(length)` | Read record at current position |
| `EsosFile.update(buffer, offset, length)` | Update the last-read record |
| `EsosFile.delete_record()` | Delete the last-read record |

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
| No output in STDOUT DD | Missing STDENV configuration | Add `ESPY_OUTPUT_ENCODING=ASCII` to STDENV |

### Diagnostic Tips

- Set log level to `+T` (trace) in the JCL PARM for detailed PYLDM diagnostics in SYSPRINT
- Check SYSPRINT DD for PYLDM initialization messages
- Check STDERR DD for Python tracebacks
- PYLDM handles unhandled exceptions safely — no need for try/except in scripts
