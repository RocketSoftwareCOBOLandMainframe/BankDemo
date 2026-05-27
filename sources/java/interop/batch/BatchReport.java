/**
 * A Java batch program invoked directly via JVMLDM.
 * Demonstrates receiving arguments and writing output.
 *
 * Usage: EXEC PGM=JVMLDM86,PARM='BatchReport arg1 arg2'
 */
class BatchReport {
    public static void main(String[] args) {
        System.out.println("=== Batch Report Generator ===");
        System.out.println("Arguments received: " + args.length);

        for (int i = 0; i < args.length; i++) {
            System.out.println("  arg[" + i + "] = " + args[i]);
        }

        System.out.println("Report complete. RC=0");
    }
}
