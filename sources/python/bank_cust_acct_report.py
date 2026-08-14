"""
Step 3 Demo: Multi-step Batch Processing.

A single Python script invoked twice from different JCL steps with different
arguments, demonstrating how one script can serve multiple batch functions.
This is the Python equivalent of BankCustAcctReport.java.

Step 1 (FILTER mode):
  - Reads the BNKCUST (customer) dataset via DD name CUSTDATA
  - Filters customers by a regex pattern on the customer ID
  - Prints matching customer records to stdout

Step 2 (REPORT mode):
  - Reads the BNKACC (account) dataset via DD name ACCDATA
  - Decodes COMP-3 packed decimal balance fields
  - Produces a formatted account summary with totals

Key concepts demonstrated:
  - Same script, different JCL steps with different PARM arguments
  - COMP-3 (packed decimal) decoding - the mainframe numeric format
  - Multiple VSAM datasets accessed in one job
  - Record layout mapping from COBOL copybooks to Python byte offsets

COBOL copybook references:
  - CBANKVCS.cpy: BNKCUST record layout (250 bytes)
  - CBANKVAC.cpy: BNKACC  record layout (200 bytes)

See PYMULTI.jcl for the multi-step JCL.

Usage:
  EXEC PGM=PYLDM,PARM='bank_cust_acct_report.py FILTER pattern'
  EXEC PGM=PYLDM,PARM='bank_cust_acct_report.py REPORT [max_records]'
"""

import re
import sys
import ctypes
from decimal import Decimal

from zoautil_py.zoau_io import zopen
from esos.esos import EsosLocateOption


# =============================================================================
# Bridge Data Type Conversion API
# =============================================================================
# The cblcpyiapi bridge library provides functions for converting between
# COBOL data types and Python objects. These handle encoding, sign, padding,
# and decimal scaling correctly — no need to do it manually.
#
# _mFpyStringFromCOBOL: COBOL PIC X/N/U → Python str (strips trailing spaces)
# _mFpyDecimalFromCOBOL: COBOL COMP-3/DISPLAY → Python decimal.Decimal

# COBOL string type constants (from cblcpyiapi.h)
COBOL_PIC_X = 0             # ASCII PIC X (space-padded)

# COBOL numeric type constants
NUMERIC_COMP_3 = 1          # Packed decimal (2 digits/byte, sign in last nibble)

# Sign conventions
SIGN_TRAILING_INC = 0x80    # Sign embedded in last byte (standard for COMP-3)


def _load_conversion_api():
    """Load the cblcpyiapi bridge and configure the conversion functions.

    The bridge is already loaded in the process by PYLDM — we just need
    a ctypes handle to access the conversion exports.

    IMPORTANT: Must use PyDLL (not CDLL) because these functions call
    Python C API functions internally (PyUnicode_FromString, Decimal
    constructor). PyDLL keeps the GIL held during the call; CDLL would
    release it, causing undefined behavior when the C code calls back
    into Python.
    """
    bridge = ctypes.PyDLL("cblcpyiapi")

    # void * _mFpyStringFromCOBOL(const char *src, int type, int slen)
    # Returns: new Python str object (auto-strips trailing spaces)
    bridge._mFpyStringFromCOBOL.restype = ctypes.py_object
    bridge._mFpyStringFromCOBOL.argtypes = [
        ctypes.c_char_p, ctypes.c_int, ctypes.c_int
    ]

    # void * _mFpyDecimalFromCOBOL(const char *src, int type, int intdig, int decdig, int sign)
    # Returns: new decimal.Decimal object
    bridge._mFpyDecimalFromCOBOL.restype = ctypes.py_object
    bridge._mFpyDecimalFromCOBOL.argtypes = [
        ctypes.c_char_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int
    ]

    return bridge


_bridge = _load_conversion_api()


def field(record, offset_len):
    """Extract a text field from a fixed-length record using the bridge API.

    Uses _mFpyStringFromCOBOL which handles encoding conversion and
    trailing space removal — the same logic used by the COBOL runtime.
    """
    offset, length = offset_len
    return _bridge._mFpyStringFromCOBOL(
        record[offset:offset + length], COBOL_PIC_X, length
    )


