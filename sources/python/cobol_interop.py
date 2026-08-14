"""
Step 5 Demo: Calling COBOL Programs from Python (Bidirectional Interop).

This demonstrates the REVERSE direction of interoperability: Python calling
existing COBOL subroutines. The Java demos showed COBOL calling Java
(CALL "Java.Class.method"). Python has the opposite — Python calls COBOL
via the _mFpyCobcall bridge function.

How it works:
  1. Python uses ctypes to call _mFpyCobcall in the cblcpyiapi bridge library
  2. The bridge loads and calls the named COBOL program via the COBOL runtime
  3. COBOL receives LINKAGE SECTION parameters as flat byte buffers
  4. COBOL modifies the buffers in-place (output parameters)
  5. Python reads the results from the same buffers after the call returns

The bridge function signature:
  int _mFpyCobcall(const char *prog_name, int argc, cobchar_t **argv)

  - prog_name: COBOL PROGRAM-ID (e.g., "SVERSONP")
  - argc: number of LINKAGE SECTION parameters
  - argv: array of pointers to byte buffers (one per parameter)
  - Returns 0 on success; raises RuntimeError on failure

COBOL data type mapping to Python ctypes:
  PIC X(n)          -> ctypes.create_string_buffer(n)  (space-padded ASCII)
  PIC S9(4) COMP    -> struct.pack('>h', value)         (2-byte big-endian int)
  PIC S9(8) COMP    -> struct.pack('>i', value)         (4-byte big-endian int)
  Group item        -> single contiguous buffer, fields at fixed offsets

Note: COMP fields are big-endian because BankDemo uses the ENTCOBOL dialect
which implies HOSTNUMMOVE (mainframe-compatible numeric storage).

Operations:
  VERSION  - Call SVERSONP: simplest possible call (1 output param)
  DATECONV - Call UDATECNV: structured group parameter (date conversion)
  TWOSCOMP - Call UTWOSCMP: multiple params including binary COMP field

See PYCBLCL.jcl for the JCL, and the COBOL sources in sources/cobol/core/.

Usage:
  EXEC PGM=PYLDM,PARM='cobol_interop.py VERSION'
  EXEC PGM=PYLDM,PARM='cobol_interop.py DATECONV 20260624'
  EXEC PGM=PYLDM,PARM='cobol_interop.py TWOSCOMP HELLO'
"""

import ctypes
import ctypes.util
import struct
import sys

# COBOL string type constant (from cblcpyiapi.h)
COBOL_PIC_X = 0  # ASCII PIC X (space-padded)


# =============================================================================
# Bridge Loading
# =============================================================================

def _load_bridge():
    """Load the cblcpyiapi bridge library.

    The bridge DLL/SO is already loaded in the process by PYLDM (which used
    it to call _mFpyCallScript/_mFpyCallModule to run this script). We just
    need to get a ctypes handle to call _mFpyCobcall and the conversion APIs.

    Uses PyDLL for the conversion APIs (_mFpyStringFromCOBOL) because they
    call Python C API functions internally (PyUnicode_FromString) which
    require the GIL to be held. _mFpyCobcall manages the GIL internally
    (PyGILState_Ensure/Release), so it also works correctly under PyDLL.
    """
    try:
        lib = ctypes.PyDLL("cblcpyiapi")
    except OSError:
        # Fallback: try platform-specific library resolution
        path = ctypes.util.find_library("cblcpyiapi")
        if path is None:
            raise RuntimeError("Cannot find cblcpyiapi library. "
                               "Ensure PYLDM loaded the bridge.")
        lib = ctypes.PyDLL(path)

    # Declare the function signature so ctypes can marshal arguments correctly
    # int _mFpyCobcall(const char *prog_name, int argc, cobchar_t **argv)
    lib._mFpyCobcall.restype = ctypes.c_int
    lib._mFpyCobcall.argtypes = [
        ctypes.c_char_p,                        # prog_name (null-terminated)
        ctypes.c_int,                           # argc (number of LINKAGE params)
        ctypes.POINTER(ctypes.c_char_p),        # argv (array of buffer pointers)
    ]

    # void * _mFpyStringFromCOBOL(const char *src, int type, int slen)
    # Returns: new Python str object (handles encoding + trailing space removal)
    lib._mFpyStringFromCOBOL.restype = ctypes.py_object
    lib._mFpyStringFromCOBOL.argtypes = [
        ctypes.c_char_p, ctypes.c_int, ctypes.c_int
    ]

    return lib


