"""
A Python batch script invoked directly via PYLDM from JCL.
Demonstrates receiving arguments and writing output.

PYLDM handles stream redirection automatically - no need to call
redirect_streams()/restore_streams() like in the COBOL bootstrap case.

Usage:
  Script mode: EXEC PGM=PYLDM,PARM='+I batch_report.py arg1 arg2'
  Module mode: EXEC PGM=PYLDM,PARM='+I -m batch_report arg1 arg2'
"""
import os
import sys


def main(args=None):
    """Entry point for module mode (-m batch_report).

    Args:
        args: List of arguments passed by PYLDM, or None.
    """
    if args is None:
        args = sys.argv[1:]

    print("=" * 60)
    print("Python Batch Report (via PYLDM)")
    print("=" * 60)

    print(f"\nScript: {sys.argv[0]}")
    print(f"Python version: {sys.version}")
    print(f"Working directory: {os.getcwd()}")

    print(f"\nArguments received: {len(args)}")
    for i, arg in enumerate(args):
        print(f"  arg[{i}] = {arg!r}")

    # Show selected ESPY_* environment variables
    print("\nPYLDM environment:")
    for key in sorted(k for k in os.environ if k.startswith("ESPY_")):
        print(f"  {key} = {os.environ[key]}")

    # Show PYTHONPATH entries
    print("\nPYTHONPATH entries:")
    pythonpath = os.environ.get("PYTHONPATH", "")
    for i, p in enumerate(pythonpath.split(os.pathsep), 1):
        if p:
            print(f"  [{i}] {p}")

    print(f"\nReport complete. RC=0")
    print("=" * 60)
    return 0


if __name__ in ("__main__", "<run_path>"):
    try:
        main()
    except Exception as e:
        import sys, traceback
        print(f"ERROR: {e}", file=sys.stderr)
        traceback.print_exc(file=sys.stderr)
