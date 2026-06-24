"""
Low-level VSAM operations on BNKCUST using the esos API directly.

Demonstrates three VSAM operations:
  LOOKUP - Random read by primary key (customer ID)
  BROWSE - Sequential browse starting from a given key (KEY_GE)
  UPDATE - Read-for-update and rewrite a record field

Usage:
  EXEC PGM=PYLDM,PARM='vsam_account_ops.py LOOKUP key'
  EXEC PGM=PYLDM,PARM='vsam_account_ops.py BROWSE start_key max_records'
  EXEC PGM=PYLDM,PARM='vsam_account_ops.py UPDATE key new_email'
"""

import sys

from esos.esos import (
    Esos,
    EsosError,
    EsosFileMode,
    EsosLocateOption,
    EsosOpenFlags,
    EsosDisposition,
    EsosDsorg,
    EsosVsamType,
    FileOptions,
)


# --- BNKCUST record layout (250 bytes, VSAM KSDS, key offset 0, len 5) ---
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
    """Extract a text field from a record buffer."""
    offset, length = layout
    return bytes(record[offset:offset + length]).decode("ascii", errors="replace").strip()


def set_field(record, layout, value):
    """Set a text field in a mutable record buffer (left-justified, space-padded)."""
    offset, length = layout
    encoded = value.encode("ascii")[:length].ljust(length)
    record[offset:offset + length] = encoded


def open_custdata(update=False):
    """Open the CUSTDATA DD using the low-level esos API.

    Returns an EsosFile (context manager).
    """
    opts = FileOptions()
    if update:
        opts.mode_flags = EsosFileMode.MODE_TYPE_READ | EsosFileMode.MODE_FLAG_UPDATE
    else:
        opts.mode_flags = EsosFileMode.MODE_TYPE_READ
    opts.open_flags = EsosOpenFlags.OPEN_MODE_RECORD | EsosOpenFlags.OPEN_MODE_BINARY
    opts.recfm = "KS"
    opts.lrecl = CUST_LRECL
    opts.disposition = EsosDisposition.FLAG_DISP_SHR if not update else EsosDisposition.FLAG_DISP_OLD
    opts.dsorg = EsosDsorg.VSAM
    opts.vsam_type = EsosVsamType.CLUSTER
    opts.vsam_key_length = 5

    return Esos.default.file_open("//DD:CUSTDATA", opts)


def read_record(f):
    """Read one record from the current file position. Returns bytearray or None on EOF."""
    buf = bytearray(CUST_LRECL)
    try:
        n = f.read(buf, 0, CUST_LRECL)
        if n == 0:
            return None
        return buf
    except EsosError as e:
        # Status 10 = EOF, 23 = record not found
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


def do_lookup(args):
    """LOOKUP: Random read by primary key."""
    if len(args) < 1:
        print("Usage: vsam_account_ops.py LOOKUP <customer_id>", file=sys.stderr)
        return 1

    key = args[0].encode("ascii").ljust(5)[:5]
    print(f"=== VSAM LOOKUP: key='{key.decode()}' ===")

    with open_custdata() as f:
        found = f.locate(key, EsosLocateOption.KEY_EQ)
        if not found:
            print(f"  Customer '{key.decode().strip()}' not found.")
            return 1

        record = read_record(f)
        if record is None:
            print(f"  Customer '{key.decode().strip()}' not found (read failed).")
            return 1

        print_customer(record)

    print("=== Lookup Complete ===")
    return 0


def do_browse(args):
    """BROWSE: Sequential read from a starting key."""
    start_key = args[0].encode("ascii").ljust(5)[:5] if args else b'     '
    max_records = int(args[1]) if len(args) > 1 else 10

    print(f"=== VSAM BROWSE: start='{start_key.decode().strip()}', max={max_records} ===")
    print(f"{'PID':<6s} {'Name':<25s} {'State':<6s} {'Email':<30s}")
    print("-" * 70)

    with open_custdata() as f:
        found = f.locate(start_key, EsosLocateOption.KEY_GE)
        if not found:
            print("  No records found at or after the given key.")
            return 0

        count = 0
        while count < max_records:
            record = read_record(f)
            if record is None:
                break
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


def do_update(args):
    """UPDATE: Read-for-update and rewrite a customer's email field."""
    if len(args) < 2:
        print("Usage: vsam_account_ops.py UPDATE <customer_id> <new_email>",
              file=sys.stderr)
        return 1

    key = args[0].encode("ascii").ljust(5)[:5]
    new_email = args[1]
    print(f"=== VSAM UPDATE: key='{key.decode().strip()}', new_email='{new_email}' ===")

    with open_custdata(update=True) as f:
        found = f.locate(key, EsosLocateOption.KEY_EQ)
        if not found:
            print(f"  Customer '{key.decode().strip()}' not found.")
            return 1

        record = read_record(f)
        if record is None:
            print(f"  Customer '{key.decode().strip()}' not found (read failed).")
            return 1

        old_email = field(record, CUST_EMAIL)
        print(f"  Before: email='{old_email}'")

        set_field(record, CUST_EMAIL, new_email)
        f.update(bytes(record), 0, CUST_LRECL)

        print(f"  After:  email='{new_email}'")

    print("=== Update Complete ===")
    return 0


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
    try:
        main()
    except Exception as e:
        import traceback
        print(f"ERROR: {e}", file=sys.stderr)
        traceback.print_exc(file=sys.stderr)
