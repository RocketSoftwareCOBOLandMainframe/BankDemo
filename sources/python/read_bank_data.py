"""
Read bank account data from a dataset allocated via JCL DD.
Demonstrates using zoautil_py to access sequential datasets
from Python in a batch environment.

This is the Python equivalent of ReadBankData.java.

Usage: EXEC PGM=PYLDM,PARM='+I read_bank_data.py 5'
"""
import sys
from zoautil_py.zoau_io import zopen, ALL
from esos.esos import EsosLocateOption


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

    Record layout (VSAM KSDS, lrecl=200, key offset 5, key length 9):
        Offset 0-4:  Customer ID  (5 bytes)
        Offset 5-13: Account ID   (9 bytes) [primary key]
        Offset 14:   Account Type (1 byte)
    """
    # Open the dataset allocated to DD name ACCDATA.
    # Must specify lrecl and recfm — Python zopen requires these explicitly.
    # BNKACC is a VSAM KSDS (Key Sequenced) dataset.
    f = zopen("//DD:ACCDATA", "r", lrecl=200, recfm="KS")
    try:
        f._file.locate(b'', EsosLocateOption.KEY_FIRST)  # START at first record

        # Read records manually - esos raises FILE_ACCESS (status 10) on EOF
        # rather than returning empty bytes as zoautil_py expects.
        records = []
        while True:
            try:
                record = f.readrecord()
                if not record:
                    break
                records.append(record)
            except Exception:
                # Status 10 = EOF, treat as end of data
                break
        count = len(records)

        for i, record in enumerate(records):
            if i >= display_n:
                break

            # Extract fields from fixed-length record via byte slicing
            cust_id = record[0:5].decode("ascii").strip()
            account_id = record[5:14].decode("ascii").strip()
            account_type = record[14:15].decode("ascii").strip()

            print(f"  Account: {account_id}  Customer: {cust_id}  Type: {account_type}")

            if i == display_n - 1:
                print(f"  ... (showing first {display_n} records)")

        print(f"  Total records: {count}")
    finally:
        f.close()


if __name__ in ("__main__", "<run_path>"):
    try:
        main()
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc(file=sys.stderr)
