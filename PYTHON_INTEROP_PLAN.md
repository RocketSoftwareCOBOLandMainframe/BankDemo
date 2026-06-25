# Plan: Python Batch Interoperability for BankDemo

## Current Status (2026-06-24)

**All code implementation is COMPLETE and TESTED.** Remaining work is documentation only.

| Phase | Status | Notes |
|-------|--------|-------|
| Phase 1: `batch_report.py` + `PYDEMO.jcl` | ✅ Tested | Script/module mode, arg passing |
| Phase 2: `read_bank_data.py` + `PYREADBNK.jcl` | ✅ Tested | VSAM sequential read via zopen |
| Phase 3: `bank_cust_acct_report.py` + `PYMULTI.jcl` | ✅ Tested | FILTER + REPORT, COMP-3 decode |
| Phase 4: `vsam_account_ops.py` + `PYVSAM.jcl` | ✅ Tested | LOOKUP/BROWSE/UPDATE via esos |
| Phase 5: `cobol_interop.py` + `PYCBLCL.jcl` | ✅ Tested | Python→COBOL cobcall (3 programs) |
| Phase 6: FILTER dataset write (OUTFILE DD) | ✅ Tested | Dual output: stdout + dataset |
| Phase 7: REPORT control cards (STDIN DD) | ✅ Tested | KEY=VALUE params from inline JCL |
| Phase 8: `demos/.../python/README.md` | ⬜ Not started | Tutorial documentation |
| Phase 9: Update interop + root READMEs | ⬜ Not started | Cross-references |
| Phase 10: Capture output for README | ⬜ Not started | Final validation |

