"""
Step 4 Demo: Low-level VSAM Operations with the esos API.

Demonstrates direct VSAM KSDS operations on the BNKCUST (customer) dataset
using the low-level esos.esos API instead of the higher-level zoautil_py.
This is the Python equivalent of VsamAccountOps.java.

Three VSAM operations are shown:
  LOOKUP - Random keyed read: locate a specific customer by primary key
  BROWSE - Sequential browse: read records starting from a given key (KEY_GE)
  UPDATE - Read-for-update: locate a record, modify a field, rewrite it

Key concepts demonstrated:
  - Low-level esos API: Esos.default.file_open(path, FileOptions)
  - FileOptions configuration: mode, recfm, lrecl, disposition, VSAM type
  - EsosFile as a context manager (with ... as f:)
  - VSAM locate options: KEY_EQ (exact match), KEY_GE (greater or equal)
  - Read-for-update: MODE_TYPE_READ | MODE_FLAG_UPDATE, then file.update()
  - Difference from zoautil_py: more control, but more setup required

When to use which API:
  - zoautil_py (zopen): Simple sequential read/write, less setup, familiar API
  - esos (EsosFile): Keyed access, update-in-place, browse, delete, position

Dataset: MFI01V.MFIDEMO.BNKCUST (VSAM KSDS, 250 bytes, key at offset 0)
Record layout: CBANKVCS.cpy

See PYVSAM.jcl for the JCL that runs all three operations.

Usage:
  EXEC PGM=PYLDM,PARM='vsam_account_ops.py LOOKUP key'
  EXEC PGM=PYLDM,PARM='vsam_account_ops.py BROWSE start_key max_records'
  EXEC PGM=PYLDM,PARM='vsam_account_ops.py UPDATE key new_email'
"""

import sys

from esos.esos import (
    Esos,              # Main entry point: Esos.default gives the EsosContext
    EsosError,         # Exception raised on file I/O errors
    EsosFileMode,      # Read, Write, Append, Update flags
    EsosLocateOption,  # KEY_EQ, KEY_GE, KEY_FIRST, KEY_LAST, etc.
    EsosOpenFlags,     # OPEN_MODE_RECORD, OPEN_MODE_BINARY
    EsosDisposition,   # SHR, OLD, NEW, MOD (like JCL DISP=)
    EsosDsorg,         # Dataset organization: PS, VSAM, PO, etc.
    EsosVsamType,      # CLUSTER, PATH, AIX, etc.
    FileOptions,       # Structure holding all open parameters
)


# =============================================================================
# Record Layout: BNKCUST (from CBANKVCS.cpy)
# =============================================================================
# 250 bytes total, VSAM KSDS, primary key = bytes 0-4 (customer ID, 5 bytes)
#
# Offset  Length  Field             COBOL Definition
# ------  ------  -----             ----------------
#   0       5     Customer ID       PIC X(5)         [PRIMARY KEY]
#   5      25     Name              PIC X(25)
#  30      25     Name (formal)     PIC X(25)
#  55       9     SIN               PIC X(9)
#  64      25     Address line 1    PIC X(25)
#  89      25     Address line 2    PIC X(25)
# 114       2     State             PIC X(2)
# 116       6     Country           PIC X(6)
# 122       6     Post code         PIC X(6)
# 128      12     Phone             PIC X(12)
# 140      30     Email             PIC X(30)
# 170       1     Send mail flag    PIC X(1)
# 171       1     Send email flag   PIC X(1)
# 172       4     ATM PIN           PIC X(4)
# 176      74     Filler            PIC X(74)

CUST_LRECL = 250
CUST_PID = (0, 5)
CUST_NAME = (5, 25)
CUST_NAME_FF = (30, 25)
CUST_SIN = (55, 9)
CUST_ADDR1 = (64, 25)
CUST_ADDR2 = (89, 25)
CUST_STATE = (114, 2)
CUST_CNTRY = (116, 6)
CUST_POST = (122, 6)
CUST_TEL = (128, 12)
CUST_EMAIL = (140, 30)


def field(record, layout):
    """Extract a text field from a record buffer.

    COBOL PIC X fields are stored as fixed-width ASCII, padded with spaces.
    """
    offset, length = layout
    return bytes(record[offset:offset + length]).decode("ascii", errors="replace").strip()