def unpack_comp3(data, offset, length, scale):
    """Decode a COMP-3 (packed decimal) field using the bridge API.

    Uses _mFpyDecimalFromCOBOL which handles BCD unpacking, sign detection,
    and decimal point placement — returns a Python decimal.Decimal directly.

    For PIC S9(7)V99 COMP-3 (5 bytes):
      intdig = 7 (integer digits before implied V)
      decdig = 2 (decimal digits after implied V = scale)
      sign = SIGN_TRAILING_INC (sign packed in last nibble)
    """
    intdig = (length * 2 - 1) - scale   # total digits minus decimal digits
    return _bridge._mFpyDecimalFromCOBOL(
        data[offset:offset + length], NUMERIC_COMP_3,
        intdig, scale, SIGN_TRAILING_INC
    )


# =============================================================================
# Record Layouts
# =============================================================================
# These offsets come directly from the COBOL copybooks. Each field is at a
# fixed byte position within the record. The tuple format is (offset, length).

# --- BNKCUST record layout (from CBANKVCS.cpy) ---
# 250 bytes, VSAM KSDS, primary key at offset 0 (length 5)
CUST_LRECL  = 250
CUST_PID    = (0, 5)       # Customer ID (primary key)
CUST_NAME   = (5, 25)      # Customer name
CUST_ADDR1  = (64, 25)     # Address line 1
CUST_STATE  = (114, 2)     # State code
CUST_TEL    = (128, 12)    # Phone number
CUST_EMAIL  = (140, 30)    # Email address

# --- BNKACC record layout (from CBANKVAC.cpy) ---
# 200 bytes, VSAM KSDS, primary key at offset 5 (length 9)
ACC_LRECL   = 200
ACC_PID     = (0, 5)        # Customer ID (foreign key to BNKCUST)
ACC_ACCNO   = (5, 9)        # Account number (primary key)
ACC_TYPE    = (14, 1)       # Account type: 'C'hecking, 'S'avings, etc.
ACC_BALANCE_OFFSET  = 15    # Balance field starts at byte 15
ACC_BALANCE_LEN     = 5     # PIC S9(7)V99 COMP-3 = 5 bytes packed decimal


def read_vsam_records(file_handle):
    """Read all records from a positioned VSAM file.

    Reads sequentially from the current position until EOF.

    Known issue: esos.py's EsosFile.read() raises EsosError at EOF
    (VSAM status "10") instead of returning 0 bytes. zoautil_py's
    readrecord() wraps EsosFile.read() and expects 0 at EOF (returning
    empty bytes b''), so this bug propagates through both API layers.
    We catch the exception here as our EOF signal.
    """
    records = []
    while True:
        try:
            record = file_handle.readrecord()
            if not record:
                break
            records.append(record)
        except Exception:
            # Workaround: esos.py raises on EOF instead of returning
            # empty bytes. Any read exception after positioning = EOF.
            break
    return records


# =============================================================================
# FILTER Mode
# =============================================================================

def do_filter(args):
    """Read BNKCUST and display customers whose ID matches a regex pattern.

    The pattern is a Python regular expression applied to the 5-character
    customer ID field. Use '.*' to match all customers.

    If an OUTFILE DD is allocated in the JCL, matching records are also
    written to that output dataset (FB, lrecl=132). This demonstrates
    writing to a dataset from Python — the equivalent of Java's
    BankCustAcctReport writing to MFI01V.MFIDEMO.CUST.FILTER.
    """
    if len(args) < 1:
        pattern = ".*"
    else:
        pattern = args[0]

    print(f"=== Customer Filter: pattern='{pattern}' ===")
    regex = re.compile(pattern)

    # Try to open the output dataset (optional — not all JCL will have it)
    # If the DD is not allocated, we just write to stdout only.
    outfile = None
    try:
        outfile = zopen("//DD:OUTFILE", "w", lrecl=132, recfm="FB")
    except Exception:
        pass  # OUTFILE DD not allocated — output to stdout only

    # Open BNKCUST via DD name allocated in JCL: //CUSTDATA DD DSN=MFI01V.MFIDEMO.BNKCUST
    f = zopen("//DD:CUSTDATA", "r", lrecl=CUST_LRECL, recfm="KS")
    try:
        # Position to first record before sequential browse
        f._file.locate(b'', EsosLocateOption.KEY_FIRST)
        records = read_vsam_records(f)

        # Write header to output dataset if open
        if outfile is not None:
            outfile.write(f"=== Customer Filter: pattern='{pattern}' ===".encode("ascii").ljust(132))

        matches = 0
        for record in records:
            pid = field(record, CUST_PID)
            if regex.search(pid):
                name = field(record, CUST_NAME)
                state = field(record, CUST_STATE)
                email = field(record, CUST_EMAIL)
                line = f"  {pid}  {name:<25s}  {state}  {email}"
                print(line)
                # Also write to output dataset (space-padded to lrecl=132)
                if outfile is not None:
                    outfile.write(line.encode("ascii").ljust(132))
                matches += 1

        summary = f"--- {matches} customers matched out of {len(records)} total ---"
        print(summary)
        if outfile is not None:
            outfile.write(summary.encode("ascii").ljust(132))
    finally:
        f.close()
        if outfile is not None:
            outfile.close()

    if outfile is not None:
        print("  (Results also written to OUTFILE DD)")

    return 0


