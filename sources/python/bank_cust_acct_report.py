"""
Multi-step batch report: Customer Account Summary.

Step 1 (FILTER): Read BNKCUST, filter by customer ID pattern, write matches to stdout.
Step 2 (REPORT): Read BNKACC, decode COMP-3 balances, produce formatted report.

Usage:
  EXEC PGM=PYLDM,PARM='bank_cust_acct_report.py FILTER pattern'
  EXEC PGM=PYLDM,PARM='bank_cust_acct_report.py REPORT [max_records]'
"""

import re
import sys
from decimal import Decimal

from zoautil_py.zoau_io import zopen
from esos.esos import EsosLocateOption


# --- BNKCUST record layout (250 bytes, VSAM KSDS, key offset 0, len 5) ---
CUST_LRECL = 250
CUST_PID = (0, 5)
CUST_NAME = (5, 25)
CUST_ADDR1 = (64, 25)
CUST_STATE = (114, 2)
CUST_TEL = (128, 12)
CUST_EMAIL = (140, 30)

# --- BNKACC record layout (200 bytes, VSAM KSDS, key offset 5, len 9) ---
ACC_LRECL = 200
ACC_PID = (0, 5)
ACC_ACCNO = (5, 9)
ACC_TYPE = (14, 1)
ACC_BALANCE_OFFSET = 15
ACC_BALANCE_LEN = 5  # PIC S9(7)V99 COMP-3


def field(record, offset_len):
    """Extract a text field from a record."""
    offset, length = offset_len
    return record[offset:offset + length].decode("ascii", errors="replace").strip()


def unpack_comp3(data, offset, length, scale):
    """Decode a COMP-3 (packed decimal) field to Decimal.

    COMP-3 stores two digits per byte (high/low nybble),
    with the last nybble being the sign (C=+, D=-, F=unsigned+).
    """
    digits = []
    for i in range(length):
        b = data[offset + i]
        digits.append(str((b >> 4) & 0x0F))
        if i < length - 1:
            digits.append(str(b & 0x0F))
    sign_nybble = data[offset + length - 1] & 0x0F
    int_value = int("".join(digits))
    value = Decimal(int_value) / Decimal(10 ** scale)
    return -value if sign_nybble == 0x0D else value


def read_vsam_records(file_handle):
    """Read all records from a positioned VSAM file, handling EOF as exception."""
    records = []
    while True:
        try:
            record = file_handle.readrecord()
            if not record:
                break
            records.append(record)
        except Exception:
            break
    return records


def do_filter(args):
    """FILTER mode: read BNKCUST, filter by PID pattern, output matches."""
    if len(args) < 1:
        pattern = ".*"
    else:
        pattern = args[0]

    print(f"=== Customer Filter: pattern='{pattern}' ===")
    regex = re.compile(pattern)

    f = zopen("//DD:CUSTDATA", "r", lrecl=CUST_LRECL, recfm="KS")
    try:
        f._file.locate(b'', EsosLocateOption.KEY_FIRST)
        records = read_vsam_records(f)

        matches = 0
        for record in records:
            pid = field(record, CUST_PID)
            if regex.search(pid):
                name = field(record, CUST_NAME)
                state = field(record, CUST_STATE)
                email = field(record, CUST_EMAIL)
                print(f"  {pid}  {name:<25s}  {state}  {email}")
                matches += 1

        print(f"--- {matches} customers matched out of {len(records)} total ---")
    finally:
        f.close()

    return 0


def do_report(args):
    """REPORT mode: read BNKACC, decode balances, produce account summary."""
    max_records = int(args[0]) if args else 20

    print("=== Account Balance Report ===")
    print(f"{'PID':<6s} {'Account':<10s} {'Type':<5s} {'Balance':>12s}")
    print("-" * 40)

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
    try:
        main()
    except Exception as e:
        import traceback
        print(f"ERROR: {e}", file=sys.stderr)
        traceback.print_exc(file=sys.stderr)