def set_field(record, layout, value):
    """Set a text field in a mutable record buffer.

    Left-justifies and pads with spaces to fill the fixed field width,
    matching COBOL's MOVE semantics for PIC X fields.
    """
    offset, length = layout
    encoded = value.encode("ascii")[:length].ljust(length)
    record[offset:offset + length] = encoded


def open_custdata(update=False):
    """Open the CUSTDATA DD using the low-level esos API.

    This demonstrates configuring FileOptions manually — equivalent to
    the parameters you'd pass to ZFile in Java, but more explicit.

    Args:
        update: If True, opens for read+update (DISP=OLD).
                If False, opens for read-only (DISP=SHR).

    Returns:
        EsosFile instance (use as context manager: with open_custdata() as f:)
    """
    opts = FileOptions()

    # Mode: read-only or read+update
    # MODE_FLAG_UPDATE enables the file.update() method for rewriting records
    if update:
        opts.mode_flags = EsosFileMode.MODE_TYPE_READ | EsosFileMode.MODE_FLAG_UPDATE
    else:
        opts.mode_flags = EsosFileMode.MODE_TYPE_READ

    # Open flags: we want record-mode binary I/O (not text/stream)
    opts.open_flags = EsosOpenFlags.OPEN_MODE_RECORD | EsosOpenFlags.OPEN_MODE_BINARY

    # Record format: KS = Key-Sequenced (VSAM KSDS)
    opts.recfm = "KS"
    opts.lrecl = CUST_LRECL

    # Disposition: SHR for read-only, OLD for exclusive update access
    # This matches JCL DISP=SHR vs DISP=OLD
    opts.disposition = EsosDisposition.FLAG_DISP_SHR if not update else EsosDisposition.FLAG_DISP_OLD

    # Dataset organization and VSAM type
    opts.dsorg = EsosDsorg.VSAM
    opts.vsam_type = EsosVsamType.CLUSTER
    opts.vsam_key_length = 5  # Primary key is 5 bytes (customer ID)

    # Open the file. "//DD:CUSTDATA" refers to the DD allocated in JCL.
    # Esos.default is the singleton EsosContext (initialized by PYLDM).
    return Esos.default.file_open("//DD:CUSTDATA", opts)


def read_record(f):
    """Read one fixed-length record from the current VSAM position.

    Returns:
        bytearray of CUST_LRECL bytes, or None if at end-of-file.
    """
    buf = bytearray(CUST_LRECL)
    try:
        n = f.read(buf, 0, CUST_LRECL)
        if n == 0:
            return None
        return buf
    except EsosError as e:
        # VSAM status codes returned as file status:
        #   "10" = end of file (no more records)
        #   "23" = record not found (key doesn't exist)
        status = f.status()
        if status.code in ("10", "23"):
            return None
        raise


def print_customer(record):
    """Print a formatted customer record."""
    pid = field(record, CUST_PID)
    name = field(record, CUST_NAME)
    addr1 = field(record, CUST_ADDR1)
    state = field(record, CUST_STATE)
    post = field(record, CUST_POST)
    tel = field(record, CUST_TEL)
    email = field(record, CUST_EMAIL)
    print(f"  PID:    {pid}")
    print(f"  Name:   {name}")
    print(f"  Addr:   {addr1}")
    print(f"  State:  {state}  Post: {post}")
    print(f"  Tel:    {tel}")
    print(f"  Email:  {email}")


# =============================================================================
# LOOKUP: Random Read by Primary Key
# =============================================================================

def do_lookup(args):
    """Locate and display a single customer by exact key match.

    Uses KEY_EQ which finds only an exact match on the 5-byte primary key.
    If the customer doesn't exist, locate() returns False.
    """
    if len(args) < 1:
        print("Usage: vsam_account_ops.py LOOKUP <customer_id>", file=sys.stderr)
        return 1

    # Pad key to exactly 5 bytes (VSAM key must be full length)
    key = args[0].encode("ascii").ljust(5)[:5]
    print(f"=== VSAM LOOKUP: key='{key.decode()}' ===")

    # EsosFile is a context manager — automatically closes on exit
    with open_custdata() as f:
        # locate() positions the file to the matching record.
        # Returns False if no record matches (status "23").
        found = f.locate(key, EsosLocateOption.KEY_EQ)
        if not found:
            print(f"  Customer '{key.decode().strip()}' not found.")
            return 1

        # Read the record at the current position
        record = read_record(f)
        if record is None:
            print(f"  Customer '{key.decode().strip()}' not found (read failed).")
            return 1

        print_customer(record)

    print("=== Lookup Complete ===")
    return 0