_bridge = None  # Lazily loaded on first cobcall


def _get_bridge():
    global _bridge
    if _bridge is None:
        _bridge = _load_bridge()
    return _bridge


def cobcall(prog_name, *buffers):
    """Call a COBOL program by name, passing LINKAGE SECTION buffers.

    Each buffer must be a ctypes string buffer (create_string_buffer) whose
    size matches the corresponding COBOL LINKAGE parameter. The COBOL program
    modifies these buffers in-place — read the results after this call returns.

    Args:
        prog_name: COBOL PROGRAM-ID (e.g., "SVERSONP", "UDATECNV")
        *buffers:  One ctypes.create_string_buffer per LINKAGE parameter

    Returns:
        int: 0 on success

    Raises:
        RuntimeError: If the COBOL program can't be found (error 173) or
                      encounters a runtime error. The error message comes
                      from PyErr_SetString in the bridge.

    Example:
        buf = ctypes.create_string_buffer(7)   # PIC X(7)
        cobcall("SVERSONP", buf)
        print(buf.raw.decode("ascii"))         # " V5.99c"
    """
    bridge = _get_bridge()
    argc = len(buffers)

    # Build the argv array: each element is a pointer to one buffer.
    # This matches COBOL's "PROCEDURE DIVISION USING param1 param2 ..."
    # where each param is passed BY REFERENCE (pointer to data).
    argv_type = ctypes.c_char_p * argc
    argv = argv_type()
    for i, buf in enumerate(buffers):
        argv[i] = ctypes.cast(buf, ctypes.c_char_p)

    rc = bridge._mFpyCobcall(prog_name.encode("ascii"), argc, argv)
    return rc


# =============================================================================
# VERSION: Call SVERSONP — the simplest possible cobcall
# =============================================================================
# COBOL source: sources/cobol/core/SVERSONP.cbl
#
# This is the "hello world" of cobcall. SVERSONP has a single LINKAGE
# parameter: one PIC X(7) field that it fills with the version string.
#
# COBOL LINKAGE SECTION:
#   01  LK-VERSION  PIC X(7).
# PROCEDURE DIVISION USING LK-VERSION.
#   MOVE WS-VERSION TO LK-VERSION.
#   GOBACK.

def do_version():
    """Call SVERSONP and display the application version."""
    print("=== Python -> COBOL: SVERSONP (Version String) ===")

    # Allocate a 7-byte buffer matching PIC X(7).
    # create_string_buffer(n) allocates n+1 bytes (null-terminated),
    # but COBOL only sees the first 7 bytes.
    lk_version = ctypes.create_string_buffer(7)

    # Call COBOL — it fills lk_version with " V5.99c"
    cobcall("SVERSONP", lk_version)

    
    # Use _mFpyStringFromCOBOL to convert the PIC X(7) result to a Python str.
    # This handles encoding and strips trailing spaces automatically.
    bridge = _get_bridge()
    version = bridge._mFpyStringFromCOBOL(lk_version.raw, COBOL_PIC_X, 7)

    # Alternative method: .raw gives the exact bytes (no null-termination issues)
    # version = lk_version.raw.decode("ascii").strip()

    print(f"  COBOL returned version: '{version}'")
    print("=== Complete ===")
    return 0


# =============================================================================
# DATECONV: Call UDATECNV — structured group parameter
# =============================================================================
# COBOL source: sources/cobol/core/UDATECNV.cbl
# Copybook: sources/copybook/CDATED.cpy
#
# UDATECNV converts dates between formats. It takes a single GROUP item
# (LK-DATE-WORK-AREA) which is a contiguous 61-byte buffer containing
# multiple fields at fixed offsets. In Python, we build one buffer and
# write/read fields at the documented offsets.
#
# COBOL LINKAGE SECTION:
#   01  LK-DATE-WORK-AREA.
#     COPY CDATED.
# PROCEDURE DIVISION USING LK-DATE-WORK-AREA.
#
# CDATED layout (61 bytes total):
#   Offset  0: DD-ENV           PIC X(4)   - environment indicator:
#                                             LOW-VALUES = batch/null (uses system time)
#                                             'CICS' = CICS environment
#                                             'IMS'  = IMS environment
#                                             'INET' = Internet/web
#   Offset  4: DD-TIME-INPUT    PIC X(7)   - time input (numeric, e.g. '1430000')
#   Offset 11: DD-TIME-OUTPUT   PIC X(8)   - time output result (HH:MM:SS)
#   Offset 19: DDI-TYPE         PIC X(1)   - input date format:
#                                             '0' = ISO (YYYY-MM-DD)
#                                             '1' = YYYYMMDD
#                                             '2' = YYMMDD
#                                             '3' = YYDDD (Julian)
#   Offset 20: DDI-DATA         PIC X(20)  - input date string
#   Offset 40: DDO-TYPE         PIC X(1)   - output date format:
#                                             '1' = DD.MMM.YY
#                                             '2' = DD.MMM.YYYY
#   Offset 41: DDO-DATA         PIC X(20)  - output date string (result)

