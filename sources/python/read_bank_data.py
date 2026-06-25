"""
Step 2 Demo: Accessing Datasets from Python with zoautil_py.

Reads bank account records from a VSAM KSDS dataset allocated via a JCL DD
statement. This is the Python equivalent of ReadBankData.java (which uses
the com.rocketsoftware.jzos ZFile class).

Key concepts demonstrated:
  - Opening a dataset by DD name: zopen("//DD:ACCDATA", ...)
  - VSAM KSDS access: must specify recfm="KS" and provide lrecl
  - Positioning: locate(KEY_FIRST) before sequential read
  - Record I/O: readrecord() returns bytes; EOF raises an exception
  - Fixed-length record parsing via byte slicing

The dataset MFI01V.MFIDEMO.BNKACC is a VSAM Key-Sequenced Data Set:
  - Record length: 200 bytes
  - Primary key: bytes 5-13 (account number, 9 bytes)
  - Record layout defined in COBOL copybook CBANKVAC.cpy

See PYREADBNK.jcl for the JCL that allocates the DD and runs this script.

Usage: EXEC PGM=PYLDM,PARM='+I read_bank_data.py 5'
"""
import sys
import ctypes

# zoautil_py provides a high-level record I/O API similar to Java's ZFile.
# zopen() returns a RecordIO object for reading/writing dataset records.
from zoautil_py.zoau_io import zopen, ALL

# EsosLocateOption provides VSAM positioning options (KEY_FIRST, KEY_EQ, etc.)
from esos.esos import EsosLocateOption


# =============================================================================
# Bridge Data Type Conversion API
# =============================================================================
# Use _mFpyStringFromCOBOL from the cblcpyiapi bridge to convert COBOL PIC X
# fields to Python strings. This handles encoding and trailing space removal.

COBOL_PIC_X = 0  # ASCII PIC X (space-padded)


def _load_conversion_api():
    """Load the bridge and configure the string conversion function.

    Must use PyDLL (not CDLL) because _mFpyStringFromCOBOL calls Python
    C API functions internally (PyUnicode_FromString) which require the GIL.
    """
    bridge = ctypes.PyDLL("cblcpyiapi")
    bridge._mFpyStringFromCOBOL.restype = ctypes.py_object
    bridge._mFpyStringFromCOBOL.argtypes = [
        ctypes.c_char_p, ctypes.c_int, ctypes.c_int
    ]
    return bridge


_bridge = _load_conversion_api()


def pic_x(record, offset, length):
    """Extract a PIC X field from a record using the bridge conversion API."""
    return _bridge._mFpyStringFromCOBOL(
        record[offset:offset + length], COBOL_PIC_X, length
    )


def main(args=None):
    if args is None:
        args = sys.argv[1:]

    if len(args) < 1:
        print("Usage: read_bank_data.py <num_records>", file=sys.stderr)
        return 1

    records_to_show = int(args[0])

    print("=== Reading Bank Account Data ===")
    read_account_file(records_to_show)
    print("=== Complete ===")
    return 0


def read_account_file(display_n):
    """Read the BNKACC dataset and display the first N records.

    Record layout (from CBANKVAC.cpy, VSAM KSDS, lrecl=200):
        Offset 0-4:   Customer ID  PIC X(5)
        Offset 5-13:  Account ID   PIC X(9)  [primary key]
        Offset 14:    Account Type PIC X(1)   ('C'heck, 'S'avings, etc.)
        Offset 15-19: Balance      PIC S9(7)V99 COMP-3 (packed decimal)
        ... (see copybook for remaining fields)
    """
    # Open the dataset allocated to DD name ACCDATA.
    #
    # Parameters:
    #   "//DD:ACCDATA" - the DD name from JCL (//ACCDATA DD DSN=...)
    #   "r"            - open for reading
    #   lrecl=200      - logical record length (must match dataset definition)
    #   recfm="KS"     - record format: Key-Sequenced (VSAM KSDS)
    #
    # Note: Unlike Java's ZFile which auto-detects these from the catalog,
    # Python's zopen() requires explicit lrecl and recfm parameters.
    f = zopen("//DD:ACCDATA", "r", lrecl=200, recfm="KS")
    try:
        # Position to the first record in the dataset.
        # VSAM KSDS requires an explicit locate/START before sequential reading.
        # This is equivalent to Java's zFile.locate(key, LOCATE_KEY_FIRST).
        f._file.locate(b'', EsosLocateOption.KEY_FIRST)

        # Read all records. The esos layer raises an exception (FILE_ACCESS,
        # status code "10") at end-of-file rather than returning empty bytes.
        # We catch that exception as our EOF signal.
        records = []
        while True:
            try:
                record = f.readrecord()
                if not record:
                    break
                records.append(record)
            except Exception:
                # VSAM status 10 = end of file. Treat any read exception as EOF.
                break
        count = len(records)

        # Display the first N records using the bridge conversion API
        for i, record in enumerate(records):
            if i >= display_n:
                break

            # Use _mFpyStringFromCOBOL to convert PIC X fields to Python strings.
            # This handles encoding conversion and trailing space removal.
            cust_id = pic_x(record, 0, 5)
            account_id = pic_x(record, 5, 9)
            account_type = pic_x(record, 14, 1)

            print(f"  Account: {account_id}  Customer: {cust_id}  Type: {account_type}")

            if i == display_n - 1:
                print(f"  ... (showing first {display_n} records)")

        print(f"  Total records: {count}")
    finally:
        # Always close the file handle to release the VSAM dataset.
        # RecordIO is NOT a context manager, so we use try/finally.
        f.close()


if __name__ in ("__main__", "<run_path>"):
    main()
