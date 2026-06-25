"""
Step 2 Demo: Non-VSAM Sequential File I/O with zoautil_py.

Demonstrates reading and writing a Physical Sequential (PS) dataset using
zoautil_py's zopen() API. This is basic flat-file I/O - no VSAM keyed
access, no locate/browse. Records are read/written sequentially.

Two operations are shown:
  WRITE - Write sample transaction records to the PS file
  READ  - Read records back and produce a formatted summary report

Key concepts demonstrated:
  - zopen() for sequential access: zopen(path, mode, lrecl=N, recfm="F")
  - Fixed record format: classic mainframe card-image (LRECL=80)
  - RecordIO write/readrecord: one record at a time
  - DD DSN=...,DISP=OLD allocation in JCL (same pattern as VSAM)
  - Batch JCL integration via PYLDM and STDENV environment variables

Note: Scripts running under PYLDM must NOT call sys.exit(). The embedded
Python interpreter does not handle SystemExit cleanly; instead, let the
script return naturally from its top-level code.

Record layout (80-byte fixed):
  Offset  Length  Field
  ------  ------  -----
    0       8     Transaction ID
    8       5     Account Number
   13       8     Date (YYYYMMDD)
   21       2     Type (DR=debit, CR=credit)
   23      12     Amount (right-justified, 2 decimal places)
   35      45     Description

See PYREADBNK.jcl for the JCL that runs WRITE and READ steps.

Usage:
  EXEC PGM=PYLDM,PARM='sequential_file_ops.py WRITE'
  EXEC PGM=PYLDM,PARM='sequential_file_ops.py READ'
  EXEC PGM=PYLDM,PARM='sequential_file_ops.py WRITEREAD'
"""
import sys

from zoautil_py.zoau_io import zopen

# Record layout: 80-byte Fixed
LRECL = 80

# Sample transaction data to write
SAMPLE_TRANSACTIONS = [
    ("TXN00001", "10001", "20260615", "CR", "1500.00", "Monthly salary deposit"),
    ("TXN00002", "10001", "20260616", "DR", "45.99", "Grocery store purchase"),
    ("TXN00003", "10002", "20260616", "CR", "3200.00", "Wire transfer received"),
    ("TXN00004", "10001", "20260617", "DR", "120.00", "Utility bill payment"),
    ("TXN00005", "10003", "20260617", "CR", "500.00", "ATM cash deposit"),
    ("TXN00006", "10002", "20260618", "DR", "89.50", "Online subscription"),
    ("TXN00007", "10003", "20260618", "DR", "250.00", "Insurance premium"),
    ("TXN00008", "10001", "20260619", "CR", "200.00", "Refund processed"),
    ("TXN00009", "10002", "20260620", "DR", "1800.00", "Rent payment"),
    ("TXN00010", "10003", "20260620", "CR", "75.00", "Interest credit"),
]


def format_record(txn_id, account, date, txn_type, amount, description):
    """Format fields into an 80-byte fixed-length record.

    Each field is left-justified and space-padded to its defined width,
    matching COBOL MOVE semantics for PIC X fields.
    """
    rec = (
        txn_id.ljust(8) +
        account.ljust(5) +
        date.ljust(8) +
        txn_type.ljust(2) +
        amount.rjust(12) +
        description.ljust(45)
    )
    return rec[:LRECL].ljust(LRECL)


def parse_record(record):
    """Parse an 80-byte record into its component fields."""
    text = record if isinstance(record, str) else record.decode("ascii", errors="replace")
    return {
        "txn_id": text[0:8].strip(),
        "account": text[8:13].strip(),
        "date": text[13:21].strip(),
        "type": text[21:23].strip(),
        "amount": text[23:35].strip(),
        "description": text[35:80].strip(),
    }