CDATED_LEN = 61
CDATED_ENV = 0
CDATED_TIME_INPUT = 4
CDATED_TIME_OUTPUT = 11
CDATED_DDI_TYPE = 19
CDATED_DDI_DATA = 20
CDATED_DDO_TYPE = 40
CDATED_DDO_DATA = 41


def do_dateconv(args):
    """Call UDATECNV to convert a date from YYYYMMDD to DD.MMM.YYYY.

    This demonstrates how to build a structured group parameter — a single
    contiguous buffer with multiple fields at fixed byte offsets, matching
    the COBOL COPY CDATED layout.
    """
    if len(args) < 1:
        print("Usage: cobol_interop.py DATECONV <YYYYMMDD>", file=sys.stderr)
        return 1

    input_date = args[0]
    print(f"=== Python -> COBOL: UDATECNV (Date Conversion) ===")
    print(f"  Input: '{input_date}' (YYYYMMDD)")

    # Allocate a single 61-byte buffer for the entire group item.
    # create_string_buffer initializes to zeros (which is LOW-VALUES in COBOL).
    buf = ctypes.create_string_buffer(CDATED_LEN)

    # DD-ENV = LOW-VALUES (already zero = null environment).
    # In null/batch mode, UDATECNV uses ACCEPT FROM TIME for the system time.

    # DD-TIME-INPUT = '0000000' (7 numeric chars — ignored in null env mode)
    buf[CDATED_TIME_INPUT:CDATED_TIME_INPUT + 7] = b'0000000'

    # DDI-TYPE = '1' means input is in YYYYMMDD format
    buf[CDATED_DDI_TYPE:CDATED_DDI_TYPE + 1] = b'1'

    # DDI-DATA = the date string, left-justified, space-padded to 20 bytes
    # (matching COBOL's MOVE semantics for PIC X fields)
    date_bytes = input_date.encode("ascii")[:20].ljust(20)
    buf[CDATED_DDI_DATA:CDATED_DDI_DATA + 20] = date_bytes

    # DDO-TYPE = '2' means output should be DD.MMM.YYYY format
    buf[CDATED_DDO_TYPE:CDATED_DDO_TYPE + 1] = b'2'

    # DDO-DATA = spaces (will be filled by COBOL with the converted date)
    buf[CDATED_DDO_DATA:CDATED_DDO_DATA + 20] = b' ' * 20

    # Call COBOL — it reads DDI fields and writes DDO fields in the same buffer
    cobcall("UDATECNV", buf)

    # Use _mFpyStringFromCOBOL to extract the output fields from the buffer.
    # This handles encoding and trailing space removal automatically.
    bridge = _get_bridge()
    time_output = bridge._mFpyStringFromCOBOL(
        buf[CDATED_TIME_OUTPUT:CDATED_TIME_OUTPUT + 8], COBOL_PIC_X, 8
    )
    date_output = bridge._mFpyStringFromCOBOL(
        buf[CDATED_DDO_DATA:CDATED_DDO_DATA + 20], COBOL_PIC_X, 20
    )

    print(f"  Output date: '{date_output}'")
    print(f"  System time: '{time_output}'")
    print("=== Complete ===")
    return 0


