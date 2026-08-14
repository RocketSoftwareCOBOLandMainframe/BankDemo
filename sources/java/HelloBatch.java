import com.rocketsoftware.jzos.ZUtil;

/**
 * A simple Java class invoked from COBOL in a batch JCL job.
 * The static run() method is the entry point called by COBOL.
 *
 * Usage: CALL "Java.HelloBatch.run" from COBOL
 */
class HelloBatch {
    public static void run() {
        try {
            // Explicitly map Java standard streams to JCL DDs when not using JVMLDM.
            ZUtil.redirectStandardStreams("iso-8859-1", true);

            System.out.println("Hello from Java in a batch job!");
            System.out.println("Java version: " + System.getProperty("java.version"));
            System.out.println("Working directory: " + System.getProperty("user.dir"));
            System.out.println("Env var (ESOS_TEST_VAR): " + System.getenv("ESOS_TEST_VAR"));
        } catch (Exception e) {
            System.err.println("ERROR: " + e.getMessage());
            e.printStackTrace(System.err);
        } finally {
            ZUtil.restoreStandardStreams();
        }
    }
}