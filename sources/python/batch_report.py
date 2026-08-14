"""
Step 1 Demo: Using PYLDM Directly from JCL.

This is the simplest possible Python script invoked from a batch JCL job.
It demonstrates how arguments flow from JCL to Python and how output
is automatically redirected to JCL DDs.

PYLDM (Python Language Definition Module) is the COBOL program that hosts
the Python interpreter inside Enterprise Server. It can run Python two ways:

  Script mode: PARM='+I batch_report.py arg1 arg2'
      - Runs the .py file directly (like "python batch_report.py arg1 arg2")
      - Entry: module-level code / if __name__ == "__main__"
      - Needs ESPY_WORKING_DIR set so PYLDM can find the script file

  Module mode: PARM='+I -m batch_report arg1 arg2'
      - Imports the module and calls main(args) (like "python -m batch_report")
      - Entry: def main(args) function below
      - Needs PYTHONPATH set so the module is importable

Stream redirection is automatic - print() goes to the STDOUT DD,
print(..., file=sys.stderr) goes to STDERR DD. No manual setup needed.

Arguments come from three sources (assembled in this order):
  1. PARM string (after the script/module name)
  2. ESPY_MAIN_ARGS environment variable (set in STDENV DD)
  3. MAINARGS DD (inline data, one arg per line)

See PYDEMO.jcl for the JCL that invokes this script.
"""
import os
import sys


def main(args=None):
    """Entry point for module mode (-m batch_report).

    In module mode, PYLDM imports this module and calls main(args)
    with the argument list. In script mode, main() is called from
    the if __name__ block below with args=None, so it reads sys.argv.
    """
    if args is None:
        args = sys.argv[1:]

    print("=" * 60)
    print("Python Batch Report (via PYLDM)")
    print("=" * 60)

    # sys.argv[0] is the script path (script mode) or module name (module mode)
    print(f"\nScript: {sys.argv[0]}")
    print(f"Python version: {sys.version}")
    print(f"Working directory: {os.getcwd()}")

    # Display all arguments received from JCL PARM / MAINARGS / ESPY_MAIN_ARGS
    print(f"\nArguments received: {len(args)}")
    for i, arg in enumerate(args):
        print(f"  arg[{i}] = {arg!r}")

    # ESPY_* variables control PYLDM behavior. These are set in the STDENV DD
    # of the JCL and synced to Python's os.environ by PYLDM at startup.
    print("\nPYLDM environment:")
    for key in sorted(k for k in os.environ if k.startswith("ESPY_")):
        print(f"  {key} = {os.environ[key]}")

    # PYTHONPATH tells Python where to find importable modules.
    # Set in STDENV DD, typically pointing to the sources/python directory.
    print("\nPYTHONPATH entries:")
    pythonpath = os.environ.get("PYTHONPATH", "")
    for i, p in enumerate(pythonpath.split(os.pathsep), 1):
        if p:
            print(f"  [{i}] {p}")

    print(f"\nReport complete. RC=0")
    print("=" * 60)
    return 0


if __name__ in ("__main__", "<run_path>"):
    main()