# =============================================================================
# TWOSCOMP: Call UTWOSCMP — multiple parameters including COMP binary
# =============================================================================
# COBOL source: sources/cobol/core/UTWOSCMP.cbl
#
# UTWOSCMP has THREE separate LINKAGE parameters (not a group — three
# individual items). This demonstrates passing multiple buffers via argv.
# It also shows how to encode a PIC S9(4) COMP (binary integer) field.
#
# COBOL LINKAGE SECTION:
#   01  LK-TWOS-CMP-LEN     PIC S9(4) COMP.   (2 bytes, big-endian signed)
#   01  LK-TWOS-CMP-INPUT   PIC X(256).        (input byte buffer)
#   01  LK-TWOS-CMP-OUTPUT  PIC X(256).        (output byte buffer)
# PROCEDURE DIVISION USING LK-TWOS-CMP-LEN
#                           LK-TWOS-CMP-INPUT
#                           LK-TWOS-CMP-OUTPUT.
#
# The program computes: output[i] = 255 - input[i] for i = 1..LEN
#
# PIC S9(4) COMP under ENTCOBOL dialect:
#   - 2 bytes, big-endian (network byte order)
#   - Signed range: -9999 to +9999
#   - Python: struct.pack('>h', value)  ['>h' = big-endian signed short]

def do_twoscomp(args):
    """Call UTWOSCMP to compute two's complement of input bytes.

    This demonstrates:
    - Passing multiple LINKAGE parameters (3 buffers in argv)
    - Encoding a COMP (binary) field with struct.pack
    - Reading output from a buffer modified by COBOL
    - Verifying the COBOL computation from Python
    """
    if len(args) < 1:
        print("Usage: cobol_interop.py TWOSCOMP <text>", file=sys.stderr)
        return 1

    input_text = args[0]
    input_bytes = input_text.encode("ascii")
    length = min(len(input_bytes), 256)

    print(f"=== Python -> COBOL: UTWOSCMP (Two's Complement) ===")
    print(f"  Input:  '{input_text}' (length={length})")
    print(f"  Input bytes:  {list(input_bytes[:length])}")

    # Parameter 1: PIC S9(4) COMP — 2-byte big-endian signed integer
    # '>h' = big-endian signed short (matches ENTCOBOL COMP storage)
    lk_len = ctypes.create_string_buffer(2)
    struct.pack_into('>h', lk_len, 0, length)

    # Parameter 2: PIC X(256) — input buffer
    # Space-padded (create_string_buffer initializes to nulls, which is fine)
    lk_input = ctypes.create_string_buffer(256)
    lk_input[:length] = input_bytes[:length]

    # Parameter 3: PIC X(256) — output buffer (COBOL writes results here)
    lk_output = ctypes.create_string_buffer(256)

    # Call COBOL with 3 separate LINKAGE parameters
    cobcall("UTWOSCMP", lk_len, lk_input, lk_output)

    # Read the output bytes computed by COBOL
    output_bytes = lk_output.raw[:length]
    print(f"  Output bytes: {list(output_bytes)}")

    # Verify: COBOL should compute 255 - input[i] for each byte
    expected = bytes(255 - b for b in input_bytes[:length])
    if output_bytes == expected:
        print("  Verification: PASSED (255 - input = output for each byte)")
    else:
        print("  Verification: MISMATCH")
        print(f"    Expected: {list(expected)}")

    print("=== Complete ===")
    return 0


# =============================================================================
# Main Entry Point
# =============================================================================

def main(args=None):
    """Dispatch to the requested operation based on the first argument."""
    if args is None:
        args = sys.argv[1:]

    if len(args) < 1:
        print("Usage: cobol_interop.py VERSION|DATECONV|TWOSCOMP [args...]",
              file=sys.stderr)
        print("\nDemonstrates calling COBOL programs from Python via _mFpyCobcall.",
              file=sys.stderr)
        print("  VERSION           - Get application version from SVERSONP",
              file=sys.stderr)
        print("  DATECONV YYYYMMDD - Convert date via UDATECNV",
              file=sys.stderr)
        print("  TWOSCOMP text     - Two's complement via UTWOSCMP",
              file=sys.stderr)
        return 1

    mode = args[0].upper()
    remaining = args[1:]

    if mode == "VERSION":
        return do_version()
    elif mode == "DATECONV":
        return do_dateconv(remaining)
    elif mode == "TWOSCOMP":
        return do_twoscomp(remaining)
    else:
        print(f"Unknown operation: {mode}. Use VERSION, DATECONV, or TWOSCOMP.",
              file=sys.stderr)
        return 1


if __name__ in ("__main__", "<run_path>"):
    main()