def do_write():
    """Write sample transaction records to the sequential file.

    Opens the PS dataset for writing and populates it with sample
    transaction records via zoautil_py.
    """
    print("=== Sequential Write: Writing transaction records ===")

    f = zopen("//DD:TXNDATA", "w", lrecl=LRECL, recfm="F")
    if f is None:
        print("ERROR: Could not open //DD:TXNDATA for writing.", file=sys.stderr)
        return 1
    try:
        count = 0
        for txn in SAMPLE_TRANSACTIONS:
            record = format_record(*txn)
            f.write(record.encode("ascii"))
            count += 1
            print(f"  Wrote: {txn[0]}  Acct={txn[1]}  {txn[3]}  {txn[4]:>10}")

        print(f"  ---")
        print(f"  Total records written: {count}")
    finally:
        f.close()
        del f

    print("=== Write Complete ===")
    return 0


def do_read():
    """Read transaction records from the sequential file and produce a summary.

    Demonstrates sequential reading of a PS dataset using zoautil_py's
    zopen, accumulating totals by account and transaction type.
    """
    print("=== Sequential Read: Transaction Summary ===")

    f = zopen("//DD:TXNDATA", "r", lrecl=LRECL, recfm="F")
    if f is None:
        print("ERROR: Could not open //DD:TXNDATA for reading.", file=sys.stderr)
        return 1
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
    finally:
        f.close()
        del f

    if not records:
        print("  No records found.")
        return 0

    # Produce summary by account
    accounts = {}
    for rec in records:
        acct = rec["account"]
        if acct not in accounts:
            accounts[acct] = {"credits": 0.0, "debits": 0.0, "count": 0}
        amount = float(rec["amount"])
        if rec["type"] == "CR":
            accounts[acct]["credits"] += amount
        else:
            accounts[acct]["debits"] += amount
        accounts[acct]["count"] += 1

    # Display record listing
    print(f"  {'TXN ID':<10} {'ACCT':<7} {'DATE':<10} {'TYPE':<5} {'AMOUNT':>10}  DESCRIPTION")
    print(f"  {'-'*10} {'-'*7} {'-'*10} {'-'*5} {'-'*10}  {'-'*20}")
    for rec in records:
        print(f"  {rec['txn_id']:<10} {rec['account']:<7} {rec['date']:<10} "
              f"{rec['type']:<5} {rec['amount']:>10}  {rec['description']}")

    # Display account summary
    print()
    print(f"  {'ACCOUNT':<10} {'RECORDS':>8} {'CREDITS':>12} {'DEBITS':>12} {'NET':>12}")
    print(f"  {'-'*10} {'-'*8} {'-'*12} {'-'*12} {'-'*12}")
    total_credits = 0.0
    total_debits = 0.0
    for acct in sorted(accounts):
        info = accounts[acct]
        net = info["credits"] - info["debits"]
        total_credits += info["credits"]
        total_debits += info["debits"]
        print(f"  {acct:<10} {info['count']:>8} {info['credits']:>12.2f} "
              f"{info['debits']:>12.2f} {net:>12.2f}")
    print(f"  {'TOTAL':<10} {len(records):>8} {total_credits:>12.2f} "
          f"{total_debits:>12.2f} {total_credits - total_debits:>12.2f}")

    print()
    print(f"  Total records read: {len(records)}")
    print("=== Read Complete ===")
    return 0


def main(args=None):
    if args is None:
        args = sys.argv[1:]

    if len(args) < 1:
        print("Usage: sequential_file_ops.py WRITE|READ", file=sys.stderr)
        return 1

    operation = args[0].upper()

    if operation == "WRITE":
        return do_write()
    elif operation == "READ":
        return do_read()
    elif operation == "WRITEREAD":
        rc = do_write()
        if rc != 0:
            return rc
        return do_read()
    else:
        print(f"Unknown operation: {operation}", file=sys.stderr)
        print("Usage: sequential_file_ops.py WRITE|READ|WRITEREAD", file=sys.stderr)
        return 1


if __name__ in ("__main__", "<run_path>"):
    main()
