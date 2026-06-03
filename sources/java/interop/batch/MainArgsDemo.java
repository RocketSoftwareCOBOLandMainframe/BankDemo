import com.rocketsoftware.jzos.*;

/**
 * Demonstrates passing complex MAINARGS patterns to a Java batch program.
 * Shows how JVMLDM parses quoted strings and special characters from
 * the MAINARGS DD — useful for regex filters, file paths, etc.
 *
 * Usage via JCL Procedure:
 *   //STEP00   EXEC PROC=JVMPRC86,
 *   //             JAVACLS='MainArgsDemo'
 *   //MAINARGS  DD *
 *   'Test string 1' 'T[e].+[0-9]' '--verbose'
 *   /*
 *
 * JVMLDM reads MAINARGS DD (or JZOS_MAIN_ARGS env) and passes
 * each token as a separate argument to main(String[] args).
 */
public class MainArgsDemo {
    public static void main(String[] args) {
        System.out.println("=== MAINARGS Demonstration ===");
        System.out.println("Total arguments: " + args.length);
        System.out.println();

        for (int i = 0; i < args.length; i++) {
            System.out.printf("  args[%d] = '%s' (length=%d)%n",
                i, args[i], args[i].length());
        }

        System.out.println();

        // Demonstrate using args as regex patterns
        if (args.length >= 2) {
            String testData = args[0];
            String pattern = args[1];
            System.out.println("Regex test:");
            System.out.println("  Data:    '" + testData + "'");
            System.out.println("  Pattern: '" + pattern + "'");
            boolean matches = testData.matches(pattern);
            System.out.println("  Match:   " + matches);
        }

        // Check for flags
        boolean verbose = false;
        for (String arg : args) {
            if ("--verbose".equals(arg)) {
                verbose = true;
            }
        }

        if (verbose) {
            System.out.println();
            System.out.println("Verbose mode enabled. System properties:");
            System.out.println("  java.version = " + System.getProperty("java.version"));
            System.out.println("  java.home    = " + System.getProperty("java.home"));
            System.out.println("  user.dir     = " + System.getProperty("user.dir"));
            System.out.println("  file.encoding= " + System.getProperty("file.encoding"));
        }

        System.out.println();
        System.out.println("=== MAINARGS Demo Complete. RC=0 ===");
    }
}