# =============================================================================
# REPORT Mode
# =============================================================================

def read_control_cards():
    """Read KEY=VALUE control cards from the STDIN DD (if available).

    In JCL, inline data can be passed via //STDIN DD * which PYLDM
    redirects to Python's sys.stdin. This is the Python equivalent of
    Java's readControlCards() reading from System.in.

    Control card format:
      - One KEY=VALUE pair per line
      - Lines starting with '*' are comments (ignored)
      - Blank lines are ignored
      - Keys are case-sensitive

    Returns:
        dict of key->value strings (empty if no STDIN DD or no data)
    """
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
        pass  # No STDIN DD allocated, or empty — just use defaults
    return cards


def do_report(args):
    """Read BNKACC and produce a formatted account balance summary.

    Decodes COMP-3 packed decimal balance fields and computes totals.

    If a STDIN DD is allocated with control cards, the following keys
    are recognized:
      REPORT_TITLE=<title>     - Custom report title (default: Account Balance Report)
      MAX_RECORDS=<n>          - Override max records to display

    This demonstrates reading inline JCL data (DD *) from Python via
    sys.stdin — the same pattern Java uses with System.in.
    """
    # Read control cards from STDIN DD (if allocated)
    cards = read_control_cards()

    # Control cards can override defaults
    title = cards.get("REPORT_TITLE", "Account Balance Report")
    max_records = int(cards.get("MAX_RECORDS", args[0] if args else "20"))

    print(f"=== {title} ===")
    if cards:
        print(f"  (Control cards: {', '.join(f'{k}={v}' for k, v in cards.items())})")
    print(f"{'PID':<6s} {'Account':<10s} {'Type':<5s} {'Balance':>12s}")
    print("-" * 40)

    # Open BNKACC via DD name: //ACCDATA DD DSN=MFI01V.MFIDEMO.BNKACC
    f = zopen("//DD:ACCDATA", "r", lrecl=ACC_LRECL, recfm="KS")
    try:
        f._file.locate(b'', EsosLocateOption.KEY_FIRST)
        records = read_vsam_records(f)

        total_balance = Decimal(0)
        displayed = 0

        for record in records:
            pid = field(record, ACC_PID)
            accno = field(record, ACC_ACCNO)
            acc_type = field(record, ACC_TYPE)
            # Decode the COMP-3 balance: PIC S9(7)V99 at offset 15, 5 bytes
            balance = unpack_comp3(record, ACC_BALANCE_OFFSET, ACC_BALANCE_LEN, 2)
            total_balance += balance

            if displayed < max_records:
                print(f"  {pid:<5s} {accno:<10s} {acc_type:<5s} {balance:>12,.2f}")
                displayed += 1

        if len(records) > max_records:
            print(f"  ... ({len(records) - max_records} more records not shown)")

        print("-" * 40)
        print(f"  Total records: {len(records)}")
        print(f"  Total balance: {total_balance:>12,.2f}")
        print("=== Report Complete ===")
    finally:
        f.close()

    return 0


# =============================================================================
# Main Entry Point
# =============================================================================

def main(args=None):
    if args is None:
        args = sys.argv[1:]

    if len(args) < 1:
        print("Usage: bank_cust_acct_report.py FILTER|REPORT [args...]",
              file=sys.stderr)
        return 1

    mode = args[0].upper()
    remaining = args[1:]

    if mode == "FILTER":
        return do_filter(remaining)
    elif mode == "REPORT":
        return do_report(remaining)
    else:
        print(f"Unknown mode: {mode}. Use FILTER or REPORT.", file=sys.stderr)
        return 1


if __name__ in ("__main__", "<run_path>"):
    main()