# =============================================================================
# BROWSE: Sequential Read from a Starting Key
# =============================================================================

def do_browse(args):
    """Browse customers sequentially starting from a given key.

    Uses KEY_GE (greater than or equal) to find the starting position,
    then reads forward sequentially. This is the standard VSAM browse pattern.
    """
    # Default: start from beginning, show 10 records
    start_key = args[0].encode("ascii").ljust(5)[:5] if args else b'     '
    max_records = int(args[1]) if len(args) > 1 else 10

    print(f"=== VSAM BROWSE: start='{start_key.decode().strip()}', max={max_records} ===")
    print(f"{'PID':<6s} {'Name':<25s} {'State':<6s} {'Email':<30s}")
    print("-" * 70)

    with open_custdata() as f:
        # KEY_GE: position to first record with key >= start_key.
        # If start_key is all spaces, this effectively starts from the beginning.
        found = f.locate(start_key, EsosLocateOption.KEY_GE)
        if not found:
            print("  No records found at or after the given key.")
            return 0

        # Read forward sequentially from the positioned record
        count = 0
        while count < max_records:
            record = read_record(f)
            if record is None:
                break  # End of file
            pid = field(record, CUST_PID)
            name = field(record, CUST_NAME)
            state = field(record, CUST_STATE)
            email = field(record, CUST_EMAIL)
            print(f"  {pid:<5s} {name:<25s} {state:<6s} {email}")
            count += 1

    print("-" * 70)
    print(f"  {count} records displayed.")
    print("=== Browse Complete ===")
    return 0


# =============================================================================
# UPDATE: Read-for-Update and Rewrite
# =============================================================================

def do_update(args):
    """Locate a customer, modify the email field, and rewrite the record.

    This demonstrates the VSAM update pattern:
      1. Open with MODE_FLAG_UPDATE (and DISP=OLD for exclusive access)
      2. locate() the target record by key
      3. read() the record (this "locks" it for update)
      4. Modify the field(s) in the buffer
      5. update() rewrites the record at the same position

    The JCL must specify DISP=OLD on the DD for update access.
    """
    if len(args) < 2:
        print("Usage: vsam_account_ops.py UPDATE <customer_id> <new_email>",
              file=sys.stderr)
        return 1

    key = args[0].encode("ascii").ljust(5)[:5]
    new_email = args[1]
    print(f"=== VSAM UPDATE: key='{key.decode().strip()}', new_email='{new_email}' ===")

    # Open with update=True for read+update mode (DISP=OLD)
    with open_custdata(update=True) as f:
        found = f.locate(key, EsosLocateOption.KEY_EQ)
        if not found:
            print(f"  Customer '{key.decode().strip()}' not found.")
            return 1

        # Read the record — after this, file.update() will rewrite THIS record
        record = read_record(f)
        if record is None:
            print(f"  Customer '{key.decode().strip()}' not found (read failed).")
            return 1

        old_email = field(record, CUST_EMAIL)
        print(f"  Before: email='{old_email}'")

        # Modify the email field in our buffer
        set_field(record, CUST_EMAIL, new_email)

        # Rewrite the entire record at the same VSAM position
        f.update(bytes(record), 0, CUST_LRECL)

        print(f"  After:  email='{new_email}'")

    print("=== Update Complete ===")
    return 0


# =============================================================================
# Main Entry Point
# =============================================================================

def main(args=None):
    if args is None:
        args = sys.argv[1:]

    if len(args) < 1:
        print("Usage: vsam_account_ops.py LOOKUP|BROWSE|UPDATE [args...]",
              file=sys.stderr)
        return 1

    mode = args[0].upper()
    remaining = args[1:]

    if mode == "LOOKUP":
        return do_lookup(remaining)
    elif mode == "BROWSE":
        return do_browse(remaining)
    elif mode == "UPDATE":
        return do_update(remaining)
    else:
        print(f"Unknown mode: {mode}. Use LOOKUP, BROWSE, or UPDATE.",
              file=sys.stderr)
        return 1


if __name__ in ("__main__", "<run_path>"):
    main()