**Key lessons learned during implementation:**
- `RecordIO` write method is `write()` (not `writerecord()` — that's read-only)
- `if outfile:` on a `RecordIO` object triggers `__len__` → `NotImplementedError`; always use `if outfile is not None:`
- PYLDM's `pyonexception`/`pyexceptioncheck` handles unhandled exceptions safely (RC=0100); do NOT wrap scripts in try/except
- `import ctypes.util` inside a function makes `ctypes` a local variable — import at module level
- ENTCOBOL COMP fields are big-endian: `struct.pack('>h', value)`
- **Must use `ctypes.PyDLL` (not `ctypes.CDLL`)** when calling bridge conversion APIs (`_mFpyStringFromCOBOL`, `_mFpyDecimalFromCOBOL`) from Python. These functions call Python C API functions internally (`PyUnicode_FromString`, `Decimal()` constructor) which require the GIL. `CDLL` releases the GIL before the call → access violation crash. `PyDLL` keeps the GIL held.

---

## Summary

Add Python batch interoperability demonstrations mirroring the existing Java interoperability demo (`demos/interoperability/batch/java/`). The Java demo was added in commits `b3077e4..6a2dc73` and follows a 5-step tutorial structure of increasing complexity. This plan replicates that structure for Python using PYLDM (the Python Language Definition Module) as the sole invocation mechanism, in a 4-step tutorial.

---

## What the Java Demo Added (Reference)

| Category | Files | Description |
|----------|-------|-------------|
| Documentation | `demos/interoperability/README.md` | Top-level interop index (already mentions Python) |
| Documentation | `demos/interoperability/batch/java/README.md` | 1557-line, 5-step tutorial |
| COBOL | `sources/cobol/HELLOJAV.cbl` | Bootstrap: `CALL "Java.HelloBatch.run"` |
| Java | `sources/java/HelloBatch.java` | Hello World via ZUtil stream redirect |
| Java | `sources/java/BatchReport.java` | Direct JVMLDM invocation with args |
| Java | `sources/java/ReadBankData.java` | ZFile sequential dataset read (BNKACC) |
| Java | `sources/java/BankCustAcctReport.java` | Multi-step FILTER + REPORT with ZFile, COMP-3 decode |
| Java | `sources/java/VsamAccountOps.java` | VSAM KSDS LOOKUP / BROWSE / UPDATE via ZFile |
| JCL | `sources/jcl/HELLOJAV.jcl` | COBOL bootstrap JCL |
| JCL | `sources/jcl/JVMDEMO.jcl` | JVMLDM direct invocation with PROC, STDENV, MAINARGS |
| JCL | `sources/jcl/JVMREADBNK.jcl` | Dataset read JCL |
| JCL | `sources/jcl/JVMMULTI.jcl` | Multi-step batch JCL |
| JCL | `sources/jcl/JVMVSAM.jcl` | VSAM operations JCL |

### Java Mechanism Summary
- **COBOL→Java**: `CALL "Java.<Class>.<method>"` invokes a static Java method
- **JCL→Java**: `EXEC PGM=JVMLDM` runs a Java `main()` directly from JCL
- **Dataset I/O**: `com.rocketsoftware.jzos` package (ZFile, ZUtil, ZFileConstants)
- **Env config**: `STDENV` DD sets `JAVA_HOME`, `CLASSPATH`, `JZOS_*` variables

---

## Resolved: Python Interop Mechanisms

All questions from the original plan are now answered from the `esos` and `coretech` source code:

| # | Question | Java | Python (Confirmed) |
|---|----------|------|--------------------|
| 1 | COBOL CALL syntax | `CALL "Java.Class.method"` | Not used in these demos. PYLDM is the supported mechanism.  |
| 2 | Direct JCL invocation | `EXEC PGM=JVMLDM` | `EXEC PGM=PYLDM` — COBOL program in `esos/src/ldm/cbl/pyldm.cbl` |
| 3 | Dataset/DD I/O package | `com.rocketsoftware.jzos` (ZFile) | `zoautil_py.zoau_io` (`zopen()`, `RecordIO`) + low-level `esos.esos` (`EsosFile`, `FileOptions`) |
| 4 | Stream redirection | `ZUtil.redirectStandardStreams()` | **Automatic** via PYLDM (calls `esos.ldm.ldm_redirect_streams()`). Manual: `esos.util.redirect_streams()` |
| 5 | Env vars | `JAVA_HOME`, `CLASSPATH`, `JZOS_*` | `PYTHONPATH`, `ESPY_*` vars (see table below) |
| 6 | VSAM keyed ops | `ZFile.locate()` | `EsosFile.locate(key, EsosLocateOption.KEY_EQ)` — fully exposed with `KEY_EQ`, `KEY_GE`, `KEY_FIRST`, `KEY_LAST`, `KEY_EQ_BWD`, `RBA_EQ`. Also: `delete_record()`, `getpos()`/`setpos()`, `rba` property. |
| 7 | Bridge role | cblcjiapi (`_mFj*`) | cblcpyiapi (`_mFpy*`) — `_mFpyCallScript` (void), `_mFpyCallModule` (void) called by PYLDM. Note: both return void — no return code from scripts. |

### Python Environment Variables (STDENV)

| Variable | Purpose | Default |
|----------|---------|---------|
| `PYTHONPATH` | Python module search path | (via STDENV) |
| `ESPY_MAIN_ARGS` | Additional arguments from env | (none) |
| `ESPY_MAIN_ARGS_DD` | DD name for argument file | `MAINARGS` |
| `ESPY_OUTPUT_ENCODING` | Encoding for redirected streams | system default |
| `ESPY_ENABLE_OUTPUT_TRANSCODING` | Enable encoding transcoding | `true` |
| `ESPY_MERGE_SYSOUT` | Merge stdout+stderr to SYSOUT DD | `false` |
| `ESPY_WORKING_DIR` | Working directory override | (none) |
| `ESPY_VALIDATE_RUNTIME_ENV_SYNC` | Debug trace for env sync | (optional) |

### PYLDM Invocation Modes

1. **Script mode**: `PARM='script.py arg1 arg2'` — calls `_mFpyCallScript` (returns void)
2. **Module mode**: `PARM='-m module_name arg1 arg2'` — calls `_mFpyCallModule` (returns void)

**Args passing to bridge**: Fixed-width flat buffer (260 bytes per arg slot, COBOL_PIC_X type, zero-terminated within slot). PYLDM's `flatten-mainargs` section converts the pointer vector to this format.

### Critical: Error Handling in Python Scripts

The Python interpreter is initialized **once** per region lifetime (by `_mFpyInitPython`). CPython does not support clean reinit, so the same interpreter is reused across all PYLDM invocations until the region is restarted.

**PYLDM exception handling (`pyonexception`/`pyexceptioncheck`)**:
- PYLDM wraps script execution with `pyonexception` / `pyexceptioncheck` directives
- If a Python script raises an unhandled exception, PYLDM catches it safely
- The exception traceback is printed to STDERR
- `ws-max-rc` is set to 100 (via `set ws-rc-main-exception to true`)
- Streams are properly restored regardless of the exception

**Recommended pattern** — let exceptions propagate:
```python
if __name__ in ("__main__", "<run_path>"):
    main()
```

Do **NOT** wrap entry points in try/except — this is counterproductive because:
1. PYLDM's `pyonexception` mechanism already handles unhandled exceptions safely
2. A try/except swallows the exception, causing PYLDM to report RC 0000 (success) instead of RC 0100 (error)
3. The exception traceback is still printed (PYLDM handles this before restoring streams)

**Return codes from PYLDM**:
- `0000` — script completed successfully
- `0100` — unhandled exception (caught by `pyonexception`)
- `0101` — configuration error
- `0102` — system error

**Module mode caching**: `_mFpyCallModule` invalidates the module from `sys.modules` before each import, so code changes are picked up without region restart. Sub-modules imported by the main module remain cached (library modules like `esos`, `zoautil_py` don't change between runs).

### Python Entry Point Conventions

- **Script mode**: Python script runs as `__main__`, receives args via `sys.argv`
- **Module mode**: Module must define `def main(args: list[str] | None = None) -> int:` — receives args as parameter

### VSAM Support (Fully Available)

All VSAM operations are now exposed in the Python `esos.py` wrapper:

| Python Method | Java Equivalent | Description |
|---------------|-----------------|-------------|
| `file.locate(key, EsosLocateOption.KEY_EQ)` | `zFile.locate(key, LOCATE_KEY_EQ)` | Exact key match |
| `file.locate(key, EsosLocateOption.KEY_GE)` | `zFile.locate(key, LOCATE_KEY_GE)` | First record with key >= given key |
| `file.locate(key, EsosLocateOption.KEY_FIRST)` | `zFile.locate(key, LOCATE_KEY_FIRST)` | Position to first record |
| `file.locate(key, EsosLocateOption.KEY_LAST)` | `zFile.locate(key, LOCATE_KEY_LAST)` | Position to last record |
| `file.locate(key, EsosLocateOption.KEY_EQ_BWD)` | `zFile.locate(key, LOCATE_KEY_EQ_BWD)` | Exact key, backward read |
| `file.delete_record()` | `zFile.delrec()` | Delete last-read record |
| `file.rba` | N/A | Relative byte address (property) |
| `file.getpos()` / `file.setpos(pos)` | `zFile.getPos()` / `zFile.setPos()` | Save/restore position (`FcdEncodedOffset`) |

`locate()` returns `bool` — `False` when the record is not found (VSAM status "23" or "10"), `True` on success. This matches Java's `ZFile.locate()` behavior.

---

## Proposed File Inventory

### New Files to Create

| # | File | Python Equivalent Of | Description |
|---|------|---------------------|-------------|
| 1 | `demos/interoperability/batch/python/README.md` | `batch/java/README.md` | Full tutorial (4 steps), ~1200 lines |
| 2 | `sources/python/batch_report.py` | `BatchReport.java` | Direct PYLDM invocation, argument handling |
| 3 | `sources/python/read_bank_data.py` | `ReadBankData.java` | Sequential dataset read (BNKACC) via Python ZFile equivalent |
| 4 | `sources/python/bank_cust_acct_report.py` | `BankCustAcctReport.java` | Multi-step FILTER + REPORT, COMP-3 decode |
| 5 | `sources/python/vsam_account_ops.py` | `VsamAccountOps.java` | VSAM KSDS LOOKUP / BROWSE / UPDATE |
| 6 | `sources/jcl/PYDEMO.jcl` | `JVMDEMO.jcl` | JCL for direct PYLDM invocation |
| 7 | `sources/jcl/PYREADBNK.jcl` | `JVMREADBNK.jcl` | JCL for dataset read demo |
| 8 | `sources/jcl/PYMULTI.jcl` | `JVMMULTI.jcl` | JCL for multi-step batch |
| 9 | `sources/jcl/PYVSAM.jcl` | `JVMVSAM.jcl` | JCL for VSAM operations |

### Files to Modify

| # | File | Change |
|---|------|--------|
| 1 | `demos/interoperability/README.md` | Add Python section under "Available Demonstrations" + update Prerequisites |
| 2 | `README.md` (root) | Possibly mention Python interop demo in the "Available demonstrations" list |

---

## 4-Step Tutorial Structure (Mirroring Java)

### Step 1 — Using PYLDM Directly from JCL ✅ COMPLETE

**Goal**: Invoke Python script directly from JCL using PYLDM (the Python Language Definition Module).

- **Python** (`batch_report.py`):
  - **Script mode** (default): runs as `__main__`, reads `sys.argv` for args
  - **Module mode**: defines `def main(args=None)` — receives args as parameter
  - Prints formatted report header, argument list, ESPY_* env vars, PYTHONPATH
  - No need to call `redirect_streams()` — PYLDM handles this automatically
- **JCL** (`PYDEMO.jcl`):
  - Inline PYPROC (mirrors JVMPROC): `EXEC PGM=PYLDM,PARM='&LEPARM/&LOGLVL &PYSCRIPT &ARGS'`
  - DD allocations: SYSPRINT, SYSOUT, STDOUT, STDERR, CEEDUMP, ABNLIGNR
  - STDENV DD sets `PYTHONPATH` using `%BANKROOT%` for portability (no PYTHON_HOME needed — PYLDM finds Python automatically)
  - **STDENV env-sync flow**: PYLDM executes STDENV script natively → calls `esos.ldm.ldm_update_env()` which refreshes `os.environ` from the native process environment
  - Step 1 (script mode): `PYSCRIPT='batch_report.py'`, `ARGS='hello world'` + MAINARGS DD
  - Step 2 (module mode): `PYSCRIPT='-m batch_report'`, `ARGS='moduleArg1 moduleArg2'`
  - Demonstrates argument passing:
    1. **PARM** args after script name
    2. **ESPY_MAIN_ARGS** env var in STDENV
    3. **MAINARGS DD** inline data

**Key teaching points**:
- STDENV configuration: `PYTHONPATH` is the Python equivalent of `CLASSPATH`
- No `PYTHON_HOME` needed — cblcpyiapi scans standard locations to find Python
- STDENV env vars are synced to Python via `ldm_update_env()` (refreshes `os.environ` from native process)
- Argument assembly order: PARM → ESPY_MAIN_ARGS → MAINARGS (same as Java)
- Script mode vs module mode (`-m` flag) — see below
- PYLDM handles stream redirection automatically
- `_mFpyCallScript`/`_mFpyCallModule` return void — no script return code propagation
- Log level: `+I` (info), `+T` (trace), `+D` (debug) — first arg starting with `+`

#### Script Mode vs Module Mode

| | Script Mode | Module Mode |
|---|---|---|
| **PYSCRIPT value** | `'batch_report.py'` | `'-m batch_report'` |
| **Bridge function** | `_mFpyCallScript` → `runpy.run_path()` | `_mFpyCallModule` → imports module, calls `main(args)` |
| **File resolution** | File path relative to CWD (or absolute) | Module name resolved via `sys.path` (PYTHONPATH) |
| **Requires ESPY_WORKING_DIR** | Yes — CWD must contain the script file | No — only needs PYTHONPATH |
| **Requires PYTHONPATH** | No — Python auto-adds script dir to `sys.path[0]` | Yes — module must be importable |
| **Entry point** | Module-level code / `if __name__ == "__main__":` | `def main(args=None)` function |
| **Args delivery** | `sys.argv` (set by bridge before run_path) | `args` parameter passed to `main()` |
| **Equivalent CLI** | `python batch_report.py arg1 arg2` | `python -m batch_report arg1 arg2` |

**When to use which:**
- **Script mode**: Simple one-off scripts, scripts that use `if __name__ == "__main__":` pattern
- **Module mode**: Reusable modules, testable code (main can be called from tests), cleaner separation of concerns

### Step 2 — Accessing Datasets from Python with zoautil_py

**Goal**: Read Enterprise Server datasets from Python using the `zoautil_py` record I/O API.

- **Python** (`read_bank_data.py`):
  - `from zoautil_py.zoau_io import zopen, ALL`
  - Opens `//DD:ACCDATA` using `zopen("//DD:ACCDATA", "r", lrecl=200, recfm="F")`
  - Reads records via `f.readrecords(ALL)` — returns list of `bytes`
  - Extracts account ID, customer ID, account type from byte slices: `record[0:9].decode().strip()`
  - Displays first N records (N from `sys.argv[1]`)
  - **Note**: `RecordIO` (returned by `zopen()`) is NOT a context manager — must use try/finally:
    ```python
    f = zopen("//DD:ACCDATA", "r", lrecl=200, recfm="F")
    try:
        records = f.readrecords(ALL)
        for record in records[:n]:
            print(record[0:9].decode().strip())
    finally:
        f.close()
    ```
- **JCL** (`PYREADBNK.jcl`):
  - ACCDATA DD → `MFI01V.MFIDEMO.BNKACC`
  - Uses PYPROC with STDENV setting `PYTHONPATH`
  - `PARM='read_bank_data.py 5'`

**Key teaching points**:
- `zopen()` is the Python equivalent of Java's `new ZFile()`
- **Must specify `lrecl` and `recfm`** — unlike Java's ZFile which gets them from the DD
- **`RecordIO` is NOT a context manager** — use try/finally with explicit `f.close()`
- Binary record access: byte slicing (`record[offset:offset+length]`) instead of `new String(record, offset, length)`
- `readrecords(ALL)` vs `readrecord()` for batch vs single-record reads
- DD-based file access: `//DD:NAME` path pattern (same as Java `//DD:NAME`)

### Step 3 — Multi-Step Batch: Customer Account Summary

**Goal**: Realistic multi-step batch job processing BankDemo datasets.

- **Python** (`bank_cust_acct_report.py`):
  - **FILTER mode** (`sys.argv[1] == "FILTER"`):
    - Opens `//DD:CUSTDATA` via `zopen()` — reads BNKCUST (lrecl=250, recfm="F")
    - Filters by regex pattern from args using `re.match(pattern, pid)`
    - Writes matches to output dataset via `zopen("//DD:OUTFILE", "w", lrecl=132, recfm="FB")` if OUTFILE DD is allocated
    - Writes to both `sys.stdout` and the dataset simultaneously
    - Uses try/finally for explicit `close()` (RecordIO is not a context manager)
  - **REPORT mode** (`sys.argv[1] == "REPORT"`):
    - Reads control cards from `sys.stdin` (key=value pairs)
    - Opens `//DD:ACCDATA` — reads BNKACC (lrecl=200, recfm="F")
    - Decodes COMP-3 packed-decimal balances using Python byte manipulation:
      ```python
      def unpack_decimal(data, offset, length, scale):
          digits = []
          for i in range(length):
              b = data[offset + i]
              digits.append(str((b >> 4) & 0x0F))
              if i < length - 1:
                  digits.append(str(b & 0x0F))
          sign = data[offset + length - 1] & 0x0F
          value = Decimal(''.join(digits)) / Decimal(10 ** scale)
          return -value if sign == 0x0D else value
      ```
    - Writes formatted report to stdout AND `zopen("//'MFI01V.MFIDEMO.ACCT.SUMMARY'", "w", ...)`
    - Logs diagnostics to `sys.stderr`
    - All file handles explicitly closed in finally blocks
- **JCL** (`PYMULTI.jcl`):
  - Step 1: `PARM='bank_cust_acct_report.py FILTER'`, MAINARGS DD with regex pattern, CUSTDATA DD
  - Step 2: `PARM='bank_cust_acct_report.py REPORT 25'`, STDIN DD with control cards, ACCDATA DD

**Key teaching points**:
- COMP-3 packed-decimal decoding in Python (using `decimal.Decimal` for precision)
- Multi-step job with different operations per step
- `zopen()` with write mode creates datasets (`"w"` mode)
- `RecordIO` is NOT a context manager — use try/finally with explicit `close()`
- Simultaneous output to stdout and dataset
- Control card processing via `sys.stdin` (already redirected by PYLDM)
- No job context API yet in Python (unlike Java's `ZUtil.getCurrentJobname()`)

### Step 4 — VSAM Operations from Python

**Goal**: Demonstrate direct VSAM KSDS operations from Python — **keyed lookup**, **sequential browse**, and **record update** — matching the Java demo exactly.

- **Python** (`vsam_account_ops.py`):
  - Uses low-level `esos` API (`Esos`, `EsosFile`, `FileOptions`, `EsosLocateOption`, `EsosFileMode`, `EsosOpenFlags`) for full VSAM control
  - **EsosFile IS a context manager** — can use `with Esos.default.file_open(path, opts) as f:`
  - **LOOKUP**: Opens `//DD:CUSTDATA` in record mode, calls `file.locate(key, EsosLocateOption.KEY_EQ)`, reads and displays record fields
  - **BROWSE**: Positions to key using `file.locate(key, EsosLocateOption.KEY_GE)` (or `KEY_FIRST` for empty key), reads up to N records sequentially
  - **UPDATE**: Opens with `MODE_TYPE_READ` + update flags, locates record by key with `KEY_EQ`, reads it, toggles SendMail flag (`Y`↔`N`), calls `file.update(buffer, offset, length)` to write back
  - Operates on `MFI01V.MFIDEMO.BNKCUST` (same dataset as Java demo)
  - Displays BNKCUST record layout (PID, Name, Address, Phone, Email, SendMail, SendEmail)
  - Key padding: `key.ljust(vsam_key_length, b'\x00')` to match exact VSAM key length
- **JCL** (`PYVSAM.jcl`):
  - Step 1: LOOKUP B0001 — locate and display specific customer
  - Step 2: BROWSE from start, 10 records
  - Step 3: UPDATE B0001 — toggle SendMail flag

**Key teaching points**:
- Low-level `esos` API: `Esos.default.file_open()`, `FileOptions`, `EsosFile`
- **`EsosFile` IS a context manager** (unlike `RecordIO`) — use `with ... as f:`
- `FileOptions` setup: `mode_flags`, `open_flags = OPEN_MODE_BINARY | OPEN_MODE_RECORD`
- `EsosLocateOption.KEY_EQ` for exact match, `KEY_GE` for browse, `KEY_FIRST` for start
- `locate()` returns `bool` — check before `read()` (mirrors Java's `ZFile.locate()` pattern)
- Read-only mode vs update mode (`FLAG_MODE_UPDATE`)
- Record update cycle: `locate()` → `read()` → modify bytes → `update()`
- Key must be exactly `vsam_key_length` bytes — pad with null bytes if shorter
- BNKCUST record layout (offsets, field lengths from CBANKVCS.cpy)
- Difference between `zoautil_py.zopen()` (high-level, no locate, NOT context manager) and `esos` (low-level, full VSAM, IS context manager) APIs

---

## Documentation Plan

### `demos/interoperability/batch/python/README.md` (~1200 lines)

Mirror the Java README structure exactly:

1. **Header** — "Batch Python Interoperability with PYLDM"
2. **Contents** — Table of contents with anchors
3. **Prerequisites** — Python 3.8+, Enterprise Developer/Server, running MFDS + ESCWA
4. **Overview** — How It Works diagram (JCL → PYLDM → cblcpyiapi → Python → Enterprise Server)
5. **Step 1–4** — Each with:
   - Explanation of the concept
   - Complete source code (Python + JCL)
   - DD allocation tables
   - Deploy instructions (no compile step for Python — just copy `.py` to PYTHONPATH directory)
   - Expected output (copy from actual runs)
   - Key points / notes
6. **Source Files Reference** — Table mapping files to locations
7. **Python API Reference** — Cover both API layers:
   - `zoautil_py.zoau_io` — `zopen()`, `RecordIO` (NOT context manager, truthiness check triggers `__len__` which raises `NotImplementedError` — always use `is not None`), `RecordIO_TextWrapper`, `readrecords()`, `readrecord()`, `write()`
   - `esos` — `Esos`, `EsosContext`, `EsosFile` (IS context manager), `FileOptions`, `EsosFileMode`, `EsosOpenFlags`, `EsosLocateOption`, `FcdEncodedOffset`
     - VSAM: `locate()`, `update()`, `delete_record()`, `getpos()`/`setpos()`, `rba`
   - `esos.util` — `redirect_streams()`, `restore_streams()`
8. **Troubleshooting** — Common errors, return codes, diagnostics
   - RC 100 = exception, RC 101 = config error, RC 102 = system error
   - SYSPRINT/SYSOUT for PYLDM messages
   - STDERR for Python tracebacks

### `demos/interoperability/README.md` Updates

Add under "Available Demonstrations → Batch Interoperability":
```markdown
- [Python Batch Interoperability](batch/python/README.md)
    - Invoke Python scripts from JCL using PYLDM
    - Access datasets from Python using the zoautil_py and ESOS APIs
```

Update Prerequisites to include Python 3.8+.

---

## Implementation Order (Original 4-Step Plan)

| Phase | Tasks | Dependencies |
|-------|-------|-------------|
| **Phase 1** ✅ | Create `sources/python/batch_report.py` + `sources/jcl/PYDEMO.jcl` | None |
| **Phase 2** ✅ | Create `sources/python/read_bank_data.py` + `sources/jcl/PYREADBNK.jcl` | None |
| **Phase 3** ✅ | Create `sources/python/bank_cust_acct_report.py` + `sources/jcl/PYMULTI.jcl` | None |
| **Phase 4** ✅ | Create `sources/python/vsam_account_ops.py` + `sources/jcl/PYVSAM.jcl` | None — full VSAM locate/update available |
| **Phase 5** ✅ | `cobol_interop.py` + `PYCBLCL.jcl` — Python→COBOL cobcall | Loadlib with SVERSONP, UDATECNV, UTWOSCMP |
| **Phase 6** ✅ | Enhance FILTER mode: write to output dataset + PYMULTI.jcl OUTFILE DD | Phase 3 |
| **Phase 7** ✅ | Enhance REPORT mode: read control cards from STDIN DD | Phase 3 |
| **Phase 8** | Write `demos/interoperability/batch/python/README.md` | Phases 1–7 |
| **Phase 9** | Update `demos/interoperability/README.md` + root `README.md` | Phase 8 |
| **Phase 10** | End-to-end test, capture output for README | All |

---

## Key Differences: Python vs Java Implementation

| Aspect | Java | Python |
|--------|------|--------|
| **Direct JCL invocation** | `EXEC PGM=JVMLDM` | `EXEC PGM=PYLDM` |
| **Bridge library** | cblcjiapi (`_mFj*` exports) | cblcpyiapi (`_mFpy*` exports) |
| **Language style** | Compiled `.class` files deployed to loadlib | `.py` scripts — no compilation, just copy to PYTHONPATH dir |
| **Entry point (PYLDM script)** | `public static void main(String[])` | Module-level code / `if __name__ == "__main__":` |
| **Entry point (PYLDM module)** | N/A | `def main(args: list[str] \| None = None) -> int:` |
| **Dataset I/O (high-level)** | `new ZFile("//DD:X", "rb,type=record")` | `zopen("//DD:X", "r", lrecl=200, recfm="F")` — returns `RecordIO` (NOT a context manager) |
| **Dataset I/O (low-level)** | N/A | `Esos.default.file_open(path, FileOptions())` — returns `EsosFile` (IS a context manager) |
| **Record read** | `zFile.read(record)` returns bytes read | `f.readrecords(ALL)` returns `list[bytes]` |
| **Record update** | `zFile.update(record)` | `file.update(buffer, offset, length)` (low-level `EsosFile` only) |
| **VSAM keyed lookup** | `zFile.locate(key, LOCATE_KEY_EQ)` | `file.locate(key, EsosLocateOption.KEY_EQ)` → `bool` (low-level `EsosFile` only) |
| **Cross-language call** | COBOL→Java: `CALL "Java.Class.method"` | Python→COBOL: `_mFpyCobcall(prog, argc, argv)` via ctypes |
| **Dataset write** | `zFile.write(record)` | `zopen("//DD:X", "w", lrecl=N, recfm="FB")` + `f.write(data)` |
| **Stream/STDIN reading** | `new BufferedReader(InputStreamReader(System.in))` | `sys.stdin.readline()` (STDIN DD redirected by PYLDM) |

---

## Gap Analysis: Additional Demos (Steps 5–8)

The following gaps were identified by comparing Python coverage against the Java demo suite and considering unique Python capabilities.

### Step 5 — Python→COBOL Interop (`_mFpyCobcall`)

**Gap**: Java demonstrated COBOL→Java (`CALL "Java.HelloBatch.run"`). Python has the **reverse** — Python calling COBOL programs via `_mFpyCobcall`. This is a unique Python capability not available in the Java bridge and the most significant missing demo.

**Goal**: Call existing BankDemo COBOL subroutines from Python using ctypes to build LINKAGE SECTION buffers, demonstrating bidirectional interoperability.

**Target COBOL programs** (no CICS dependency, already compiled in loadlib):

| Program | Function | LINKAGE | Complexity |
|---------|----------|---------|------------|
| `SVERSONP` | Returns app version string | `LK-VERSION PIC X(7)` (output) | Trivial — "hello world" |
| `UDATECNV` | Date/time format conversion | `LK-DATE-WORK-AREA` (~60 byte group: input type, input date, output type, output date) | Medium — real utility |
| `UTWOSCMP` | Two's complement computation | 3 params: length (S9(4) COMP), input PIC X(256), output PIC X(256) | Trivial — shows input→output |

**Python** (`cobol_interop.py`):
```python
"""
Demonstrates calling COBOL programs from Python via _mFpyCobcall.

Usage:
  EXEC PGM=PYLDM,PARM='cobol_interop.py VERSION'
  EXEC PGM=PYLDM,PARM='cobol_interop.py DATECONV 20260624'
  EXEC PGM=PYLDM,PARM='cobol_interop.py TWOSCOMP HELLO'
"""
import ctypes
import sys

# _mFpyCobcall signature: int (const char *prog, int argc, cobchar_t **argv)
# Called via ctypes. On error raises RuntimeError (PyErr_SetString in bridge).
# Each argv[i] is a pointer to a flat buffer matching COBOL LINKAGE.

def cobcall(prog_name: str, *buffers: bytearray) -> None:
    """Call a COBOL program with LINKAGE SECTION buffers."""
    ...

def do_version():
    """Call SVERSONP — returns PIC X(7) version string."""
    buf = bytearray(7)
    cobcall("SVERSONP", buf)
    print(f"  App version: '{buf.decode('ascii').strip()}'")

def do_dateconv(input_date: str):
    """Call UDATECNV — convert YYYYMMDD to DD.MMM.YYYY."""
    # Build 60-byte work area matching CDATED copybook layout
    ...

def do_twoscomp(input_text: str):
    """Call UTWOSCMP — compute two's complement of input bytes."""
    # 3 LINKAGE params: length (2 bytes COMP), input (256), output (256)
    ...
```

**JCL** (`PYCBLCL.jcl`):
- Step 1: `ARGS='VERSION'` — simplest possible cobcall
- Step 2: `ARGS='DATECONV 20260624'` — date conversion with structured group parameter
- Step 3: `ARGS='TWOSCOMP HELLO'` — byte manipulation showing input→output

**Key teaching points**:
- ctypes buffer construction matching COBOL LINKAGE SECTION layouts
- COMP (binary) field encoding: `struct.pack('>h', length)` for PIC S9(4) COMP
- Group items: single contiguous buffer with fields at fixed offsets
- Error handling: `_mFpyCobcall` raises `RuntimeError` on COBOL error (error 173 = not found, etc.)
- GIL handling is transparent to the Python caller (bridge handles internally)
- Programs must be available in loadlib (already compiled in BankDemo)

---

### Step 6 — Dataset Write with Filtered Output

**Gap**: Java's `BankCustAcctReport.FILTER` writes matched records to an output dataset (`//'MFI01V.MFIDEMO.CUST.FILTER'`). Python FILTER step only writes to stdout. This leaves dataset WRITE undemonstrated.

**Goal**: Add output dataset writing to the existing FILTER step, plus a new standalone script showing sequential dataset creation (write new records).

**Approach A — Enhance existing `bank_cust_acct_report.py` FILTER mode**:
- Add optional `OUTFILE` DD: if allocated, write matched records to it
- Uses `zopen("//DD:OUTFILE", "w", lrecl=132, recfm="FB")` + `f.write(line.encode())`
- Falls back gracefully if DD not allocated (write to stdout only)
- Add `//OUTFILE DD DSN=MFI01V.MFIDEMO.CUST.FILTER,DISP=(NEW,CATLG),LRECL=132,RECFM=FB` to PYMULTI.jcl Step 1

**Approach B — New standalone script (`write_report.py`)**:
```python
"""
Reads BNKACC, produces a formatted report written to an output dataset.
Demonstrates dataset WRITE from Python.

Usage:
  EXEC PGM=PYLDM,PARM='write_report.py'
"""
from zoautil_py.zoau_io import zopen
from esos.esos import EsosLocateOption

def main():
    # Read accounts
    infile = zopen("//DD:ACCDATA", "r", lrecl=200, recfm="KS")
    outfile = zopen("//DD:RPTOUT", "w", lrecl=132, recfm="FB")
    try:
        infile._file.locate(b'', EsosLocateOption.KEY_FIRST)
        # ... read records, format, write to outfile ...
        outfile.write(header_line)
        for record in records:
            outfile.write(formatted_line)
        outfile.write(total_line)
    finally:
        infile.close()
        outfile.close()
```

**Recommendation**: Approach A (enhance existing) — keeps demo count manageable, shows the "dual output" pattern (stdout for console + DD for batch output), mirrors what Java does exactly.

**JCL changes to PYMULTI.jcl Step 1**:
```jcl
//OUTFILE  DD  DSN=MFI01V.MFIDEMO.CUST.FILTER,
//             DISP=(NEW,CATLG,DELETE),
//             LRECL=132,RECFM=FB
```

---

### Step 7 — Control Cards / STDIN DD Reading

**Gap**: Java's `BankCustAcctReport.REPORT` reads control cards from STDIN (`readControlCards()`) to parameterize the report (e.g., `REPORT_TITLE=...`). Python demos don't demonstrate reading JCL inline data via STDIN.

**Goal**: Demonstrate reading inline JCL data (control cards) from `sys.stdin` in a Python script, showing how JCL `//STDIN DD *` data flows through PYLDM to Python.

**Approach — Enhance `bank_cust_acct_report.py` REPORT mode**:
```python
def read_control_cards() -> dict[str, str]:
    """Read KEY=VALUE control cards from STDIN DD (if available)."""
    cards = {}
    try:
        for line in sys.stdin:
            line = line.strip()
            if not line or line.startswith('*'):
                continue
            if '=' in line:
                key, _, value = line.partition('=')
                cards[key.strip()] = value.strip()
    except (EOFError, OSError):
        pass  # No STDIN DD allocated or empty
    return cards

def do_report(args):
    cards = read_control_cards()
    title = cards.get("REPORT_TITLE", "Account Balance Report")
    max_records = int(cards.get("MAX_RECORDS", args[0] if args else "20"))
    ...
```

**JCL addition to PYMULTI.jcl Step 2**:
```jcl
//STDIN    DD  *
REPORT_TITLE=BankDemo Account Summary Report
MAX_RECORDS=50
/*
```

**Key teaching points**:
- `sys.stdin` is redirected by PYLDM to the STDIN DD (same as Java's `System.in`)
- Inline JCL data (`DD *`) appears as standard input to the Python script
- Graceful handling when STDIN DD is not allocated (catch `OSError`)
- Control card pattern: `KEY=VALUE`, ignore blank lines and `*` comments

---

### ~~Step 8 — COBOL→Python Bootstrap~~ (Removed)

Removed from scope. The `_mFpyCall` export is for internal PYLDM use only, not a supported user API. The cobcall direction (Step 5) is the compelling bidirectional interop story.

---

## Updated Implementation Order

| Phase | Tasks | Dependencies | Priority |
|-------|-------|-------------|----------|
| **Phase 1** ✅ | `batch_report.py` + `PYDEMO.jcl` | None | — |
| **Phase 2** ✅ | `read_bank_data.py` + `PYREADBNK.jcl` | None | — |
| **Phase 3** ✅ | `bank_cust_acct_report.py` + `PYMULTI.jcl` | None | — |
| **Phase 4** ✅ | `vsam_account_ops.py` + `PYVSAM.jcl` | None | — |
| **Phase 5** ✅ | `cobol_interop.py` + `PYCBLCL.jcl` — Python→COBOL cobcall | Loadlib with SVERSONP, UDATECNV, UTWOSCMP | **HIGH** |
| **Phase 6** ✅ | Enhance FILTER mode: write to output dataset + PYMULTI.jcl OUTFILE DD | Phase 3 | **MEDIUM** |
| **Phase 7** ✅ | Enhance REPORT mode: read control cards from STDIN DD | Phase 3 | **LOW** |
| **Phase 8** | Write `demos/interoperability/batch/python/README.md` | Phases 1–7 | — |
| **Phase 9** | Update `demos/interoperability/README.md` + root `README.md` | Phase 8 | — |
| **Phase 10** | End-to-end test, capture output for README | All | — |

---

## Step 5 Technical Details: `_mFpyCobcall` from Python

### Bridge Function Signature

```c
int _mFpyCobcall(const char *prog_name, int argc, cobchar_t **argv)
```

- `prog_name`: null-terminated COBOL program name (e.g., `"SVERSONP"`)
- `argc`: number of LINKAGE SECTION parameters
- `argv`: array of `argc` pointers, each pointing to a buffer matching the corresponding LINKAGE parameter
- Returns: 0 on success. On failure: sets Python exception via `PyErr_SetString` → ctypes auto-raises `RuntimeError`

### ctypes Calling Pattern

```python
import ctypes

# Load the bridge (already loaded by PYLDM — find it).
# IMPORTANT: Use PyDLL, not CDLL. The bridge conversion functions
# (_mFpyStringFromCOBOL, _mFpyDecimalFromCOBOL) call Python C API
# functions internally. PyDLL keeps the GIL held; CDLL releases it,
# causing access violations when the C code calls back into Python.
bridge = ctypes.PyDLL("cblcpyiapi")

# Define the function signature
cobcall = bridge._mFpyCobcall
cobcall.restype = ctypes.c_int
cobcall.argtypes = [ctypes.c_char_p, ctypes.c_int, ctypes.POINTER(ctypes.c_char_p)]

# Build argv array
buf1 = ctypes.create_string_buffer(7)  # PIC X(7) for SVERSONP
argv = (ctypes.c_char_p * 1)(ctypes.cast(buf1, ctypes.c_char_p))

# Call COBOL
rc = cobcall(b"SVERSONP", 1, argv)

# Read result from buf1 using the bridge conversion API
version = bridge._mFpyStringFromCOBOL(buf1.raw, 0, 7)  # COBOL_PIC_X=0
```

### COBOL Data Type Mapping

| COBOL Type | Python ctypes | Notes |
|-----------|---------------|-------|
| `PIC X(n)` | `ctypes.create_string_buffer(n)` | Space-padded, ASCII |
| `PIC S9(4) COMP` | `struct.pack('>h', value)` in buffer | Big-endian signed short (2 bytes) |
| `PIC S9(8) COMP` | `struct.pack('>i', value)` in buffer | Big-endian signed int (4 bytes) |
| `PIC S9(n)V9(m) COMP-3` | Manual pack (same as decode but reverse) | Packed decimal |
| Group item | Single contiguous `create_string_buffer(total_len)` | Fields at fixed offsets |

### Error Handling

```python
try:
    rc = cobcall(b"BADPROG", 0, None)
except RuntimeError as e:
    # Bridge raised PyErr_SetString with error details
    print(f"COBOL call failed: {e}")
    # Common: "cobcall failed: error 173" (program not found)
```
| **VSAM keyed lookup** | `zFile.locate(key, LOCATE_KEY_EQ)` | `file.locate(key, EsosLocateOption.KEY_EQ)` → `bool` (low-level `EsosFile` only) |
| **Stream redirect** | `ZUtil.redirectStandardStreams()` | Automatic via PYLDM |
| **Job context** | `ZUtil.getCurrentJobname()` etc. | Not yet available in Python |
| **COMP-3 decode** | Manual byte manipulation → `BigDecimal` | Manual byte manipulation → `decimal.Decimal` |
| **Args** | `String[] args` via `main()` | `sys.argv` (script mode) or `args` parameter (module mode) |
| **Env config DD** | `STDENV` sets `JAVA_HOME`, `CLASSPATH` | `STDENV` sets `PYTHONPATH`, `ESPY_*` vars |
| **Runtime discovery** | `JAVA_HOME` required | Automatic — cblcpyiapi scans standard Python locations |
| **Dependencies** | `esjos.jar` on CLASSPATH | `esos` + `zoautil_py` packages on PYTHONPATH |
| **Deployment** | `javac` → `.class` → loadlib | Copy `.py` to PYTHONPATH directory (e.g. `$ESP/loadlib`) |
| **Return code from script** | Available via `System.exit()` | Not available — `_mFpyCallScript`/`_mFpyCallModule` return void |

---

## Naming Conventions

Following the Java pattern with Python equivalents:

| Java | Python | Rationale |
|------|--------|-----------|
| `BatchReport.java` | `batch_report.py` | Python snake_case convention |
| `ReadBankData.java` | `read_bank_data.py` | Python snake_case convention |
| `BankCustAcctReport.java` | `bank_cust_acct_report.py` | Python snake_case convention |
| `VsamAccountOps.java` | `vsam_account_ops.py` | Python snake_case convention |
| `JVMDEMO.jcl` | `PYDEMO.jcl` | PY prefix replaces JVM |
| `JVMMULTI.jcl` | `PYMULTI.jcl` | PY prefix replaces JVM |
| `JVMVSAM.jcl` | `PYVSAM.jcl` | PY prefix replaces JVM |
| `JVMREADBNK.jcl` | `PYREADBNK.jcl` | JVM→PY prefix (Java→Python) |
| `JVMLDM` | `PYLDM` | Python Load Module (confirmed in esos) |
| `JVMPROC` (JCL PROC) | `PYPROC` | Inline JCL PROC for Python steps |
| `JZOS_*` env vars | `ESPY_*` env vars | Runtime configuration namespace |
| `esjos.jar` | `esos` + `zoautil_py` packages | Python dataset I/O libraries |

---

## Architecture Diagram

```
┌────────────────────────────────────────┐
│  JCL Job Step                          │
│  EXEC PGM=PYLDM                       │
│  DD allocations (STDIN, STDOUT, etc.)  │
└───────────────────┬────────────────────┘
                    │
                    ▼
┌──────────────────────────────────────────┐
│ PYLDM (pyldm.cbl)                       │
│ Reads STDENV, MAINARGS, PARM            │
│ Calls _mFpyCallScript / _mFpyCallModule │
└───────────────────┬──────────────────────┘
                    │
                    ▼
┌────────────────────────────────────────┐
│  cblcpyiapi Bridge (coretech)         │
│  _mFpyInitPython()                    │
│  _mFpyCallScript() / _mFpyCallModule()│
│  Uses CPython Stable ABI (python3.dll)│
│  NOTE: CallScript/CallModule → void   │
└───────────────────┬────────────────────┘
                    │
                    ▼
┌────────────────────────────────────────┐
│  Python Runtime                        │
│  - Your Python script/module           │
│  - zoautil_py.zopen() for datasets     │
│  - esos.esos.EsosFile for low-level IO │
└───────────────────┬────────────────────┘
                    │
                    ▼
┌────────────────────────────────────────┐
│  Enterprise Server (ESOS)              │
│  - Manages DD allocations              │
│  - Provides dataset I/O               │
│  - Returns exit code to JCL            │
└────────────────────────────────────────┘
```
